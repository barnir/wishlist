import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mywishstash/models/user_profile.dart';
import 'package:mywishstash/repositories/page.dart';
import 'package:mywishstash/utils/app_logger.dart';

/// Simplified search repository for public users.
/// Firestore doesn't support full text search natively; this performs a
/// prefix search on lowercased display_name and email fields that should be
/// maintained (consider adding a `search_tokens` array in future for better matching).
class UserSearchRepository {
  final FirebaseFirestore _firestore;
  UserSearchRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      return r;
    } catch (e, st) {
      logE(
        'UserSearchRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}',
        tag: 'SEARCH',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Returns a page of public users whose display_name or email starts with the query (case-insensitive).
  /// If query length < 2 returns empty immediately.
  Future<PageResult<UserProfile>> searchPage({
    required String query,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('searchPage', () async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) {
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }

    // Strategy: query ordered by display_name_lower then filter in memory for prefix; fallback to email search if not enough.
    // Assumes documents have auxiliary lowercase fields (add if missing) else we normalize on the fly after fetch.
    var baseQuery = _firestore
        .collection('users')
        .where('is_private', isEqualTo: false)
        .orderBy('display_name');

    if (startAfter != null) {
      baseQuery = baseQuery.startAfterDocument(startAfter);
    }

    // Attempt the indexed query first. If Firestore rejects it because a
    // composite index is required, fallback to an unordered scan (still
    // scoped to is_private==false) and perform the prefix filtering client-side.
    QuerySnapshot snap;
    try {
      snap = await baseQuery.limit(limit * 2).get(); // overfetch for filtering
    } catch (e) {
      // Common Firestore error when an index is missing: failed-precondition
      // with message pointing to the console index creation URL. Fall back.
      logW(
        'User search indexed query failed, falling back to unordered scan: $e',
        tag: 'SEARCH',
      );
      var fallback = _firestore
          .collection('users')
          .where('is_private', isEqualTo: false);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      // Increase fetch window when unordered to avoid excessive roundtrips.
      snap = await fallback.limit(limit * 4).get();
    }
    final docs = snap.docs;
    final matches = <UserProfile>[];
    for (final d in docs) {
      final dataObj = d.data();
      final Map<String, dynamic>? data = dataObj is Map<String, dynamic>
          ? dataObj
          : null;
      if (data == null) continue;
      final display = (data['display_name'] as String? ?? '').toLowerCase();
      final email = (data['email'] as String? ?? '').toLowerCase();
      if (display.startsWith(q) || email.startsWith(q)) {
        // Build a map safely from the Firestore map
        final mp = <String, dynamic>{'id': d.id};
        mp.addAll(data);
        matches.add(UserProfile.fromMap(mp));
      }
      if (matches.length >= limit) break;
    }

    // Choose lastDoc based on the position of the final matched doc in the original docs
    DocumentSnapshot? lastDoc;
    if (matches.isNotEmpty) {
      final lastMatchedId = matches.last.id;
      final idx = docs.indexWhere((d) => d.id == lastMatchedId);
      if (idx >= 0) {
        lastDoc = docs[idx];
      }
    } else if (docs.isNotEmpty) {
      lastDoc =
          docs.last; // still allow pagination attempts if there are more docs
    }
    final hasMore = matches.length == limit && lastDoc != null;
    logI(
      'User search page',
      tag: 'SEARCH',
      data: {'query': q, 'returned': matches.length, 'hasMore': hasMore},
    );
    return PageResult(items: matches, lastDoc: lastDoc, hasMore: hasMore);
  });

  /// Returns a page of public users without search query (for explore screen initialization).
  /// This method loads public profiles to show when the explore screen is first opened.
  /// Excludes the current user from results.
  Future<PageResult<UserProfile>> getPublicUsersPage({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('getPublicUsersPage', () async {
    // Get current user ID to exclude from results
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid;

    var query = _firestore
        .collection('users')
        .where('is_private', isEqualTo: false)
        .orderBy('display_name');

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot snap;
    try {
      snap = await query
          .limit(limit * 2)
          .get(); // Get more to account for filtering
    } catch (e) {
      // Fallback to unordered query if index is not ready
      logW(
        'Public users indexed query failed, falling back to unordered scan: $e',
        tag: 'SEARCH',
      );
      var fallback = _firestore
          .collection('users')
          .where('is_private', isEqualTo: false);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      snap = await fallback
          .limit(limit * 2)
          .get(); // Get more to account for filtering
    }

    final docs = snap.docs;
    final users = <UserProfile>[];
    for (final d in docs) {
      // Skip current user
      if (currentUserId != null && d.id == currentUserId) {
        continue;
      }

      final dataObj = d.data();
      final Map<String, dynamic>? data = dataObj is Map<String, dynamic>
          ? dataObj
          : null;
      if (data == null) continue;

      // Build a map safely from the Firestore map
      final mp = <String, dynamic>{'id': d.id};
      mp.addAll(data);
      users.add(UserProfile.fromMap(mp));

      // Stop when we have enough users after filtering
      if (users.length >= limit) break;
    }

    final lastDoc = docs.isNotEmpty ? docs.last : null;
    final hasMore = docs.length == limit;
    logI(
      'Public users page loaded',
      tag: 'SEARCH',
      data: {'returned': users.length, 'hasMore': hasMore},
    );
    return PageResult(items: users, lastDoc: lastDoc, hasMore: hasMore);
  });

  /// Test basic database connectivity
  Future<bool> testConnectivity() async {
    try {
      logI('Testing Firestore connectivity...', tag: 'CONTACT_DEBUG');

      // Try to get current user's own profile first (should always work)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          logI('✅ User profile accessible', tag: 'CONTACT_DEBUG');
        } else {
          logW('⚠️ Current user profile does not exist', tag: 'CONTACT_DEBUG');
        }
      }

      // Test basic query
      final testQuery = await _firestore
          .collection('users')
          .limit(1)
          .get(const GetOptions(source: Source.server)); // Force server query

      logI(
        '✅ Firestore connectivity OK - ${testQuery.docs.length} docs retrieved',
        tag: 'CONTACT_DEBUG',
      );
      return true;
    } catch (e) {
      logE('❌ Firestore connectivity failed: $e', tag: 'CONTACT_DEBUG');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') ||
          errorStr.contains('unable to resolve host') ||
          errorStr.contains('unavailable')) {
        logW('📡 Network connectivity issue detected', tag: 'CONTACT_DEBUG');
      } else if (errorStr.contains('permission')) {
        logW(
          '🔒 Permission denied - check Firestore rules',
          tag: 'CONTACT_DEBUG',
        );
      } else {
        logW('❓ Unknown connectivity error', tag: 'CONTACT_DEBUG');
      }
      return false;
    }
  }

  /// Debug method to check what users exist in the database
  Future<void> debugAllUsers() async => _withLatency('debugAllUsers', () async {
    try {
      logI('=== DATABASE USERS DEBUG START ===', tag: 'CONTACT_DEBUG');

      // Check current authentication
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        logI(
          '📱 Authentication Status: ${currentUser.email} (${currentUser.uid})',
          tag: 'CONTACT_DEBUG',
        );
      } else {
        logW(
          '❌ No authenticated user - this will cause permission issues',
          tag: 'CONTACT_DEBUG',
        );
        return;
      }

      // Test connectivity first
      final isConnected = await testConnectivity();
      if (!isConnected) {
        logW(
          '❌ Database connectivity failed - skipping user enumeration',
          tag: 'CONTACT_DEBUG',
        );
        return;
      }

      // Try to get ALL users first to see total count
      final allUsersSnapshot = await _firestore.collection('users').get();
      logI(
        '📊 Total users in database: ${allUsersSnapshot.docs.length}',
        tag: 'CONTACT_DEBUG',
      );

      if (allUsersSnapshot.docs.isEmpty) {
        logW('⚠️ Database appears to be empty', tag: 'CONTACT_DEBUG');
        return;
      }

      // Check for Portuguese phone numbers specifically
      int portuguesePhoneCount = 0;
      for (final doc in allUsersSnapshot.docs) {
        final data = doc.data();
        final phoneNumber = data['phone_number'] as String?;
        final displayName = data['display_name'] as String? ?? 'Unknown';
        final email = data['email'] as String? ?? 'No email';
        final isPrivate = data['is_private'] as bool? ?? false;

        if (phoneNumber != null && phoneNumber.contains('+351')) {
          portuguesePhoneCount++;
          logI(
            '🇵🇹 Portuguese User: $displayName | Phone: $phoneNumber | Email: $email | Private: $isPrivate',
            tag: 'CONTACT_DEBUG',
          );
        }
      }

      logI(
        '📞 Users with Portuguese phone numbers: $portuguesePhoneCount',
        tag: 'CONTACT_DEBUG',
      );

      if (portuguesePhoneCount == 0) {
        logW(
          '⚠️ No Portuguese phone numbers found in database',
          tag: 'CONTACT_DEBUG',
        );
        logW(
          'This explains why contact matching is failing',
          tag: 'CONTACT_DEBUG',
        );
      }

      logI('=== DATABASE USERS DEBUG END ===', tag: 'CONTACT_DEBUG');
    } catch (e) {
      logE('❌ Error debugging users: $e', tag: 'CONTACT_DEBUG');

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission')) {
        logW(
          '🔒 Permission denied - this suggests Firestore rules need adjustment',
          tag: 'CONTACT_DEBUG',
        );
      } else if (errorStr.contains('network')) {
        logW(
          '📡 Network error - check internet connection',
          tag: 'CONTACT_DEBUG',
        );
      } else {
        logW('❓ Unexpected error type', tag: 'CONTACT_DEBUG');
      }
    }
  });

  /// Finds registered users by phone numbers or emails.
  /// Returns a map where keys are the contact identifiers (phone/email) and values are UserProfile objects.
  Future<Map<String, UserProfile>> findUsersByContacts({
    required List<String> phoneNumbers,
    required List<String> emails,
  }) async => _withLatency('findUsersByContacts', () async {
    final results = <String, UserProfile>{};

    // Debug: Check what users are in the database
    await debugAllUsers();

    // Clean and normalize phone numbers (remove spaces, dashes, etc.)
    final cleanPhones = phoneNumbers
        .map((p) => _normalizePhoneNumber(p))
        .where((p) => p != null && p.isNotEmpty)
        .cast<String>()
        .toList();

    logI('Searching for phones: $cleanPhones', tag: 'CONTACT_SEARCH');

    // Normalize emails to lowercase
    final cleanEmails = emails
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Search by phone numbers in batches (Firestore whereIn limit is 10)
    if (cleanPhones.isNotEmpty) {
      try {
        const batchSize = 10;
        final phoneBatches = <List<String>>[];

        // Split phones into batches of 10
        for (int i = 0; i < cleanPhones.length; i += batchSize) {
          final endIndex = (i + batchSize > cleanPhones.length)
              ? cleanPhones.length
              : i + batchSize;
          phoneBatches.add(cleanPhones.sublist(i, endIndex));
        }

        logI(
          'Processing ${phoneBatches.length} phone batches (${cleanPhones.length} total phones)',
          tag: 'CONTACT_SEARCH',
        );

        // Query each batch separately
        for (int batchNum = 0; batchNum < phoneBatches.length; batchNum++) {
          final batch = phoneBatches[batchNum];
          logI(
            'Querying phone batch ${batchNum + 1}/${phoneBatches.length}: ${batch.length} phones',
            tag: 'CONTACT_SEARCH',
          );
          logI('Phone numbers in batch: $batch', tag: 'CONTACT_SEARCH');

          final phoneQuery = await _firestore
              .collection('users')
              .where('phone_number', whereIn: batch)
              .get();

          logI(
            'Phone batch ${batchNum + 1} returned ${phoneQuery.docs.length} users',
            tag: 'CONTACT_SEARCH',
          );

          // Debug: log what phone numbers were actually found
          if (phoneQuery.docs.isNotEmpty) {
            for (final doc in phoneQuery.docs) {
              final data = doc.data();
              final foundPhone = data['phone_number'];
              final userName = data['display_name'] ?? 'Unknown';
              logI(
                '  📞 Found user: $userName with phone: $foundPhone',
                tag: 'CONTACT_SEARCH',
              );
            }
          }

          for (final doc in phoneQuery.docs) {
            final data = doc.data();
            final mp = <String, dynamic>{'id': doc.id};
            mp.addAll(data);
            final user = UserProfile.fromMap(mp);
            if (user.phoneNumber != null) {
              logI(
                'Found user ${user.displayName} with phone: ${user.phoneNumber}',
                tag: 'CONTACT_SEARCH',
              );
              results[user.phoneNumber!] = user;
            }
          }
        }
      } catch (e) {
        logE('Error searching users by phone: $e', tag: 'CONTACT_SEARCH');

        // Categorize the error to help with debugging
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('network') ||
            errorStr.contains('unable to resolve host')) {
          logW(
            'Network connectivity issue detected when searching by phone',
            tag: 'CONTACT_SEARCH',
          );
        } else if (errorStr.contains('permission')) {
          logW(
            'Permission denied when searching by phone - check Firestore rules',
            tag: 'CONTACT_SEARCH',
          );
        } else {
          logW(
            'Unknown error when searching by phone: $e',
            tag: 'CONTACT_SEARCH',
          );
        }
      }
    }

    // Search by emails in batches (Firestore whereIn limit is 10)
    if (cleanEmails.isNotEmpty) {
      try {
        const batchSize = 10;
        final emailBatches = <List<String>>[];

        // Split emails into batches of 10
        for (int i = 0; i < cleanEmails.length; i += batchSize) {
          final endIndex = (i + batchSize > cleanEmails.length)
              ? cleanEmails.length
              : i + batchSize;
          emailBatches.add(cleanEmails.sublist(i, endIndex));
        }

        logI(
          'Processing ${emailBatches.length} email batches (${cleanEmails.length} total emails)',
          tag: 'CONTACT_SEARCH',
        );

        // Query each batch separately
        for (int batchNum = 0; batchNum < emailBatches.length; batchNum++) {
          final batch = emailBatches[batchNum];
          logI(
            'Querying email batch ${batchNum + 1}/${emailBatches.length}: ${batch.length} emails',
            tag: 'CONTACT_SEARCH',
          );

          final emailQuery = await _firestore
              .collection('users')
              .where('email', whereIn: batch)
              .get();

          logI(
            'Email batch ${batchNum + 1} returned ${emailQuery.docs.length} users',
            tag: 'CONTACT_SEARCH',
          );

          for (final doc in emailQuery.docs) {
            final data = doc.data();
            final mp = <String, dynamic>{'id': doc.id};
            mp.addAll(data);
            final user = UserProfile.fromMap(mp);
            if (user.email != null) {
              logI(
                'Found user ${user.displayName} with email: ${user.email}',
                tag: 'CONTACT_SEARCH',
              );
              results[user.email!.toLowerCase()] = user;
            }
          }
        }
      } catch (e) {
        logE('Error searching users by email: $e', tag: 'CONTACT_SEARCH');

        // Categorize the error to help with debugging
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('network') ||
            errorStr.contains('unable to resolve host')) {
          logW(
            'Network connectivity issue detected when searching by email',
            tag: 'CONTACT_SEARCH',
          );
        } else if (errorStr.contains('permission')) {
          logW(
            'Permission denied when searching by email - check Firestore rules',
            tag: 'CONTACT_SEARCH',
          );
        } else {
          logW(
            'Unknown error when searching by email: $e',
            tag: 'CONTACT_SEARCH',
          );
        }
      }
    }

    logI(
      'Contact search completed',
      tag: 'SEARCH',
      data: {
        'phones_searched': cleanPhones.length,
        'emails_searched': cleanEmails.length,
        'users_found': results.length,
      },
    );

    return results;
  });

  /// Normalize phone number for database matching
  /// Uses same logic as ContactsService to ensure consistency
  String? _normalizePhoneNumber(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return null;

    // Remove all non-numeric characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // If starts with 00, replace with +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }

    // Portuguese phone normalization
    if (!cleaned.startsWith('+')) {
      // Portuguese mobile: 9 digits starting with 9
      if (cleaned.length == 9 && cleaned.startsWith('9')) {
        cleaned = '+351$cleaned';
      }
      // Portuguese with national code: 351XXXXXXXXX
      else if (cleaned.length == 12 && cleaned.startsWith('351')) {
        cleaned = '+$cleaned';
      }
      // Portuguese landline/mobile: starting with 2, 3 or 9
      else if (cleaned.length == 9 && RegExp(r'^[239]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
      // Old Portuguese landline: 8 digits starting with 2-3
      else if (cleaned.length == 8 && RegExp(r'^[2-3]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
    }

    return cleaned.isEmpty ? null : cleaned;
  }
}

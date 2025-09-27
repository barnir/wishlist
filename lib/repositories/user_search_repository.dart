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
    bool debug = false,
  }) async => _withLatency('findUsersByContacts', () async {
    final results = <String, UserProfile>{};

    // Light-weight debug (avoid full enumeration unless explicitly required)
    if (debug) {
      logI('Debug contact lookup enabled', tag: 'CONTACT_SEARCH');
    }

    // 1. Normalize & deduplicate inputs early
    final cleanPhones = phoneNumbers
        .map(_normalizePhoneNumber)
        .whereType<String>()
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet() // dedupe
        .toList();

    final cleanEmails = emails
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (debug) {
      logI(
        'Normalized inputs phones=${cleanPhones.length} emails=${cleanEmails.length}',
        tag: 'CONTACT_SEARCH',
      );
    }

    // 2. Short-circuit if nothing to do
    if (cleanPhones.isEmpty && cleanEmails.isEmpty) {
      return results;
    }

    // 3. Partition for whereIn batching. Modern Firestore supports up to 30 values per whereIn.
    const phoneBatchSize = 30; // previously 10
    const emailBatchSize = 30; // previously 10

    List<List<String>> chunkLists(List<String> source, int size) {
      final chunks = <List<String>>[];
      for (var i = 0; i < source.length; i += size) {
        chunks.add(
          source.sublist(
            i,
            i + size > source.length ? source.length : i + size,
          ),
        );
      }
      return chunks;
    }

    final phoneBatches = chunkLists(cleanPhones, phoneBatchSize);
    final emailBatches = chunkLists(cleanEmails, emailBatchSize);

    // Simple per-execution cache to avoid duplicate Firestore lookups in the same call
    final seenDocIds = <String>{};

    Future<void> processBatch({
      required List<String> values,
      required String field,
    }) async {
      if (values.isEmpty) return;
      final query = await _firestore
          .collection('users')
          .where(field, whereIn: values)
          .get();
      for (final doc in query.docs) {
        if (seenDocIds.add(doc.id)) {
          final data = doc.data();
          final mp = <String, dynamic>{'id': doc.id}..addAll(data);
          final user = UserProfile.fromMap(mp);
          // Store under both phone/email canonical keys when present for faster lookup
          if (user.phoneNumber != null) {
            results[user.phoneNumber!] = user;
          }
          if (user.email != null) {
            results[user.email!.toLowerCase()] = user;
          }
        }
      }
      if (debug) {
        logI(
          'Batch field=$field size=${values.length} -> docs=${seenDocIds.length}',
          tag: 'CONTACT_SEARCH',
        );
      }
    }

    // 4. Execute phone & email batches concurrently (bounded by # of batches)
    // Build all tasks
    final tasks = <Future<void>>[
      for (final batch in phoneBatches)
        processBatch(values: batch, field: 'phone_number'),
      for (final batch in emailBatches)
        processBatch(values: batch, field: 'email'),
    ];

    // Throttle concurrency manually by processing in windows
    const maxConcurrent = 6;
    for (var i = 0; i < tasks.length; i += maxConcurrent) {
      final window = tasks.sublist(
        i,
        i + maxConcurrent > tasks.length ? tasks.length : i + maxConcurrent,
      );
      await Future.wait(window); // wait each window to complete
    }

    if (debug) {
      logI(
        'Contact search finished phones=${cleanPhones.length} emails=${cleanEmails.length} users_found=${results.length}',
        tag: 'CONTACT_SEARCH',
      );
    } else {
      logI(
        'Contact search summary',
        tag: 'SEARCH',
        data: {
          'phones': cleanPhones.length,
          'emails': cleanEmails.length,
          'found': results.length,
        },
      );
    }

    return results;
  });

  /// Streaming variant: emits partial maps as batches complete so UI can update incrementally.
  /// Each event contains only the newly discovered users (delta) keyed by phone/email canonical form.
  Stream<Map<String, UserProfile>> streamUsersByContacts({
    required List<String> phoneNumbers,
    required List<String> emails,
    bool debug = false,
  }) async* {
    // Reuse normalization logic similar to findUsersByContacts (duplicated minimally to keep streaming lazy semantics).
    final cleanPhones = phoneNumbers
        .map(_normalizePhoneNumber)
        .whereType<String>()
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toSet()
        .toList();
    final cleanEmails = emails
        .map((e) => e.toLowerCase().trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (cleanPhones.isEmpty && cleanEmails.isEmpty) {
      if (debug) {
        logI('streamUsersByContacts empty input', tag: 'CONTACT_SEARCH');
      }
      return;
    }

    const phoneBatchSize = 30;
    const emailBatchSize = 30;
    List<List<String>> chunkLists(List<String> src, int size) {
      final out = <List<String>>[];
      for (var i = 0; i < src.length; i += size) {
        out.add(src.sublist(i, i + size > src.length ? src.length : i + size));
      }
      return out;
    }

    final phoneBatches = chunkLists(cleanPhones, phoneBatchSize);
    final emailBatches = chunkLists(cleanEmails, emailBatchSize);
    final seenDocIds = <String>{};

    Future<Map<String, UserProfile>> runBatch(
      List<String> values,
      String field,
    ) async {
      if (values.isEmpty) return {};
      try {
        final snap = await _firestore
            .collection('users')
            .where(field, whereIn: values)
            .get();
        final delta = <String, UserProfile>{};
        for (final doc in snap.docs) {
          if (seenDocIds.add(doc.id)) {
            final data = doc.data();
            final mp = <String, dynamic>{'id': doc.id}..addAll(data);
            final user = UserProfile.fromMap(mp);
            if (user.phoneNumber != null) {
              delta[user.phoneNumber!] = user;
            }
            if (user.email != null) {
              delta[user.email!.toLowerCase()] = user;
            }
          }
        }
        if (debug) {
          logI(
            'stream batch field=$field in=${values.length} -> delta=${delta.length}',
            tag: 'CONTACT_SEARCH',
          );
        }
        return delta;
      } catch (e) {
        logE('stream batch error field=$field: $e', tag: 'CONTACT_SEARCH');
        return {};
      }
    }

    // Interleave phone then email batches for quicker first hits.
    final maxLen = phoneBatches.length > emailBatches.length
        ? phoneBatches.length
        : emailBatches.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < phoneBatches.length) {
        final delta = await runBatch(phoneBatches[i], 'phone_number');
        if (delta.isNotEmpty) yield delta;
      }
      if (i < emailBatches.length) {
        final delta = await runBatch(emailBatches[i], 'email');
        if (delta.isNotEmpty) yield delta;
      }
    }
  }

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

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

  /// Finds registered users by phone numbers or emails.
  /// Returns a map where keys are the contact identifiers (phone/email) and values are UserProfile objects.
  Future<Map<String, UserProfile>> findUsersByContacts({
    required List<String> phoneNumbers,
    required List<String> emails,
  }) async => _withLatency('findUsersByContacts', () async {
    final results = <String, UserProfile>{};

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

    // Search by phone numbers
    if (cleanPhones.isNotEmpty) {
      try {
        final phoneQuery = await _firestore
            .collection('users')
            .where('phone_number', whereIn: cleanPhones)
            .get();

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
      } catch (e) {
        logW('Error searching users by phone: $e', tag: 'SEARCH');
      }
    }

    // Search by emails
    if (cleanEmails.isNotEmpty) {
      try {
        final emailQuery = await _firestore
            .collection('users')
            .where('email', whereIn: cleanEmails)
            .get();

        for (final doc in emailQuery.docs) {
          final data = doc.data();
          final mp = <String, dynamic>{'id': doc.id};
          mp.addAll(data);
          final user = UserProfile.fromMap(mp);
          if (user.email != null) {
            results[user.email!.toLowerCase()] = user;
          }
        }
      } catch (e) {
        logW('Error searching users by email: $e', tag: 'SEARCH');
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

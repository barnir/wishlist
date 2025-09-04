import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/models/user_profile.dart';
import 'package:mywishstash/repositories/page.dart';
import 'package:mywishstash/utils/app_logger.dart';

/// Simplified search repository for public users.
/// Firestore doesn't support full text search natively; this performs a
/// prefix search on lowercased display_name and email fields that should be
/// maintained (consider adding a `search_tokens` array in future for better matching).
class UserSearchRepository {
  final FirebaseFirestore _firestore;
  UserSearchRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      return r;
    } catch (e, st) {
      logE('UserSearchRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}', tag: 'SEARCH', error: e, stackTrace: st);
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
          logW('User search indexed query failed, falling back to unordered scan: $e', tag: 'SEARCH');
          var fallback = _firestore.collection('users').where('is_private', isEqualTo: false);
          if (startAfter != null) fallback = fallback.startAfterDocument(startAfter);
          // Increase fetch window when unordered to avoid excessive roundtrips.
          snap = await fallback.limit(limit * 4).get();
        }
        final docs = snap.docs;
        final matches = <UserProfile>[];
        for (final d in docs) {
          final dataObj = d.data();
          final Map<String, dynamic>? data = dataObj is Map<String, dynamic> ? dataObj : null;
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
          lastDoc = docs.last; // still allow pagination attempts if there are more docs
        }
        final hasMore = matches.length == limit && lastDoc != null;
        logI('User search page', tag: 'SEARCH', data: {'query': q, 'returned': matches.length, 'hasMore': hasMore});
        return PageResult(items: matches, lastDoc: lastDoc, hasMore: hasMore);
      });
}

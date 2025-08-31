import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/models/user_profile.dart';
import 'package:wishlist_app/repositories/page.dart';
import 'package:wishlist_app/utils/app_logger.dart';

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
      logD('UserSearchRepository op=$op latency_ms=${sw.elapsedMilliseconds}', tag: 'SEARCH');
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

        final snap = await baseQuery.limit(limit * 2).get(); // overfetch for filtering
        final docs = snap.docs;
        final matches = <UserProfile>[];
        for (final d in docs) {
          final data = d.data();
            final display = (data['display_name'] as String? ?? '').toLowerCase();
            final email = (data['email'] as String? ?? '').toLowerCase();
            if (display.startsWith(q) || email.startsWith(q)) {
              matches.add(UserProfile.fromMap({'id': d.id, ...data}));
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
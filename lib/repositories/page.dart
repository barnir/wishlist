import 'package:cloud_firestore/cloud_firestore.dart';

/// Generic page result for cursor-based pagination.
class PageResult<T> {
  final List<T> items;
  final DocumentSnapshot? lastDoc; // Firestore cursor for next page
  final bool hasMore; // Convenience flag

  const PageResult({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });
}

import 'package:flutter/material.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';

class WishlistTotal extends StatefulWidget {
  final String wishlistId;

  const WishlistTotal({super.key, required this.wishlistId});

  @override
  State<WishlistTotal> createState() => _WishlistTotalState();
}

class _WishlistTotalState extends State<WishlistTotal> {
  final _databaseService = FirebaseDatabaseService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _databaseService.getWishItems(widget.wishlistId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return const Text('-');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('€0.00');
        }

        double total = 0;
        for (var itemData in snapshot.data!) {
          final price = (itemData['price'] as num?)?.toDouble() ?? 0.0;
          // Quantity is not in the wish_items table in the proposed schema.
          // If needed, it should be added to the wish_items table.
          total += price; // Assuming quantity is 1 if not specified
        }

        return Text('€${total.toStringAsFixed(2)}');
      },
    );
  }
}

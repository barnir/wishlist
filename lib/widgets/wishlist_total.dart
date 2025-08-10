import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/firestore_service.dart';

class WishlistTotal extends StatefulWidget {
  final String wishlistId;

  const WishlistTotal({super.key, required this.wishlistId});

  @override
  State<WishlistTotal> createState() => _WishlistTotalState();
}

class _WishlistTotalState extends State<WishlistTotal> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getWishItems(widget.wishlistId),
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

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('€0.00');
        }

        double total = 0;
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final price = (data['price'] as num?)?.toDouble() ?? 0.0;
          final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
          total += price * quantity;
        }

        return Text('€${total.toStringAsFixed(2)}');
      },
    );
  }
}
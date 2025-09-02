import 'package:flutter/material.dart';
import 'package:mywishstash/repositories/stats_repository.dart';

class WishlistTotal extends StatefulWidget {
  final String wishlistId;

  const WishlistTotal({super.key, required this.wishlistId});

  @override
  State<WishlistTotal> createState() => _WishlistTotalState();
}

class _WishlistTotalState extends State<WishlistTotal> {
  final _statsRepo = StatsRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<double>(
      stream: _statsRepo.wishlistTotalStream(widget.wishlistId),
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
        final total = snapshot.data ?? 0.0;
        return Text('€${total.toStringAsFixed(2)}');
      },
    );
  }
}

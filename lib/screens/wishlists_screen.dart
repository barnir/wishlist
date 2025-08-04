import 'package:flutter/material.dart';

class WishlistsScreen extends StatelessWidget {
  const WishlistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Wishlists')),
      body: const Center(child: Text('Em breve: lista de wishlists')),
    );
  }
}

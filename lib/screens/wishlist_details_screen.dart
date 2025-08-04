import 'package:flutter/material.dart';

class WishlistDetailsScreen extends StatelessWidget {
  const WishlistDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da Wishlist')),
      body: const Center(
        child: Text('Em breve: detalhes da wishlist selecionada'),
      ),
    );
  }
}

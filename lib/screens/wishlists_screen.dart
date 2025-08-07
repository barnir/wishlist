import 'package:flutter/material.dart';

class WishlistsScreen extends StatelessWidget {

  const WishlistsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Wishlists')),
      body: const Center(child: Text('Em breve: lista de wishlists')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aqui podes abrir o ecrã para adicionar nova wishlist
          Navigator.pushNamed(context, '/add_new_wishlist');
        },
        child: const Icon(Icons.add),
        tooltip: 'Adicionar nova wishlist',
      ),
    );
  }
}

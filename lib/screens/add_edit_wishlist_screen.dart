import 'package:flutter/material.dart';

class AddEditWishlistScreen extends StatelessWidget {
  const AddEditWishlistScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Wishlists')),
      body: const Center(
        child: Text(
          'Em breve: lista de wishlists',
          style: TextStyle(fontSize: 18),
        ),
      ),
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

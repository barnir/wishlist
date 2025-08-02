import 'package:flutter/material.dart';
import '../models/wish_item.dart';
import '../services/firestore_service.dart';
import '../widgets/wish_item_tile.dart';
import 'add_item_screen.dart';

class WishlistScreen extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Minha Wishlist')),
      body: StreamBuilder<List<WishItem>>(
        stream: firestoreService.streamWishlist(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final itens = snapshot.data ?? [];
          if (itens.isEmpty) {
            return Center(child: Text('Lista vazia'));
          }
          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (context, idx) {
              final item = itens[idx];
              return WishItemTile(
                item: item,
                onDelete: () => firestoreService.deleteWishItem(item.id),
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddItemScreen(item: item),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddItemScreen()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

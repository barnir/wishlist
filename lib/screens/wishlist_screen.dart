import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/wish_item.dart';
import 'add_item_screen.dart';
import '../widgets/wish_item_tile.dart';

class WishlistScreen extends StatelessWidget {
  final Box<WishItem> box = Hive.box<WishItem>('wishlist');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Minha Wishlist')),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<WishItem> box, _) {
          if (box.isEmpty) return Center(child: Text('Lista vazia'));
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, idx) =>
                WishItemTile(item: box.getAt(idx)!, onDelete: () => box.deleteAt(idx)),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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

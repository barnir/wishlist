import 'package:flutter/material.dart';
import '../models/wish_item.dart';

class WishItemTile extends StatelessWidget {
  final WishItem item;
  final VoidCallback onDelete;

  WishItemTile({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.title),
      subtitle: item.link != null ? Text(item.link!) : null,
      trailing: IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
    );
  }
}

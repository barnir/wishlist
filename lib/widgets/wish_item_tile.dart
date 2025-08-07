import 'package:flutter/material.dart';
import '../models/wish_item.dart';

class WishItemTile extends StatelessWidget {
  final WishItem item;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;  // opcional para evitar erro se não usar

  const WishItemTile({super.key, required this.item, required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: categoriaImagem(item.category),
      title: Text(item.title),
      subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.link != null && item.link!.isNotEmpty) Text(item.link!),
            if (item.price != null) Text('Preço: €${item.price!.toStringAsFixed(2)}'), 
          ],
        ),     
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onEdit != null)  // se tiver função onEdit, mostra o botão
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: onEdit,
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget categoriaImagem(String cat) {
    switch (cat) {
      case 'Livro':
        return Icon(Icons.book, size: 40);
      case 'Eletrónico':
        return Icon(Icons.electrical_services, size: 40);
      case 'Viagem':
        return Icon(Icons.flight, size: 40);
      case 'Moda':
        return Icon(Icons.checkroom, size: 40);
      case 'Casa':
        return Icon(Icons.home, size: 40);
      default:
        return Icon(Icons.star, size: 40);
    }
  }
}

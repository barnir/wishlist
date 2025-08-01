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
      leading: categoriaImagem(item.category),
    );
  }
  Widget categoriaImagem(String cat) {
  switch (cat) {
    case 'Livro': return Icon(Icons.book, size: 40);
    case 'Eletrónico': return Icon(Icons.electrical_services, size: 40);
    case 'Viagem': return Icon(Icons.flight, size: 40);
    case 'Moda': return Icon(Icons.checkroom, size: 40);
    case 'Casa': return Icon(Icons.home, size: 40);
    default: return Icon(Icons.star, size: 40);
  }
}

}

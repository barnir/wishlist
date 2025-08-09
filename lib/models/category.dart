import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});
}

final List<Category> categories = [
  Category(name: 'Livro', icon: Icons.book),
  Category(name: 'Eletrónico', icon: Icons.electrical_services),
  Category(name: 'Viagem', icon: Icons.flight),
  Category(name: 'Moda', icon: Icons.checkroom),
  Category(name: 'Casa', icon: Icons.home),
  Category(name: 'Outros', icon: Icons.star),
];

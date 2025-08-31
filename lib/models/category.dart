import 'package:flutter/material.dart';

/// Domain category with icon mapping.
/// Names are persisted as strings in Firestore so existing labels MUST remain stable.
class Category {
  final String name;          // Display & storage key (PT)
  final IconData icon;        // Material icon representing the category
  final String? alias;        // Optional internal alias (future i18n mapping)

  const Category({required this.name, required this.icon, this.alias});

  static List<String> getAllCategories() => categories.map((c) => c.name).toList();

  static Category? find(String? name) {
    if (name == null) return null;
    return categories.firstWhere(
      (c) => c.name == name || (c.alias != null && c.alias == name),
      orElse: () => const Category(name: 'Outros', icon: Icons.more_horiz),
    );
  }
}

// NOTE: Keep original base names ('Livro', 'Eletrónico', 'Viagem', 'Moda', 'Casa', 'Outros')
// to avoid breaking existing stored items. New categories appended below.
// Prefer outlined variants for a lighter, more elegant visual style.
final List<Category> categories = [
  // Originais
  const Category(name: 'Livro', icon: Icons.menu_book_outlined),
  const Category(name: 'Eletrónico', icon: Icons.devices_other_outlined),
  const Category(name: 'Viagem', icon: Icons.flight_takeoff_outlined),
  const Category(name: 'Moda', icon: Icons.style_outlined),
  const Category(name: 'Casa', icon: Icons.chair_outlined),
  const Category(name: 'Outros', icon: Icons.more_horiz),

  // Expandidas
  const Category(name: 'Beleza', icon: Icons.brush_outlined),
  const Category(name: 'Saúde & Fitness', icon: Icons.fitness_center_outlined, alias: 'Saúde'),
  const Category(name: 'Brinquedos', icon: Icons.toys),
  const Category(name: 'Gourmet', icon: Icons.restaurant_menu_outlined),
  const Category(name: 'Gaming', icon: Icons.sports_esports_outlined),
  const Category(name: 'Música', icon: Icons.music_note_outlined),
  const Category(name: 'Arte & DIY', icon: Icons.palette_outlined, alias: 'Arte'),
  const Category(name: 'Fotografia', icon: Icons.photo_camera_outlined),
  const Category(name: 'Educação', icon: Icons.school_outlined, alias: 'Curso'),
  const Category(name: 'Jardim', icon: Icons.yard_outlined),
  const Category(name: 'Bebé', icon: Icons.child_friendly_outlined, alias: 'Infantil'),
  const Category(name: 'Experiência', icon: Icons.local_activity_outlined, alias: 'Evento'),
  const Category(name: 'Eco', icon: Icons.eco_outlined, alias: 'Sustentável'),
  const Category(name: 'Pet', icon: Icons.pets_outlined, alias: 'Animais'),
];

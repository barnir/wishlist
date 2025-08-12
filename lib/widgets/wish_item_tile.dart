import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import '../models/wish_item.dart';
import '../models/category.dart';

class WishItemTile extends StatelessWidget {
  final WishItem item;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const WishItemTile(
      {super.key, required this.item, required this.onDelete, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere((c) => c.name == item.category,
        orElse: () => categories.last);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: SizedBox(
          width: 50, // Standard size for CircleAvatar
          height: 50,
          child: FutureBuilder<File?>(
            future: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? ImageCacheService.getFile(item.imageUrl!)
                : Future.value(null), // No image URL, so no file
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                );
              } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                // Fallback to category icon if image fails to load or is not present
                return CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Icon(
                    category.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              } else {
                // Display the image from file
                return CircleAvatar(
                  backgroundImage: FileImage(snapshot.data!),
                  radius: 50,
                );
              }
            },
          ),
        ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item.description!),
              ),
            if (item.link != null && item.link!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: InkWell(
                  onTap: () { // Add function to open link
                    // launchUrl(Uri.parse(item.link!));
                  },
                  child: Text(
                    item.link!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            if (item.price != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Preço: €${item.price!.toStringAsFixed(2)}',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
                tooltip: 'Editar',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }
}


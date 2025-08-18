import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishlist_app/models/sort_options.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import '../models/wish_item.dart';
import '../models/category.dart';

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  final _supabaseDatabaseService = SupabaseDatabaseService();

  String _wishlistName = 'Carregando...';
  bool _isPrivate = false;
  String? _selectedCategory;
  SortOptions _sortOption = SortOptions.nameAsc;

  @override
  void initState() {
    super.initState();
    _loadWishlistDetails();
  }

  Future<void> _loadWishlistDetails() async {
    try {
      final wishlistData = await _supabaseDatabaseService.getWishlist(widget.wishlistId);
      if (mounted && wishlistData != null) {
        setState(() {
          _wishlistName = wishlistData['name'] ?? 'Sem nome';
          _isPrivate = wishlistData['is_private'] ?? false;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar detalhes da wishlist: $e', isError: true);
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _supabaseDatabaseService.deleteWishItem(widget.wishlistId, itemId);
      if (!mounted) return;
      _showSnackBar('Item eliminado com sucesso!');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao eliminar item: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
            tooltip: 'Filtrar e Ordenar',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/add_edit_wishlist',
                arguments: widget.wishlistId,
              ).then((_) => _loadWishlistDetails());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabaseDatabaseService.getWishItems(
                widget.wishlistId,
                category: _selectedCategory,
                sortOption: _sortOption,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final items = snapshot.data!
                    .map((itemData) => WishItem.fromMap(itemData))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(items[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add_edit_item',
            arguments: {'wishlistId': widget.wishlistId},
          );
        },
        tooltip: 'Adicionar novo item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            _isPrivate ? Icons.lock_outline : Icons.public_outlined,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 8),
          Text(
            _isPrivate ? 'Esta wishlist é privada' : 'Esta wishlist é pública',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_shopping_cart_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'A sua wishlist está vazia',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Adicione o seu primeiro desejo!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(WishItem item) {
    final category = categories.firstWhere((c) => c.name == item.category,
        orElse: () => categories.last);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: FutureBuilder<File?>(
                  future: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ImageCacheService.getFile(item.imageUrl!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: colorScheme.primary.withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                      return Container(
                        color: colorScheme.primary.withOpacity(0.1),
                        child: Icon(category.icon, color: colorScheme.primary, size: 40),
                      );
                    } else {
                      return Image.file(snapshot.data!, fit: BoxFit.cover);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  if (item.description != null && item.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(item.description!, style: textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  if (item.price != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '€${item.price!.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => Navigator.pushNamed(context, '/add_edit_item', arguments: {
                    'wishlistId': widget.wishlistId,
                    'itemId': item.id,
                  }),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteItem(item.id),
                  tooltip: 'Eliminar',
                ),
                if (item.link != null && item.link!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () async {
                      final uri = Uri.parse(item.link!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    tooltip: 'Abrir link',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filtrar e Ordenar'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Filtrar por Categoria'),
                    hint: const Text('Todas as Categorias'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Todas as Categorias'),
                      ),
                      ...categories.map((Category category) {
                        return DropdownMenuItem<String>(
                          value: category.name,
                          child: Row(
                            children: [
                              Icon(category.icon),
                              const SizedBox(width: 10),
                              Text(category.name),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (newValue) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<SortOptions>(
                    value: _sortOption,
                    decoration: const InputDecoration(labelText: 'Ordenar por'),
                    items: const [
                      DropdownMenuItem(
                        value: SortOptions.nameAsc,
                        child: Text('Nome (A-Z)'),
                      ),
                      DropdownMenuItem(
                        value: SortOptions.nameDesc,
                        child: Text('Nome (Z-A)'),
                      ),
                      DropdownMenuItem(
                        value: SortOptions.priceAsc,
                        child: Text('Preço (Crescente)'),
                      ),
                      DropdownMenuItem(
                        value: SortOptions.priceDesc,
                        child: Text('Preço (Decrescente)'),
                      ),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _sortOption = newValue;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Rebuild the main screen with the new filter/sort
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}
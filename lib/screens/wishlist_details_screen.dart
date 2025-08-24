import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:wishlist_app/models/sort_options.dart';
import '../models/wish_item.dart';
import '../models/category.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'package:wishlist_app/services/auth_service.dart';

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
    _checkOwnership();
  }
  
  Future<void> _checkOwnership() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;
      
      final wishlistData = await _supabaseDatabaseService.getWishlist(widget.wishlistId);
      if (wishlistData != null && mounted) {
        setState(() {
        });
      }
    } catch (e) {
      // Falhar silenciosamente
    }
  }

  Future<void> _loadWishlistDetails() async {
    try {
      final wishlistData = await _supabaseDatabaseService.getWishlist(
        widget.wishlistId,
      );
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
                  padding: UIConstants.listPadding,
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
      padding: UIConstants.paddingM,
      child: Row(
        children: [
          Icon(
            _isPrivate ? Icons.lock_outline : Icons.public_outlined,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          Spacing.horizontalS,
          Text(
            _isPrivate ? 'Esta wishlist é privada' : 'Esta wishlist é pública',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return WishlistEmptyState(
      icon: Icons.add_shopping_cart_rounded,
      title: 'A sua wishlist está vazia',
      subtitle: 'Adicione o seu primeiro desejo!',
    );
  }

  Widget _buildItemCard(WishItem item) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return WishlistCard(
      child: Padding(
        padding: UIConstants.paddingM,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: UIConstants.imageSizeL,
              height: UIConstants.imageSizeL,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(UIConstants.radiusS),
                child: FutureBuilder<File?>(
                  future: item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? ImageCacheService.getFile(item.imageUrl!)
                      : Future.value(null),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(UIConstants.radiusS),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: UIConstants.strokeWidthMedium,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data == null) {
                      return Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(UIConstants.radiusS),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: UIConstants.iconSizeL,
                            color: colorScheme.error,
                          ),
                        ),
                      );
                    } else {
                      return Image.file(snapshot.data!, fit: BoxFit.cover);
                    }
                  },
                ),
              ),
            ),
            Spacing.horizontalM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description != null && item.description!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: UIConstants.spacingXS),
                      child: Text(
                        item.description!,
                        style: textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (item.price != null)
                    Padding(
                      padding: EdgeInsets.only(top: UIConstants.spacingS),
                      child: Text(
                        '€${item.price!.toStringAsFixed(2)}',
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.pushNamed(
                    context,
                    '/add_edit_item',
                    arguments: {
                      'wishlistId': widget.wishlistId,
                      'itemId': item.id,
                    },
                  );
                } else if (value == 'delete') {
                  _deleteItem(item.id);
                } else if (value == 'open_link' &&
                    item.link != null &&
                    item.link!.isNotEmpty) {
                  final uri = Uri.parse(item.link!);
                  if (await canLaunchUrl(uri)) {
                    launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      Spacing.horizontalS,
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline),
                      Spacing.horizontalS,
                      Text('Eliminar'),
                    ],
                  ),
                ),
                if (item.link != null && item.link!.isNotEmpty)
                  const PopupMenuItem<String>(
                    value: 'open_link',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new),
                        Spacing.horizontalS,
                        Text('Abrir link'),
                      ],
                    ),
                  ),
              ],
              icon: const Icon(Icons.more_vert),
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
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Filtrar por Categoria',
                    ),
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
                  Spacing.l,
                  DropdownButtonFormField<SortOptions>(
                    initialValue: _sortOption,
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
                setState(
                  () {},
                ); // Rebuild the main screen with the new filter/sort
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import '../models/wish_item.dart';
import '../models/category.dart';
import '../widgets/wish_item_tile.dart';

enum SortOptions { priceAsc, priceDesc, nameAsc, nameDesc }

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  final _firestoreService = FirestoreService();

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
      final doc = await _firestoreService.getWishlist(widget.wishlistId);
      if (doc.exists) {
        setState(() {
          _wishlistName = doc['name'] ?? 'Sem nome';
          _isPrivate = doc['private'] ?? false;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar detalhes da wishlist: $e');
    }
  }

  Future<void> _confirmDeleteWishlist(BuildContext context) async {
    TextEditingController confirmController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button!
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Eliminação'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Tem a certeza que quer eliminar a wishlist "$_wishlistName"?'),
                const Text('Esta ação é irreversível.'),
                const SizedBox(height: 10),
                const Text('Para confirmar, escreva "SIM" na caixa abaixo:'),
                TextField(
                  controller: confirmController,
                  decoration: const InputDecoration(hintText: 'SIM'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () async {
                if (confirmController.text == 'SIM') {
                  Navigator.of(dialogContext).pop();
                  await _deleteWishlist();
                } else {
                  _showSnackBar('Confirmação inválida. Escreva SIM.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteWishlist() async {
    try {
      await _firestoreService.deleteWishlist(widget.wishlistId);
      if (!mounted) return;
      _showSnackBar('Wishlist "$_wishlistName" eliminada com sucesso!');
      Navigator.of(context).pop(); // Go back to previous screen (wishlists list)
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao eliminar wishlist: $e');
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _firestoreService.deleteWishItem(widget.wishlistId, itemId);
      if (!mounted) return;
      _showSnackBar('Item eliminado com sucesso!');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao eliminar item: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
              ).then((_) => _loadWishlistDetails()); // Reload details after editing
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDeleteWishlist(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _isPrivate ? 'Esta wishlist é privada.' : 'Esta wishlist é pública.',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getWishItems(widget.wishlistId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Nenhum item nesta wishlist.'));
                }

                var items = snapshot.data!.docs
                    .map((doc) => WishItem.fromFirestore(doc))
                    .toList();

                // Filtering
                if (_selectedCategory != null) {
                  items = items.where((item) => item.category == _selectedCategory).toList();
                }

                // Sorting
                items.sort((a, b) {
                  switch (_sortOption) {
                    case SortOptions.priceAsc:
                      return (a.price ?? 0).compareTo(b.price ?? 0);
                    case SortOptions.priceDesc:
                      return (b.price ?? 0).compareTo(a.price ?? 0);
                    case SortOptions.nameAsc:
                      return a.name.compareTo(b.name);
                    case SortOptions.nameDesc:
                      return b.name.compareTo(a.name);
                  }
                });

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return WishItemTile(
                      item: item,
                      onDelete: () => _deleteItem(item.id),
                      onEdit: () {
                        Navigator.pushNamed(
                          context,
                          '/add_edit_item',
                          arguments: {
                            'wishlistId': widget.wishlistId,
                            'itemId': item.id,
                          },
                        );
                      },
                    );
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
                      }).toList(),
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
                this.setState(() {}); // Rebuild the main screen with the new filter/sort
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}
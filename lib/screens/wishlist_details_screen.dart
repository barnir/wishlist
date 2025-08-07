import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  String _wishlistName = 'Carregando...';
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistDetails();
  }

  Future<void> _loadWishlistDetails() async {
    final doc = await FirebaseFirestore.instance.collection('wishlists').doc(widget.wishlistId).get();
    if (doc.exists) {
      setState(() {
        _wishlistName = doc['name'] ?? 'Sem nome';
        _isPrivate = doc['private'] ?? false;
      });
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Confirmação inválida. Escreva SIM.')),
                  );
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
      await FirebaseFirestore.instance.collection('wishlists').doc(widget.wishlistId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wishlist "$_wishlistName" eliminada com sucesso!')),
      );
      Navigator.of(context).pop(); // Go back to previous screen (wishlists list)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao eliminar wishlist: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlistName),
        actions: [
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
              stream: FirebaseFirestore.instance
                  .collection('wishlists')
                  .doc(widget.wishlistId)
                  .collection('items')
                  .snapshots(),
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

                final items = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final itemName = item['name'] ?? 'Sem nome';
                    final itemDescription = item['description'] ?? '';

                    return ListTile(
                      title: Text(itemName),
                      subtitle: Text(itemDescription),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/add_edit_item',
                            arguments: {
                              'wishlistId': widget.wishlistId,
                              'itemId': item.id,
                            },
                          );
                        },
                      ),
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
}

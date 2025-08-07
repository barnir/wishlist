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

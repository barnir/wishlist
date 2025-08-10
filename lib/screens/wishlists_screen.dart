import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/wishlist_total.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas Wishlists')),
        body: const Center(child: Text('Por favor, faça login para ver suas wishlists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Wishlists')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getWishlists(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhuma wishlist encontrada. Crie uma!'));
          }

          final wishlists = snapshot.data!.docs;

          return ListView.builder(
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              final wishlist = wishlists[index];
              final name = wishlist['name'] ?? 'Sem nome';
              final isPrivate = wishlist['private'] ?? false;

              final data = wishlist.data() as Map<String, dynamic>;
              final imageUrl = data.containsKey('imageUrl') ? data['imageUrl'] : null;

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl) : null,
                  child: imageUrl == null ? const Icon(Icons.card_giftcard) : null,
                ),
                title: Text(name),
                subtitle: Text(isPrivate ? 'Privada' : 'Pública'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/wishlist_details',
                    arguments: wishlist.id,
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WishlistTotal(wishlistId: wishlist.id),
                    const Icon(Icons.arrow_forward_ios),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_edit_wishlist');
        },
        tooltip: 'Adicionar nova wishlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}

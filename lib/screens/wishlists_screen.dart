import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firestore_service.dart';
import 'package:wishlist_app/services/image_cache_service.dart';
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
                leading: SizedBox(
                  width: 50, // Standard size for CircleAvatar
                  height: 50,
                  child: FutureBuilder<File?>(
                    future: imageUrl != null && imageUrl.isNotEmpty
                        ? ImageCacheService.getFile(imageUrl)
                        : Future.value(null),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        );
                      } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                        return CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.card_giftcard),
                        );
                      } else {
                        return CircleAvatar(
                          backgroundImage: FileImage(snapshot.data!),
                          radius: 50,
                        );
                      }
                    },
                  ),
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

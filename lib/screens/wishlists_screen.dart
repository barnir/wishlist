import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Minhas Wishlists')),
        body: const Center(child: Text('Por favor, faça login para ver suas wishlists.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Wishlists')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('wishlists')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
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

              return ListTile(
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
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/add_edit_wishlist',
                          arguments: wishlist.id,
                        );
                      },
                    ),
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
          Navigator.pushNamed(context, '/add_new_wishlist');
        },
        tooltip: 'Adicionar nova wishlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}

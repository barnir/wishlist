import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import CachedNetworkImage
import '../widgets/wishlist_total.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _authService = AuthService();
  final _supabaseDatabaseService = SupabaseDatabaseService();

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseDatabaseService.getWishlists(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma wishlist encontrada. Crie uma!'));
          }

          final wishlists = snapshot.data!;

          return ListView.builder(
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              final wishlist = wishlists[index];
              final name = wishlist['name'] ?? 'Sem nome';
              final isPrivate = wishlist['is_private'] ?? false;

              final imageUrl = wishlist.containsKey('image_url') ? wishlist['image_url'] : null;

              return ListTile(
                leading: SizedBox(
                  width: 50, // Standard size for CircleAvatar
                  height: 50,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            backgroundImage: imageProvider,
                            radius: 50,
                          ),
                          placeholder: (context, url) => CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                            child: const Icon(Icons.card_giftcard),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(26),
                          child: const Icon(Icons.card_giftcard),
                        ),
                ),
                title: Text(name),
                subtitle: Text(isPrivate ? 'Privada' : 'Pública'),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/wishlist_details',
                    arguments: wishlist['id'],
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WishlistTotal(wishlistId: wishlist['id']),
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
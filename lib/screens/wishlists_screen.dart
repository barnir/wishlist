import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/wishlist_total.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _authService = AuthService();
  final _supabaseDatabaseService = SupabaseDatabaseService();

  // Widget para o estado de "lista vazia"
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma wishlist por aqui',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Toque em "+" para criar a sua primeira!",
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  // Widget para construir cada card da wishlist
  Widget _buildWishlistCard(BuildContext context, Map<String, dynamic> wishlist) {
    final name = wishlist['name'] ?? 'Sem nome';
    final isPrivate = wishlist['is_private'] ?? false;
    final imageUrl = wishlist['image_url'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      child: const Icon(Icons.card_giftcard, size: 30),
                    ),
                  )
                : Container(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.card_giftcard, size: 30),
                  ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isPrivate ? 'Privada' : 'Pública'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WishlistTotal(wishlistId: wishlist['id']),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/wishlist_details',
            arguments: wishlist['id'],
          );
        },
      ),
    );
  }

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
      appBar: AppBar(
        title: const Text('Minhas Wishlists'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabaseDatabaseService.getWishlists(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Ocorreu um erro: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final wishlists = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80), // Padding para o FAB
            itemCount: wishlists.length,
            itemBuilder: (context, index) {
              return _buildWishlistCard(context, wishlists[index]);
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

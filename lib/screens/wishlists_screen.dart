import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/wishlist_total.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

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
    return WishlistEmptyState(
      icon: Icons.card_giftcard_rounded,
      title: 'Nenhuma wishlist por aqui',
      subtitle: 'Toque em "+" para criar a sua primeira!',
    );
  }

  // Widget para construir cada card da wishlist
  Widget _buildWishlistCard(
    BuildContext context,
    Map<String, dynamic> wishlist,
  ) {
    final name = wishlist['name'] ?? 'Sem nome';
    final isPrivate = wishlist['is_private'] ?? false;
    final imageUrl = wishlist['image_url'];

    return WishlistCard(
      child: ListTile(
        contentPadding: UIConstants.paddingM,
        leading: SizedBox(
          width: UIConstants.imageSizeM,
          height: UIConstants.imageSizeM,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusS),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(UIConstants.radiusS),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: UIConstants.strokeWidthMedium,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(UIConstants.radiusS),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.broken_image,
                          size: UIConstants.iconSizeL,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: UIConstants.iconSizeL,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isPrivate ? 'Privada' : 'Pública'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                WishlistTotal(wishlistId: wishlist['id']),
                // You can add more details here if needed
              ],
            ),
            Spacing.horizontalS,
            Icon(
              Icons.arrow_forward_ios,
              size: UIConstants.iconSizeS,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
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
        body: const Center(
          child: Text('Por favor, faça login para ver suas wishlists.'),
        ),
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
            padding: UIConstants.listPadding,
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

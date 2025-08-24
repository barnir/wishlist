import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _favoritesService = FavoritesService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: WishlistAppBar(
        title: 'Favoritos',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            tooltip: 'Explorar perfis',
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _favoritesService.getFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const WishlistLoadingIndicator(message: 'A carregar favoritos...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: UIConstants.iconSizeXL,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  Spacing.m,
                  Text(
                    'Erro ao carregar favoritos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Spacing.s,
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const WishlistEmptyState(
              icon: Icons.star_border,
              title: 'Nenhum favorito ainda',
              subtitle: 'Explora perfis e marca os teus utilizadores favoritos para veres as suas wishlists públicas!',
            );
          }

          final favorites = snapshot.data!;
          return ListView.builder(
            padding: UIConstants.listPadding,
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(favorites[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    final displayName = favorite['display_name'] as String? ?? 'Utilizador';
    final email = favorite['email'] as String?;
    final userId = favorite['id'] as String;

    return WishlistCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: email != null && email.isNotEmpty
            ? Text(
                email,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: Colors.amber,
              size: UIConstants.iconSizeS,
            ),
            Spacing.horizontalXS,
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
            '/user_profile',
            arguments: userId,
          );
        },
      ),
    );
  }
}
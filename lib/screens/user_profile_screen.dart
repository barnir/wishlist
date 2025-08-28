import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firebase_database_service.dart';
import '../services/favorites_service.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _databaseService = FirebaseDatabaseService();
  final _favoritesService = FavoritesService();

  Map<String, dynamic>? _userProfile;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFavoriteStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _databaseService.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar perfil: $e')),
        );
      }
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final isFavorite = await _favoritesService.isFavorite(widget.userId);
      if (mounted) {
        setState(() => _isFavorite = isFavorite);
      }
    } catch (e) {
      // Falhar silenciosamente
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: WishlistAppBar(title: 'Perfil'),
        body: const WishlistLoadingIndicator(message: 'A carregar perfil...'),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: WishlistAppBar(title: 'Perfil'),
        body: const WishlistEmptyState(
          icon: Icons.person_off,
          title: 'Perfil não encontrado',
          subtitle: 'Este utilizador pode ter sido removido.',
        ),
      );
    }

    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';

    return Scaffold(
      appBar: WishlistAppBar(
        title: displayName,
        actions: [
          _buildFavoriteActionButton(),
        ],
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          _buildTabSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';

    return Container(
      width: double.infinity,
      padding: UIConstants.paddingL,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: UIConstants.imageSizeXL / 2,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.person,
              size: UIConstants.iconSizeXXL / 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Spacing.m,
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if ((_userProfile!['email'] as String?) != null && (_userProfile!['email'] as String).isNotEmpty) ...[
            Spacing.xs,
            Text(
              _userProfile!['email'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          Spacing.m,
          _buildFavoriteStatusBadge(),
        ],
      ),
    );
  }

  Widget _buildFavoriteStatusBadge() {
    if (!_isFavorite) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(51),
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: UIConstants.iconSizeS, color: Colors.amber),
          Spacing.horizontalXS,
          Text(
            'Favorito',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.amber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteActionButton() {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
        color: _isFavorite ? Colors.amber : Theme.of(context).colorScheme.primary,
      ),
      onPressed: _toggleFavorite,
      tooltip: _isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
    );
  }

  Widget _buildTabSection() {
    return Expanded(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Wishlists Públicas', icon: Icon(Icons.list_alt)),
                  Tab(text: 'Sobre', icon: Icon(Icons.info_outline)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPublicWishlistsTab(),
                  _buildAboutTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicWishlistsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _databaseService.getPublicWishlistsForUser(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const WishlistLoadingIndicator(message: 'A carregar wishlists...');
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const WishlistEmptyState(
            icon: Icons.list_alt_outlined,
            title: 'Nenhuma wishlist pública',
            subtitle: 'Este utilizador ainda não tem wishlists públicas.',
          );
        }

        final wishlists = snapshot.data!;
        return ListView.builder(
          padding: UIConstants.listPadding,
          itemCount: wishlists.length,
          itemBuilder: (context, index) {
            return _buildWishlistCard(wishlists[index]);
          },
        );
      },
    );
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
    final name = wishlist['name'] as String? ?? 'Sem nome';
    final imageUrl = wishlist['image_url'] as String?;

    return WishlistCard(
      child: ListTile(
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(UIConstants.radiusS),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.card_giftcard,
                          size: UIConstants.iconSizeL,
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(UIConstants.radiusS),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.card_giftcard,
                        size: UIConstants.iconSizeL,
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ),
          ),
        ),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.public,
              size: UIConstants.iconSizeS,
              color: Theme.of(context).colorScheme.primary,
            ),
            Spacing.horizontalXS,
            Text(
              'Pública',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: UIConstants.iconSizeS,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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

  Widget _buildAboutTab() {
    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';
    
    return Padding(
      padding: UIConstants.paddingM,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WishlistCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: UIConstants.iconSizeM,
                    ),
                    Spacing.horizontalS,
                    Text(
                      'Informações do Perfil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Spacing.m,
                _buildInfoRow('Nome', displayName),
                if (_userProfile!['email'] != null)
                  _buildInfoRow('Email', _userProfile!['email'] as String),
                _buildInfoRow('Membro desde', 'Recentemente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: UIConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _favoritesService.removeFavorite(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removido dos favoritos')),
          );
          setState(() => _isFavorite = false);
        }
      } else {
        await _favoritesService.addFavorite(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionado aos favoritos!')),
          );
          setState(() => _isFavorite = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }
}
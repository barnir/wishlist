import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:wishlist_app/widgets/optimized_cloudinary_image.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/repositories/user_profile_repository.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _userProfileRepo = UserProfileRepository();
  final _favoritesService = FavoritesService();

  Map<String, dynamic>? _userProfile;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _profileViewTracked = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadFavoriteStatus();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userProfileRepo.fetchById(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile?.toMap();
          _isLoading = false;
        });
        _trackProfileView();
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
        appBar: const WishlistAppBar(title: 'Perfil'),
        body: _buildProfileSkeleton(),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: const WishlistAppBar(title: 'Perfil'),
        body: WishlistEmptyState(
          icon: Icons.person_off,
          title: AppLocalizations.of(context)?.profileNotFoundTitle ?? 'Perfil não encontrado',
          subtitle: AppLocalizations.of(context)?.profileNotFoundSubtitle ?? 'Este utilizador pode ter sido removido.',
        ),
      );
    }

    final displayName = _userProfile!['display_name'] as String? ?? 'Utilizador';

    return Scaffold(
      appBar: WishlistAppBar(
        title: displayName,
        actions: [
          _buildFavoriteActionButton(),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: AppLocalizations.of(context)?.shareProfileTooltip ?? 'Partilhar perfil',
            onPressed: _shareProfile,
          ),
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
  final bio = _sanitizeAndTrimBio(_userProfile!['bio']);

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
          if (bio != null && bio.isNotEmpty) ...[
            Spacing.xs,
            Text(
              bio,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
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
  color: context.semanticColors.favorite.withAlpha(51),
        borderRadius: BorderRadius.circular(UIConstants.radiusL),
  border: Border.all(color: context.semanticColors.favorite, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: UIConstants.iconSizeS, color: context.semanticColors.favorite),
          Spacing.horizontalXS,
          Text(
            (AppLocalizations.of(context)?.favoriteBadge ?? 'Favorito'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.semanticColors.favorite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteActionButton() {
    final l10n = AppLocalizations.of(context)!;
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
  color: _isFavorite ? context.semanticColors.favorite : Theme.of(context).colorScheme.primary,
      ),
      onPressed: _toggleFavorite,
      tooltip: _isFavorite ? l10n.removeFromFavorites : l10n.addToFavorites,
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
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.publicWishlistsTab, icon: const Icon(Icons.list_alt)),
                  Tab(text: AppLocalizations.of(context)!.aboutTab, icon: const Icon(Icons.info_outline)),
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
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPublicWishlists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildWishlistSkeletonList();
        }

        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context)!;
          return Center(child: Text(l10n.errorPrefix(snapshot.error.toString())));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          final l10n = AppLocalizations.of(context)!;
          return WishlistEmptyState(
            icon: Icons.list_alt_outlined,
            title: l10n.noPublicWishlists,
            subtitle: l10n.noPublicWishlistsSubtitle,
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

  Future<List<Map<String, dynamic>>> _fetchPublicWishlists() async {
    try {
      final snap = await _firestore
          .collection('wishlists')
          .where('owner_id', isEqualTo: widget.userId)
          .where('is_private', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();
      return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    } catch (e) {
      rethrow;
    }
  }

  Widget _buildWishlistCard(Map<String, dynamic> wishlist) {
  final l10n = AppLocalizations.of(context)!;
  final name = wishlist['name'] as String? ?? l10n.noName;
    final imageUrl = wishlist['image_url'] as String?;

    return WishlistCard(
      child: ListTile(
        leading: SizedBox(
          width: UIConstants.imageSizeM,
          height: UIConstants.imageSizeM,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UIConstants.radiusS),
            child: OptimizedCloudinaryImage(
              originalUrl: imageUrl,
              transformationType: ImageType.wishlistIcon,
              width: UIConstants.imageSizeM,
              height: UIConstants.imageSizeM,
              borderRadius: BorderRadius.circular(UIConstants.radiusS),
              fallbackIcon: Icon(
                Icons.card_giftcard,
                size: UIConstants.iconSizeL,
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
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
                l10n.publicLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward,
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
  final bio = _sanitizeAndTrimBio(_userProfile!['bio']);
    
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
                      AppLocalizations.of(context)?.profileInfoSectionTitle ?? 'Informações do Perfil',
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
                if (bio != null && bio.isNotEmpty)
                  _buildInfoRow('Bio', bio),
                _buildInfoRow(AppLocalizations.of(context)?.memberSinceLabel ?? 'Membro desde', AppLocalizations.of(context)?.recentlyLabel ?? 'Recentemente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UIConstants.spacingS),
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
            SnackBar(content: Text(AppLocalizations.of(context)?.removedFromFavorites ?? 'Removido dos favoritos')),
          );
          setState(() => _isFavorite = false);
          MonitoringService().trackEvent('profile_unfavorite', properties: {'profile_id': widget.userId});
        }
      } else {
        await _favoritesService.addFavorite(widget.userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)?.addedToFavorites ?? 'Adicionado aos favoritos!')),
          );
          setState(() => _isFavorite = true);
          MonitoringService().trackEvent('profile_favorite', properties: {'profile_id': widget.userId});
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

  // --- Quick Win Helpers ---
  void _trackProfileView() {
    if (_profileViewTracked) return;
    _profileViewTracked = true;
    MonitoringService().trackEvent('profile_view', properties: {'profile_id': widget.userId});
  }

  String? _sanitizeAndTrimBio(dynamic raw) {
    if (raw is! String || raw.trim().isEmpty) return null;
    var text = raw.replaceAll(RegExp(r'<[^>]*>'), ''); // remove HTML tags
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length > 280) text = '${text.substring(0, 277)}...';
    return text;
  }

  void _shareProfile() {
    final link = 'https://wishlist.app/user/${widget.userId}';
    final localizedMessage = AppLocalizations.of(context)?.shareProfileMessage(link) ?? 'Vê o meu perfil no Wishlist App:';
    final message = '$localizedMessage $link';
    SharePlus.instance.share(ShareParams(text: message));
    MonitoringService().trackEvent('profile_share', properties: {'profile_id': widget.userId});
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: UIConstants.paddingM,
      child: Column(
        children: [
          _shimmerBox(height: 160, width: double.infinity, radius: UIConstants.radiusM),
          Spacing.l,
          _shimmerCircle(diameter: UIConstants.imageSizeXL),
          Spacing.m,
          _shimmerBox(height: 20, width: 180),
          Spacing.s,
          _shimmerBox(height: 14, width: 140),
          Spacing.l,
          _shimmerBox(height: 40, width: double.infinity, radius: UIConstants.radiusS),
        ],
      ),
    );
  }

  Widget _buildWishlistSkeletonList() {
    return ListView.builder(
      padding: UIConstants.listPadding,
      itemCount: 5,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: UIConstants.spacingM),
        child: Row(
          children: [
            _shimmerBox(height: UIConstants.imageSizeM, width: UIConstants.imageSizeM, radius: UIConstants.radiusS),
            Spacing.horizontalM,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(height: 16, width: double.infinity),
                  Spacing.xs,
                  _shimmerBox(height: 12, width: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox({required double height, required double width, double radius = 8}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }

  Widget _shimmerCircle({required double diameter}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: diameter,
        width: diameter,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }
}
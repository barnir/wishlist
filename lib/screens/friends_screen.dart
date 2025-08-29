import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _favoritesService = FavoritesService();
  final _scrollController = ScrollController();

  // Paginação
  static const int _pageSize = 15;
  final List<Map<String, dynamic>> _favorites = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _favorites.clear();
      _currentPage = 0;
      _hasMoreData = true;
    });

    await _loadMoreData();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newFavorites = await _favoritesService.getFavoritesPaginated(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (newFavorites.length < _pageSize) {
            _hasMoreData = false;
          }
          _favorites.addAll(newFavorites);
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorLoadingFavorites(e.toString()) ?? 'Erro ao carregar favoritos: $e')),
        );
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: WishlistAppBar(
        title: l10n.favoritesTitle,
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/explore'),
            tooltip: l10n.searchProfilesTooltip,
          ),
        ],
      ),
      body: _isInitialLoading
          ? WishlistLoadingIndicator(message: l10n.loadingFavorites)
          : _favorites.isEmpty
              ? WishlistEmptyState(
                  icon: Icons.star_border,
                  title: l10n.noFavoritesYet,
                  subtitle: l10n.favoritesEmptySubtitle,
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: UIConstants.listPadding,
                    itemCount: _favorites.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _favorites.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(child: Text(l10n.loadingMoreFavorites)),
                        );
                      }
                      return _buildFavoriteCard(_favorites[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite) {
    final displayName = favorite['display_name'] as String? ?? 'Utilizador';
    final email = favorite['email'] as String?;
    final userId = favorite['id'] as String;
    final bio = favorite['bio'] as String?;
  // final isPrivate = favorite['is_private'] as bool? ?? false; // (não usado atualmente)
    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/user_profile',
            arguments: userId,
          );
        },
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: Container(
          padding: UIConstants.paddingM,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withAlpha(204),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              Spacing.horizontalM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome com badge de favorito
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withAlpha(51),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppLocalizations.of(context)?.favoriteBadge ?? 'FAVORITO',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.amber.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (email != null && email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Seta de navegação (fora das colunas de texto)
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward,
                size: UIConstants.iconSizeS,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
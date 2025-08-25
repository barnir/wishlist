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
          SnackBar(content: Text('Erro ao carregar favoritos: $e')),
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
      body: _isInitialLoading
          ? const WishlistLoadingIndicator(message: 'A carregar favoritos...')
          : _favorites.isEmpty
              ? const WishlistEmptyState(
                  icon: Icons.star_border,
                  title: 'Nenhum favorito ainda',
                  subtitle: 'Explora perfis e marca os teus utilizadores favoritos para veres as suas wishlists públicas!',
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: UIConstants.listPadding,
                    itemCount: _favorites.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _favorites.length) {
                        return _buildLoadingIndicator();
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

  Widget _buildLoadingIndicator() {
    return Container(
      padding: UIConstants.paddingM,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Spacing.horizontalM,
          Text(
            'A carregar mais favoritos...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
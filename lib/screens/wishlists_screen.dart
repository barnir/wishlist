import 'package:flutter/material.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/widgets/optimized_cloudinary_image.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
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
  final _databaseService = FirebaseDatabaseService();
  final _scrollController = ScrollController();

  // Paginação
  static const int _pageSize = 10;
  final List<Map<String, dynamic>> _wishlists = [];
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
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isInitialLoading = true;
      _wishlists.clear();
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

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newWishlists = await _databaseService.getWishlistsPaginated(
        user.uid,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (newWishlists.length < _pageSize) {
            _hasMoreData = false;
          }
          _wishlists.addAll(newWishlists);
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
          // TODO(l10n): Replace with generated getter errorLoadingWishlists when running gen-l10n
          SnackBar(content: Text('Erro ao carregar wishlists: $e')),
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

  // Widget para o estado de "lista vazia"
  Widget _buildEmptyState(BuildContext context) {
  // l10n placeholder (getters ainda não regenerados)
    return WishlistEmptyState(
      icon: Icons.card_giftcard_rounded,
  // TODO(l10n): Replace with l10n.noWishlistsYetTitle / Subtitle
  title: 'Nenhuma wishlist por aqui',
  subtitle: 'Toque em "+" para criar a sua primeira!',
    );
  }

  // Widget para construir cada card da wishlist - Modernizado
  Widget _buildWishlistCard(
    BuildContext context,
    Map<String, dynamic> wishlist,
  ) {
  // l10n placeholder (getters ainda não regenerados)
  final name = wishlist['name'] ?? 'Sem nome'; // TODO(l10n): use l10n.noName
    final isPrivate = wishlist['is_private'] ?? false;
    final imageUrl = wishlist['image_url'];

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
            '/wishlist_details',
            arguments: wishlist['id'],
          );
        },
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: Container(
          padding: UIConstants.paddingM,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem da wishlist maior e mais moderna
                _buildWishlistImage(context, imageUrl),
                
                Spacing.horizontalM,
                
                // Informação principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título da wishlist
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      Spacing.s,
                      
                      // Status de privacidade com chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPrivate 
                            ? Theme.of(context).colorScheme.errorContainer
                            : Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPrivate ? Icons.lock : Icons.public,
                              size: 12,
                              color: isPrivate 
                                ? Theme.of(context).colorScheme.onErrorContainer
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isPrivate ? 'Privada' : 'Pública', // TODO(l10n): use l10n.private / l10n.public
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isPrivate 
                                  ? Theme.of(context).colorScheme.onErrorContainer
                                  : Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Bottom row com total e seta
                      Row(
                        children: [
                          Expanded(
                            child: WishlistTotal(wishlistId: wishlist['id']),
                          ),
                          
                          Icon(
                            Icons.arrow_forward,
                            size: UIConstants.iconSizeS,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para a imagem da wishlist
  Widget _buildWishlistImage(BuildContext context, String? imageUrl) {
    return OptimizedCloudinaryImage(
      originalUrl: imageUrl,
      transformationType: ImageType.wishlistIcon,
      width: 80,
      height: 80,
      borderRadius: BorderRadius.circular(UIConstants.radiusM),
      fallbackIcon: const Icon(Icons.card_giftcard),
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
            'A carregar mais wishlists...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return Scaffold(
  appBar: AppBar(title: Text(AppLocalizations.of(context)?.myWishlists ?? 'Minhas Wishlists')),
        body: const Center(
          child: Text('Por favor, faça login para ver suas wishlists.'), // TODO(l10n): l10n.pleaseLoginToSeeWishlists
        ),
      );
    }

    return Scaffold(
      appBar: WishlistAppBar(
        title: AppLocalizations.of(context)?.myWishlists ?? 'Minhas Wishlists',
        showBackButton: false,
      ),
      body: _isInitialLoading
          ? const WishlistLoadingIndicator(message: 'A carregar wishlists...')
          : _wishlists.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: UIConstants.listPadding,
                    itemCount: _wishlists.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _wishlists.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildWishlistCard(context, _wishlists[index]);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_edit_wishlist').then((_) {
            // Refresh data when returning from add/edit
            _loadInitialData();
          });
        },
  tooltip: 'Adicionar nova wishlist',
        child: const Icon(Icons.add),
      ),
    );
  }
}
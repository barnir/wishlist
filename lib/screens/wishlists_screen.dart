import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
// Legacy FirebaseDatabaseService removed in favor of typed repository
import 'package:wishlist_app/repositories/wishlist_repository.dart';
import 'package:wishlist_app/models/wishlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/wishlist_card_item.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  final _authService = AuthService();
  final _wishlistRepo = WishlistRepository();
  final _scrollController = ScrollController();

  // Paginação
  static const int _pageSize = 10;
  final List<Wishlist> _wishlists = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;
  DocumentSnapshot? _lastDoc;

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
  _lastDoc = null;
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
      final page = await _wishlistRepo.fetchUserWishlists(
        ownerId: user.uid,
        limit: _pageSize,
        startAfter: _lastDoc,
      );
      if (!mounted) return;
      setState(() {
        _wishlists.addAll(page.items);
        _lastDoc = page.lastDoc;
        _hasMoreData = page.hasMore;
        _isLoading = false;
      });
      if (!_hasMoreData) {
        _scrollController.removeListener(_onScroll);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((AppLocalizations.of(context)?.errorLoadingWishlists(e.toString())) ?? 'Erro ao carregar wishlists: $e')),
        );
      }
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.idle) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
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
  title: AppLocalizations.of(context)?.noWishlistsYetTitle ?? 'Nenhuma wishlist por aqui',
  subtitle: AppLocalizations.of(context)?.noWishlistsYetSubtitle ?? 'Toque em "+" para criar a sua primeira!',
    );
  }

  // Widget para construir cada card da wishlist - Modernizado
  Widget _buildWishlistCard(BuildContext context, Wishlist wishlist) => WishlistCardItem(
        wishlist: wishlist,
        onTap: () => Navigator.pushNamed(context, '/wishlist_details', arguments: wishlist.id),
      );

  // _buildWishlistImage removido (lógica movida para WishlistCardItem)

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
            AppLocalizations.of(context)?.loadingMoreWishlists ?? 'A carregar mais wishlists...',
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
        body: Center(
          child: Text(AppLocalizations.of(context)?.pleaseLoginToSeeWishlists ?? 'Por favor, faça login para ver suas wishlists.'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Se estamos na tela principal (wishlists) e o usuário usa gesto back,
          // sair da aplicação em vez de ir para login
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: WishlistAppBar(
          title: AppLocalizations.of(context)?.myWishlists ?? 'Minhas Wishlists',
          showBackButton: false,
        ),
      body: _isInitialLoading
          ? WishlistLoadingIndicator(message: AppLocalizations.of(context)?.loadingWishlists ?? 'A carregar wishlists...')
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
    tooltip: AppLocalizations.of(context)?.addNewWishlistTooltip ?? 'Adicionar nova wishlist',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
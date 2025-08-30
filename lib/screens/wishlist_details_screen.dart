import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishlist_app/widgets/optimized_cloudinary_image.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/widgets/swipe_action_widget.dart';
import 'package:wishlist_app/widgets/safe_navigation_wrapper.dart';
import 'package:wishlist_app/models/sort_options.dart';
import '../models/wish_item.dart';
import '../widgets/ui_components.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../constants/ui_constants.dart';
import 'package:wishlist_app/services/auth_service.dart';
import '../services/filter_preferences_service.dart';
import '../widgets/app_snack.dart';

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  final _databaseService = FirebaseDatabaseService();
  final _scrollController = ScrollController();

  String _wishlistName = 'Carregando...';
  bool _isPrivate = false;
  String? _selectedCategory;
  SortOptions _sortOption = SortOptions.nameAsc;

  // Paginação
  static const int _pageSize = 20;
  final List<WishItem> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;
  Timer? _reloadDebounce;
  DocumentSnapshot? _lastDoc; // cursor for Firestore pagination
  DateTime _lastScrollRequest = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
  _restoreSavedFilters();
    _loadWishlistDetails();
    _checkOwnership();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _reloadDebounce?.cancel();
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;
      
      final wishlistData = await _databaseService.getWishlist(widget.wishlistId);
      if (wishlistData != null && mounted) {
        setState(() {
          // Ownership check can be added here if needed
        });
      }
    } catch (e) {
      // Falhar silenciosamente
    }
  }

  Future<void> _loadWishlistDetails() async {
    try {
      final wishlistData = await _databaseService.getWishlist(
        widget.wishlistId,
      );
      if (mounted && wishlistData != null) {
        setState(() {
          _wishlistName = wishlistData['name'] ?? (AppLocalizations.of(context)?.noName ?? 'Sem nome');
          _isPrivate = wishlistData['is_private'] ?? false;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar detalhes da wishlist: $e', isError: true);
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialLoading = true;
      _items.clear();
      _hasMoreData = true;
  _lastDoc = null;
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
  final now = DateTime.now();
  if (now.difference(_lastScrollRequest).inMilliseconds < 150) return; // throttle
  _lastScrollRequest = now;

    setState(() {
      _isLoading = true;
    });

    try {
  final pageResult = await _databaseService.getWishItemsPageCursor(
        widget.wishlistId,
        limit: _pageSize,
        category: _selectedCategory,
        sortOption: _sortOption,
        startAfter: _lastDoc,
      );
  final (pageItems, pageLastDoc) = pageResult;
  final newItems = pageItems.map((m) => WishItem.fromMap(m)).toList();

      if (mounted) {
        setState(() {
          _lastDoc = pageLastDoc;
          if (newItems.length < _pageSize || pageLastDoc == null) {
            _hasMoreData = false;
          }
          _items.addAll(newItems);
          _isLoading = false;
        });

        // Precache first image of newly loaded first page for smoother UX
        if (_items.length == newItems.length && newItems.isNotEmpty) {
          final firstWithImage = newItems.firstWhere(
            (w) => w.imageUrl != null && w.imageUrl!.isNotEmpty,
            orElse: () => newItems.first,
          );
          if (firstWithImage.imageUrl != null && mounted) {
            // Use a NetworkImage; OptimizedCloudinaryImage already transforms at build time
            precacheImage(NetworkImage(firstWithImage.imageUrl!), context).catchError((_) {});
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Erro ao carregar itens: $e', isError: true);
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

  Future<void> _onFilterChanged() async {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 120), () async {
      await FilterPreferencesService()
          .save(_selectedCategory, _sortOption, wishlistId: widget.wishlistId);
      await _loadInitialData();
    });
  }

  Future<void> _restoreSavedFilters() async {
    final data = await FilterPreferencesService().load(wishlistId: widget.wishlistId);
    if (data != null && mounted) {
      setState(() {
        _selectedCategory = data.$1;
        _sortOption = data.$2;
      });
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _databaseService.deleteWishItemFromWishlist(widget.wishlistId, itemId);
      if (!mounted) return;
      _showSnackBar('Item eliminado com sucesso!');
      
      // Remove item from local list
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Erro ao eliminar item: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    AppSnack.show(context, message,
        type: isError ? SnackType.error : SnackType.info);
  }

  @override
  Widget build(BuildContext context) {
    return SafeNavigationWrapper(
      onBackPressed: () {
        // Prefer a simple pop so we return to HomeScreen / BottomNav intact.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
              // Da tela de detalhes da wishlist: pop preservando bottom navigation
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed('/wishlists');
              }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_wishlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
            tooltip: AppLocalizations.of(context)?.filterAndSortTooltip ?? 'Filtrar e Ordenar',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/add_edit_wishlist',
                arguments: widget.wishlistId,
              ).then((_) => _loadWishlistDetails());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/add_edit_item',
            arguments: {'wishlistId': widget.wishlistId},
          ).then((_) => _loadInitialData()); // Refresh after adding item
        },
        tooltip: AppLocalizations.of(context)?.addNewItemTooltip ?? 'Adicionar novo item',
        child: const Icon(Icons.add),
      ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading) {
      return WishlistLoadingIndicator(
        message: AppLocalizations.of(context)?.loadingItems ?? 'A carregar itens...',
      );
    }

    if (_items.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: UIConstants.listPadding,
        itemCount: _items.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _buildLoadingIndicator();
          }
          return _buildItemCardWithSwipe(_items[index]);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: UIConstants.paddingM,
      child: Row(
        children: [
          Icon(
            _isPrivate ? Icons.lock_outline : Icons.public_outlined,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          Spacing.horizontalS,
          Text(
            _isPrivate
                ? (AppLocalizations.of(context)?.wishlistIsPrivate ?? 'Esta wishlist é privada')
                : (AppLocalizations.of(context)?.wishlistIsPublic ?? 'Esta wishlist é pública'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return WishlistEmptyState(
      icon: Icons.add_shopping_cart_rounded,
      title: AppLocalizations.of(context)?.wishlistEmptyTitle ?? 'A sua wishlist está vazia',
      subtitle: AppLocalizations.of(context)?.wishlistEmptySubtitle ?? 'Adicione o seu primeiro desejo!',
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
            AppLocalizations.of(context)?.loadingMoreItems ?? 'A carregar mais itens...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCardWithSwipe(WishItem item) {
    return SwipeActionWidget(
      onEdit: () => _editItem(item),
      onDelete: () => _showDeleteConfirmation(item),
  editLabel: AppLocalizations.of(context)?.edit ?? 'Editar',
  deleteLabel: AppLocalizations.of(context)?.delete ?? 'Eliminar',
      child: _buildItemCard(item),
    );
  }

  void _editItem(WishItem item) {
    Navigator.pushNamed(
      context,
      '/add_edit_item',
      arguments: {
        'wishlistId': widget.wishlistId,
        'itemId': item.id,
      },
    ).then((_) => _loadInitialData());
  }

  Widget _buildItemCard(WishItem item) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return WishlistCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item image with Hero animation
          if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            Hero(
              tag: 'item_image_${item.id}',
              child: GestureDetector(
                onTap: () => _showImageFullscreen(item),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(UIConstants.radiusM),
                      topRight: Radius.circular(UIConstants.radiusM),
                    ),
                    child: OptimizedCloudinaryImage(
                      originalUrl: item.imageUrl!,
                      transformationType: ImageType.productLarge,
                      width: double.infinity,
                      height: 200,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(UIConstants.radiusM),
                        topRight: Radius.circular(UIConstants.radiusM),
                      ),
                      fallbackIcon: Icon(
                        Icons.broken_image,
                        color: Theme.of(context).colorScheme.error,
                        size: 48,
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: UIConstants.paddingM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name
                Text(
                  item.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                if (item.description?.isNotEmpty == true) ...[
                  Spacing.xs,
                  Text(
                    item.description!,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                Spacing.s,
                
                // Price and category row
                Row(
                  children: [
                    if (item.price != null && item.price! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(UIConstants.radiusS),
                        ),
                        child: Text(
                          '€${item.price!.toStringAsFixed(2)}',
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Spacing.horizontalS,
                    ],
                    
                    if (item.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(UIConstants.radiusS),
                        ),
                        child: Text(
                          item.category,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                
                Spacing.s,
                
                // Action buttons
                Row(
                  children: [
                    if (item.link?.isNotEmpty == true)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final l10n = AppLocalizations.of(context);
                            final uri = Uri.tryParse(item.link!);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              if (context.mounted) {
                                _showSnackBar(l10n?.couldNotOpenLink ?? 'Não foi possível abrir o link', isError: true);
                              }
                            }
                          },
                          icon: const Icon(Icons.launch, size: 16),
              label: Text(AppLocalizations.of(context)?.view ?? 'Ver'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    
                    if (item.link?.isNotEmpty == true)
                      Spacing.horizontalS,
                    
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (!mounted) return;
                          Navigator.pushNamed(
                            context,
                            '/add_edit_item',
                            arguments: {
                              'wishlistId': widget.wishlistId,
                              'itemId': item.id,
                            },
                          ).then((_) => _loadInitialData());
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(AppLocalizations.of(context)?.edit ?? 'Editar'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    
                    Spacing.horizontalS,
                    
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(item),
                      icon: Icon(
                        Icons.delete_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      tooltip: AppLocalizations.of(context)?.deleteItemTooltip ?? 'Eliminar item',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullscreen(WishItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _FullscreenImageViewer(
          imageUrl: item.imageUrl!,
          heroTag: 'item_image_${item.id}',
          title: item.name,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        opaque: false,
        barrierColor: Colors.black87,
      ),
    );
  }

  void _showDeleteConfirmation(WishItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.deleteItemTitle ?? 'Eliminar item'),
        content: Text(
          (AppLocalizations.of(context)?.deleteItemConfirmation(item.name) ?? 'Tens a certeza que queres eliminar "${item.name}"?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)?.delete ?? 'Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showFilterBottomSheet(
      context: context,
      selectedCategory: _selectedCategory,
      sortOption: _sortOption,
      onFiltersChanged: (category, sortOption) {
        setState(() {
          _selectedCategory = category;
          _sortOption = sortOption;
        });
        _onFilterChanged();
      },
      wishlistId: widget.wishlistId,
    );
  }
}

class _FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;
  final String title;

  const _FullscreenImageViewer({
    required this.imageUrl,
    required this.heroTag,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            child: OptimizedCloudinaryImage(
              originalUrl: imageUrl,
              transformationType: ImageType.productLarge,
              fit: BoxFit.contain,
              fallbackIcon: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.error,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
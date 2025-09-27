import 'package:mywishstash/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/scheduler.dart';
import 'package:mywishstash/widgets/optimized_cloudinary_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mywishstash/widgets/accessible_icon_button.dart';
import 'package:mywishstash/services/cloudinary_service.dart'
    as cloudinary_service;
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/repositories/wish_item_repository.dart';
import 'package:mywishstash/widgets/safe_navigation_wrapper.dart';
import 'package:mywishstash/models/sort_options.dart';
import 'package:mywishstash/models/wishlist_layout_mode.dart';
import '../models/wish_item.dart';
import '../widgets/ui_components.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../constants/ui_constants.dart';
import '../services/filter_preferences_service.dart';
import '../widgets/app_snack.dart';
import '../widgets/item_status_dialog.dart';
import '../utils/validation_utils.dart';
import 'package:mywishstash/utils/performance_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wish_item_status_service.dart';
import '../models/wish_item_status.dart';

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen>
    with PerformanceOptimizedState {
  final _wishlistRepo = WishlistRepository();
  final _wishItemRepo = WishItemRepository();
  final _scrollController = ScrollController();
  final _statusService = WishItemStatusService();

  String _wishlistName = '';
  bool _isPrivate = false;
  String? _selectedCategory;
  SortOptions _sortOption = SortOptions.nameAsc;
  WishlistLayoutMode _layoutMode = WishlistLayoutMode.list;
  bool get _isCompactList => _layoutMode == WishlistLayoutMode.list;

  // SECURITY: Track ownership to prevent unauthorized editing
  String? _wishlistOwnerId;
  bool get _isOwner {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _wishlistOwnerId == null) return false;
    return currentUser.uid == _wishlistOwnerId;
  }

  // Paginação
  static const int _pageSize = 20;
  final List<WishItem> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;
  Timer? _reloadDebounce;
  DocumentSnapshot? _lastDoc; // cursor for Firestore pagination
  DateTime _lastScrollRequest = DateTime.fromMillisecondsSinceEpoch(0);

  // Purchase statuses
  Map<String, List<WishItemStatus>> _itemStatuses = {};

  @override
  void initState() {
    super.initState();
    _restoreSavedFilters();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  bool _detailsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer loading details that depend on InheritedWidgets (Localizations, Theme)
    if (!_detailsLoaded) {
      _detailsLoaded = true;
      // schedule to run after the current frame to be safe
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadWishlistDetails();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _reloadDebounce?.cancel();
    super.dispose();
  }

  // Ownership was previously checked via legacy database service. Removed after migration.

  Future<void> _loadWishlistDetails() async {
    final l10n = AppLocalizations.of(context);
    try {
      final wishlist = await _wishlistRepo.fetchById(widget.wishlistId);
      if (wishlist == null) {
        logW('Wishlist fetchById returned null', tag: 'DB');
        if (mounted) {
          setState(() {
            // Provide a useful fallback title so the appBar isn't stuck on the localized loading text
            _wishlistName = 'Wishlist (${widget.wishlistId.substring(0, 6)})';
            _isPrivate = false;
            _wishlistOwnerId = null;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _wishlistName = wishlist.name.isNotEmpty
              ? wishlist.name
              : 'Wishlist (${widget.wishlistId.substring(0, 6)})';
          _isPrivate = wishlist.isPrivate;
          _wishlistOwnerId = wishlist.ownerId;

          // SECURITY LOG: Track ownership for security audit
          final currentUser = FirebaseAuth.instance.currentUser;
          logI(
            'SECURITY: Wishlist access - Owner: ${wishlist.ownerId}, Current User: ${currentUser?.uid}, IsOwner: ${currentUser?.uid == wishlist.ownerId}',
            tag: 'SECURITY',
          );
        });
      }
    } catch (e) {
      logE('Wishlist details load error', tag: 'DB', error: e);
      // Ensure UI shows a useful title even on error
      if (mounted) {
        setState(() {
          _wishlistName = 'Wishlist (${widget.wishlistId.substring(0, 6)})';
          _isPrivate = false;
          _wishlistOwnerId = null;
        });
      }
      final msg =
          l10n?.wishlistDetailsLoadError(e.toString()) ??
          'Erro ao carregar detalhes da wishlist: $e';
      _showSnackBar(msg, isError: true);
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
    await _loadPurchaseStatuses();

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading || !_hasMoreData) return;
    final now = DateTime.now();
    if (now.difference(_lastScrollRequest).inMilliseconds < 150) {
      return; // throttle (throttled rapid scroll events)
    }
    _lastScrollRequest = now;

    setState(() {
      _isLoading = true;
    });

    try {
      final pageFuture = _wishItemRepo.fetchPage(
        wishlistId: widget.wishlistId,
        limit: _pageSize,
        category: _selectedCategory,
        sortOptions: _sortOption,
        startAfter: _lastDoc,
      );
      // Não aguardar ainda: permite preparar contexto se necessário
      final page = await pageFuture;
      final newItems = page.items;

      // Garantir que widget ainda está montado antes de qualquer uso de contexto posterior
      if (!mounted) return;

      if (mounted) {
        setState(() {
          _lastDoc = page.lastDoc;
          _hasMoreData = page.hasMore;
          _items.addAll(newItems);
          _isLoading = false;
        });

        if (!_hasMoreData) {
          _scrollController.removeListener(_onScroll);
        }
      }
      // Prefetch thumbnails da próxima página (se houver mais dados)
      if (page.hasMore && page.lastDoc != null) {
        final nextPage = await _wishItemRepo.fetchPage(
          wishlistId: widget.wishlistId,
          limit: _pageSize,
          category: _selectedCategory,
          sortOptions: _sortOption,
          startAfter: page.lastDoc,
        );
        final nextImageUrls = nextPage.items
            .map((item) => item.imageUrl)
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList();
        for (final url in nextImageUrls) {
          // Prefetch usando CachedNetworkImageProvider
          CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
        }
      }
      // Schedule first image precache without using BuildContext after awaits.
      _scheduleFirstImagePrecache(newItems);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        final msg =
            AppLocalizations.of(context)?.itemsLoadError(e.toString()) ??
            'Erro ao carregar itens: $e';
        _showSnackBar(msg, isError: true);
      }
    }
  }

  void _scheduleFirstImagePrecache(List<WishItem> newItems) {
    if (!mounted) return;
    if (_items.length != newItems.length || newItems.isEmpty) {
      // apenas primeira página
      return;
    }
    final firstWithImage = newItems.firstWhere(
      (w) => w.imageUrl != null && w.imageUrl!.isNotEmpty,
      orElse: () => newItems.first,
    );
    final imageUrl = firstWithImage.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // ainda garantir que a página não foi descartada
      final provider = NetworkImage(imageUrl);
      // Inicia resolução/caching sem BuildContext para evitar lint use_build_context_synchronously.
      provider.resolve(const ImageConfiguration());
    });
  }

  void _onScroll() {
    // Guard: ignore when user not actively scrolling (idle/ballistic) to reduce spurious checks
    final pos = _scrollController.position;
    if (pos.userScrollDirection == ScrollDirection.idle) return;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  Future<void> _onFilterChanged() async {
    _reloadDebounce?.cancel();
    _reloadDebounce = Timer(const Duration(milliseconds: 120), () async {
      await FilterPreferencesService().save(
        _selectedCategory,
        _sortOption,
        wishlistId: widget.wishlistId,
      );
      await _loadInitialData();
    });
  }

  Future<void> _restoreSavedFilters() async {
    final data = await FilterPreferencesService().load(
      wishlistId: widget.wishlistId,
    );
    if (data != null && mounted) {
      setState(() {
        _selectedCategory = data.$1;
        _sortOption = data.$2;
      });
    }
    final layout = await FilterPreferencesService().loadLayout(
      wishlistId: widget.wishlistId,
    );
    if (layout != null && mounted) {
      setState(() {
        _layoutMode = layout;
      });
    }
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      // Use repository delete (legacy service kept for other flows if needed)
      await _wishItemRepo.deleteItem(itemId);
      if (!mounted) return;
      AppSnack.show(
        context,
        AppLocalizations.of(context)?.itemDeletedSuccess ??
            'Item eliminado com sucesso!',
        type: SnackType.success,
      );

      // Remove item from local list
      setState(() {
        _items.removeWhere((item) => item.id == itemId);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        AppLocalizations.of(context)?.itemDeleteError(e.toString()) ??
            'Erro ao eliminar item: $e',
        isError: true,
      );
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    AppSnack.show(
      context,
      message,
      type: isError ? SnackType.error : SnackType.info,
    );
  }

  Future<void> _toggleLayoutMode() async {
    setState(() {
      _layoutMode = _layoutMode.toggled;
    });
    // Persist preference (scoped by wishlist)
    await FilterPreferencesService().saveLayout(
      _layoutMode,
      wishlistId: widget.wishlistId,
    );
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
          title: Text(
            _wishlistName.isEmpty
                ? (AppLocalizations.of(context)?.loadingInline ??
                      'A carregar...')
                : _wishlistName,
          ),
          actions: [
            AccessibleIconButton(
              icon: Icons.filter_list,
              semanticLabel:
                  AppLocalizations.of(context)?.filterAndSortTooltip ??
                  'Filtrar e ordenar wishlist',
              tooltip:
                  AppLocalizations.of(context)?.filterAndSortTooltip ??
                  'Filtrar e Ordenar',
              onPressed: () => _showFilterBottomSheet(),
            ),
            AccessibleIconButton(
              icon: _layoutMode == WishlistLayoutMode.list
                  ? Icons.grid_view
                  : Icons.view_agenda,
              semanticLabel: _layoutMode.iconSemanticLabel,
              tooltip: _layoutMode.tooltip,
              onPressed: _toggleLayoutMode,
            ),
            AccessibleIconButton(
              icon: Icons.edit,
              semanticLabel:
                  '${AppLocalizations.of(context)?.edit ?? 'Editar'} wishlist',
              tooltip: AppLocalizations.of(context)?.edit ?? 'Editar',
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
            Expanded(child: _buildContent()),
          ],
        ),
        // SECURITY: Only show add button to owner
        floatingActionButton: _isOwner
            ? Semantics(
                label:
                    AppLocalizations.of(context)?.addNewItemTooltip ??
                    'Adicionar novo item',
                button: true,
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/add_edit_item',
                      arguments: {'wishlistId': widget.wishlistId},
                    ).then((_) => _loadInitialData());
                  },
                  tooltip:
                      AppLocalizations.of(context)?.addNewItemTooltip ??
                      'Adicionar novo item',
                  child: const Icon(Icons.add),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading) {
      return const SkeletonLoader(itemCount: 6);
    }

    if (_items.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _isCompactList
          ? ListView.builder(
              controller: _scrollController,
              padding: UIConstants.listPadding.copyWith(top: 4, bottom: 12),
              itemExtent: 68,
              itemCount: _items.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isInitialLoading) {
                  return const SkeletonLoader(itemCount: 1);
                }
                if (index == _items.length) {
                  return const SkeletonLoader(itemCount: 1);
                }
                return _buildCompactRow(_items[index]);
              },
            )
          : GridView.builder(
              controller: _scrollController,
              padding: UIConstants.listPadding.copyWith(top: 4, bottom: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: _items.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isInitialLoading) {
                  return const SkeletonLoader(itemCount: 1);
                }
                if (index == _items.length) {
                  return const SkeletonLoader(itemCount: 1);
                }
                return _buildGridItem(_items[index]);
              },
            ),
    );
  }

  Widget _buildCompactRow(WishItem item) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return InkWell(
      // SECURITY: Owners can edit, non-owners can mark purchase status
      onTap: _isOwner
          ? () => _editItem(item)
          : () => _showPurchaseStatusDialog(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildItemThumbnail(item, size: 48),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.price != null && item.price! > 0)
                        Text(
                          '€${item.price!.toStringAsFixed(2)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (item.price != null && item.price! > 0)
                        const SizedBox(width: 8),
                      Text(
                        'x${item.quantity}',
                        style: textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      // Purchase status indicator
                      if (_getItemStatusText(item) != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getItemStatusColor(
                              item,
                            )?.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getItemStatusColor(item) ?? Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getItemStatusText(item)!,
                            style: textTheme.labelSmall?.copyWith(
                              color: _getItemStatusColor(item),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (item.link?.isNotEmpty == true)
              AccessibleIconButton(
                icon: Icons.shopping_cart_outlined,
                tooltip: AppLocalizations.of(context)?.view ?? 'Ver',
                semanticLabel: AppLocalizations.of(context)?.view ?? 'Ver',
                onPressed: () => _openItemLink(item),
              ),
            // SECURITY: Only show edit/delete buttons to owner
            if (_isOwner) ...[
              AccessibleIconButton(
                icon: Icons.edit_outlined,
                tooltip: AppLocalizations.of(context)?.edit ?? 'Editar',
                semanticLabel: AppLocalizations.of(context)?.edit ?? 'Editar',
                onPressed: () => _editItem(item),
              ),
              AccessibleIconButton(
                icon: Icons.delete_outline,
                tooltip: AppLocalizations.of(context)?.delete ?? 'Eliminar',
                semanticLabel:
                    AppLocalizations.of(context)?.delete ?? 'Eliminar',
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _showDeleteConfirmation(item),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemThumbnail(WishItem item, {double size = 56.0}) {
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant, size: 28),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(
          item.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            final cs = Theme.of(context).colorScheme;
            return Container(
              color: cs.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Icon(
                Icons.broken_image_outlined,
                color: cs.onSurfaceVariant,
                size: 24,
              ),
            );
          },
        ),
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
                ? (AppLocalizations.of(context)?.wishlistIsPrivate ??
                      'Esta wishlist é privada')
                : (AppLocalizations.of(context)?.wishlistIsPublic ??
                      'Esta wishlist é pública'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return WishlistEmptyState(
      icon: Icons.add_shopping_cart_rounded,
      title:
          AppLocalizations.of(context)?.wishlistEmptyTitle ??
          'A sua wishlist está vazia',
      subtitle:
          AppLocalizations.of(context)?.wishlistEmptySubtitle ??
          'Adicione o seu primeiro desejo!',
    );
  }

  void _editItem(WishItem item) {
    // SECURITY: Only allow owner to edit items
    if (!_isOwner) {
      logW(
        'SECURITY: Unauthorized edit attempt by user ${FirebaseAuth.instance.currentUser?.uid} on wishlist ${widget.wishlistId}',
        tag: 'SECURITY',
      );
      _showSnackBar(
        'Não tens permissão para editar esta wishlist',
        isError: true,
      );
      return;
    }

    Navigator.pushNamed(
      context,
      '/add_edit_item',
      arguments: {'wishlistId': widget.wishlistId, 'itemId': item.id},
    ).then((_) => _loadInitialData());
  }

  Future<void> _openItemLink(WishItem item) async {
    if (item.link == null || item.link!.isEmpty) {
      return; // nothing to open
    }
    final raw = item.link!.trim();
    final sanitized = ValidationUtils.sanitizeUrlForSave(raw);
    final uri = Uri.tryParse(sanitized);
    if (uri == null) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)?.couldNotOpenLink ??
              'Não foi possível abrir o link',
          isError: true,
        );
      }
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        _showSnackBar(
          AppLocalizations.of(context)?.couldNotOpenLink ??
              'Não foi possível abrir o link',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)?.couldNotOpenLink ??
              'Não foi possível abrir o link',
          isError: true,
        );
      }
    }
  }

  Widget _buildGridItem(WishItem item) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      // SECURITY: Owners can edit/delete, non-owners can mark purchase status
      onTap: _isOwner
          ? () => _editItem(item)
          : () => _showPurchaseStatusDialog(item),
      onLongPress: _isOwner
          ? () => _showDeleteConfirmation(item)
          : () => _showPurchaseStatusDialog(item),
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(UIConstants.radiusM),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0x00000000,
                ).withValues(alpha: 0.05, red: 0, green: 0, blue: 0),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image + optional link action overlay
              Stack(
                children: [
                  if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(UIConstants.radiusM),
                        topRight: Radius.circular(UIConstants.radiusM),
                      ),
                      child: OptimizedCloudinaryImage(
                        originalUrl: item.imageUrl!,
                        transformationType:
                            cloudinary_service.ImageType.productLarge,
                        width: double.infinity,
                        height: 120,
                        fit: BoxFit.cover,
                        fallbackIcon: Icon(
                          Icons.broken_image,
                          color: colorScheme.error,
                          size: 32,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(UIConstants.radiusM),
                          topRight: Radius.circular(UIConstants.radiusM),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (item.link != null && item.link!.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openItemLink(item),
                          child: const Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Textual details
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.price != null && item.price! > 0)
                      Text(
                        '€${item.price!.toStringAsFixed(2)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (item.category.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          item.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    // Purchase status indicator
                    if (_getItemStatusText(item) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getItemStatusColor(
                              item,
                            )?.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _getItemStatusColor(item) ?? Colors.grey,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getItemStatusText(item)!,
                            style: textTheme.labelSmall?.copyWith(
                              color: _getItemStatusColor(item),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(WishItem item) {
    // SECURITY: Only allow owner to delete items
    if (!_isOwner) {
      logW(
        'SECURITY: Unauthorized delete attempt by user ${FirebaseAuth.instance.currentUser?.uid} on wishlist ${widget.wishlistId}',
        tag: 'SECURITY',
      );
      _showSnackBar(
        'Não tens permissão para eliminar itens desta wishlist',
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.deleteItemTitle ?? 'Eliminar item',
        ),
        content: Text(
          (AppLocalizations.of(context)?.deleteItemConfirmation(item.name) ??
              'Tens a certeza que queres eliminar "${item.name}"?'),
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

  Future<void> _loadPurchaseStatuses() async {
    try {
      final statuses = await _statusService.getWishlistStatuses(
        widget.wishlistId,
      );

      // Group statuses by item ID
      final statusMap = <String, List<WishItemStatus>>{};
      for (final status in statuses) {
        statusMap.putIfAbsent(status.wishItemId, () => []).add(status);
      }

      if (mounted) {
        setState(() {
          _itemStatuses = statusMap;
        });
      }
    } catch (e) {
      logE(
        'Error loading purchase statuses',
        tag: 'WISHLIST_DETAILS',
        error: e,
      );
    }
  }

  String? _getItemStatusText(WishItem item) {
    final statuses = _itemStatuses[item.id] ?? [];
    if (statuses.isEmpty) return null;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    // Check if current user has status
    final myStatus = statuses
        .where((s) => s.userId == currentUserId)
        .firstOrNull;
    if (myStatus != null) {
      return myStatus.status.shortDisplayName;
    }

    // Show how many people marked it
    final purchasedCount = statuses
        .where((s) => s.status == ItemPurchaseStatus.purchased)
        .length;
    final willBuyCount = statuses
        .where((s) => s.status == ItemPurchaseStatus.willBuy)
        .length;

    if (purchasedCount > 0) {
      return '$purchasedCount comprado${purchasedCount > 1 ? 's' : ''}';
    } else if (willBuyCount > 0) {
      return '$willBuyCount reservado${willBuyCount > 1 ? 's' : ''}';
    }

    return null;
  }

  Color? _getItemStatusColor(WishItem item) {
    final statuses = _itemStatuses[item.id] ?? [];
    if (statuses.isEmpty) return null;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    // Check if current user has status
    final myStatus = statuses
        .where((s) => s.userId == currentUserId)
        .firstOrNull;
    if (myStatus != null) {
      return myStatus.status == ItemPurchaseStatus.purchased
          ? Colors.green
          : Colors.orange;
    }

    // Show status for others
    final purchasedCount = statuses
        .where((s) => s.status == ItemPurchaseStatus.purchased)
        .length;
    if (purchasedCount > 0) {
      return Colors.green;
    }

    return Colors.orange;
  }

  void _showPurchaseStatusDialog(WishItem item) {
    // Don't allow owners to mark their own items
    if (_isOwner) {
      return;
    }

    // Show the purchase status dialog
    showDialog(
      context: context,
      builder: (context) => ItemStatusDialog(
        wishItemId: item.id,
        itemName: item.name,
        isOwner: _isOwner,
      ),
    ).then((result) {
      if (result == true) {
        // Status was successfully updated, refresh the list
        _loadInitialData();
      }
    });
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

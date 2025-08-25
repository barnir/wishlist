import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishlist_app/services/supabase_database_service.dart';
import 'package:wishlist_app/widgets/swipe_action_widget.dart';
import 'package:wishlist_app/models/sort_options.dart';
import '../models/wish_item.dart';
import '../widgets/ui_components.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../constants/ui_constants.dart';
import 'package:wishlist_app/services/auth_service.dart';

class WishlistDetailsScreen extends StatefulWidget {
  final String wishlistId;

  const WishlistDetailsScreen({super.key, required this.wishlistId});

  @override
  State<WishlistDetailsScreen> createState() => _WishlistDetailsScreenState();
}

class _WishlistDetailsScreenState extends State<WishlistDetailsScreen> {
  final _supabaseDatabaseService = SupabaseDatabaseService();
  final _scrollController = ScrollController();

  String _wishlistName = 'Carregando...';
  bool _isPrivate = false;
  String? _selectedCategory;
  SortOptions _sortOption = SortOptions.nameAsc;

  // Paginação
  static const int _pageSize = 20;
  final List<WishItem> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMoreData = true;
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWishlistDetails();
    _checkOwnership();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkOwnership() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;
      
      final wishlistData = await _supabaseDatabaseService.getWishlist(widget.wishlistId);
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
      final wishlistData = await _supabaseDatabaseService.getWishlist(
        widget.wishlistId,
      );
      if (mounted && wishlistData != null) {
        setState(() {
          _wishlistName = wishlistData['name'] ?? 'Sem nome';
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
      final newItemsData = await _supabaseDatabaseService.getWishItemsPaginatedFuture(
        widget.wishlistId,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        category: _selectedCategory,
        sortOption: _sortOption,
      );

      final newItems = newItemsData
          .map((itemData) => WishItem.fromMap(itemData))
          .toList();

      if (mounted) {
        setState(() {
          if (newItems.length < _pageSize) {
            _hasMoreData = false;
          }
          _items.addAll(newItems);
          _currentPage++;
          _isLoading = false;
        });
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
    // Reload data with new filters
    await _loadInitialData();
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await _supabaseDatabaseService.deleteWishItem(widget.wishlistId, itemId);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishlistName),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(),
            tooltip: 'Filtrar e Ordenar',
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
        tooltip: 'Adicionar novo item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    if (_isInitialLoading) {
      return const WishlistLoadingIndicator(message: 'A carregar itens...');
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
            _isPrivate ? 'Esta wishlist é privada' : 'Esta wishlist é pública',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return WishlistEmptyState(
      icon: Icons.add_shopping_cart_rounded,
      title: 'A sua wishlist está vazia',
      subtitle: 'Adicione o seu primeiro desejo!',
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
            'A carregar mais itens...',
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
      editLabel: 'Editar',
      deleteLabel: 'Eliminar',
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
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
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
                            final uri = Uri.tryParse(item.link!);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            } else {
                              _showSnackBar('Não foi possível abrir o link', isError: true);
                            }
                          },
                          icon: const Icon(Icons.launch, size: 16),
                          label: const Text('Ver'),
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
                        label: const Text('Editar'),
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
                      tooltip: 'Eliminar item',
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
        title: const Text('Eliminar item'),
        content: Text('Tens a certeza que queres eliminar "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteItem(item.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
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
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.error,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
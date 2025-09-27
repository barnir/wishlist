import '../widgets/app_snack.dart';
import 'package:flutter/material.dart';
import 'package:mywishstash/widgets/accessible_icon_button.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/services.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/widgets/loading_message.dart';
import 'package:mywishstash/widgets/animated/animated_primitives.dart';
// Legacy FirebaseDatabaseService removed in favor of typed repository
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/models/wishlist.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/wishlist_card_item.dart';
import '../widgets/ui_components.dart';
import '../constants/ui_constants.dart';
import 'wishlist_details_screen.dart';
import '../utils/page_transitions.dart';

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

  // Sorting & filtering state
  String _sortField = 'created_at';
  bool _sortDescending = true;
  bool? _isPrivateFilter; // null = all
  double? _minTotal;
  double? _maxTotal;

  void _openSortFilterSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final minController = TextEditingController(
              text: _minTotal?.toStringAsFixed(0) ?? '',
            );
            final maxController = TextEditingController(
              text: _maxTotal?.toStringAsFixed(0) ?? '',
            );
            // Substitui RadioListTile deprecated por SegmentedButton + ChoiceChips
            final sortSegments = <ButtonSegment<String>>[
              ButtonSegment(
                value: 'created_at|true',
                label: Text(l10n?.sortNewestFirst ?? 'Mais recentes'),
              ),
              ButtonSegment(
                value: 'created_at|false',
                label: Text(l10n?.sortOldestFirst ?? 'Mais antigas'),
              ),
              ButtonSegment(
                value: 'name|false',
                label: Text(l10n?.sortNameAsc ?? 'Nome A-Z'),
              ),
              ButtonSegment(
                value: 'name|true',
                label: Text(l10n?.sortNameDesc ?? 'Nome Z-A'),
              ),
              ButtonSegment(
                value: 'total_value|true',
                label: Text(l10n?.sortTotalDesc ?? 'Valor ↓'),
              ),
              ButtonSegment(
                value: 'total_value|false',
                label: Text(l10n?.sortTotalAsc ?? 'Valor ↑'),
              ),
            ];
            Widget sortSelector() => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<String>(
                segments: sortSegments,
                selected: <String>{'$_sortField|$_sortDescending'},
                showSelectedIcon: false,
                onSelectionChanged: (set) {
                  if (set.isEmpty) return;
                  final sel = set.first.split('|');
                  setModalState(() {
                    _sortField = sel[0];
                    _sortDescending = sel[1] == 'true';
                  });
                },
              ),
            );
            Widget privacyChips() {
              final entries = <(String, bool?)>[
                (l10n?.privacyAll ?? 'Todas', null),
                (l10n?.privacyPublic ?? 'Públicas', false),
                (l10n?.privacyPrivate ?? 'Privadas', true),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entries.map((e) {
                  final selected = _isPrivateFilter == e.$2;
                  return ChoiceChip(
                    label: Text(e.$1),
                    selected: selected,
                    onSelected: (_) =>
                        setModalState(() => _isPrivateFilter = e.$2),
                  );
                }).toList(),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.sortBy ?? 'Ordenar',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    sortSelector(),
                    const Divider(),
                    Text(
                      l10n?.privacyTitle ?? 'Privacidade',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    privacyChips(),
                    const Divider(),
                    Text(
                      l10n?.totalValueFilterTitle ??
                          'Filtro por valor total (€)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n?.minLabel ?? 'Mínimo',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: maxController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n?.maxLabel ?? 'Máximo',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          double? parse(String v) => v.trim().isEmpty
                              ? null
                              : double.tryParse(v.replaceAll(',', '.'));
                          setState(() {
                            _minTotal = parse(minController.text);
                            _maxTotal = parse(maxController.text);
                          });
                          Navigator.pop(ctx);
                          _loadInitialData();
                        },
                        child: Text(l10n?.applyFilters ?? 'Aplicar'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

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
        sortField: _sortField,
        descending: _sortDescending,
        isPrivateFilter: _isPrivateFilter,
      );
      if (!mounted) return;
      var newItems = page.items;
      // If we need total values (sorting or filtering) compute them client-side
      final needTotals =
          _sortField == 'total_value' || _minTotal != null || _maxTotal != null;
      if (needTotals) {
        newItems = await _computeTotals(newItems);
        newItems = newItems.where((w) {
          final v = w.totalValue ?? 0;
          if (_minTotal != null && v < _minTotal!) return false;
          if (_maxTotal != null && v > _maxTotal!) return false;
          return true;
        }).toList();
        if (_sortField == 'total_value') {
          newItems.sort(
            (a, b) => (a.totalValue ?? 0).compareTo(b.totalValue ?? 0),
          );
          if (_sortDescending) newItems = newItems.reversed.toList();
        }
      }
      setState(() {
        _wishlists.addAll(newItems);
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
        AppSnack.show(
          context,
          (AppLocalizations.of(context)?.errorLoadingWishlists(e.toString())) ??
              'Erro ao carregar wishlists: $e',
          type: SnackType.error,
        );
      }
    }
  }

  Future<List<Wishlist>> _computeTotals(List<Wishlist> batch) async {
    final firestore = FirebaseFirestore.instance;
    final List<Wishlist> enriched = [];
    for (final w in batch) {
      if (w.totalValue != null) {
        enriched.add(w);
        continue;
      }
      try {
        final snap = await firestore
            .collection('wish_items')
            .where('wishlist_id', isEqualTo: w.id)
            .get();
        double total = 0;
        for (final d in snap.docs) {
          final price = (d.data()['price'] as num?)?.toDouble() ?? 0;
          total += price;
        }
        enriched.add(w.copyWith(totalValue: total));
      } catch (_) {
        enriched.add(w);
      }
    }
    return enriched;
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
      title:
          AppLocalizations.of(context)?.noWishlistsYetTitle ??
          'Nenhuma wishlist por aqui',
      subtitle:
          AppLocalizations.of(context)?.noWishlistsYetSubtitle ??
          'Toque em "+" para criar a sua primeira!',
    );
  }

  // Widget para construir cada card da wishlist - Modernizado
  Widget _buildWishlistCard(BuildContext context, Wishlist wishlist) =>
      WishlistCardItem(
        wishlist: wishlist,
        onTap: () =>
            context.pushHero(WishlistDetailsScreen(wishlistId: wishlist.id)),
      );

  // _buildWishlistImage removido (lógica movida para WishlistCardItem)

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: UIConstants.paddingM,
      child: Center(
        child: LoadingMessage(
          messageKey: 'loadingMoreWishlists',
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final l10n = AppLocalizations.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)?.myWishlists ?? 'Minhas Wishlists',
          ),
        ),
        body: Center(
          child: Text(
            AppLocalizations.of(context)?.pleaseLoginToSeeWishlists ??
                'Por favor, faça login para ver suas wishlists.',
          ),
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
          title:
              AppLocalizations.of(context)?.myWishlists ?? 'Minhas Wishlists',
          showBackButton: false,
          actions: [
            AccessibleIconButton(
              icon: Icons.filter_list_rounded,
              semanticLabel: l10n?.filtersAndSortingTitle ?? 'Filtros',
              tooltip: l10n?.filtersAndSortingTitle ?? 'Filtros',
              onPressed: _openSortFilterSheet,
            ),
          ],
        ),
        body: ScaleFadeSwitcher(
          child: _isInitialLoading
              ? const Center(
                  key: ValueKey('wl-list-loading'),
                  child: LoadingMessage(messageKey: 'loadingWishlists'),
                )
              : _wishlists.isEmpty
              ? KeyedSubtree(
                  key: const ValueKey('wl-list-empty'),
                  child: _buildEmptyState(context),
                )
              : RefreshIndicator(
                  key: const ValueKey('wl-list-data'),
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: UIConstants.listPadding,
                    itemCount: _wishlists.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _wishlists.length) {
                        return _buildLoadingIndicator();
                      }
                      return FadeIn(
                        child: _buildWishlistCard(context, _wishlists[index]),
                      );
                    },
                  ),
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add_edit_wishlist').then((_) {
              // Refresh data when returning from add/edit
              _loadInitialData();
            });
          },
          tooltip:
              AppLocalizations.of(context)?.addNewWishlistTooltip ??
              'Adicionar nova wishlist',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

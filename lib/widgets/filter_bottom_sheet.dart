import 'package:flutter/material.dart';
import 'package:mywishstash/models/category.dart';
import 'package:mywishstash/services/category_usage_service.dart';
import 'package:mywishstash/models/sort_options.dart';
import 'package:mywishstash/services/haptic_service.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import '../services/filter_preferences_service.dart';
import '../constants/ui_constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final SortOptions sortOption;
  final Function(String? category, SortOptions sortOption) onFiltersChanged;
  final String? wishlistId;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    required this.sortOption,
    required this.onFiltersChanged,
    this.wishlistId,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  String? _selectedCategory;
  SortOptions _sortOption = SortOptions.nameAsc;
  // Preserve original values to support true "Cancel" semantics
  late final String? _originalCategory;
  late final SortOptions _originalSort;

  @override
  void initState() {
    super.initState();
  _selectedCategory = widget.selectedCategory;
  _sortOption = widget.sortOption;
  _originalCategory = widget.selectedCategory;
  _originalSort = widget.sortOption;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleClose() async {
    // Revert to original state (no external callback)
    setState(() {
      _selectedCategory = _originalCategory;
      _sortOption = _originalSort;
    });
    await _animationController.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _handleApply() async {
    HapticService.success();
    widget.onFiltersChanged(_selectedCategory, _sortOption);
    // persist selection (scoped if wishlistId provided)
    FilterPreferencesService().save(
      _selectedCategory,
      _sortOption,
      wishlistId: widget.wishlistId,
    );
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleReset() {
    HapticService.lightImpact();
    setState(() {
      _selectedCategory = null;
      _sortOption = SortOptions.nameAsc;
    });
    // Persist reset immediately
    FilterPreferencesService().save(
      _selectedCategory,
      _sortOption,
      wishlistId: widget.wishlistId,
    );
  }

  String _selectedSummary(AppLocalizations? l10n) {
    final cat = _selectedCategory ?? (l10n?.allLabel ?? 'Todas');
    String sortLabel;
    switch (_sortOption) {
      case SortOptions.nameAsc:
        sortLabel = l10n?.sortNameAsc ?? 'Nome (A-Z)';
        break;
      case SortOptions.nameDesc:
        sortLabel = l10n?.sortNameDesc ?? 'Nome (Z-A)';
        break;
      case SortOptions.priceAsc:
        sortLabel = l10n?.sortPriceAsc ?? 'Preço (Menor-Maior)';
        break;
      case SortOptions.priceDesc:
        sortLabel = l10n?.sortPriceDesc ?? 'Preço (Maior-Menor)';
        break;
    }
    return '${l10n?.filtersSummaryPrefix ?? 'Atual:'} $cat • $sortLabel';
  }

  @override
  Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;
  final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 300),
              child: Material(
                color: colorScheme.surface,
                elevation: 8,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(UIConstants.radiusL),
                    topRight: Radius.circular(UIConstants.radiusL),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: double.infinity,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: UIConstants.paddingM,
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune,
                              color: colorScheme.primary,
                              size: 24,
                            ),
                            Spacing.horizontalS,
                            Text(
                              l10n?.filtersAndSortingTitle ?? 'Filtros e Ordenação',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: _handleReset,
                              child: Text(l10n?.clear ?? 'Limpar'),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Current selection summary (helps user remember state)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _selectedSummary(l10n),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Content
                      Flexible(
                        child: SingleChildScrollView(
                          padding: UIConstants.paddingM,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Section
                              _buildSectionTitle(l10n?.categoryLabel ?? 'Categoria', Icons.category),
                              Spacing.s,
                              _buildCategorySelector(),

                              Spacing.l,

                              // Sort Section
                              _buildSectionTitle(l10n?.sortBy ?? 'Ordenar por', Icons.sort),
                              Spacing.s,
                              _buildSortSelector(),
                            ],
                          ),
                        ),
                      ),

                      // Action buttons
                      Container(
                        padding: UIConstants.paddingM,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(UIConstants.radiusM),
                            topRight: Radius.circular(UIConstants.radiusM),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _handleClose,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                                child: Text(l10n?.cancel ?? 'Cancelar'),
                              ),
                            ),
                            Spacing.horizontalM,
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleApply,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(0, 48),
                                ),
                                child: Text(l10n?.applyFilters ?? 'Aplicar Filtros'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        Spacing.horizontalXS,
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return FutureBuilder<List<String>>(
      future: CategoryUsageService().sortByUsage(Category.getAllCategories()),
      builder: (context, snapshot) {
        final categories = snapshot.data ?? Category.getAllCategories();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip(
              label: AppLocalizations.of(context)?.allLabel ?? 'Todas',
              isSelected: _selectedCategory == null,
              onTap: () {
                HapticService.selectionClick();
                setState(() { _selectedCategory = null; });
              },
            ),
            ...categories.map((category) => _buildCategoryChip(
              label: category,
              isSelected: _selectedCategory == category,
              onTap: () {
                HapticService.selectionClick();
                setState(() { _selectedCategory = category; });
              },
            )),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
  label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: TextStyle(
          color: isSelected 
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSortSelector() {
    return Column(
      children: SortOptions.values.map((option) => _buildSortOption(option)).toList(),
    );
  }

  Widget _buildSortOption(SortOptions option) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _sortOption == option;

    IconData getIconForSort(SortOptions sortOption) {
      switch (sortOption) {
        case SortOptions.nameAsc:
          return Icons.sort_by_alpha;
        case SortOptions.nameDesc:
          return Icons.sort_by_alpha;
        case SortOptions.priceAsc:
          return Icons.trending_up;
        case SortOptions.priceDesc:
          return Icons.trending_down;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: InkWell(
          onTap: () {
            HapticService.selectionClick();
            setState(() {
              _sortOption = option;
            });
          },
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
          child: Container(
            padding: UIConstants.paddingM,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                    ? colorScheme.primary 
                    : colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(UIConstants.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  getIconForSort(option),
                  color: isSelected 
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                Spacing.horizontalS,
                Expanded(
                  child: Text(
                    _localizedSortName(option, context),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected 
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _localizedSortName(SortOptions option, BuildContext context) {
  switch (option) {
    case SortOptions.priceAsc:
  return 'Preço (Menor-Maior)';
    case SortOptions.priceDesc:
  return 'Preço (Maior-Menor)';
    case SortOptions.nameAsc:
  return 'Nome (A-Z)';
    case SortOptions.nameDesc:
  return 'Nome (Z-A)';
  }
}

/// Show filter bottom sheet
Future<void> showFilterBottomSheet({
  required BuildContext context,
  String? selectedCategory,
  required SortOptions sortOption,
  required Function(String? category, SortOptions sortOption) onFiltersChanged,
  String? wishlistId,
}) {
  HapticService.lightImpact();
  
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => FilterBottomSheet(
        selectedCategory: selectedCategory,
        sortOption: sortOption,
        onFiltersChanged: onFiltersChanged,
        wishlistId: wishlistId,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      opaque: false,
      barrierColor: Colors.transparent,
    ),
  );
}
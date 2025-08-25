import 'package:flutter/material.dart';
import 'package:wishlist_app/models/category.dart';
import 'package:wishlist_app/models/sort_options.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import '../constants/ui_constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? selectedCategory;
  final SortOptions sortOption;
  final Function(String? category, SortOptions sortOption) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    this.selectedCategory,
    required this.sortOption,
    required this.onFiltersChanged,
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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _sortOption = widget.sortOption;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleApply() async {
    HapticService.success();
    widget.onFiltersChanged(_selectedCategory, _sortOption);
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value * 300),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(UIConstants.radiusL),
                    topRight: Radius.circular(UIConstants.radiusL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
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
                            'Filtros e Ordenação',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _handleReset,
                            child: const Text('Limpar'),
                          ),
                        ],
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
                            _buildSectionTitle('Categoria', Icons.category),
                            Spacing.s,
                            _buildCategorySelector(),
                            
                            Spacing.l,

                            // Sort Section
                            _buildSectionTitle('Ordenar por', Icons.sort),
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
                              child: const Text('Cancelar'),
                            ),
                          ),
                          Spacing.horizontalM,
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleApply,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 48),
                              ),
                              child: const Text('Aplicar Filtros'),
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
    final categories = Category.getAllCategories();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // All categories option
        _buildCategoryChip(
          label: 'Todas',
          isSelected: _selectedCategory == null,
          onTap: () {
            HapticService.selectionClick();
            setState(() {
              _selectedCategory = null;
            });
          },
        ),
        // Individual categories
        ...categories.map((category) => _buildCategoryChip(
          label: category,
          isSelected: _selectedCategory == category,
          onTap: () {
            HapticService.selectionClick();
            setState(() {
              _selectedCategory = category;
            });
          },
        )),
      ],
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
                    option.displayName,
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

/// Show filter bottom sheet
Future<void> showFilterBottomSheet({
  required BuildContext context,
  String? selectedCategory,
  required SortOptions sortOption,
  required Function(String? category, SortOptions sortOption) onFiltersChanged,
}) {
  HapticService.lightImpact();
  
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => FilterBottomSheet(
        selectedCategory: selectedCategory,
        sortOption: sortOption,
        onFiltersChanged: onFiltersChanged,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      opaque: false,
      barrierColor: Colors.transparent,
    ),
  );
}
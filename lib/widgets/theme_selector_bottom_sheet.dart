import 'package:flutter/material.dart';
import 'package:wishlist_app/services/theme_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';
import '../constants/ui_constants.dart';

class ThemeSelectorBottomSheet extends StatefulWidget {
  const ThemeSelectorBottomSheet({super.key});

  @override
  State<ThemeSelectorBottomSheet> createState() => _ThemeSelectorBottomSheetState();
}

class _ThemeSelectorBottomSheetState extends State<ThemeSelectorBottomSheet>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();

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

  void _selectTheme(ThemeMode mode) async {
    HapticService.selectionClick();
    await _themeService.setThemeMode(mode);
    
    // Small delay to let user see the selection
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      _handleClose();
    }
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
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(UIConstants.radiusL),
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
                            Icons.palette,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          Spacing.horizontalS,
                          Text(
                            'Tema da App',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _handleClose,
                            icon: const Icon(Icons.close),
                            tooltip: 'Fechar',
                          ),
                        ],
                      ),
                    ),

                    const Divider(height: 1),

                    // Theme options
                    Padding(
                      padding: UIConstants.paddingM,
                      child: Column(
                        children: [
                          _buildThemeOption(
                            ThemeMode.light,
                            'Tema Claro',
                            'Sempre usar o tema claro',
                          ),
                          Spacing.s,
                          _buildThemeOption(
                            ThemeMode.dark,
                            'Tema Escuro',
                            'Sempre usar o tema escuro',
                          ),
                          Spacing.s,
                          _buildThemeOption(
                            ThemeMode.system,
                            'Automático',
                            'Seguir as definições do sistema',
                          ),
                        ],
                      ),
                    ),

                    Spacing.m,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String title, String subtitle) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _themeService.themeMode == mode;

    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusM),
            border: Border.all(
              color: isSelected 
                  ? colorScheme.primary 
                  : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(UIConstants.radiusM),
            child: InkWell(
              onTap: () => _selectTheme(mode),
              borderRadius: BorderRadius.circular(UIConstants.radiusM),
              child: Padding(
                padding: UIConstants.paddingM,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(UIConstants.radiusS),
                      ),
                      child: Icon(
                        _themeService.getThemeModeIcon(mode),
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    Spacing.horizontalM,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              color: isSelected 
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall?.copyWith(
                              color: isSelected 
                                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      Spacing.horizontalS,
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Show theme selector bottom sheet
Future<void> showThemeSelectorBottomSheet(BuildContext context) {
  HapticService.lightImpact();
  
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => 
          const ThemeSelectorBottomSheet(),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      opaque: false,
      barrierColor: Colors.transparent,
    ),
  );
}
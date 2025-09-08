import 'package:flutter/material.dart';
import 'package:mywishstash/services/haptic_service.dart';
import '../constants/ui_constants.dart';

/// Widgets UI reutilizáveis para manter consistência na aplicação

class WishlistAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const WishlistAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
      ),
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 2, // Material 3 standard for scrolled content
      surfaceTintColor: theme.colorScheme.surfaceTint,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, size: 24), // Standardized icon size
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class WishlistCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? elevation;

  const WishlistCard({
    super.key,
    required this.child,
    this.margin = UIConstants.cardMargin,
    this.padding = UIConstants.paddingM,
    this.onTap,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Material 3 standard: reduced elevation, prefer surface tint
    final cardElevation = elevation ?? 1.0;
    
    return Card(
      margin: margin,
      elevation: cardElevation,
      color: backgroundColor,
      surfaceTintColor: theme.colorScheme.surfaceTint,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1), // Reduced shadow intensity
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Material 3 standard radius
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: padding!,
          child: child,
        ),
      ),
    );
  }
}

class WishlistButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  final IconData? icon;
  final double? width;
  final double height;

  const WishlistButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
    this.icon,
    this.width,
    this.height = 48.0, // Material 3 minimum touch target
  });

  void _handlePress() {
    if (onPressed != null) {
      HapticService.buttonPress();
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Material 3 button styling
    final buttonStyle = isPrimary
        ? ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            elevation: isLoading ? 0 : 1,
            shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Pill shape
            minimumSize: Size(width ?? 120, height),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            side: BorderSide(color: theme.colorScheme.outline, width: 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Pill shape
            minimumSize: Size(width ?? 120, height),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          );

    final buttonContent = _buildButtonContent(theme);

    final button = isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : _handlePress,
            style: buttonStyle,
            child: buttonContent,
          )
        : OutlinedButton(
            onPressed: isLoading ? null : _handlePress,
            style: buttonStyle,
            child: buttonContent,
          );

    return SizedBox(
      width: width,
      height: height,
      child: button,
    );
  }

  Widget _buildButtonContent(ThemeData theme) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20), // Standardized icon size
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}

class WishlistTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;

  const WishlistTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
        ),
        filled: true,
        contentPadding: UIConstants.paddingHorizontalM + UIConstants.paddingVerticalM,
      ),
    );
  }
}

class WishlistEmptyState extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onAction;

  const WishlistEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionText,
    this.onAction,
  });

  @override
  State<WishlistEmptyState> createState() => _WishlistEmptyStateState();
}

class _WishlistEmptyStateState extends State<WishlistEmptyState>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _textController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Material 3 standard animation durations
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeIn,
    ));

    _textSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOutCubic,
    ));

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeOut,
    ));

    // Start animations with delay
    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _textController.forward();
      }
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0), // More generous padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _iconFadeAnimation,
              child: ScaleTransition(
                scale: _iconScaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 64, // Material 3 standard icon size for empty states
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _textController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _textSlideAnimation.value),
                  child: FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (widget.actionText != null && widget.onAction != null) ...[
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _textFadeAnimation,
                    child: WishlistButton(
                      text: widget.actionText!,
                      onPressed: widget.onAction,
                      width: 200,
                      isPrimary: true,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}


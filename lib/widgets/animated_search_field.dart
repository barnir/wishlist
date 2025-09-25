import 'package:flutter/material.dart';
import '../constants/ui_constants.dart';

/// Enhanced search text field with smooth animations and optimized performance
/// Designed to reduce UI glitches during search interactions
class AnimatedSearchField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AnimatedSearchField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.isLoading = false,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<AnimatedSearchField> createState() => _AnimatedSearchFieldState();
}

class _AnimatedSearchFieldState extends State<AnimatedSearchField>
    with TickerProviderStateMixin {
  late AnimationController _focusController;
  late AnimationController _loadingController;
  late Animation<double> _focusAnimation;
  late Animation<double> _loadingAnimation;

  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Set up animations
    _focusAnimation = CurvedAnimation(
      parent: _focusController,
      curve: Curves.easeOutCubic,
    );

    _loadingAnimation = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeInOut,
    );

    // Listen to focus changes
    _focusNode.addListener(_onFocusChanged);

    // Start loading animation if needed
    if (widget.isLoading) {
      _loadingController.repeat();
    }
  }

  void _onFocusChanged() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  void didUpdateWidget(AnimatedSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle loading state changes
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _loadingController.repeat();
      } else {
        _loadingController.stop();
        _loadingController.reset();
      }
    }
  }

  @override
  void dispose() {
    _focusController.dispose();
    _loadingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: Listenable.merge([_focusAnimation, _loadingAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(UIConstants.radiusM),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(51),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            onChanged: widget.onChanged,
            onTap: widget.onTap,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint,
              prefixIcon: _buildPrefixIcon(theme),
              suffixIcon: _buildSuffixIcon(theme),
              filled: true,
              fillColor: _isFocused
                  ? theme.colorScheme.surface
                  : theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusM),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusM),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withAlpha(128),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(UIConstants.radiusM),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              // Smooth label animation
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: theme.textTheme.bodyMedium?.copyWith(
                color: _isFocused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildPrefixIcon(ThemeData theme) {
    if (widget.prefixIcon == null) return null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: IconTheme(
        data: IconThemeData(
          color: _isFocused
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
          size: 24,
        ),
        child: widget.prefixIcon!,
      ),
    );
  }

  Widget? _buildSuffixIcon(ThemeData theme) {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
            value: null, // Indeterminate
          ),
        ),
      );
    }

    if (widget.suffixIcon != null) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: IconTheme(
          data: IconThemeData(
            color: _isFocused
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          child: widget.suffixIcon!,
        ),
      );
    }

    return null;
  }
}

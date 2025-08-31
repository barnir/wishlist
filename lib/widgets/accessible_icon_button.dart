import 'package:flutter/material.dart';

/// A reusable icon button that enforces a minimum accessible tap target,
/// provides Semantics information, and optional tooltip.
///
/// Use this instead of a raw IconButton when adding small action icons so
/// screen readers and larger touch areas are supported consistently.
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Color? color;
  final double iconSize;
  final EdgeInsets padding;
  final String? analyticsEvent; // reserved for future instrumentation

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.tooltip,
    this.color,
    this.iconSize = 20,
    this.padding = const EdgeInsets.all(8),
    this.analyticsEvent,
  });

  @override
  Widget build(BuildContext context) {
    // Minimum recommended target ~44. We wrap IconButton to enforce it even if visual icon is smaller.
    final button = IconButton(
      icon: Icon(icon, size: iconSize, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      visualDensity: VisualDensity.compact,
    );

    return Semantics(
      // Mark as button role
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: button,
    );
  }
}

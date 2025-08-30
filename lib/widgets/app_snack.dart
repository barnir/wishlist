import 'package:flutter/material.dart';
import '../theme_extensions.dart';

enum SnackType { success, warning, error, info }

class AppSnack {
  static void show(BuildContext context, String message, {SnackType type = SnackType.info, String? actionLabel, VoidCallback? onAction}) {
    final colors = context.semanticColors;
    final scheme = Theme.of(context).colorScheme;
    Color bg;
    Color fg;
    switch (type) {
      case SnackType.success:
        bg = colors.successContainer; fg = colors.onSuccessContainer; break;
      case SnackType.warning:
        bg = colors.warningContainer; fg = colors.onWarningContainer; break;
      case SnackType.error:
        bg = colors.dangerContainer; fg = colors.onDangerContainer; break;
      case SnackType.info:
        bg = scheme.inverseSurface; fg = scheme.onInverseSurface; break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(label: actionLabel, onPressed: onAction, textColor: fg)
            : null,
      ),
    );
  }
}

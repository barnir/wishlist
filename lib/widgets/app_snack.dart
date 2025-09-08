import 'package:flutter/material.dart';
import '../theme_extensions.dart';

enum SnackType { success, warning, error, info }

class AppSnack {
  static void show(BuildContext context, String message, {SnackType type = SnackType.info, String? actionLabel, VoidCallback? onAction}) {
    final colors = context.semanticColors;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    
    Color bg;
    Color fg;
    IconData icon;
    
    switch (type) {
      case SnackType.success:
        bg = colors.successContainer; 
        fg = colors.onSuccessContainer; 
        icon = Icons.check_circle_outline;
        break;
      case SnackType.warning:
        bg = colors.warningContainer; 
        fg = colors.onWarningContainer; 
        icon = Icons.warning_amber_outlined;
        break;
      case SnackType.error:
        bg = colors.dangerContainer; 
        fg = colors.onDangerContainer; 
        icon = Icons.error_outline;
        break;
      case SnackType.info:
        bg = scheme.inverseSurface; 
        fg = scheme.onInverseSurface; 
        icon = Icons.info_outline;
        break;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: fg,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
        duration: Duration(milliseconds: type == SnackType.error ? 4000 : 3000),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onAction,
                textColor: fg,
                backgroundColor: fg.withValues(alpha: 0.1),
              )
            : null,
      ),
    );
  }
}

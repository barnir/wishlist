import 'package:flutter/material.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import '../theme_extensions.dart';

/// A small semantic status chip for enrichment / background states
/// Usage: StatusChip(status: StatusChipStatus.pending)
class StatusChip extends StatelessWidget {
  final StatusChipStatus status;
  final EdgeInsetsGeometry padding;
  final bool dense;

  const StatusChip({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final semantic = context.semanticColors;
    final theme = Theme.of(context);

    final data = _dataFor(status, l10n, semantic, theme);

    return Semantics(
      label: data.semanticLabel,
      container: true,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: data.bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: dense ? 12 : 14, color: data.fgColor),
            SizedBox(width: dense ? 4 : 6),
            Flexible(
              child: Text(
                data.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: data.fgColor,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
          ],
        ),
      ),
    );
  }

  _StatusChipVisual _dataFor(StatusChipStatus status, AppLocalizations? l10n, AppSemanticColors semantic, ThemeData theme) {
    switch (status) {
      case StatusChipStatus.pending:
        return _StatusChipVisual(
          label: l10n?.enrichmentPending ?? 'Loading details...',
            semanticLabel: l10n?.enrichmentPending ?? 'Loading details',
          icon: Icons.auto_fix_high,
          bgColor: semantic.warningContainer,
          fgColor: semantic.onWarningContainer,
        );
      case StatusChipStatus.rateLimited:
        return _StatusChipVisual(
          label: l10n?.enrichmentRateLimited ?? 'Rate limited',
          semanticLabel: l10n?.enrichmentRateLimited ?? 'Rate limited',
          icon: Icons.timer_off,
          bgColor: semantic.dangerContainer,
          fgColor: semantic.onDangerContainer,
        );
      case StatusChipStatus.failed:
        return _StatusChipVisual(
          label: l10n?.enrichmentFailed ?? 'Enrichment failed',
          semanticLabel: l10n?.enrichmentFailed ?? 'Enrichment failed',
          icon: Icons.error_outline,
          bgColor: semantic.dangerContainer,
          fgColor: semantic.onDangerContainer,
        );
      case StatusChipStatus.completed:
        return _StatusChipVisual(
          label: l10n?.enrichmentCompleted ?? 'Completed',
          semanticLabel: l10n?.enrichmentCompleted ?? 'Completed',
          icon: Icons.check_circle,
          bgColor: semantic.successContainer,
          fgColor: semantic.onSuccessContainer,
        );
    }
  }
}

enum StatusChipStatus { pending, rateLimited, failed, completed }

class _StatusChipVisual {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final Color bgColor;
  final Color fgColor;

  _StatusChipVisual({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.bgColor,
    required this.fgColor,
  });
}

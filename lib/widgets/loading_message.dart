import 'package:flutter/material.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

/// Simple reusable inline loading text widget.
/// Use for small placeholders instead of repeating literal/lookup each time.
class LoadingMessage extends StatelessWidget {
  final String? messageKey; // optional localization key name (without params)
  final TextStyle? style;
  final EdgeInsetsGeometry padding;
  final double indicatorSize;
  final Color? indicatorColor;

  const LoadingMessage({
    super.key,
    this.messageKey,
    this.style,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
    this.indicatorSize = 16,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = _resolveMessage(l10n);
    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: indicatorSize,
            height: indicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: indicatorColor != null
                  ? AlwaysStoppedAnimation<Color>(indicatorColor!)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: style ?? Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _resolveMessage(AppLocalizations? l10n) {
    if (l10n == null) return 'Loading...';
    if (messageKey == null) return l10n.loadingInline;
    switch (messageKey) {
      case 'loadingInline':
        return l10n.loadingInline;
      case 'loadingWishlists':
        return l10n.loadingWishlists;
      case 'loadingMoreWishlists':
        return l10n.loadingMoreWishlists;
      case 'loadingWishlist':
        return l10n.loadingWishlist;
      case 'loadingItems':
        return l10n.loadingItems;
      case 'loadingMoreItems':
        return l10n.loadingMoreItems;
      case 'loadingFavorites':
        return l10n.loadingFavorites;
      case 'loadingMoreFavorites':
        return l10n.loadingMoreFavorites;
      case 'loadingSuggestions':
        return l10n.loadingSuggestions;
      case 'loadingMore':
        return l10n.loadingMore;
      default:
        return l10n.loadingInline;
    }
  }
}

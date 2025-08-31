import 'package:flutter/material.dart';
import 'package:wishlist_app/models/wishlist.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import '../constants/ui_constants.dart';
import 'wishlist_total.dart';
import 'optimized_cloudinary_image.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';

class WishlistCardItem extends StatelessWidget {
  final Wishlist wishlist;
  final VoidCallback onTap;
  const WishlistCardItem({super.key, required this.wishlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = wishlist.name;
    final isPrivate = wishlist.isPrivate;
    final imageUrl = wishlist.imageUrl;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(UIConstants.radiusM)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
        child: Padding(
          padding: UIConstants.paddingM,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWishlistImage(context, imageUrl),
                Spacing.horizontalM,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.s,
                      _PrivacyChip(isPrivate: isPrivate, l10n: l10n),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(child: WishlistTotal(wishlistId: wishlist.id)),
                          Icon(Icons.arrow_forward, size: UIConstants.iconSizeS, color: theme.colorScheme.primary),
                        ],
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
  }

  Widget _buildWishlistImage(BuildContext context, String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusS),
        child: OptimizedCloudinaryImage(
          originalUrl: imageUrl,
          transformationType: ImageType.wishlistIcon,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          fallbackIcon: Icon(Icons.image_not_supported, size: 32, color: Theme.of(context).colorScheme.error),
        ),
      );
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(UIConstants.radiusS),
      ),
      child: Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _PrivacyChip extends StatelessWidget {
  final bool isPrivate;
  final AppLocalizations? l10n;
  const _PrivacyChip({required this.isPrivate, required this.l10n});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bg = isPrivate ? colorScheme.errorContainer : colorScheme.primaryContainer;
    final fg = isPrivate ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPrivate ? Icons.lock : Icons.public, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            isPrivate ? (l10n?.privateLabel ?? 'Privada') : (l10n?.publicLabel ?? 'Pública'),
            style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/services/language_service.dart';
import 'package:mywishstash/widgets/profile_widgets.dart';
import 'package:mywishstash/utils/performance_utils.dart';

/// Memoized language selector widget para evitar rebuilds desnecessários
class MemoizedLanguageTile extends StatelessWidget {
  final VoidCallback onTap;
  final LanguageService _languageService;
  
  const MemoizedLanguageTile({
    super.key,
    required this.onTap,
    required LanguageService languageService,
  }) : _languageService = languageService;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Use ListenableBuilder para rebuild apenas quando necessário
    return ListenableBuilder(
      listenable: _languageService,
      builder: (context, child) {
        return ProfileListTile(
          icon: Icons.language,
          title: l10n.language,
          subtitle: _languageService.currentLanguageDisplayName,
          onTap: onTap,
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}

/// Memoized stats card para evitar recálculos desnecessários
class MemoizedStatsCard extends StatelessWidget {
  final int wishlistsCount;
  final int itemsCount;
  final int favoritesCount;
  final int sharedCount;

  MemoizedStatsCard({
    required this.wishlistsCount,
    required this.itemsCount,
    required this.favoritesCount,
    required this.sharedCount,
  }) : super(key: ValueKey('$wishlistsCount-$itemsCount-$favoritesCount-$sharedCount'));

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _StatRow(
              icon: Icons.list_alt,
              label: 'Wishlists',
              value: wishlistsCount,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.card_giftcard,
              label: 'Items',
              value: itemsCount,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.favorite,
              label: 'Favoritos',
              value: favoritesCount,
            ),
            const SizedBox(height: 8),
            _StatRow(
              icon: Icons.share,
              label: 'Partilhados',
              value: sharedCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Performance-optimized image widget que usa memoização inteligente
class MemoizedOptimizedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  MemoizedOptimizedImage({
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: ValueKey('$imageUrl-${width?.toInt()}-${height?.toInt()}-$fit'));

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return errorWidget ?? 
        Container(
          width: width,
          height: height,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image_not_supported),
        );
    }

    return OptimizedBuilder(
      dependencies: [imageUrl, width, height, fit],
      builder: (context) => Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
            SizedBox(
              width: width,
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.error,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            );
        },
      ),
    );
  }
}

/// Memoized animated container para transições fluidas
class MemoizedAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;
  final double? width;
  final double? height;

  MemoizedAnimatedContainer({
    required this.child,
    this.duration = PerformanceUtils.normalAnimation,
    this.curve = PerformanceUtils.defaultCurve,
    this.color,
    this.padding,
    this.margin,
    this.decoration,
    this.width,
    this.height,
  }) : super(key: ValueKey('$color-$width-$height-${padding?.hashCode}-${margin?.hashCode}'));

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: decoration,
      color: color,
      child: child,
    );
  }
}


/// Const widgets para elementos estáticos
class ConstSectionDivider extends StatelessWidget {
  const ConstSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 16);
  }
}

/// Memoized privacy settings para evitar rebuilds
class MemoizedPrivacyTile extends StatelessWidget {
  final bool isPrivate;
  final VoidCallback onTap;

  MemoizedPrivacyTile({
    required this.isPrivate,
    required this.onTap,
  }) : super(key: ValueKey('privacy-$isPrivate'));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ProfileListTile(
      icon: Icons.privacy_tip,
      title: l10n.privacy,
      subtitle: isPrivate ? l10n.privateProfile : l10n.publicProfile,
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
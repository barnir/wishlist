import 'package:flutter/material.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/widgets/profile_widgets.dart';

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
    // Cache dos valores com ValueKey para evitar rebuild se não mudaram
    return ProfileStatsCard(
      wishlistsCount: wishlistsCount,
      itemsCount: itemsCount,
      favoritesCount: favoritesCount,
      sharedCount: sharedCount,
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
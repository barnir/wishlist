import 'package:flutter/material.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';
import 'package:wishlist_app/services/language_service.dart';
import 'package:wishlist_app/services/haptic_service.dart';

class LanguageSelectorBottomSheet extends StatefulWidget {
  const LanguageSelectorBottomSheet({super.key});

  @override
  State<LanguageSelectorBottomSheet> createState() => _LanguageSelectorBottomSheetState();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const LanguageSelectorBottomSheet(),
    );
  }
}

class _LanguageSelectorBottomSheetState extends State<LanguageSelectorBottomSheet> {
  final LanguageService _languageService = LanguageService();
  bool _isLoading = false;

  Future<void> _handleLanguageSelection(Locale? locale) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    HapticService.lightImpact();
    
    try {
      if (locale == null) {
        // Auto-detect selected
        await _languageService.enableAutoDetect();
      } else {
        // Specific language selected
        await _languageService.setLanguage(locale);
      }
      
      HapticService.success();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      HapticService.error();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar idioma: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: _isLoading ? null : onTap,
      leading: Icon(
        icon,
        color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: _isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isSelected 
              ? Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  l10n.languageSettings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    HapticService.lightImpact();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Language options
          AnimatedBuilder(
            animation: _languageService,
            builder: (context, child) {
              return Column(
                children: [
                  // Auto-detect option
                  _buildLanguageOption(
                    context: context,
                    title: l10n.automatic,
                    subtitle: l10n.systemLanguage,
                    isSelected: _languageService.isAutoDetect,
                    icon: Icons.auto_mode,
                    onTap: () => _handleLanguageSelection(null),
                  ),
                  
                  const Divider(),
                  
                  // Available languages
                  ..._languageService.availableLanguages.entries.map((entry) {
                    final locale = entry.key;
                    final displayName = entry.value;
                    final isSelected = !_languageService.isAutoDetect && 
                                     _languageService.isCurrentLocale(locale);
                    
                    return _buildLanguageOption(
                      context: context,
                      title: displayName,
                      subtitle: locale.languageCode == 'pt' ? 'Português de Portugal' : 'International',
                      isSelected: isSelected,
                      icon: locale.languageCode == 'pt' 
                          ? Icons.flag_outlined 
                          : Icons.language,
                      onTap: () => _handleLanguageSelection(locale),
                    );
                  }),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
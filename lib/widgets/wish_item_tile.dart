import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/widgets/accessible_icon_button.dart';
import '../theme_extensions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mywishstash/services/image_cache_service.dart';
import 'package:mywishstash/services/haptic_service.dart';
import '../models/wish_item.dart';
import '../models/category.dart';
import 'status_chip.dart';

class WishItemTile extends StatelessWidget {
  final WishItem item;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const WishItemTile({
    super.key,
    required this.item,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final category = categories.firstWhere(
      (c) => c.name == item.category,
      orElse: () => categories.last,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem maior e quadrada
              _buildProductImage(context, category),
              
              const SizedBox(width: 12),
              
              // Informação principal
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Preço destacado
                    if (item.price != null && item.price! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '€${item.price!.toStringAsFixed(2)}', // Consider localizing currency formatting if multi-currency support is needed
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 6),
                    
                    // Descrição
                    if (item.description != null && item.description!.isNotEmpty)
                      Text(
                        item.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    // Rating com estrelas
                    if (item.rating != null && item.rating! > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            ...List.generate(5, (index) {
                              final starValue = index + 1;
                              return Icon(
                                starValue <= item.rating!.round()
                                    ? Icons.star
                                    : starValue - 0.5 <= item.rating!
                                        ? Icons.star_half
                                        : Icons.star_border,
                                size: 14,
                                color: context.semanticColors.favorite,
                              );
                            }),
                            const SizedBox(width: 4),
                            Text(
                              item.rating!.toStringAsFixed(1),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: context.semanticColors.favorite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const Spacer(),
                    
                    // Bottom row: Category chip + Actions
                    Row(
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                category.icon,
                                size: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                category.name,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const Spacer(),
                        
                        // Quick actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Link button
                            if (item.link != null && item.link!.isNotEmpty)
                              AccessibleIconButton(
                                icon: Icons.open_in_new,
                                color: Theme.of(context).colorScheme.primary,
                                semanticLabel: AppLocalizations.of(context)?.openItemLink ?? 'Abrir link do item',
                                tooltip: AppLocalizations.of(context)?.openLink ?? 'Abrir link',
                                onPressed: () => _openLink(item.link!),
                              ),
                            
                            // Edit button
                            if (onEdit != null)
                              AccessibleIconButton(
                                icon: Icons.edit_outlined,
                                color: Theme.of(context).colorScheme.outline,
                                semanticLabel: AppLocalizations.of(context)?.editItem ?? 'Editar item',
                                tooltip: AppLocalizations.of(context)?.editItem ?? 'Editar',
                                onPressed: () {
                                  HapticService.lightImpact();
                                  onEdit!();
                                },
                              ),
                            
                            // Delete button
                            AccessibleIconButton(
                              icon: Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                              semanticLabel: '${AppLocalizations.of(context)?.delete ?? 'Eliminar'} item',
                              tooltip: AppLocalizations.of(context)?.delete ?? 'Eliminar',
                              onPressed: () {
                                HapticService.mediumImpact();
                                onDelete();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(BuildContext context, dynamic category) {
    final border = BorderRadius.circular(12);
    final chipStatus = _chipStatusFor(item.enrichStatus);
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: border,
            child: FutureBuilder<File?>(
              future: item.imageUrl != null && item.imageUrl!.isNotEmpty
                  ? ImageCacheService.getFile(item.imageUrl!)
                  : Future.value(null),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  );
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                  // Fallback to category icon
                  return Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      category.icon,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                } else {
                  // Display the actual image
                  return Image(
                    image: FileImage(snapshot.data!),
                    fit: BoxFit.cover,
                  );
                }
              },
            ),
          ),
          if (chipStatus != null)
            Positioned(
              top: 6,
              left: 6,
              child: StatusChip(
                status: chipStatus,
                dense: true,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              ),
            ),
        ],
      ),
    );
  }

  StatusChipStatus? _chipStatusFor(String? s) {
    final v = s?.toLowerCase().trim();
    switch (v) {
      case 'pending':
        return StatusChipStatus.pending;
      case 'failed':
        return StatusChipStatus.failed;
      case 'rate_limited':
        return StatusChipStatus.rateLimited;
      default:
        return null; // do not show for 'enriched' or unknown
    }
  }

  Future<void> _openLink(String url) async {
    try {
      HapticService.lightImpact();
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Handle error silently or show snackbar
    }
  }
}

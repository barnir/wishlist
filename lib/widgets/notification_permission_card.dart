import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:wishlist_app/services/notification_service.dart';
import 'package:wishlist_app/services/fcm_service.dart';
import 'package:wishlist_app/constants/ui_constants.dart';
import 'package:wishlist_app/generated/l10n/app_localizations.dart';

class NotificationPermissionCard extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final bool showOnlyIfNeeded;

  const NotificationPermissionCard({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.showOnlyIfNeeded = true,
  });

  @override
  State<NotificationPermissionCard> createState() => _NotificationPermissionCardState();
}

class _NotificationPermissionCardState extends State<NotificationPermissionCard> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  bool _isVisible = true;
  Map<String, dynamic>? _notificationStatus;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      final status = await _notificationService.getNotificationStatus(context);
      if (mounted) {
        setState(() {
          _notificationStatus = status;
          
          // Se showOnlyIfNeeded for true e as notificações já estão ativadas, esconder o card
          if (widget.showOnlyIfNeeded && status['enabled'] == true) {
            _isVisible = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking notification status: $e');
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _notificationService.requestPermission();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        switch (result) {
          case NotificationPermissionResult.granted:
            _showSuccessSnackBar();
            widget.onPermissionGranted?.call();
            if (widget.showOnlyIfNeeded) {
              setState(() {
                _isVisible = false;
              });
            }
            break;
            
          case NotificationPermissionResult.provisional:
            _showProvisionalSnackBar();
            widget.onPermissionGranted?.call();
            break;
            
          case NotificationPermissionResult.denied:
            _showDeniedSnackBar();
            widget.onPermissionDenied?.call();
            break;
            
          case NotificationPermissionResult.notDetermined:
            _showRetrySnackBar();
            break;
            
          case NotificationPermissionResult.error:
            _showErrorSnackBar();
            break;
        }
        
        // Atualizar status após pedido
        await _checkNotificationStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar();
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsSuccess),
  backgroundColor: context.semanticColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showProvisionalSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsProvisional),
  backgroundColor: context.semanticColors.warning,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsDenied),
  backgroundColor: context.semanticColors.danger,
        action: SnackBarAction(
          label: _notificationsSettingsButton,
          textColor: Colors.white,
          onPressed: _openSettings,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showRetrySnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsRetryMessage),
        action: SnackBarAction(
          label: _notificationsRetryButton,
          onPressed: _requestPermission,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsErrorRequest),
  backgroundColor: context.semanticColors.danger,
        action: SnackBarAction(
          label: _notificationsRetryButtonLabel,
          textColor: Colors.white,
          onPressed: _requestPermission,
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _openSettings() {
    // TODO: Implementar abertura das configurações do sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_notificationsSettingsPath),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _dismissCard() {
    setState(() {
      _isVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Não mostrar se não deve ser visível
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    // Não mostrar se ainda está carregando o status inicial
    if (_notificationStatus == null) {
      return const SizedBox.shrink();
    }

    final status = _notificationStatus!;
    final isEnabled = status['enabled'] as bool;
    final canRequest = status['canRequest'] as bool;
    final needsSettings = status['needsSettings'] as bool;
    final message = status['message'] as String;

    return Card(
      margin: UIConstants.cardMargin,
      elevation: UIConstants.elevationM,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      child: Container(
        padding: UIConstants.paddingM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do card
            Row(
              children: [
                Icon(
                  isEnabled ? Icons.notifications_active : Icons.notifications_off,
                  color: isEnabled ? context.semanticColors.success : context.semanticColors.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEnabled ? _notificationsActive : _notificationsDisabled,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEnabled)
                  IconButton(
                    onPressed: _dismissCard,
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
              ],
            ),
            
            if (!isEnabled) ...[
              const SizedBox(height: 16),
              
              // Descrição do benefício
              Text(
                _notificationsBenefitsTitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              
              // Lista de benefícios
              Column(
                children: [
                  _buildBenefitRow('💰', _notificationsBenefitPriceDrops),
                  _buildBenefitRow('🎁', _notificationsBenefitShares),
                  _buildBenefitRow('⭐', _notificationsBenefitFavorites),
                  _buildBenefitRow('💡', _notificationsBenefitGiftHints),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Botões de ação
              Row(
                children: [
                  if (canRequest) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _requestPermission,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.notifications_active, size: 20),
                        label: Text(_isLoading ? _notificationsRequestLoading : _notificationsActivateButton),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ] else if (needsSettings) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.settings, size: 20),
                        label: const Text('Ir para Configurações'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Métodos helper para strings localizadas com fallback
  String _getLocalizedString(String Function(AppLocalizations) getter, String fallback) {
    try {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        return getter(l10n);
      }
      return fallback;
    } catch (e) {
      return fallback;
    }
  }

  String get _notificationsActive => _getLocalizedString(
    (l10n) => l10n.notificationsActive,
    'Notificações Ativas',
  );

  String get _notificationsDisabled => _getLocalizedString(
    (l10n) => l10n.notificationsDisabled,
    'Notificações Desativadas',
  );

  String get _notificationsSuccess => _getLocalizedString(
    (l10n) => l10n.notificationsSuccess,
    '✅ Notificações ativadas com sucesso!',
  );

  String get _notificationsProvisional => _getLocalizedString(
    (l10n) => l10n.notificationsSilentSuccess,
    '🔔 Notificações silenciosas ativadas!',
  );

  String get _notificationsDenied => _getLocalizedString(
    (l10n) => l10n.notificationsDenied,
    '❌ Notificações negadas. Pode ativar nas configurações.',
  );

  String get _notificationsRequestLoading => _getLocalizedString(
    (l10n) => l10n.notificationsRequesting,
    'A solicitar...',
  );

  String get _notificationsActivateButton => _getLocalizedString(
    (l10n) => l10n.notificationsActivate,
    'Ativar Notificações',
  );

  String get _notificationsBenefitsTitle => _getLocalizedString(
    (l10n) => l10n.notificationsReceiveAlerts,
    'Receba alertas sobre:',
  );

  String get _notificationsBenefitPriceDrops => _getLocalizedString(
    (l10n) => l10n.notificationsBenefitPriceDrops,
    'Baixas de preço nos seus itens',
  );

  String get _notificationsBenefitShares => _getLocalizedString(
    (l10n) => l10n.notificationsBenefitShares,
    'Novas partilhas de listas',
  );

  String get _notificationsBenefitFavorites => _getLocalizedString(
    (l10n) => l10n.notificationsBenefitFavorites,
    'Novos favoritos',
  );

  String get _notificationsBenefitGiftHints => _getLocalizedString(
    (l10n) => l10n.notificationsBenefitGiftHints,
    'Dicas de presentes',
  );

  String get _notificationsSettingsPath => _getLocalizedString(
    (l10n) => l10n.notificationsSettingsInstructions,
    'Ir para: Configurações > Apps > WishlistApp > Notificações',
  );

  String get _notificationsRetryMessage => _getLocalizedString(
    (l10n) => l10n.notificationsNotDetermined,
    '⚠️ Permissão não determinada. Tentar novamente?',
  );

  String get _notificationsRetryButton => _getLocalizedString(
    (l10n) => l10n.notificationsTryAgain,
    'Tentar',
  );

  String get _notificationsErrorRequest => _getLocalizedString(
    (l10n) => l10n.notificationsError,
    '❌ Erro ao solicitar permissões de notificação',
  );

  String get _notificationsRetryButtonLabel => _getLocalizedString(
    (l10n) => l10n.notificationsTryAgain,
    'Tentar novamente',
  );

  String get _notificationsSettingsButton => _getLocalizedString(
    (l10n) => l10n.notificationsGoSettings,
    'Configurações',
  );

  Widget _buildBenefitRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

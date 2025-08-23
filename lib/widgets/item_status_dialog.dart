import 'package:flutter/material.dart';
import '../models/wish_item_status.dart';
import '../services/wish_item_status_service.dart';
import '../constants/ui_constants.dart';
import 'ui_components.dart';

class ItemStatusDialog extends StatefulWidget {
  final String wishItemId;
  final String itemName;
  final WishItemStatus? currentStatus;
  final bool isOwner;

  const ItemStatusDialog({
    super.key,
    required this.wishItemId,
    required this.itemName,
    this.currentStatus,
    this.isOwner = false,
  });

  @override
  State<ItemStatusDialog> createState() => _ItemStatusDialogState();
}

class _ItemStatusDialogState extends State<ItemStatusDialog> {
  final _statusService = WishItemStatusService();
  final _notesController = TextEditingController();
  
  ItemPurchaseStatus _selectedStatus = ItemPurchaseStatus.willBuy;
  bool _visibleToOwner = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.currentStatus != null) {
      _selectedStatus = widget.currentStatus!.status;
      _visibleToOwner = widget.currentStatus!.visibleToOwner;
      _notesController.text = widget.currentStatus!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOwner) {
      return _buildOwnerDialog();
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            color: Theme.of(context).colorScheme.primary,
            size: UIConstants.iconSizeM,
          ),
          Spacing.horizontalS,
          Expanded(
            child: Text(
              'Marcar presente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.itemName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Spacing.l,
            
            // Seleção do status
            Text(
              'O que queres fazer?',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacing.s,
            
            ...ItemPurchaseStatus.values.map((status) => 
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedStatus == status 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey.shade300,
                    width: _selectedStatus == status ? 2.0 : 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                  color: _selectedStatus == status 
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : null,
                ),
                child: ListTile(
                  leading: Icon(
                    _selectedStatus == status 
                      ? Icons.radio_button_checked 
                      : Icons.radio_button_unchecked,
                    color: _selectedStatus == status 
                      ? Theme.of(context).colorScheme.primary 
                      : null,
                  ),
                  title: Text(status.displayName),
                  subtitle: Text(_getStatusDescription(status)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  onTap: () {
                    setState(() {
                      _selectedStatus = status;
                    });
                  },
                ),
              ),
            ),
            
            Spacing.m,
            
            // Visibilidade para o dono (só se for "comprado")
            if (_selectedStatus == ItemPurchaseStatus.purchased) ...[
              Container(
                padding: UIConstants.paddingM,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(UIConstants.radiusM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          size: UIConstants.iconSizeS,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Spacing.horizontalXS,
                        Text(
                          'Visibilidade',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Spacing.xs,
                    CheckboxListTile(
                      title: Text('Mostrar ao dono da lista'),
                      subtitle: Text(
                        'O dono saberá que o item foi comprado, mas não por quem.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: _visibleToOwner,
                      onChanged: (value) {
                        setState(() {
                          _visibleToOwner = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              Spacing.m,
            ],
            
            // Notas privadas
            WishlistTextField(
              label: 'Notas privadas (opcional)',
              hint: 'Ex: Comprei na loja X, entrega em Y...',
              controller: _notesController,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.currentStatus != null)
          TextButton(
            onPressed: _isLoading ? null : _removeStatus,
            child: Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        WishlistButton(
          text: widget.currentStatus != null ? 'Atualizar' : 'Marcar',
          onPressed: _isLoading ? null : _saveStatus,
          isLoading: _isLoading,
          width: 100,
          height: 36,
        ),
      ],
    );
  }

  Widget _buildOwnerDialog() {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: UIConstants.iconSizeM,
          ),
          Spacing.horizontalS,
          Text('Esta é a tua wishlist'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: UIConstants.iconSizeXXL / 2,
            color: Theme.of(context).colorScheme.primary.withAlpha(
              (255 * UIConstants.opacityLight).round(),
            ),
          ),
          Spacing.m,
          Text(
            'Não podes marcar os teus próprios itens como presentes!',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          Spacing.s,
          Text(
            'Esta funcionalidade é para os teus amigos coordenarem presentes.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        WishlistButton(
          text: 'Entendi',
          onPressed: () => Navigator.of(context).pop(),
          width: 100,
          height: 36,
        ),
      ],
    );
  }

  String _getStatusDescription(ItemPurchaseStatus status) {
    switch (status) {
      case ItemPurchaseStatus.willBuy:
        return 'Reservar para comprar mais tarde';
      case ItemPurchaseStatus.purchased:
        return 'Já comprei este item';
    }
  }

  Future<void> _saveStatus() async {
    setState(() => _isLoading = true);
    
    try {
      await _statusService.setItemStatus(
        wishItemId: widget.wishItemId,
        status: _selectedStatus,
        visibleToOwner: _visibleToOwner,
        notes: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
      );
      
      if (mounted) {
        Navigator.of(context).pop(true); // true indica sucesso
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item marcado como "${_selectedStatus.shortDisplayName}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeStatus() async {
    setState(() => _isLoading = true);
    
    try {
      await _statusService.removeItemStatus(widget.wishItemId);
      
      if (mounted) {
        Navigator.of(context).pop(true); // true indica sucesso
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status removido'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
import 'package:flutter/material.dart';
import 'package:mywishstash/services/haptic_service.dart';
import '../constants/ui_constants.dart';

/// Custom swipe actions widget for list items
class SwipeActionWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? editLabel;
  final String? deleteLabel;
  final IconData editIcon;
  final IconData deleteIcon;
  final bool showEdit;
  final bool showDelete;
  final double actionWidth;

  const SwipeActionWidget({
    super.key,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.editLabel,
    this.deleteLabel,
    this.editIcon = Icons.edit,
    this.deleteIcon = Icons.delete,
    this.showEdit = true,
    this.showDelete = true,
    this.actionWidth = 80.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Build action buttons
    final actions = <Widget>[];
    
    if (showEdit && onEdit != null) {
      actions.add(
        SizedBox(
          width: actionWidth,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(UIConstants.radiusS),
                bottomLeft: Radius.circular(UIConstants.radiusS),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.swipe();
                  onEdit!();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      editIcon,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                    if (editLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        editLabel!,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (showDelete && onDelete != null) {
      actions.add(
        SizedBox(
          width: actionWidth,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.error,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(
                  showEdit ? 0 : UIConstants.radiusS,
                ),
                bottomRight: Radius.circular(
                  showEdit ? 0 : UIConstants.radiusS,
                ),
                topLeft: Radius.circular(
                  showEdit ? 0 : UIConstants.radiusS,
                ),
                bottomLeft: Radius.circular(
                  showEdit ? 0 : UIConstants.radiusS,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticService.delete();
                  onDelete!();
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      deleteIcon,
                      color: colorScheme.onError,
                      size: 24,
                    ),
                    if (deleteLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        deleteLabel!,
                        style: TextStyle(
                          color: colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // If no actions, return child as is
    if (actions.isEmpty) {
      return child;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Don't actually dismiss - we handle actions manually
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: actions,
        ),
      ),
      child: child,
    );
  }
}

/// Enhanced dismissible widget with custom actions
class EnhancedDismissible extends StatefulWidget {
  final Widget child;
  final List<SwipeAction> actions;
  final Duration animationDuration;
  final double actionWidth;
  final bool hapticFeedback;

  const EnhancedDismissible({
    super.key,
    required this.child,
    required this.actions,
    this.animationDuration = const Duration(milliseconds: 200),
    this.actionWidth = 80.0,
    this.hapticFeedback = true,
  });

  @override
  State<EnhancedDismissible> createState() => _EnhancedDismissibleState();
}

class _EnhancedDismissibleState extends State<EnhancedDismissible>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  // Animation for slide effects (currently unused but may be needed for future enhancements)
  // late Animation<double> _slideAnimation;
  double _dragExtent = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    // _slideAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.easeOut,
    // ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final delta = details.primaryDelta ?? 0.0;
    final maxDragExtent = widget.actions.length * widget.actionWidth;
    
    setState(() {
      _dragExtent = (_dragExtent - delta).clamp(0.0, maxDragExtent);
    });

    // Provide haptic feedback when reaching action thresholds
    if (widget.hapticFeedback) {
      final actionThreshold = widget.actionWidth * 0.7;
      final currentActionIndex = (_dragExtent / actionThreshold).floor();
      
      if (currentActionIndex > 0 && 
          _dragExtent % actionThreshold < 5 && 
          _dragExtent % actionThreshold > 0) {
        HapticService.lightImpact();
      }
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    
    setState(() {
      _isDragging = false;
    });

    final actionThreshold = widget.actionWidth * 0.7;
    final actionIndex = (_dragExtent / actionThreshold).floor();
    
    if (actionIndex > 0 && actionIndex <= widget.actions.length) {
      // Trigger action
      final action = widget.actions[actionIndex - 1];
      if (widget.hapticFeedback) {
        switch (action.type) {
          case SwipeActionType.destructive:
            HapticService.delete();
            break;
          case SwipeActionType.primary:
            HapticService.mediumImpact();
            break;
          case SwipeActionType.secondary:
            HapticService.lightImpact();
            break;
        }
      }
      action.onPressed();
    }

    // Animate back to closed position
    _animationController.reverse().then((_) {
      setState(() {
        _dragExtent = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        setState(() {
          _isDragging = true;
        });
      },
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Stack(
        children: [
          // Actions background
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: _dragExtent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: widget.actions.map((action) => _buildActionButton(action)).toList(),
            ),
          ),
          // Main content
          Transform.translate(
            offset: Offset(-_dragExtent, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(SwipeAction action) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color foregroundColor;

    switch (action.type) {
      case SwipeActionType.destructive:
        backgroundColor = colorScheme.error;
        foregroundColor = colorScheme.onError;
        break;
      case SwipeActionType.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case SwipeActionType.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        break;
    }

    return SizedBox(
      width: widget.actionWidth,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(UIConstants.radiusS),
        ),
        margin: const EdgeInsets.all(2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  action.icon,
                  color: foregroundColor,
                  size: 24,
                ),
                if (action.label != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    action.label!,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Swipe action configuration
class SwipeAction {
  final IconData icon;
  final String? label;
  final VoidCallback onPressed;
  final SwipeActionType type;

  const SwipeAction({
    required this.icon,
    required this.onPressed,
    this.label,
    this.type = SwipeActionType.secondary,
  });

  /// Factory for edit actions
  factory SwipeAction.edit({
    required VoidCallback onPressed,
    String? label,
  }) {
    return SwipeAction(
      icon: Icons.edit,
      onPressed: onPressed,
      label: label ?? 'Editar',
      type: SwipeActionType.primary,
    );
  }

  /// Factory for delete actions
  factory SwipeAction.delete({
    required VoidCallback onPressed,
  String? label = 'Eliminar',
  }) {
    return SwipeAction(
      icon: Icons.delete,
      onPressed: onPressed,
      label: label,
      type: SwipeActionType.destructive,
    );
  }
}

/// Types of swipe actions
enum SwipeActionType {
  primary,
  secondary,
  destructive,
}
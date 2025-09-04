import 'package:flutter/material.dart';
import 'package:mywishstash/utils/performance_utils.dart';
import 'package:mywishstash/generated/l10n/app_localizations.dart';

/// Estados de loading mais informativos e visualmente consistentes
enum LoadingType {
  initial,
  refresh,
  loadMore,
  upload,
  save,
  delete,
  processing,
}

/// Widget de loading contextual e informativo
class InformativeLoadingWidget extends StatefulWidget {
  final LoadingType type;
  final String? message;
  final String? subMessage;
  final double? progress; // Para progress bars (0.0 - 1.0)
  final VoidCallback? onCancel;
  final Duration animationDuration;
  final bool showProgress;
  final Color? color;

  const InformativeLoadingWidget({
    super.key,
    required this.type,
    this.message,
    this.subMessage,
    this.progress,
    this.onCancel,
    this.animationDuration = PerformanceUtils.normalAnimation,
    this.showProgress = false,
    this.color,
  });

  @override
  State<InformativeLoadingWidget> createState() => _InformativeLoadingWidgetState();
}

class _InformativeLoadingWidgetState extends State<InformativeLoadingWidget>
    with TickerProviderStateMixin, PerformanceOptimizedState {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PerformanceUtils.defaultCurve,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final primaryColor = widget.color ?? theme.colorScheme.primary;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator
            if (widget.showProgress && widget.progress != null)
              CircularProgressIndicator(
                value: widget.progress,
                color: primaryColor,
                strokeWidth: 3,
              )
            else
              CircularProgressIndicator(
                color: primaryColor,
                strokeWidth: 3,
              ),
            const SizedBox(height: 16),

            // Main message
            Text(
              widget.message ?? _getDefaultMessage(l10n),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            // Sub message
            if (widget.subMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.subMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Progress text
            if (widget.showProgress && widget.progress != null) ...[
              const SizedBox(height: 8),
              Text(
                '${(widget.progress! * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            // Cancel button
            if (widget.onCancel != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDefaultMessage(AppLocalizations? l10n) {
    switch (widget.type) {
      case LoadingType.initial:
        return 'Loading...';
      case LoadingType.refresh:
        return 'Refreshing...';
      case LoadingType.loadMore:
        return 'Loading more...';
      case LoadingType.upload:
        return 'Uploading...';
      case LoadingType.save:
        return 'Saving...';
      case LoadingType.delete:
        return 'Deleting...';
      case LoadingType.processing:
        return 'Processing...';
    }
  }
}

/// Loading overlay que pode ser mostrado sobre conteúdo existente
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final LoadingType type;
  final String? message;
  final double? progress;
  final Color? barrierColor;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.type = LoadingType.processing,
    this.message,
    this.progress,
    this.barrierColor,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: barrierColor ?? 
                Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: InformativeLoadingWidget(
                      type: type,
                      message: message,
                      progress: progress,
                      onCancel: onCancel,
                      showProgress: progress != null,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Builder que gerencia estados de loading automaticamente
class LoadingStateBuilder<T> extends StatelessWidget {
  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext, T) builder;
  final Widget Function(BuildContext, Object?)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
  final Widget Function(BuildContext)? emptyBuilder;
  final LoadingType loadingType;
  final String? loadingMessage;

  const LoadingStateBuilder({
    super.key,
    required this.snapshot,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
    this.loadingType = LoadingType.initial,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingBuilder?.call(context) ??
        Center(
          child: InformativeLoadingWidget(
            type: loadingType,
            message: loadingMessage,
          ),
        );
    }

    // Error state
    if (snapshot.hasError) {
      return errorBuilder?.call(context, snapshot.error) ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
    }

    // Empty state
    if (!snapshot.hasData || 
        (snapshot.data is List && (snapshot.data as List).isEmpty)) {
      return emptyBuilder?.call(context) ??
        const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48),
              SizedBox(height: 16),
              Text('No data available'),
            ],
          ),
        );
    }

    // Success state
    return builder(context, snapshot.data as T);
  }
}

/// Widget de loading inline para listas
class InlineLoadingIndicator extends StatelessWidget {
  final LoadingType type;
  final String? message;
  final bool showMessage;
  final EdgeInsetsGeometry? padding;

  const InlineLoadingIndicator({
    super.key,
    this.type = LoadingType.loadMore,
    this.message,
    this.showMessage = true,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          if (showMessage) ...[
            const SizedBox(width: 12),
            Text(
              message ?? _getDefaultMessage(l10n),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getDefaultMessage(AppLocalizations? l10n) {
    switch (type) {
      case LoadingType.loadMore:
        return 'Loading more...';
      case LoadingType.refresh:
        return 'Refreshing...';
      default:
        return 'Loading...';
    }
  }
}

/// Mixin para gerenciar estados de loading em widgets
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  LoadingType _loadingType = LoadingType.initial;
  String? _loadingMessage;
  double? _loadingProgress;

  bool get isLoading => _isLoading;
  LoadingType get loadingType => _loadingType;
  String? get loadingMessage => _loadingMessage;
  double? get loadingProgress => _loadingProgress;

  void setLoading(
    bool loading, {
    LoadingType type = LoadingType.processing,
    String? message,
    double? progress,
  }) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _loadingType = type;
        _loadingMessage = message;
        _loadingProgress = progress;
      });
    }
  }

  void updateProgress(double progress, {String? message}) {
    if (mounted) {
      setState(() {
        _loadingProgress = progress;
        if (message != null) {
          _loadingMessage = message;
        }
      });
    }
  }

  Widget buildWithLoadingState(Widget child) {
    return LoadingOverlay(
      isLoading: _isLoading,
      type: _loadingType,
      message: _loadingMessage,
      progress: _loadingProgress,
      child: child,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import '../generated/l10n/app_localizations.dart';

/// Error boundary widget que captura erros de widgets filhos e mostra UI de fallback
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String context;
  final Widget? fallback;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.context,
    this.fallback,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    
    // Setup error handler
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log error
      MonitoringService.logErrorStatic(
        'ErrorBoundary_${widget.context}',
        details.exception,
        stackTrace: details.stack,
        context: widget.context,
      );
      
      // Call custom error handler if provided
      widget.onError?.call(details);
      
      // Update UI state
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = details.exception.toString();
        });
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.fallback ?? _DefaultErrorWidget(
        context: widget.context,
        errorMessage: _errorMessage,
        onRetry: () {
          setState(() {
            _hasError = false;
            _errorMessage = null;
          });
        },
      );
    }

    return widget.child;
  }
}

/// Widget de erro padrão mostrado quando há falha
class _DefaultErrorWidget extends StatelessWidget {
  final String context;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const _DefaultErrorWidget({
    required this.context,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.genericError('${this.context} error') ?? 'Error in ${this.context}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Mixin para widgets que precisam de error handling
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  void safeExecute(VoidCallback operation, {String? context}) {
    try {
      operation();
    } catch (e, stackTrace) {
      MonitoringService.logErrorStatic(
        context ?? T.toString(),
        e,
        stackTrace: stackTrace,
      );
      
      // Show user-friendly error
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(this.context)?.genericError(e.toString()) ?? 
              'Error: $e',
            ),
            backgroundColor: Theme.of(this.context).colorScheme.error,
          ),
        );
      }
    }
  }
  
  Future<TResult?> safeExecuteAsync<TResult>(
    Future<TResult> Function() operation, {
    String? context,
    TResult? fallbackValue,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      MonitoringService.logErrorStatic(
        context ?? T.toString(),
        e,
        stackTrace: stackTrace,
      );
      
      // Show user-friendly error
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(this.context)?.genericError(e.toString()) ?? 
              'Error: $e',
            ),
            backgroundColor: Theme.of(this.context).colorScheme.error,
          ),
        );
      }
      
      return fallbackValue;
    }
  }
}

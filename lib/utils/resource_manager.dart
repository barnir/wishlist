import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mywishstash/services/monitoring_service.dart';

/// Gerenciador de recursos que garante limpeza adequada
class ResourceManager {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  final List<AnimationController> _animationControllers = [];
  final List<VoidCallback> _customDisposers = [];
  bool _disposed = false;

  /// Adiciona uma subscription que será cancelada no dispose
  void addSubscription(StreamSubscription subscription) {
    if (_disposed) {
      subscription.cancel();
      return;
    }
    _subscriptions.add(subscription);
  }

  /// Adiciona um timer que será cancelado no dispose
  void addTimer(Timer timer) {
    if (_disposed) {
      timer.cancel();
      return;
    }
    _timers.add(timer);
  }

  /// Adiciona um AnimationController que será disposed
  void addAnimationController(AnimationController controller) {
    if (_disposed) {
      controller.dispose();
      return;
    }
    _animationControllers.add(controller);
  }

  /// Adiciona um callback customizado para dispose
  void addCustomDisposer(VoidCallback disposer) {
    if (_disposed) {
      disposer();
      return;
    }
    _customDisposers.add(disposer);
  }

  /// Limpa todos os recursos
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    // Cancel subscriptions
    for (final subscription in _subscriptions) {
      try {
        subscription.cancel();
      } catch (e) {
        MonitoringService.logErrorStatic('ResourceManager', e,
            context: 'subscription_cancel');
      }
    }

    // Cancel timers
    for (final timer in _timers) {
      try {
        timer.cancel();
      } catch (e) {
        MonitoringService.logErrorStatic('ResourceManager', e,
            context: 'timer_cancel');
      }
    }

    // Dispose animation controllers
    for (final controller in _animationControllers) {
      try {
        controller.dispose();
      } catch (e) {
        MonitoringService.logErrorStatic('ResourceManager', e,
            context: 'animation_dispose');
      }
    }

    // Execute custom disposers
    for (final disposer in _customDisposers) {
      try {
        disposer();
      } catch (e) {
        MonitoringService.logErrorStatic('ResourceManager', e,
            context: 'custom_dispose');
      }
    }

    // Clear all lists
    _subscriptions.clear();
    _timers.clear();
    _animationControllers.clear();
    _customDisposers.clear();
  }

  /// Verifica se foi disposed
  bool get isDisposed => _disposed;
}

/// Mixin para widgets que precisam gerenciar recursos
mixin ResourceManagerMixin<T extends StatefulWidget> on State<T> {
  late final ResourceManager _resourceManager;

  @override
  void initState() {
    super.initState();
    _resourceManager = ResourceManager();
  }

  @override
  void dispose() {
    _resourceManager.dispose();
    super.dispose();
  }

  /// Acesso ao resource manager
  ResourceManager get resources => _resourceManager;
}

/// Mixin alternativo para classes que não estendem State
mixin ResourceManagedMixin {
  late final ResourceManager _resourceManager = ResourceManager();

  /// Acesso ao resource manager
  ResourceManager get resources => _resourceManager;

  /// Deve ser chamado manualmente para limpeza
  void disposeResources() {
    _resourceManager.dispose();
  }
}

/// Widget que automaticamente gerencia recursos de filhos
class ManagedResourceWidget extends StatefulWidget {
  final Widget child;
  final List<StreamSubscription>? subscriptions;
  final List<Timer>? timers;
  final List<AnimationController>? controllers;
  final List<VoidCallback>? customDisposers;

  const ManagedResourceWidget({
    super.key,
    required this.child,
    this.subscriptions,
    this.timers,
    this.controllers,
    this.customDisposers,
  });

  @override
  State<ManagedResourceWidget> createState() => _ManagedResourceWidgetState();
}

class _ManagedResourceWidgetState extends State<ManagedResourceWidget>
    with ResourceManagerMixin {
  @override
  void initState() {
    super.initState();

    // Add provided resources to manager
    widget.subscriptions?.forEach(resources.addSubscription);
    widget.timers?.forEach(resources.addTimer);
    widget.controllers?.forEach(resources.addAnimationController);
    widget.customDisposers?.forEach(resources.addCustomDisposer);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Debouncer melhorado com resource management
class ManagedDebouncer {
  Timer? _timer;
  final Duration duration;
  final ResourceManager? _resourceManager;

  ManagedDebouncer({
    required this.duration,
    ResourceManager? resourceManager,
  }) : _resourceManager = resourceManager;

  void call(VoidCallback callback) {
    _timer?.cancel();
    _timer = Timer(duration, callback);
    
    // Add to resource manager if available
    if (_timer != null) {
      _resourceManager?.addTimer(_timer!);
    }
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

/// Stream subscription helper que se auto-gerencia
extension StreamSubscriptionExtension<T> on Stream<T> {
  StreamSubscription<T> listenManaged(
    void Function(T) onData, {
    ResourceManager? resourceManager,
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
    
    resourceManager?.addSubscription(subscription);
    return subscription;
  }
}

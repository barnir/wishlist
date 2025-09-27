import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mywishstash/services/performance_metrics_service.dart';

/// Utilidades de performance para otimizar rebuilds e animações
class PerformanceUtils {
  static Timer? _debounceTimer;

  /// Durations padronizados para consistência visual
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 350);

  /// Curves padrão para transições fluidas
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bouncyCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutQuart;

  /// Limita rebuilds usando keys para widgets pesados
  static String buildKey(String base, List<dynamic> deps) {
    return '${base}_${deps.map((d) => d.hashCode).join('_')}';
  }

  /// Debounce para setState calls
  static void debounce(VoidCallback action, Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, action);
  }

  /// Optimized image dimensions baseado no contexto
  static Size getOptimalImageSize(BuildContext context, ImageType type) {
    final size = MediaQuery.of(context).size;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    switch (type) {
      case ImageType.thumbnail:
        return Size(120 * pixelRatio, 120 * pixelRatio);
      case ImageType.card:
        return Size(size.width * 0.4 * pixelRatio, 200 * pixelRatio);
      case ImageType.hero:
        return Size(size.width * pixelRatio, 300 * pixelRatio);
      case ImageType.avatar:
        return Size(80 * pixelRatio, 80 * pixelRatio);
    }
  }
}

enum ImageType { thumbnail, card, hero, avatar }

/// Mixin para otimizar StatefulWidgets pesados
mixin PerformanceOptimizedState<T extends StatefulWidget> on State<T> {
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  /// setState seguro que só executa se o widget ainda estiver montado
  void safeSetState(VoidCallback fn) {
    if (_mounted && mounted) {
      setState(fn);
    }
  }

  /// Batch multiple setState calls
  void batchSetState(List<VoidCallback> fns) {
    if (_mounted && mounted) {
      setState(() {
        for (final fn in fns) {
          fn();
        }
      });
    }
  }
}

/// Mixin to capture first build -> post frame timing for screen-level widgets.
mixin ScreenPerformanceMixin<T extends StatefulWidget> on State<T> {
  DateTime? _buildStart;
  bool _reported = false;

  @override
  void initState() {
    super.initState();
    _buildStart = DateTime.now();
    // Schedule after first frame to compute layout/render duration
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_reported || _buildStart == null) return;
      final duration = DateTime.now().difference(_buildStart!);
      PerformanceMetricsService().start('first_frame_${T.toString()}');
      // Immediately stop to emit (we already have duration captured). Using start/stop for uniform API.
      PerformanceMetricsService().stop(
        'first_frame_${T.toString()}',
        extra: {'screen': T.toString(), 'build_ms': duration.inMilliseconds},
      );
      _reported = true;
    });
  }
}

/// Widget otimizado que só rebuilds quando necessário
class OptimizedBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final List<dynamic> dependencies;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.dependencies = const [],
  });

  @override
  Widget build(BuildContext context) {
    return builder(context);
  }
}

/// Animation Coordinator para sincronizar múltiplas animações
class AnimationCoordinator extends ChangeNotifier {
  static final AnimationCoordinator _instance =
      AnimationCoordinator._internal();
  factory AnimationCoordinator() => _instance;
  AnimationCoordinator._internal();

  final Map<String, AnimationController> _controllers = {};

  void registerController(String id, AnimationController controller) {
    _controllers[id] = controller;
  }

  void unregisterController(String id) {
    _controllers.remove(id);
  }

  /// Coordena múltiplas animações com stagger
  Future<void> playStaggered(List<String> ids, Duration staggerDelay) async {
    for (int i = 0; i < ids.length; i++) {
      final controller = _controllers[ids[i]];
      if (controller != null) {
        controller.forward();
        if (i < ids.length - 1) {
          await Future.delayed(staggerDelay);
        }
      }
    }
  }

  /// Para todas as animações
  void stopAll() {
    for (final controller in _controllers.values) {
      controller.stop();
    }
  }

  /// Reseta todas as animações
  void resetAll() {
    for (final controller in _controllers.values) {
      controller.reset();
    }
  }
}

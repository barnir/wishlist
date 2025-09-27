import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mywishstash/services/analytics/analytics_service.dart';
import 'package:mywishstash/services/monitoring_service.dart';

/// Lightweight high-level performance metrics service.
/// Responsibilities:
///  - Start/stop named timers (supports nested distinct names)
///  - measureFuture helper wrapping async operations
///  - Broadcast stream of completed metrics for in-app debugging / overlays
///  - Optional forwarding to Analytics (disabled by default, enable via [enableAnalyticsForwarding])
class PerformanceMetricsService {
  static final PerformanceMetricsService _instance =
      PerformanceMetricsService._internal();
  factory PerformanceMetricsService() => _instance;
  PerformanceMetricsService._internal();

  final Map<String, _TimerEntry> _active = {};
  final StreamController<PerformanceSample> _controller =
      StreamController<PerformanceSample>.broadcast();

  bool enableAnalyticsForwarding = false; // can be toggled at runtime

  Stream<PerformanceSample> get stream => _controller.stream;

  /// Starts a named timer. If the name already exists it will be overwritten.
  void start(String name, {Map<String, Object?>? metadata}) {
    _active[name] = _TimerEntry(DateTime.now(), metadata ?? const {});
  }

  /// Stops a named timer and emits a [PerformanceSample]. Returns null if not started.
  PerformanceSample? stop(String name, {Map<String, Object?>? extra}) {
    final entry = _active.remove(name);
    if (entry == null) return null;
    final end = DateTime.now();
    final duration = end.difference(entry.startedAt);
    final sample = PerformanceSample(
      name: name,
      startedAt: entry.startedAt,
      endedAt: end,
      duration: duration,
      metadata: {...entry.metadata, if (extra != null) ...extra},
    );
    _emit(sample);
    return sample;
  }

  /// Measures an async function, automatically starting & stopping.
  Future<T> measureFuture<T>(
    String name,
    Future<T> Function() action, {
    Map<String, Object?>? metadata,
    Map<String, Object?> Function(T result)? resultMetadata,
  }) async {
    start(name, metadata: metadata);
    try {
      final result = await action();
      stop(name, extra: resultMetadata?.call(result));
      return result;
    } catch (e, st) {
      stop(name, extra: {'error': e.toString()});
      MonitoringService.logErrorStatic(
        'perf_measure_fail',
        e,
        stackTrace: st,
        context: name,
      );
      rethrow;
    }
  }

  void _emit(PerformanceSample sample) {
    if (!_controller.isClosed) {
      _controller.add(sample);
    }
    if (kDebugMode) {
      debugPrint(
        '[PERF] ${sample.name} => ${sample.duration.inMilliseconds}ms',
      );
    }
    if (enableAnalyticsForwarding) {
      // Keep analytics events lightweight; avoid large metadata payloads
      AnalyticsService().log(
        'perf_${sample.name}',
        properties: {
          'duration_ms': sample.duration.inMilliseconds,
          if (sample.metadata.isNotEmpty)
            'meta_keys': sample.metadata.keys.take(6).join(','),
        },
      );
    }
  }

  /// Dispose the stream controller (not usually needed - singleton lives app-wide).
  void dispose() {
    _controller.close();
  }
}

class PerformanceSample {
  final String name;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final Map<String, Object?> metadata;

  PerformanceSample({
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.metadata,
  });
}

class _TimerEntry {
  final DateTime startedAt;
  final Map<String, Object?> metadata;
  _TimerEntry(this.startedAt, this.metadata);
}

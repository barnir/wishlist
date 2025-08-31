import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wishlist_app/services/auth_service.dart';
// Legacy FirebaseDatabaseService removed; analytics events can be forwarded to a future analytics provider

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();


  // TODO: Inject analytics provider (e.g., Firebase Analytics) instead of direct DB writes
  final Map<String, DateTime> _operationStartTimes = {};
  final List<PerformanceMetric> _metrics = [];
  final List<ErrorLog> _errorLogs = [];
  final List<UserInteraction> _userInteractions = [];

  // Performance tracking
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
  }

  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      final metric = PerformanceMetric(
        operation: operationName,
        duration: duration,
        timestamp: DateTime.now(),
        metadata: metadata ?? {},
      );
      _metrics.add(metric);
      _operationStartTimes.remove(operationName);
      
      // Log to console in debug mode
      if (kDebugMode) {
        developer.log(
          'Performance: $operationName took ${duration.inMilliseconds}ms',
          name: 'MonitoringService',
        );
      }
    }
  }

  // Error tracking
  void logError(
    String error,
    StackTrace? stackTrace, {
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final errorLog = ErrorLog(
      error: error,
      stackTrace: stackTrace?.toString(),
      operation: operation,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    _errorLogs.add(errorLog);
    
    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        'Error: $error',
        name: 'MonitoringService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // Error tracking with context (from merged ErrorService)
  void logErrorWithContext(
    String error,
    StackTrace? stackTrace, {
    String? context,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final combinedMetadata = <String, dynamic>{
      if (context != null) 'context': context,
      ...?metadata,
    };
    
    logError(error, stackTrace, operation: operation, metadata: combinedMetadata);
  }

  // Static method for easy access (from merged ErrorService)
  static void logErrorStatic(
    String message,
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? operation,
  }) {
    MonitoringService()._logErrorWithContext(message, error, stackTrace: stackTrace, context: context, operation: operation);
  }

  // Static info logging method
  static void logInfoStatic(
    String context,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    MonitoringService().logInfo(message, context: context, metadata: metadata);
  }

  // Static warning logging method
  static void logWarningStatic(
    String context,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    MonitoringService().logWarning(message, context: context, metadata: metadata);
  }

  void _logErrorWithContext(
    String message,
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? operation,
  }) {
    final errorMessage = '$message: $error';
    final combinedMetadata = <String, dynamic>{
      if (context != null) 'context': context,
      'error_object': error.toString(),
    };
    
    logError(errorMessage, stackTrace, operation: operation, metadata: combinedMetadata);
  }

  // Info logging method
  void logInfo(
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: context ?? 'MonitoringService',
      );
    }
  }

  // Warning logging method
  void logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    if (kDebugMode) {
      developer.log(
        'WARNING: $message',
        name: context ?? 'MonitoringService',
        level: 900, // Warning level
      );
    }
  }

  // User interaction tracking
  void logUserInteraction(
    String action,
    String screen, {
    Map<String, dynamic>? metadata,
  }) {
    final interaction = UserInteraction(
      action: action,
      screen: screen,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );
    _userInteractions.add(interaction);
    
    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        'User Interaction: $action on $screen',
        name: 'MonitoringService',
      );
    }
  }

  // Analytics tracking
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
  }) async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId != null) {
        // Placeholder for analytics integration
        if (kDebugMode) {
          developer.log('Analytics event: $eventName', name: 'MonitoringService',
              error: null, stackTrace: null, level: 0);
        }
      }
    } catch (e) {
      logError('Failed to track event: $eventName', null, operation: 'trackEvent');
    }
  }

  // --- Image specific helpers ---
  static void logImageUploadSuccess(String type, {int? bytes, String? id}) {
    logInfoStatic('ImageUpload', 'success', metadata: {
      'type': type,
      if (bytes != null) 'bytes': bytes,
      if (id != null) 'id': id,
    });
    MonitoringService().trackEvent('image_upload_success', properties: {
      'type': type,
      if (bytes != null) 'bytes': bytes,
    });
  }

  static void logImageUploadFail(String type, Object error, {String? id}) {
    logErrorStatic('image_upload_fail', error, context: 'ImageUpload', operation: type);
    MonitoringService().trackEvent('image_upload_fail', properties: {
      'type': type,
      'error': error.toString(),
    });
  }

  static void logImageRenderError(String url, Object error) {
    logWarningStatic('ImageRender', 'render_error', metadata: {
      'url': url,
      'error': error.toString(),
    });
    MonitoringService().trackEvent('image_render_error', properties: {
      'url_hash': url.hashCode,
    });
  }

  // Get performance metrics
  List<PerformanceMetric> getPerformanceMetrics() {
    return List.from(_metrics);
  }

  // Get error logs
  List<ErrorLog> getErrorLogs() {
    return List.from(_errorLogs);
  }

  // Get user interactions
  List<UserInteraction> getUserInteractions() {
    return List.from(_userInteractions);
  }

  // Clear old data
  void clearOldData() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
    _errorLogs.removeWhere((error) => error.timestamp.isBefore(cutoff));
    _userInteractions.removeWhere((interaction) => interaction.timestamp.isBefore(cutoff));
  }

  // Export data for debugging
  Map<String, dynamic> exportData() {
    return {
      'performance_metrics': _metrics.map((m) => m.toJson()).toList(),
      'error_logs': _errorLogs.map((e) => e.toJson()).toList(),
      'user_interactions': _userInteractions.map((u) => u.toJson()).toList(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Save data to local storage
  Future<void> saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = exportData();
      await prefs.setString('monitoring_data', data.toString());
    } catch (e) {
      logError('Failed to save monitoring data', null, operation: 'saveToLocalStorage');
    }
  }

  // Load data from local storage
  Future<void> loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('monitoring_data');
      if (dataString != null) {
        // Parse and load data (simplified for now)
        developer.log('Loaded monitoring data from local storage', name: 'MonitoringService');
      }
    } catch (e) {
      logError('Failed to load monitoring data', null, operation: 'loadFromLocalStorage');
    }
  }
}

class PerformanceMetric {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class ErrorLog {
  final String error;
  final String? stackTrace;
  final String? operation;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ErrorLog({
    required this.error,
    this.stackTrace,
    this.operation,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'error': error,
      'stack_trace': stackTrace,
      'operation': operation,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class UserInteraction {
  final String action;
  final String screen;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserInteraction({
    required this.action,
    required this.screen,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'screen': screen,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

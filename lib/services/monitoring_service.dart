import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/auth_service.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();


  final SupabaseClient _supabaseClient = Supabase.instance.client;
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
        await _supabaseClient.from('analytics_events').insert({
          'user_id': userId,
          'event_name': eventName,
          'properties': properties ?? {},
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      logError('Failed to track event: $eventName', null, operation: 'trackEvent');
    }
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

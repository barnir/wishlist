import 'package:flutter/foundation.dart';

/// Log levels for filtering (future expansion: remote filtering / thresholds).
enum LogLevel { debug, info, warn, error }

String _levelLabel(LogLevel level) {
  switch (level) {
    case LogLevel.debug:
      return 'DEBUG';
    case LogLevel.info:
      return 'INFO';
    case LogLevel.warn:
      return 'WARN';
    case LogLevel.error:
      return 'ERROR';
  }
}

/// Centralized lightweight logger.
/// Usage: appLog('Starting auth flow', tag:'AUTH', level:LogLevel.info)
void appLog(
  String message, {
  String tag = 'APP',
  LogLevel level = LogLevel.debug,
  Object? error,
  StackTrace? stackTrace,
}) {
  if (!kDebugMode) return; // Avoid noise in release

  final buffer = StringBuffer()
    ..write('[${_levelLabel(level)}][$tag] $message');
  if (error != null) buffer.write(' | error: $error');
  if (stackTrace != null && level == LogLevel.error) {
    buffer.write('\n$stackTrace');
  }
  debugPrint(buffer.toString());
}

/// Convenience helpers.
void logD(String message, {String tag = 'APP'}) => appLog(message, tag: tag, level: LogLevel.debug);
void logI(String message, {String tag = 'APP'}) => appLog(message, tag: tag, level: LogLevel.info);
void logW(String message, {String tag = 'APP'}) => appLog(message, tag: tag, level: LogLevel.warn);
void logE(String message, {String tag = 'APP', Object? error, StackTrace? stackTrace}) =>
    appLog(message, tag: tag, level: LogLevel.error, error: error, stackTrace: stackTrace);

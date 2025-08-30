import 'package:flutter/foundation.dart';

/// Centralized lightweight logger.
void appLog(String message, {String tag = 'APP'}) {
  if (kDebugMode) {
    debugPrint('[$tag] $message');
  }
}

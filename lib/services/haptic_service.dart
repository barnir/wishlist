import 'package:flutter/services.dart';
import 'package:mywishstash/services/monitoring_service.dart';

/// Service for providing haptic feedback throughout the app
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Light haptic feedback for subtle interactions
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
      MonitoringService.logInfoStatic(
        'HapticService',
        'Light haptic feedback triggered',
      );
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Haptic feedback error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Medium haptic feedback for standard interactions
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
      MonitoringService.logInfoStatic(
        'HapticService',
        'Medium haptic feedback triggered',
      );
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Haptic feedback error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Heavy haptic feedback for important interactions
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
      MonitoringService.logInfoStatic(
        'HapticService',
        'Heavy haptic feedback triggered',
      );
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Haptic feedback error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Selection haptic feedback for picker/selector interactions
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
      MonitoringService.logInfoStatic(
        'HapticService',
        'Selection haptic feedback triggered',
      );
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Haptic feedback error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Vibrate for notifications (longer vibration)
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
      MonitoringService.logInfoStatic(
        'HapticService',
        'Vibration feedback triggered',
      );
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Vibration feedback error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Success haptic pattern - combination of light impacts
  static Future<void> success() async {
    try {
      await lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await lightImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Success haptic pattern error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Error haptic pattern - heavy impact followed by medium
  static Future<void> error() async {
    try {
      await heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await mediumImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Error haptic pattern error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Warning haptic pattern - medium impact
  static Future<void> warning() async {
    try {
      await mediumImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Warning haptic pattern error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Button press haptic - light impact for buttons
  static Future<void> buttonPress() async {
    try {
      await lightImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Button press haptic error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Switch/toggle haptic - selection click for toggles
  static Future<void> toggle() async {
    try {
      await selectionClick();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Toggle haptic error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Delete action haptic - heavy impact for destructive actions
  static Future<void> delete() async {
    try {
      await heavyImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Delete haptic error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Swipe action haptic - medium impact for swipe gestures
  static Future<void> swipe() async {
    try {
      await mediumImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Swipe haptic error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Pull to refresh haptic - light impact when refresh is triggered
  static Future<void> refresh() async {
    try {
      await lightImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Refresh haptic error',
        e,
        context: 'HapticService',
      );
    }
  }

  /// Long press haptic - heavy impact for long press actions
  static Future<void> longPress() async {
    try {
      await heavyImpact();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Long press haptic error',
        e,
        context: 'HapticService',
      );
    }
  }
}
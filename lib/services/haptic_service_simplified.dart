import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app - Simplified Version
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  /// Light haptic feedback for subtle interactions
  static Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Medium haptic feedback for standard interactions
  static Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Heavy haptic feedback for important interactions
  static Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Selection haptic feedback for picker/selector interactions
  static Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Success haptic pattern - double light impact
  static Future<void> success() async {
    try {
      await lightImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await lightImpact();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Error haptic pattern - heavy impact followed by medium
  static Future<void> error() async {
    try {
      await heavyImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      await mediumImpact();
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }
}

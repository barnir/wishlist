import 'package:flutter/services.dart';
import 'dart:async';

/// Service for providing haptic feedback throughout the app - Performance Optimized
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  // Rate limiting para evitar spam de haptic feedback
  static DateTime _lastHapticTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _minHapticInterval = Duration(milliseconds: 50);
  
  // Cache do último tipo de feedback para evitar duplicados
  static String? _lastHapticType;

  /// Light haptic feedback for subtle interactions
  static Future<void> lightImpact() async {
    if (!_shouldPerformHaptic('light')) return;
    
    try {
      await HapticFeedback.lightImpact();
      _updateHapticCache('light');
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Medium haptic feedback for standard interactions  
  static Future<void> mediumImpact() async {
    if (!_shouldPerformHaptic('medium')) return;
    
    try {
      await HapticFeedback.mediumImpact();
      _updateHapticCache('medium');
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Heavy haptic feedback for important interactions
  static Future<void> heavyImpact() async {
    if (!_shouldPerformHaptic('heavy')) return;
    
    try {
      await HapticFeedback.heavyImpact();
      _updateHapticCache('heavy');
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Selection click feedback for UI selections
  static Future<void> selectionClick() async {
    if (!_shouldPerformHaptic('selection')) return;
    
    try {
      await HapticFeedback.selectionClick();
      _updateHapticCache('selection');
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Vibrate device (if available)
  static Future<void> vibrate() async {
    if (!_shouldPerformHaptic('vibrate')) return;
    
    try {
      await HapticFeedback.vibrate();
      _updateHapticCache('vibrate');
    } catch (e) {
      // Fail silently - haptic is not critical
    }
  }

  /// Check if haptic feedback should be performed (rate limiting + duplicate prevention)
  static bool _shouldPerformHaptic(String type) {
    final now = DateTime.now();
    
    // Rate limiting check
    if (now.difference(_lastHapticTime) < _minHapticInterval) {
      return false;
    }
    
    // Duplicate prevention (mesmo tipo muito próximo no tempo)
    if (_lastHapticType == type && 
        now.difference(_lastHapticTime) < const Duration(milliseconds: 100)) {
      return false;
    }
    
    return true;
  }
  
  /// Update haptic cache with timestamp and type
  static void _updateHapticCache(String type) {
    _lastHapticTime = DateTime.now();
    _lastHapticType = type;
  }

  // Convenience methods for common UI actions
  static Future<void> buttonPress() => lightImpact();
  static Future<void> toggle() => selectionClick();
  static Future<void> delete() => heavyImpact();
  static Future<void> swipe() => mediumImpact();
  static Future<void> refresh() => lightImpact();
  static Future<void> longPress() => heavyImpact();
  static Future<void> warning() => mediumImpact();
}

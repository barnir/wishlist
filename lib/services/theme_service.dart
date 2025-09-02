import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/services/analytics/analytics_service.dart';

/// Service to manage app theme (light/dark/system)
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;
  
  /// Whether the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize theme service and load saved preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themeKey);
      
      if (savedTheme != null) {
        _themeMode = _parseThemeMode(savedTheme);
        MonitoringService.logInfoStatic(
          'ThemeService',
          'Loaded theme preference: $savedTheme',
        );
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Failed to initialize theme service',
        e,
        context: 'ThemeService',
      );
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set theme mode and save preference
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    try {
      _themeMode = mode;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, _themeModeName(mode));
      
      MonitoringService.logInfoStatic(
        'ThemeService',
        'Theme changed to: ${_themeModeName(mode)}',
      );

      // Update analytics user property (fire and forget)
      // Using microtask to avoid blocking UI even slightly
      Future.microtask(() {
        AnalyticsService().setUserProps({
          'theme_mode': _themeModeName(mode),
        });
      });
    } catch (e) {
      MonitoringService.logErrorStatic(
        'Failed to save theme preference',
        e,
        context: 'ThemeService',
      );
    }
  }

  /// Get current brightness based on theme mode and system settings
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }

  /// Check if dark mode is currently active
  bool isDarkMode(BuildContext context) {
    return getCurrentBrightness(context) == Brightness.dark;
  }

  /// Get the display name for a theme mode
  String getThemeModeDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Automático';
    }
  }

  /// Get icon for theme mode
  IconData getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Get theme mode name
  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Public accessor for current theme mode name (for analytics bootstrap)
  String get currentThemeModeName => _themeModeName(_themeMode);
}

/// Theme data configurations
// Removed duplicate AppThemes & ThemeProvider; app now uses single source in theme.dart + ThemeService for mode.
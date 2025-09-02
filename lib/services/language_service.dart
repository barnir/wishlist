import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mywishstash/services/analytics/analytics_service.dart';

class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const String _languageKey = 'selected_language';
  static const String _autoDetectKey = 'auto_detect_language';
  
  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('pt'),
    Locale('en'),
  ];

  Locale? _selectedLocale;
  bool _autoDetect = true;
  
  Locale? get selectedLocale => _selectedLocale;
  bool get isAutoDetect => _autoDetect;
  
  /// Get current locale - either user selected or system default
  Locale get currentLocale {
    if (!_autoDetect && _selectedLocale != null) {
      return _selectedLocale!;
    }
    
    // Auto-detect from system
    final systemLocale = PlatformDispatcher.instance.locale;
    final supportedLanguageCodes = supportedLocales.map((l) => l.languageCode).toList();
    
    if (supportedLanguageCodes.contains(systemLocale.languageCode)) {
      return Locale(systemLocale.languageCode);
    }
    
    // Fallback to Portuguese if system language not supported
    return const Locale('pt');
  }

  /// Get display name for locale
  String getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'pt':
        return 'Português';
      case 'en':
        return 'English';
      default:
        return locale.languageCode;
    }
  }

  /// Get all available languages with display names
  Map<Locale, String> get availableLanguages {
    return {
      for (final locale in supportedLocales)
        locale: getLanguageDisplayName(locale),
    };
  }

  /// Initialize service and load saved preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load auto-detect preference (default: true)
    _autoDetect = prefs.getBool(_autoDetectKey) ?? true;
    
    // Load selected language if not auto-detect
    if (!_autoDetect) {
      final savedLanguage = prefs.getString(_languageKey);
      if (savedLanguage != null) {
        _selectedLocale = Locale(savedLanguage);
      }
    }
    
    notifyListeners();
  }

  /// Set language manually (disables auto-detect)
  Future<void> setLanguage(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    
    _selectedLocale = locale;
    _autoDetect = false;
    
    await prefs.setString(_languageKey, locale.languageCode);
    await prefs.setBool(_autoDetectKey, false);
    
    notifyListeners();

    // Update analytics user properties
    Future.microtask(() {
      AnalyticsService().setUserProps({
        'locale': locale.languageCode,
        'language_auto_detect': false,
      });
    });
  }

  /// Enable auto-detect (uses system language)
  Future<void> enableAutoDetect() async {
    final prefs = await SharedPreferences.getInstance();
    
    _autoDetect = true;
    _selectedLocale = null;
    
    await prefs.setBool(_autoDetectKey, true);
    await prefs.remove(_languageKey);
    
    notifyListeners();

    Future.microtask(() {
      AnalyticsService().setUserProps({
        'locale': currentLocale.languageCode,
        'language_auto_detect': true,
      });
    });
  }

  /// Check if a locale is currently active
  bool isCurrentLocale(Locale locale) {
    return currentLocale.languageCode == locale.languageCode;
  }

  /// Get current language display text for UI
  String get currentLanguageDisplayName {
    if (_autoDetect) {
      return 'Automático (${getLanguageDisplayName(currentLocale)})';
    }
    return getLanguageDisplayName(currentLocale);
  }
}
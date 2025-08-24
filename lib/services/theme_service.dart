import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wishlist_app/services/monitoring_service.dart';

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
}

/// Theme data configurations
class AppThemes {
  static const Color _primaryColor = Color(0xFF6750A4);
  static const Color _primaryContainer = Color(0xFFEADDFF);
  
  /// Light theme configuration
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.2),
        thickness: 1,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.withOpacity(0.3),
        thickness: 1,
      ),
    );
  }
}

/// Widget to provide theme context
class ThemeProvider extends StatefulWidget {
  final Widget child;

  const ThemeProvider({
    super.key,
    required this.child,
  });

  @override
  State<ThemeProvider> createState() => _ThemeProviderState();
}

class _ThemeProviderState extends State<ThemeProvider>
    with WidgetsBindingObserver {
  final _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (!_themeService.isInitialized) {
      _themeService.initialize();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    // Rebuild when system theme changes (only affects system mode)
    if (_themeService.themeMode == ThemeMode.system) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'Wishlist App',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme(),
          darkTheme: AppThemes.darkTheme(),
          themeMode: _themeService.themeMode,
          home: widget.child,
        );
      },
    );
  }
}
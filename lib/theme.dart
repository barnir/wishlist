import 'package:flutter/material.dart';
import 'theme_extensions.dart';

// Unified brand seed color (matches splash and app icon accent)
const Color _brandSeed = Color(0xFFFF6B9D);

// Animation durations padronizados para coerência
const Duration _fastTransition = Duration(milliseconds: 150);
const Duration _normalTransition = Duration(milliseconds: 250);

ThemeData _buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: _brandSeed,
    brightness: brightness,
  );

  final isDark = brightness == Brightness.dark;

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    extensions: <ThemeExtension<dynamic>>[
      isDark ? AppSemanticColors.dark(scheme) : AppSemanticColors.light(scheme),
    ],
    scaffoldBackgroundColor: scheme.surface,
    
    // AppBar otimizada com transições fluidas
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: isDark ? 1 : 2,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: scheme.primary,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Cards com otimização visual
    cardTheme: CardThemeData(
      elevation: isDark ? 2 : 1,
      color: scheme.surface,
      surfaceTintColor: scheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shadowColor: isDark ? Colors.black54 : Colors.black12,
    ),
    
    // FAB com melhor contraste
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      elevation: isDark ? 4 : 3,
      highlightElevation: isDark ? 6 : 4,
    ),
    
    // Input fields otimizados
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      filled: true,
      fillColor: isDark ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        fontSize: 16,
      ),
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 16,
      ),
    ),
    
    // Botões com animações fluidas
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        elevation: isDark ? 2 : 1,
        shadowColor: isDark ? Colors.black54 : Colors.black26,
        animationDuration: _normalTransition,
      ),
    ),
    
    // Text buttons otimizados
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: scheme.primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        animationDuration: _fastTransition,
      ),
    ),
    
    // Navigation otimizada com melhor feedback visual
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: scheme.surface,
      selectedItemColor: scheme.primary,
      unselectedItemColor: scheme.onSurfaceVariant.withValues(alpha: 0.7),
      selectedIconTheme: const IconThemeData(size: 28),
      unselectedIconTheme: const IconThemeData(size: 24),
      showUnselectedLabels: true,
      elevation: isDark ? 8 : 4,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
    ),
    
    // Snackbars melhorados
    snackBarTheme: SnackBarThemeData(
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: TextStyle(
        color: scheme.onInverseSurface,
        fontSize: 16,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isDark ? 6 : 3,
      actionTextColor: scheme.primary,
    ),
    
    // Dividers sutis
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
      space: 1,
    ),
    
    // Lista tiles otimizados
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
      ),
      iconColor: scheme.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    
    // Chips otimizados
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      disabledColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      selectedColor: scheme.primaryContainer,
      secondarySelectedColor: scheme.secondaryContainer,
      labelStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
      ),
      secondaryLabelStyle: TextStyle(
        color: scheme.onSecondaryContainer,
        fontSize: 14,
      ),
      brightness: brightness,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    
    // Dialog theme otimizado
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.primary,
      elevation: isDark ? 8 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 16,
      ),
    ),
    
    // Typography otimizada para legibilidade
    textTheme: Typography.material2021(platform: TargetPlatform.android).black.apply(
      bodyColor: isDark ? scheme.onSurface : null,
      displayColor: isDark ? scheme.onSurface : null,
    ).copyWith(
      headlineLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        color: scheme.onSurface,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        color: scheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        color: scheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        color: scheme.onSurfaceVariant,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    ),
    
    // Page transitions otimizadas
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      },
    ),
    
    // Opt-in to more expressive splash consistent with brand
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
  );
}

final ThemeData lightAppTheme = _buildTheme(Brightness.light);
final ThemeData darkAppTheme = _buildTheme(Brightness.dark);

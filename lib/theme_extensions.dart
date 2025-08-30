import 'package:flutter/material.dart';

/// Semantic color roles beyond the core Material ColorScheme.
/// Centralises success / warning / danger / favorite and skeleton shimmer colors
/// so that light & dark themes stay balanced and accessible.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;

  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;

  final Color favorite;
  final Color onFavorite;

  final Color skeletonBase;
  final Color skeletonHighlight;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.favorite,
    required this.onFavorite,
    required this.skeletonBase,
    required this.skeletonHighlight,
  });

  static AppSemanticColors light(ColorScheme scheme) => AppSemanticColors(
        success: const Color(0xFF1F8B4D),
        onSuccess: Colors.white,
        successContainer: const Color(0xFFD6F2E3),
        onSuccessContainer: const Color(0xFF0E4225),
        warning: const Color(0xFFB86E00),
        onWarning: Colors.white,
        warningContainer: const Color(0xFFFFE6C2),
        onWarningContainer: const Color(0xFF4A2E00),
        danger: scheme.error,
        onDanger: scheme.onError,
        dangerContainer: scheme.errorContainer,
        onDangerContainer: scheme.onErrorContainer,
        favorite: const Color(0xFFFFB300), // Amber 600-ish
        onFavorite: const Color(0xFF3A2600),
        skeletonBase: const Color(0xFFE0E0E0),
        skeletonHighlight: const Color(0xFFF5F5F5),
      );

  static AppSemanticColors dark(ColorScheme scheme) => AppSemanticColors(
        success: const Color(0xFF63D292),
        onSuccess: const Color(0xFF00391C),
        successContainer: const Color(0xFF0F4F2C),
        onSuccessContainer: const Color(0xFF9BE7B9),
        warning: const Color(0xFFFFB74D),
        onWarning: const Color(0xFF432900),
        warningContainer: const Color(0xFF5C3A00),
        onWarningContainer: const Color(0xFFFFD8A8),
        danger: scheme.error,
        onDanger: scheme.onError,
        dangerContainer: scheme.errorContainer,
        onDangerContainer: scheme.onErrorContainer,
        favorite: const Color(0xFFFFD54F), // Lighter amber for dark bg
        onFavorite: const Color(0xFF3A2F00),
        skeletonBase: const Color(0xFF424242),
        skeletonHighlight: const Color(0xFF616161),
      );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? favorite,
    Color? onFavorite,
    Color? skeletonBase,
    Color? skeletonHighlight,
  }) => AppSemanticColors(
        success: success ?? this.success,
        onSuccess: onSuccess ?? this.onSuccess,
        successContainer: successContainer ?? this.successContainer,
        onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
        warning: warning ?? this.warning,
        onWarning: onWarning ?? this.onWarning,
        warningContainer: warningContainer ?? this.warningContainer,
        onWarningContainer: onWarningContainer ?? this.onWarningContainer,
        danger: danger ?? this.danger,
        onDanger: onDanger ?? this.onDanger,
        dangerContainer: dangerContainer ?? this.dangerContainer,
        onDangerContainer: onDangerContainer ?? this.onDangerContainer,
        favorite: favorite ?? this.favorite,
        onFavorite: onFavorite ?? this.onFavorite,
        skeletonBase: skeletonBase ?? this.skeletonBase,
        skeletonHighlight: skeletonHighlight ?? this.skeletonHighlight,
      );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(onDangerContainer, other.onDangerContainer, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      onFavorite: Color.lerp(onFavorite, other.onFavorite, t)!,
      skeletonBase: Color.lerp(skeletonBase, other.skeletonBase, t)!,
      skeletonHighlight: Color.lerp(skeletonHighlight, other.skeletonHighlight, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors => Theme.of(this).extension<AppSemanticColors>()!;
}

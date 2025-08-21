import 'package:flutter/material.dart';

/// Constantes UI para manter consistência visual em toda a aplicação
class UIConstants {
  // Espaçamentos padronizados
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Padding padronizado
  static const EdgeInsets paddingXS = EdgeInsets.all(spacingXS);
  static const EdgeInsets paddingS = EdgeInsets.all(spacingS);
  static const EdgeInsets paddingM = EdgeInsets.all(spacingM);
  static const EdgeInsets paddingL = EdgeInsets.all(spacingL);
  static const EdgeInsets paddingXL = EdgeInsets.all(spacingXL);

  // Padding horizontal
  static const EdgeInsets paddingHorizontalS = EdgeInsets.symmetric(horizontal: spacingS);
  static const EdgeInsets paddingHorizontalM = EdgeInsets.symmetric(horizontal: spacingM);
  static const EdgeInsets paddingHorizontalL = EdgeInsets.symmetric(horizontal: spacingL);

  // Padding vertical
  static const EdgeInsets paddingVerticalS = EdgeInsets.symmetric(vertical: spacingS);
  static const EdgeInsets paddingVerticalM = EdgeInsets.symmetric(vertical: spacingM);
  static const EdgeInsets paddingVerticalL = EdgeInsets.symmetric(vertical: spacingL);

  // Margin para cards
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(horizontal: spacingM, vertical: spacingS);
  static const EdgeInsets listPadding = EdgeInsets.only(top: spacingS, bottom: 80);

  // Border radius padronizado
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // Elevações padronizadas
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;

  // Tamanhos de ícones
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
  static const double iconSizeXXL = 100.0;

  // Tamanhos de imagem
  static const double imageSizeS = 40.0;
  static const double imageSizeM = 56.0;
  static const double imageSizeL = 80.0;
  static const double imageSizeXL = 120.0;

  // Altura de botões
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;

  // Largura mínima
  static const double minButtonWidth = 120.0;
  static const double fullWidth = double.infinity;

  // Opacidade padronizada
  static const double opacityDisabled = 0.6;
  static const double opacityLight = 0.7;
  static const double opacityMedium = 0.8;

  // Stroke width para indicadores de loading
  static const double strokeWidthThin = 1.0;
  static const double strokeWidthMedium = 2.0;
  static const double strokeWidthThick = 3.0;
}

/// Extensão para facilitar o uso dos espaçamentos
extension UISpacing on num {
  SizedBox get verticalSpace => SizedBox(height: toDouble());
  SizedBox get horizontalSpace => SizedBox(width: toDouble());
}

/// Helper para criar SizedBox com espaçamentos padronizados
class Spacing {
  static const Widget xs = SizedBox(height: UIConstants.spacingXS);
  static const Widget s = SizedBox(height: UIConstants.spacingS);
  static const Widget m = SizedBox(height: UIConstants.spacingM);
  static const Widget l = SizedBox(height: UIConstants.spacingL);
  static const Widget xl = SizedBox(height: UIConstants.spacingXL);
  static const Widget xxl = SizedBox(height: UIConstants.spacingXXL);

  static const Widget horizontalXS = SizedBox(width: UIConstants.spacingXS);
  static const Widget horizontalS = SizedBox(width: UIConstants.spacingS);
  static const Widget horizontalM = SizedBox(width: UIConstants.spacingM);
  static const Widget horizontalL = SizedBox(width: UIConstants.spacingL);
  static const Widget horizontalXL = SizedBox(width: UIConstants.spacingXL);
}

/// Tema consistente para botões
class AppButtonStyles {
  static ButtonStyle primaryButton(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeightM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      padding: UIConstants.paddingHorizontalL,
      elevation: UIConstants.elevationS,
    );
  }

  static ButtonStyle secondaryButton(BuildContext context) {
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.primary,
      minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeightM),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(UIConstants.radiusM),
      ),
      padding: UIConstants.paddingHorizontalL,
      side: BorderSide(color: Theme.of(context).colorScheme.primary),
    );
  }

  static ButtonStyle textButton(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.primary,
      minimumSize: const Size(UIConstants.minButtonWidth, UIConstants.buttonHeightM),
      padding: UIConstants.paddingHorizontalM,
    );
  }
}
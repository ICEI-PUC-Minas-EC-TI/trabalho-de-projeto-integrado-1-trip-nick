import 'package:flutter/material.dart';
import 'color_aliases.dart';

/// UI-specific color mappings for different application contexts
class UIColors {
  // Text colors
  static const Color textHeadings = ColorAliases.neutral700;
  static const Color textBody = ColorAliases.neutral600;
  static const Color textAction = ColorAliases.primaryDefault;
  static const Color textActionHover = ColorAliases.primary600;
  static const Color textDisabled = ColorAliases.neutral300;
  static const Color textInformation = ColorAliases.informationDefault;
  static const Color textWarning = ColorAliases.warningDefault;
  static const Color textError = ColorAliases.errorDefault;
  static const Color textOnAction = ColorAliases.white;
  static const Color textOnDisabled = ColorAliases.neutral700;

  // Surface colors
  static const Color surfacePrimary = ColorAliases.parchment;
  static const Color surfaceSuccess = ColorAliases.success100;
  static const Color surfaceError = ColorAliases.error100;
  static const Color surfaceWarning = ColorAliases.warning100;
  static const Color surfaceInformation = ColorAliases.information100;
  static const Color surfaceAction = ColorAliases.primaryDefault;
  static const Color surfaceActionHover = ColorAliases.primary100;
  static const Color surfaceActionHover2 = ColorAliases.primary600;
  static const Color surfaceDisabled = ColorAliases.neutral100;
  static const Color surfaceDisabledSelected = ColorAliases.neutral400;
  static const Color surfaceDrawer = ColorAliases.primary200;

  // Icon colors
  static const Color iconPrimary = ColorAliases.neutral700;
  static const Color iconInformation = ColorAliases.informationDefault;
  static const Color iconWarning = ColorAliases.warningDefault;
  static const Color iconSuccess = ColorAliases.successDefault;
  static const Color iconError = ColorAliases.errorDefault;
  static const Color iconAction = ColorAliases.primaryDefault;
  static const Color iconActionHover = ColorAliases.primaryDefault;
  static const Color iconOnDisabled = ColorAliases.neutral700;
  static const Color iconOnAction = ColorAliases.white;

  // Border colors
  static const Color borderPrimary = ColorAliases.neutral200;
  static const Color borderSecondary = ColorAliases.primaryDefault;
  static const Color borderInformation = ColorAliases.informationDefault;
  static const Color borderWarning = ColorAliases.warningDefault;
  static const Color borderSuccess = ColorAliases.successDefault;
  static const Color borderError = ColorAliases.errorDefault;
  static const Color borderAction = ColorAliases.primaryDefault;
  static const Color borderFocus = ColorAliases.primaryDefault;
  static const Color borderActionHover = ColorAliases.primary600;
  static const Color borderDisabled = ColorAliases.neutral300;
}
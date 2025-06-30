import 'package:flutter/material.dart';
import 'colors/color_aliases.dart';
import 'colors/ui_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      // Primary color using design system
      primaryColor: ColorAliases.primaryDefault,
      scaffoldBackgroundColor: UIColors.surfacePrimary,

      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: ColorAliases.primaryDefault,
        foregroundColor: UIColors.textOnAction,
        elevation: 0,
        iconTheme: IconThemeData(color: UIColors.iconOnAction),
        titleTextStyle: TextStyle(
          color: UIColors.textOnAction,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: ColorAliases.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(
            color: UIColors.borderPrimary,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: UIColors.textHeadings,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: UIColors.textHeadings,
        ),
        headlineLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: UIColors.textHeadings,
        ),
        headlineMedium: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: UIColors.textHeadings,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: UIColors.textBody,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: UIColors.textBody,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: UIColors.textDisabled,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: UIColors.surfaceAction,
          foregroundColor: UIColors.textOnAction,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: UIColors.textAction,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ColorAliases.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UIColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UIColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: UIColors.borderFocus, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Tab bar theme
      tabBarTheme: const TabBarThemeData(
        labelColor: UIColors.textHeadings,
        unselectedLabelColor: UIColors.textDisabled,
        indicatorColor: ColorAliases.primaryDefault,
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Drawer theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: ColorAliases.white,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: UIColors.iconPrimary,
        size: 24,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: UIColors.borderPrimary,
        thickness: 1,
      ),
    );
  }
}
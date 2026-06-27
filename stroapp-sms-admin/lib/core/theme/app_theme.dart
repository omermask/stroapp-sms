import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTypography.poppins,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.caribbeanGreen,
      onPrimary: AppColors.cyprus,
      secondary: AppColors.oceanBlue,
      onSecondary: AppColors.honeydew,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      error: Colors.red,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightHeaderBg,
      foregroundColor: AppColors.cyprus,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleSemiBold,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.lightBottomNav,
      selectedItemColor: AppColors.cyprus,
      unselectedItemColor: AppColors.cyprus,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTypography.bodySmall,
      unselectedLabelStyle: AppTypography.bodySmall,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.caribbeanGreen,
        foregroundColor: AppColors.cyprus,
        textStyle: AppTypography.buttonLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.cyprus,
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyprus,
        textStyle: AppTypography.buttonMedium,
        side: const BorderSide(color: AppColors.caribbeanGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightTextFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.caribbeanGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      labelStyle: AppTypography.inputLabel.copyWith(
        color: AppColors.textDarkBrown,
      ),
      hintStyle: AppTypography.inputText.copyWith(color: AppColors.cyprus),
    ),
    cardTheme: CardThemeData(
      color: AppColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppTypography.dialogTitle.copyWith(
        color: AppColors.cyprus,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTypography.nameBold,
      headlineMedium: AppTypography.titleSemiBold,
      titleLarge: AppTypography.titleSemiBold,
      titleMedium: AppTypography.menuItem,
      bodyLarge: AppTypography.bodyRegular,
      bodyMedium: AppTypography.bodyRegular,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.buttonLarge,
      labelMedium: AppTypography.buttonMedium,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lightGreen,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightGreen,
      labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.cyprus),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      side: BorderSide.none,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.cyprus,
      unselectedLabelColor: AppColors.fenceGreen,
      indicatorColor: AppColors.white,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.caribbeanGreen,
      foregroundColor: AppColors.cyprus,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppTypography.poppins,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.caribbeanGreen,
      onPrimary: AppColors.darkTextPrimary,
      secondary: AppColors.oceanBlue,
      onSecondary: AppColors.darkTextPrimary,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      error: Colors.red,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkHeaderBg,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTypography.titleSemiBold,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBottomNav,
      selectedItemColor: AppColors.darkTextPrimary,
      unselectedItemColor: AppColors.darkTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: AppTypography.bodySmall,
      unselectedLabelStyle: AppTypography.bodySmall,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.caribbeanGreen,
        foregroundColor: AppColors.fenceGreen,
        textStyle: AppTypography.buttonLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        textStyle: AppTypography.buttonMedium,
        side: const BorderSide(color: AppColors.caribbeanGreen),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkTextFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: AppColors.caribbeanGreen,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      labelStyle: AppTypography.inputLabel.copyWith(
        color: AppColors.darkTextBody,
      ),
      hintStyle: AppTypography.inputText.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: AppTypography.dialogTitle.copyWith(
        color: AppColors.darkTextPrimary,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: AppTypography.nameBold,
      headlineMedium: AppTypography.titleSemiBold,
      titleLarge: AppTypography.titleSemiBold,
      titleMedium: AppTypography.menuItem,
      bodyLarge: AppTypography.bodyRegular,
      bodyMedium: AppTypography.bodyRegular,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.buttonLarge,
      labelMedium: AppTypography.buttonMedium,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.darkSurface,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkIconBg,
      labelStyle: AppTypography.bodySmall.copyWith(
        color: AppColors.darkTextBody,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      side: BorderSide.none,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.darkTextPrimary,
      unselectedLabelColor: AppColors.darkTextSecondary,
      indicatorColor: AppColors.caribbeanGreen,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.caribbeanGreen,
      foregroundColor: AppColors.fenceGreen,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
  );
}

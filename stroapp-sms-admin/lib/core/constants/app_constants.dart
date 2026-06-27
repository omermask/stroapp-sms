import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'FinWise';
  static const String appVersion = '1.0.0';

  // Dimensions
  static const double screenWidth = 430;
  static const double screenHeight = 932;
  static const double bottomNavHeight = 108;
  static const double bottomNavPaddingTop = 36;
  static const double bottomNavPaddingBottom = 41;
  static const double bottomNavHorizontalPadding = 60;
  static const double bottomNavItemSpacing = 43;

  // Border Radius
  static const double radiusButton = 30;
  static const double radiusInput = 18;
  static const double radiusIconContainer = 22;
  static const double radiusDialog = 20;
  static const double radiusCard = 20;
  static const double radiusCardSmall = 14.89;
  static const double radiusBottomNav = 70;
  static const double radiusAvatar = 60;

  // Sizes
  static const double iconContainerSize = 57;
  static const double avatarSize = 117;
  static const double iconSize = 22;
  static const double notificationIconSize = 30;

  // Padding
  static const double paddingScreen = 24;
  static const double paddingLarge = 20;
  static const double paddingMedium = 16;
  static const double paddingSmall = 12;

  // Spacing
  static const double spacingLarge = 34;
  static const double spacingMedium = 20;
  static const double spacingSmall = 13;

  // Animation
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const EdgeInsets screenPadding = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 15;
  static const double lg = 20;
  static const double xl = 22;
  static const double xxl = 30;

  static BorderRadius get button => BorderRadius.circular(xxl);
  static BorderRadius get input => BorderRadius.circular(18);
  static BorderRadius get iconContainer => BorderRadius.circular(xl);
  static BorderRadius get dialog => BorderRadius.circular(lg);
  static BorderRadius get card => BorderRadius.circular(lg);
  static BorderRadius get bottomNav => const BorderRadius.only(
    topLeft: Radius.circular(radiusBottomNav),
    topRight: Radius.circular(radiusBottomNav),
  );
  static const double radiusBottomNav = 70;
}

import 'package:flutter/material.dart';
import '../utils/qaseh_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_misc.dart';
import 'app_bottom_nav.dart';

// ──────────────────────────────────────────────
// Rounded Content Container – signature card
// Honeydew bg, radius [70, 70, 0, 0]
// Used as the main content wrapper in most screens
// ──────────────────────────────────────────────
class AppRoundedContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  const AppRoundedContent({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? AppColors.darkSurface : AppColors.honeydew2);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
        ),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: padding ?? const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: child,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Screen Mode – controls layout structure
// ──────────────────────────────────────────────
enum ScreenMode {
  /// Full screen with header – app bar in colored header area
  header,

  /// Rounded content with app bar inside the card
  standard,

  /// Minimal – just background + safe area
  minimal,
}

// ──────────────────────────────────────────────
// Screen Header – colored bar at the top
// Used behind the rounded content area
// ──────────────────────────────────────────────
class AppScreenHeader extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? actions;
  final Color? backgroundColor;
  final double height;

  const AppScreenHeader({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.backgroundColor,
    this.height = 200,
  });

  factory AppScreenHeader.withBackAndNotif({
    VoidCallback? onBack,
    VoidCallback? onNotification,
    Color? backgroundColor,
    double? height,
  }) {
    return AppScreenHeader(
      height: height ?? 120,
      backgroundColor: backgroundColor ?? AppColors.caribbeanGreen,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(QasehIcons.arrowLeftCurved, color: AppColors.honeydew),
      ),
      title: null,
      actions: AppNotificationBell(onTap: onNotification),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.caribbeanGreen,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              leading ?? const SizedBox(width: 40),
              if (title != null) Expanded(child: title!),
              actions ?? const SizedBox(width: 40),
            ],
          ),
          if (title == null) const Spacer(),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// App Screen – universal screen template
// Automatically applies the FinWise visual identity
//
// Usage:
//   AppScreen.standard(
//     title: 'Screen Title',
//     child: ...your content...,
//   )
// ──────────────────────────────────────────────
class AppScreen extends StatelessWidget {
  /// The main body content
  final Widget child;

  /// Screen mode
  final ScreenMode mode;

  /// Title shown in app bar (standard/minimal mode)
  final String? title;

  /// Title widget (overrides text title)
  final Widget? titleWidget;

  /// Leading widget (back button etc.)
  final Widget? leading;

  /// Actions (notification bell etc.)
  final List<Widget>? actions;

  /// Whether to show bottom navigation
  final bool showBottomNav;

  /// Current tab (only if showBottomNav is true)
  final AppTab? currentTab;

  /// Tab changed callback
  final ValueChanged<AppTab>? onTabChanged;

  /// Custom header widget (only in header mode)
  final Widget? header;

  /// Header background color
  final Color? headerColor;

  /// Header height
  final double headerHeight;

  /// Content padding inside the rounded card
  final EdgeInsetsGeometry? contentPadding;

  /// Content background color (overrides default honeydew)
  final Color? contentBackgroundColor;

  /// Extra safe area bottom
  final bool extendBodyBehindAppBar;

  const AppScreen({
    super.key,
    required this.child,
    this.mode = ScreenMode.standard,
    this.title,
    this.titleWidget,
    this.leading,
    this.actions,
    this.showBottomNav = false,
    this.currentTab,
    this.onTabChanged,
    this.header,
    this.headerColor,
    this.headerHeight = 200,
    this.contentPadding,
    this.contentBackgroundColor,
    this.extendBodyBehindAppBar = false,
  });

  /// Standard screen with app bar inside rounded card
  factory AppScreen.standard({
    required String title,
    required Widget child,
    Widget? leading,
    List<Widget>? actions,
    bool showBottomNav = false,
    AppTab? currentTab,
    ValueChanged<AppTab>? onTabChanged,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return AppScreen(
      mode: ScreenMode.standard,
      title: title,
      leading: leading,
      actions: actions,
      showBottomNav: showBottomNav,
      currentTab: currentTab,
      onTabChanged: onTabChanged,
      contentPadding: contentPadding,
      child: child,
    );
  }

  /// Screen with colored header + rounded content (like Profile)
  factory AppScreen.header({
    required Widget child,
    Widget? header,
    Color? headerColor,
    double headerHeight = 240,
    bool showBottomNav = false,
    AppTab? currentTab,
    ValueChanged<AppTab>? onTabChanged,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return AppScreen(
      mode: ScreenMode.header,
      header: header,
      headerColor: headerColor,
      headerHeight: headerHeight,
      showBottomNav: showBottomNav,
      currentTab: currentTab,
      onTabChanged: onTabChanged,
      contentPadding: contentPadding,
      child: child,
    );
  }

  /// Minimal screen – just background + safe area
  factory AppScreen.minimal({
    required Widget child,
    bool showBottomNav = false,
    AppTab? currentTab,
    ValueChanged<AppTab>? onTabChanged,
  }) {
    return AppScreen(
      mode: ScreenMode.minimal,
      showBottomNav: showBottomNav,
      currentTab: currentTab,
      onTabChanged: onTabChanged,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.caribbeanGreen;

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: SafeArea(
        bottom: !showBottomNav,
        child: _buildBody(context, isDark),
      ),
      bottomNavigationBar:
          showBottomNav && currentTab != null && onTabChanged != null
          ? AppBottomNav(currentTab: currentTab!, onTabChanged: onTabChanged!)
          : null,
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    switch (mode) {
      case ScreenMode.header:
        return _buildHeaderMode(context, isDark);
      case ScreenMode.standard:
        return _buildStandardMode(context, isDark);
      case ScreenMode.minimal:
        return _buildMinimalMode(context, isDark);
    }
  }

  Widget _buildHeaderMode(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Colored header
        header ??
            AppScreenHeader(
              height: headerHeight,
              backgroundColor: headerColor ?? AppColors.caribbeanGreen,
              leading: leading,
              title:
                  titleWidget ??
                  (title != null
                      ? Text(title!, style: AppTypography.titleSemiBold)
                      : null),
              actions: actions != null ? Row(children: actions!) : null,
            ),
        // Rounded content
        Expanded(
          child: AppRoundedContent(
            padding: contentPadding,
            backgroundColor: contentBackgroundColor,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildStandardMode(BuildContext context, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // App bar inside the rounded card area
        Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: MediaQuery.of(context).padding.top + 8,
          ),
          child: Row(
            children: [
              leading ?? const SizedBox(width: 40),
              const Spacer(),
              titleWidget ??
                  (title != null
                      ? Text(title!, style: AppTypography.titleSemiBold)
                      : const SizedBox()),
              const Spacer(),
              actions != null
                  ? Row(children: actions!)
                  : const SizedBox(width: 40),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Rounded content
        Expanded(
          child: AppRoundedContent(
            padding: contentPadding,
            backgroundColor: contentBackgroundColor,
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalMode(BuildContext context, bool isDark) {
    return SafeArea(child: child);
  }
}

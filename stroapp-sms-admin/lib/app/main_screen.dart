import 'package:flutter/material.dart';
import '../core/utils/qaseh_icons.dart';
import '../core/localization/app_localizations.dart';
import '../core/theme/app_colors.dart';
import 'tabs/tab_home.dart';
import 'tabs/tab_users.dart';
import 'tabs/tab_orders.dart';
import 'tabs/tab_tickets.dart';
import 'tabs/tab_settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _navigatorKeys = List.generate(5, (_) => GlobalKey<NavigatorState>());

  static const _tabs = <Widget>[
    TabHome(),
    TabUsers(),
    TabOrders(),
    TabTickets(),
    TabSettings(),
  ];

  void _onTabChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  bool _onWillPop(int tabIndex) {
    final navigator = _navigatorKeys[tabIndex].currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final labels = [t('home'), t('users'), t('orders'), t('supportTickets'), t('settings')];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop(_currentIndex);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(_tabs.length, (i) {
            return Navigator(
              key: _navigatorKeys[i],
              onGenerateRoute: (_) =>
                  MaterialPageRoute(builder: (_) => _tabs[i]),
            );
          }),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: _AdminBottomNav(
            currentIndex: _currentIndex,
            labels: labels,
            onTap: _onTabChanged,
          ),
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onTap;

  const _AdminBottomNav({
    required this.currentIndex,
    required this.labels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(5, (i) {
          final isActive = i == currentIndex;
          final icon = isActive ? _navItems[i].$2 : _navItems[i].$1;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.caribbeanGreen.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isActive
                        ? AppColors.caribbeanGreen
                        : (isDark ? Colors.white54 : Colors.black45),
                    size: 22,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 9,
                      color: isActive
                          ? AppColors.caribbeanGreen
                          : (isDark ? Colors.white54 : Colors.black45),
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  static const _navItems = <(IconData, IconData)>[
    (QasehIcons.categoryCurved, QasehIcons.categoryFilled),
    (QasehIcons.twoUserCurved, QasehIcons.twoUserFilled),
    (QasehIcons.documentCurved, QasehIcons.documentFilled),
    (QasehIcons.ticketCurved, QasehIcons.ticketFilled),
    (QasehIcons.settingCurved, QasehIcons.settingFilled),
  ];
}

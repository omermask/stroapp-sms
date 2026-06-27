import 'package:flutter/material.dart';
import '../../core/utils/qaseh_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_colors.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final t = AppLocalizations.of(context)!.t;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showAppSnack(context, t('invalidCredentials'), type: SnackType.error);
      return;
    }

    setState(() => _loading = true);

    try {
      final response = await ApiClient().post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      final apiResp = ApiResponse.fromJson(response.data, null);
      if (apiResp.success && apiResp.data != null) {
        final token = apiResp.data['access_token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        if (!mounted) return;
        showAppSnack(
          context,
          apiResp.error?.message ?? t('invalidCredentials'),
          type: SnackType.error,
        );
      }
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, t('serverError'), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _langMap = {
    'ar': 'العربية',
    'en': 'English',
    'fr': 'Français',
    'es': 'Español',
    'tr': 'Türkçe',
    'ur': 'اردو',
    'de': 'Deutsch',
  };

  void _showLanguagePicker() {
    final appState = AppState.of(context);
    if (appState == null) return;
    final current = appState.locale.languageCode;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _langMap.entries.map((e) {
                final active = e.key == current;
                return ListTile(
                  leading: Icon(
                    active
                        ? QasehIcons.tickSquareFilled
                        : QasehIcons.chatCurved,
                    color: active ? AppColors.caribbeanGreen : null,
                  ),
                  title: Text(
                    e.value,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: active
                      ? const Icon(
                          QasehIcons.tickSquareCurved,
                          color: AppColors.caribbeanGreen,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(ctx);
                    appState.setLocale(Locale(e.key));
                  },
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!.t;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = AppState.of(context);
    final isDarkMode = appState?.themeMode == ThemeMode.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (appState != null) appState.toggleThemeMode();
                    },
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        isDarkMode
                            ? QasehIcons.starFilled
                            : QasehIcons.starCurved,
                        key: ValueKey(isDarkMode),
                        color: isDarkMode ? Colors.amber : AppColors.oceanBlue,
                      ),
                    ),
                    tooltip: isDarkMode ? t('lightMode') : t('darkMode'),
                  ),
                  TextButton.icon(
                    onPressed: _showLanguagePicker,
                    icon: const Icon(QasehIcons.chatCurved, size: 20),
                    label: Text(
                      _langMap[appState?.locale.languageCode] ?? 'English',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;
                  final formWidth = isTablet ? 420.0 : constraints.maxWidth;

                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isTablet ? 40 : 24),
                          Container(
                            width: isTablet ? 100 : 80,
                            height: isTablet ? 100 : 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.vividBlue,
                                  AppColors.caribbeanGreen,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(
                                isTablet ? 28 : 22,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.vividBlue.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              QasehIcons.profileCurved,
                              color: Colors.white,
                              size: isTablet ? 52 : 42,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            t('appName'),
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isTablet ? 32 : 24,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'stroapp-sms',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  letterSpacing: 2,
                                ),
                          ),
                          SizedBox(height: isTablet ? 48 : 32),
                          SizedBox(
                            width: formWidth,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 0 : 24,
                              ),
                              child: Column(
                                children: [
                                  AppTextField(
                                    label: t('email'),
                                    hintText: t('emailHint'),
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 16),
                                  AppTextField(
                                    label: t('password'),
                                    hintText: '********',
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? QasehIcons.hideCurved
                                            : QasehIcons.showCurved,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  SizedBox(
                                    width: double.infinity,
                                    height: isTablet ? 52 : 48,
                                    child: AppPrimaryButton(
                                      label: _loading
                                          ? t('loading')
                                          : t('loginButton'),
                                      onPressed: _loading ? null : _login,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isTablet ? 40 : 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

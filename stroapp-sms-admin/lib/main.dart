import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'app/screens/login_screen.dart';
import 'app/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale') ?? 'ar';
  final savedTheme = prefs.getString('theme_mode') ?? 'light';
  runApp(
    StroappSmsAdminApp(
      initialLocale: Locale(savedLocale),
      initialThemeMode: savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light,
    ),
  );
}

class StroappSmsAdminApp extends StatefulWidget {
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  const StroappSmsAdminApp({
    super.key,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  @override
  AppState createState() => AppState();
}

class AppState extends State<StroappSmsAdminApp> {
  late Locale _locale;
  late ThemeMode _themeMode;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;

  static AppState? of(BuildContext context) {
    return context.findAncestorStateOfType<AppState>();
  }

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    _themeMode = widget.initialThemeMode;
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('locale', locale.languageCode),
    );
  }

  void toggleThemeMode() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
    final mode = _themeMode == ThemeMode.dark ? 'dark' : 'light';
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setString('theme_mode', mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stroapp Sms Admin',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales
          .map((l) => Locale(l))
          .toList(),
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: const _EntryPoint(),
    );
  }
}

class _EntryPoint extends StatelessWidget {
  const _EntryPoint();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final loggedIn = snapshot.data ?? false;
        return loggedIn ? const MainScreen() : const LoginScreen();
      },
    );
  }

  Future<bool> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

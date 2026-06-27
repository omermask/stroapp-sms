import 'package:flutter/material.dart';
import 'languages/ar.dart';
import 'languages/en.dart';
import 'languages/fr.dart';
import 'languages/es.dart';
import 'languages/tr.dart';
import 'languages/ur.dart';
import 'languages/de.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static final Map<String, Map<String, String>> _data = {
    'ar': ar,
    'en': en,
    'fr': fr,
    'es': es,
    'tr': tr,
    'ur': ur,
    'de': de,
  };

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  String t(String key) {
    return _data[locale.languageCode]?[key] ?? _data['en']?[key] ?? key;
  }

  static const List<String> supportedLocales = [
    'en',
    'ar',
    'fr',
    'es',
    'tr',
    'ur',
    'de',
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

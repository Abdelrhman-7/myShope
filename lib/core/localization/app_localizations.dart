import 'package:flutter/material.dart';
import 'ar/ar_translations.dart';
import 'en/en_translations.dart';

/// Centralized localization service.
/// Access translations via [AppLocalizations.of(context)] or [context.tr(key)].
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  Map<String, String> get _translations {
    switch (locale.languageCode) {
      case 'ar':
        return arTranslations;
      case 'en':
        return enTranslations;
      default:
        return arTranslations;
    }
  }

  /// Translate a key to the current locale's text.
  String tr(String key, {Map<String, String>? params}) {
    String text = _translations[key] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }

  /// Alias for `tr` to support `loc.translate('key')`
  String translate(String key, {Map<String, String>? params}) =>
      tr(key, params: params);

  /// Whether the current locale is Arabic
  bool get isArabic => locale.languageCode == 'ar';

  /// Whether the current locale is RTL
  bool get isRtl => locale.languageCode == 'ar';

  /// Get the localized name field (name_ar / name_en pattern)
  String localizedName(String? nameAr, String? nameEn) {
    if (isArabic) {
      return nameAr ?? nameEn ?? '';
    }
    return nameEn ?? nameAr ?? '';
  }

  /// Get the localized description field
  String localizedDescription(String? descAr, String? descEn) {
    if (isArabic) {
      return descAr ?? descEn ?? '';
    }
    return descEn ?? descAr ?? '';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// Extension on BuildContext for easy translation access.
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String key, {Map<String, String>? params}) =>
      l10n.tr(key, params: params);

  String translate(String key, {Map<String, String>? params}) =>
      l10n.translate(key, params: params);

  bool get isArabic => l10n.isArabic;
  bool get isRtl => l10n.isRtl;
}


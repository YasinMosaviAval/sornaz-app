import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
/*
class Tr {
  Tr(this.context);

  final BuildContext context;

  static final Map<String, Map<String, String>> _localizedValues = {
    'fa': {
      'app_name': 'پخش‌کننده من',
      'home': 'خانه',
      'settings': 'تنظیمات',
      'about': 'درباره ما',
      'music_player': 'پخش موسیقی',
      'allow_audio_access':
          'لطفاً اجازه دسترسی به فایل‌های صوتی را در تنظیمات اپ بدهید',
      'no_music_found': 'هیچ آهنگی پیدا نشد',
      'play': 'پخش',
      'pause': 'توقف',
      'next': 'بعدی',
      'previous': 'قبلی',
      AppStrings.dark_mode: AppStrings.dark_mode_fa,
      AppStrings.dark_mode_description: AppStrings.dark_mode_description_fa,
      AppStrings.language_mode: AppStrings.language_mode_fa,
      AppStrings.language_mode_description:
          AppStrings.language_mode_description_fa,
      // هر متنی که می‌خوای اضافه کن
    },
    'en': {
      'app_name': 'My Player',
      'home': 'Home',
      'settings': 'Settings',
      'about': 'About Us',
      'music_player': 'Music Player',
      'allow_audio_access':
          'Please grant permission to access audio files in the app settings.',
      'no_music_found': 'No music found',
      'play': 'Play',
      'pause': 'Pause',
      'next': 'Next',
      'previous': 'Previous',
      AppStrings.dark_mode: AppStrings.dark_mode,
      AppStrings.dark_mode_description: AppStrings.dark_mode_description,
      AppStrings.language_mode: AppStrings.language_mode,
      AppStrings.language_mode_description:
          AppStrings.language_mode_description,
    },
  };

  String translate(String key) {
    final locale = Localizations.localeOf(
      context,
    ); // از locale فعلی استفاده می‌کنه
    final lang = locale.languageCode;

    return _localizedValues[lang]?[key] ?? _localizedValues['en']![key] ?? key;
  }

  // برای راحتی می‌تونی یه متد کوتاه هم داشته باشی
  String call(String key) => translate(key);
}

// برای دسترسی راحت‌تر در همه جای اپ
extension TranslateExtension on String {
  String tr(BuildContext context) => Tr(context).translate(this);
}
*/

class AppLocalizations {
  /*
  static final Map<String, Map<String, String>> _localizedValues = {
    'fa': {
      AppStrings.applicationName : AppStrings.applicationName_fa,
      AppStrings.applicationFullname : AppStrings.applicationFullname_fa,
      AppStrings.applicationEmail : AppStrings.applicationEmail_fa,
      AppStrings.faqTitle : AppStrings.faqTitle_fa,
      AppStrings.homeTitle : AppStrings.homeTitle_fa,
      AppStrings.blogsTitle : AppStrings.blogsTitle_fa,
      AppStrings.tunerTitle : AppStrings.tunerTitle_fa,
      AppStrings.splashTitle : AppStrings.splashTitle_fa,
      AppStrings.signUpTitle : AppStrings.signUpTitle_fa,
      AppStrings.signInTitle : AppStrings.signInTitle_fa,
      AppStrings.coursesTitle : AppStrings.coursesTitle_fa,
      AppStrings.authorsTitle : AppStrings.authorsTitle_fa,
      AppStrings.profileTitle : AppStrings.profileTitle_fa,
      AppStrings.aboutUsTitle : AppStrings.aboutUsTitle_fa,
      AppStrings.articlesTitle : AppStrings.articlesTitle_fa,
      AppStrings.settingsTitle : AppStrings.settingsTitle_fa,
      AppStrings.metronomeTitle : AppStrings.metronomeTitle_fa,
      'app_name': 'اپ من',
      'home': 'خانه',
      'settings': 'تنظیمات',
      'about': 'درباره ما',
      'music_player': 'پخش موسیقی',
      'allow_audio_access':
          'لطفاً اجازه دسترسی به فایل‌های صوتی را در تنظیمات اپ بدهید',
      'language': 'زبان',
      'app_language': 'زبان اپ',
      'change_language_desc': 'تغییر زبان اپ به انگلیسی یا فارسی',
      'english': 'انگلیسی',
      'persian': 'فارسی',
      'no_music_found': 'هیچ آهنگی پیدا نشد',
      'play': 'پخش',
      'pause': 'توقف',
      AppStrings.elements: AppStrings.elements_fa,
      AppStrings.text_size: AppStrings.text_size_fa,
      AppStrings.text_size_description: AppStrings.text_size_description_fa,
      AppStrings.notificationTitle: AppStrings.notificationTitle_fa,
      AppStrings.dark_mode: AppStrings.dark_mode_fa,
      AppStrings.dark_mode_description: AppStrings.dark_mode_description_fa,
      AppStrings.language_mode: AppStrings.language_mode_fa,
      AppStrings.language_mode_description:
          AppStrings.language_mode_description_fa,
    },
    'en': {
      AppStrings.applicationName : AppStrings.applicationName,
      AppStrings.applicationFullname : AppStrings.applicationFullname,
      AppStrings.applicationEmail : AppStrings.applicationEmail,
      AppStrings.faqTitle : AppStrings.faqTitle,
      AppStrings.homeTitle : AppStrings.homeTitle,
      AppStrings.blogsTitle : AppStrings.blogsTitle,
      AppStrings.tunerTitle : AppStrings.tunerTitle,
      AppStrings.splashTitle : AppStrings.splashTitle,
      AppStrings.signUpTitle : AppStrings.signUpTitle,
      AppStrings.signInTitle : AppStrings.signInTitle,
      AppStrings.coursesTitle : AppStrings.coursesTitle,
      AppStrings.authorsTitle : AppStrings.authorsTitle,
      AppStrings.profileTitle : AppStrings.profileTitle,
      AppStrings.aboutUsTitle : AppStrings.aboutUsTitle,
      AppStrings.articlesTitle : AppStrings.articlesTitle,
      AppStrings.settingsTitle : AppStrings.settingsTitle,
      AppStrings.metronomeTitle : AppStrings.metronomeTitle,
      'app_name': 'My App',
      'home': 'Home',
      'settings': 'Settings',
      'about': 'About Us',
      'music_player': 'Music Player',
      'allow_audio_access':
          'Please grant permission to access audio files in the app settings.',
      'language': 'Language',
      'app_language': 'App Language',
      'change_language_desc': 'Switch app language between English and Persian',
      'english': 'English',
      'persian': 'Persian',
      'no_music_found': 'No music found',
      'play': 'Play',
      'pause': 'Pause',
      AppStrings.elements: AppStrings.elements,
      AppStrings.text_size: AppStrings.text_size,
      AppStrings.text_size_description: AppStrings.text_size_description,
      AppStrings.notificationTitle: AppStrings.notificationTitle,
      AppStrings.dark_mode: AppStrings.dark_mode,
      AppStrings.dark_mode_description: AppStrings.dark_mode_description,
      AppStrings.language_mode: AppStrings.language_mode,
      AppStrings.language_mode_description:
          AppStrings.language_mode_description,
    },
  };
*/

  static final Map<String, Map<String, String>> _localizedValues = {
    "fa": AppStrings.fa,
    "en": AppStrings.en,
  };

  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return AppLocalizations(Provider.of<LocaleProvider>(context).locale);
  }

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

extension Translate on String {
  String translate(BuildContext context) {
    // return AppLocalizations.of(context).translate(this);
    final loc = AppLocalizations.of(context);
    return loc?.translate(this) ?? this;
  }
}

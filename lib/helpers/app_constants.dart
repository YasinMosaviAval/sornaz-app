class AppConstants {
  // ثابت‌های API
  static const String apiBaseUrl = 'https://sornaz.com/wp-json/wp/v2/';
  static const String apiKey =
      'your_api_key_here'; // از environment variables لود کن برای امنیت

  // ثابت‌های UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  // Strings رایج (برای localization بهتره از app_localizations استفاده کن، اما اینجا نمونه)
  static const String appName = 'Sornaz Music App';
  static const String errorMessage = 'An error occurred. Please try again.';
  static const String loadingText = 'Loading...';

  // ثابت‌های مرتبط با موسیقی
  static const int maxPlaylistSize = 100;
  static const String defaultMusicImage = 'assets/images/default_music.png';

  // ثابت‌های روت‌ها (اگر از GoRouter استفاده می‌کنی، اینجا نگه دار)
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';

  // ثابت‌های تم
  static const String fontFamily = 'Vazir';
  // می‌تونی ثابت‌های بیشتری اضافه کنی (مثل enums برای انواع موسیقی: pop, rock, etc.)
}

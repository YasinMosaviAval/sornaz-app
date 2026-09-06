# پنل اجتماعی اپ

ورود از تب پروفایل، گزینه پنل کاربری در منوی کناری یا مسیر /profile.
صفحه‌ها در lib/screens/Social قرار دارند و با طرح Instructor Profile فیگما، فونت و تم اپ تطبیق داده شده‌اند.

API همان Sornaz_API_BASE_URL ورود برنامه است. پیش‌فرض https://sornaz.com/api/sornaz/v1 است. برای تست محلی آدرس قابل دسترس گوشی را با --dart-define تعیین کنید. backend و schemaهای Modules/CourseMarket و Modules/Social باید روی سرور هدف نصب شوند. تغییرات این کار سرور production را منتشر نمی‌کنند.

هر درس یک posts خصوصی با password هش‌شده است. متن و فایل‌ها تا خرید دوره و در صورت تنظیم رمز اختصاصی، ورود رمز صحیح، پنهان می‌مانند. تغییر رمز مجوزهای قبلی آن رمز را باطل می‌کند.

اعلان‌ها داخل اپ هستند. ارسال Push از طریق FCM و اعلان پس‌زمینه سیستم‌عامل تنظیم نشده است. دایرکت از همان ChatService سایت استفاده می‌کند؛ پیام متنی هر ۵ ثانیه در صفحه باز تازه می‌شود. پیوست‌های قدیمی چت فعلاً در سایت قابل مشاهده‌اند.

تست: flutter test --no-pub test/social_api_test.dart test/social_widget_test.dart

مخزن pub.dev در این محیط پاسخ 403 داشت. video_player و وابستگی‌ها از آینه معرفی‌شده در مستندات Flutter دریافت شدند. برای همین منبع در PowerShell: $env:PUB_HOSTED_URL='https://pub.flutter-io.cn' و سپس flutter pub get.

## APK verification (2026-09-06)

Built `build/app/outputs/flutter-apk/app-release.apk` with `flutter build apk --release --no-pub --target-platform android-arm64`.
Environment for this machine: `PUB_HOSTED_URL=https://pub.flutter-io.cn`, `JAVA_TOOL_OPTIONS=-Djavax.net.ssl.trustStoreType=Windows-ROOT -Djavax.net.ssl.trustStore=NONE` (uses Windows trusted certificates).
AGP 8.11.1 and Kotlin 2.2.20 satisfy the installed Flutter minimum requirements.
The APK is intended for ARM64 devices, Android 7/API 24 or newer. Release compilation uses the existing Android Debug signing key; store signing is not configured.
Size: 35,730,626 bytes. SHA256: F16B00052584396F79770E6E8D21B82D1FCDD1B6F659F3276B623842B3963FE8.
APK signature v2 verified successfully. All 9 social Flutter tests passed in the actual mobile project. No physical device/emulator was connected.
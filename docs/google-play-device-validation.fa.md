# خروجی و آزمون انتشار گوگل پلی — ۲۰۲۶/۱۰/۲۳

## خروجی نهایی

- شاخه: `release/google-play-v1`؛ تغییرات هنوز commit نشده‌اند.
- شناسهٔ نصب: `com.sornaz`؛ نسخهٔ AAB: `1.0.0+1`؛ minSdk=24 و targetSdk=36.
- AAB: `release_outputs/1.0.0+1/20261023-090453-346-86b851/app-release.aab`
- اندازه: 140,964,782 بایت (134.43 MiB).
- SHA-256: `67CC0C685D2B91A1073C203B948CFDC5AD4B718A84AA85BC1807E0ECC5A15992`.
- معماری‌ها: ARMv7، ARM64 و x86_64.
- APK مستقیم ARM64: `release_outputs/1.0.0+1/20261023-090301-522-53a9f9/app-arm64-v8a-release.apk`؛ SHA-256: `6450B6AEC2AB4D053357360B5D72F43E90A24301E8B68635874A7B65C871713B`.
- اثرانگشت SHA-256 گواهی upload برای APK و AAB یکسان است: `AEA54AF7A63B1C518E37E7F23E2AA6014399AA3C3A15D1978769704B3A1A7737`.

خروجی برای بارگذاری در مسیر Internal testing آماده است. انتشار عمومی به بررسی Console، نصب از Google Play و آزمون قابلیت‌های اصلی نیاز دارد؛ هیچ فایلی در Play بارگذاری نشده است.

## نتیجهٔ بررسی صفحهٔ سیاه

گوشی Samsung SM-A266B با Android 16، ARM64 و صفحهٔ حافظهٔ 4096 بایتی بررسی شد. ابتدا APK قبلی و سپس APK تازهٔ شاخهٔ انتشار با شناسهٔ قبلی درست اجرا شدند. APK با شناسهٔ جدید نیز در نصب مستقل و سپس با امضای واقعی اجرا شد.

از AAB نهایی، splitهای مخصوص همین گوشی با bundletool 1.18.1 ساخته و روی گوشی نصب شدند. چهار فایل base-master، arm64_v8a، en و xxhdpi نصب شدند؛ نسخهٔ نصب‌شده کد 1 دارد. تنظیم اولیه، صفحات معرفی، ورود و ادامهٔ بدون ورود تا صفحهٔ اصلی دیده شد. سه شروع سرد بعدی حدود 337 تا 401 میلی‌ثانیه زمان Activity داشتند؛ این زمان به معنی زمان کامل دریافت محتوای شبکه نیست. فرایند زنده ماند و در لاگ بررسی‌شده خطای بحرانی Flutter/Android ثبت نشد.

مشکل تاریخی صفحهٔ سیاه بازتولید نشد؛ علت قبلی هنوز قطعی نیست و اصلاح مشخصی برای آن ادعا نمی‌شود. یک تصویر سیاه در این جلسه هنگام Dozing و قفل گوشی گرفته شد؛ پس از بازشدن قفل، UI درست نمایش داده شد. این مشاهده به معنی تشخیص علت خطای تاریخی نیست.

APK قدیمی پیش از آزمون پشتیبان گرفته شد. `com.example.sornaz` و داده‌هایش حذف نشدند. فقط نصب‌های آزمایشی `com.sornaz` که در همین جلسه ساخته شدند برای تغییر امضا و آزمون نصب تازه جایگزین شدند.

## تست‌ها و شواهد

- ۹ تست `test/release_navigation_test.dart` و `test/drawer_accounts_test.dart`: موفق.
- APK امضاشده: `apksigner verify` و `zipalign -c -P 16 4`: موفق.
- AAB: `jarsigner -verify` امضا را تأیید کرد؛ هشدار گواهی self-signed و نبود timestamp ثبت شد. JDK17 دربارهٔ تفاوت خواندن Manifest با JarInputStream نیز هشدار داد؛ اعتبارسنجی bundletool و نصب splitهای حاصل موفق بودند.
- `bundletool validate`: موفق؛ تنظیم Bundle برابر `PAGE_ALIGNMENT_16K`.
- هر ۳۰ کتابخانهٔ ELF در ARM64 و x86_64: هم‌ترازی LOAD حداقل 16384 بایت، بدون شکست.
- هر چهار split حاصل از AAB: امضا و zipalign موفق و گواهی upload یکسان.
- محافظ امضا با رمز جای‌نگهدار آزمایش شد: ساخت Release عمداً پیش از بسته‌بندی متوقف شد. ساخت با رمزهای واقعی موفق بود.
- بررسی نحو PowerShell و `git diff --check`: موفق.
- شواهد در `release_outputs/diagnostics/20261023-device-validation` ذخیره شده‌اند.

اجرای bundletool در locale فارسی ویندوز نام classes2.dex را اشتباهاً با رقم فارسی مقایسه می‌کرد. ابزار با `-Duser.language=en -Duser.country=US` اجرا شد و اعتبارسنجی گذشت؛ فایل AAB تغییر نکرد.

Flutter برای APKهای `--split-per-abi` شمارهٔ 2001 را برای ARM64 تولید می‌کند؛ AAB کد اصلی 1 دارد. به همین دلیل نصب AAB روی APK مستقیم خطای downgrade می‌دهد. برای آزمون حاضر نصب آزمایشی حذف و splitهای AAB به‌صورت تازه نصب شدند. این تفاوت با تغییر versionCode نهایی دور زده نشد.

## کلید upload و ساخت‌های بعدی

کلید در `C:/Users/Lappixel/sornaz-upload.jks` با alias برابر `upload` ساخته شد. رمزها فقط در `android/key.properties` محلی قرار دارند؛ این فایل، jks و keystore از قبل در Git مستثنا شده‌اند. کلید و رمز را امن و جداگانه پشتیبان بگیرید.

Gradle اکنون به کلید upload متصل است. fallback به debug حذف شده؛ نبود فایل، مقدار خالی، جای‌نگهدار رمز یا نبود keystore باعث توقف Release می‌شود. namespace داخلی Kotlin همان `com.example.sornaz` مانده و با شناسهٔ نصب `com.sornaz` تفاوت دارد.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Arm64 -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Bundle -Offline
```

برای ساخت کلید در دستگاه جدید (اگر کلید قبلی ندارید):

```powershell
& 'C:\dev\sdk\java\jdk-17.0.20.1+1\bin\keytool.exe' -genkeypair -v -keystore "$env:USERPROFILE\sornaz-upload.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

برای همین برنامه، کلید موجود را استفاده کنید. اگر Console گواهی عمومی upload را خواست:

```powershell
& 'C:\dev\sdk\java\jdk-17.0.20.1+1\bin\keytool.exe' -exportcert -rfc -keystore "$env:USERPROFILE\sornaz-upload.jks" -alias upload -file "$env:USERPROFILE\sornaz-upload-certificate.pem"
```

رمز در ابزار پرسیده می‌شود؛ آن را در چت یا آرگومان فرمان قرار ندهید. برای برنامهٔ جدید، AAB امضاشده در Play Console بارگذاری می‌شود و Play App Signing امضای توزیع را مدیریت می‌کند.

## تغییرات و محدودیت‌ها

- `android/app/build.gradle`: شناسهٔ جدید و اتصال امضای upload با توقف ساخت ناقص.
- `lib/main.dart`: شناسهٔ کانال اعلان موسیقی `com.sornaz.music`.
- `scripts/build_android.ps1`: اصلاح ثبت اثرانگشت گواهی از `System.Object[]` به متن واقعی.
- `scripts/README_ANDROID_BUILD.md` و این گزارش: راهنمای امضای جدید و شواهد آزمون.
- `android/key.properties`: فقط محلی و خارج از Git.

کد main و وب تغییر نکرده‌اند. وابستگی جدیدی به OMR یا تحلیل عملکرد آزمایشی اضافه نشده است. metadata_god وابستگی موجود و مورد استفادهٔ امکانات موسیقی انتشار است. تغییرات از ابتدا در worktree انتشار اعمال شدند و نیازی به انتقال به آن ندارند. انتقال احتمالی به main باید انتخابی باشد؛ AGENTS.md هیچ شاخه‌ای عوض نشده است.

مانده‌ها: آزمایش نصب واقعی از Play، آزمون دستگاه/شبیه‌ساز با صفحهٔ حافظهٔ 16KB و بررسی کامل پخش، ضبط، ورود و سایر قابلیت‌ها. تست این جلسه تأیید همهٔ دستگاه‌ها یا پذیرش نهایی Google Play نیست. اخطارهای سازگاری آیندهٔ Gradle/Kotlin هم باقی‌اند؛ نسخهٔ ابزارها تغییر نکرد.

منابع رسمی:
- https://developer.android.com/studio/publish/app-signing
- https://developer.android.com/guide/practices/page-sizes
- https://docs.flutter.dev/deployment/android
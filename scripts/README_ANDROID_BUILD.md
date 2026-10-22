# ساخت آفلاین و عیب‌یابی اندروید

این دستورها را در PowerShell و از پوشهٔ `sornaz-app-release` اجرا کنید. اسکریپت فقط روی شاخهٔ `release/google-play-v1` اجرا می‌شود. خروجی‌ها و گزارش‌ها در `release_outputs` با پوشهٔ جدا برای هر اجرا ذخیره می‌شوند. هیچ خروجی قبلی از این پوشه حذف یا بازنویسی نمی‌شود.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Arm64 -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode All -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Universal -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Bundle -Offline
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Debug -Offline
```

حالت پیش‌فرض `Arm64` است. برای ساخت بدون محدودکردن Gradle به کش آفلاین، `-Offline` را بردارید. حالت `All` به‌ترتیب APK عمومی، APKهای تفکیک‌شده و AAB را می‌سازد. هر مرحله باید موفق شود و فایل خروجی وجود داشته باشد. اگر Gradle فایل قبلی را دوباره استفاده کند، گزارش آن را با `producedThisRun: false` مشخص می‌کند؛ آن فایل خروجی تازه محسوب نمی‌شود. گزارش `build-report.json` شامل اندازه، هش SHA-256، نسخه، شناسهٔ برنامه و در صورت امکان اثرانگشت گواهی APK است. `build.log` خروجی ساخت را نگه می‌دارد. خروجی‌های این شاخه فعلاً با کلید Debug امضا می‌شوند و برای انتشار در Google Play آماده نیستند.

برای اولین بار، Flutter SDK و Android SDK و وابستگی‌های قفل‌شدهٔ `pubspec.lock` باید از قبل در کش دستگاه موجود باشند. حالت آفلاین، Gradle و Cargo را آفلاین می‌کند و از `--no-pub` استفاده می‌کند. اگر `.dart_tool/package_config.json` یا بسته‌ای در کش موجود نباشد، یک بار در محیط دارای اینترنت `flutter pub get --enforce-lockfile` را اجرا کنید؛ سپس دوباره دستور آفلاین را بزنید. اسکریپت `flutter clean` یا `flutter pub upgrade` اجرا نمی‌کند و نسخهٔ ابزارها را عوض نمی‌کند. اگر ساخت به‌خاطر کش Gradle یا کتابخانهٔ Native شکست خورد، متن دقیق `build.log` را بررسی کنید؛ تا رفع وابستگی مفقود، آفلاین بودن ساخت تضمین نمی‌شود. در آزمایش فعلی کش Release کامل است، اما کش Debug شامل همهٔ کتابخانه‌های Gradle نیست. برای آماده‌کردن Debug، یک‌بار در محیط دارای اینترنت دستور `powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_android.ps1 -Mode Debug` را اجرا کنید. سپس حالت `-Offline` را دوباره آزمایش کنید.

برای گرفتن لاگ گوشی، USB Debugging را در تنظیمات توسعه‌دهنده فعال کنید، گوشی را وصل کنید و درخواست اعتماد روی گوشی را بپذیرید. سپس اجرا کنید:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnose_android.ps1
```

اگر چند دستگاه وصل است، شمارهٔ دستگاه را از خروجی دستور بالا بردارید و اجرا کنید:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\diagnose_android.ps1 -Serial 'DEVICE_SERIAL' -CaptureSeconds 30
```

اسکریپت برنامهٔ نصب‌شده را اجرا می‌کند، وضعیت فرایند و بخشی از لاگ شروع را ثبت می‌کند و گزارش را در `release_outputs/diagnostics` می‌گذارد. توکن، گذرواژه، نشانی اینترنتی و ایمیل در خطوط ذخیره‌شده پوشانده می‌شوند؛ بااین‌حال پیش از به‌اشتراک‌گذاری، گزارش را شخصاً بازبینی کنید. اگر برنامه نصب نیست، APK ساخته‌شده را با دستور زیر نصب کنید؛ این دستور داده‌های برنامه را پاک نمی‌کند:

```powershell
& 'C:\dev\sdk\android-sdk\platform-tools\adb.exe' install -r '.\release_outputs\VERSION\RUN\app-arm64-v8a-release.apk'
```

`VERSION` و `RUN` را با نام پوشه‌های واقعی خروجی جایگزین کنید. برای خطای صفحهٔ سیاه، گزارش عیب‌یابی همان نسخه‌ای را ارسال کنید که روی گوشی نصب شده است. موفقیت Build به‌تنهایی به‌معنای رفع خطای اجرا نیست.

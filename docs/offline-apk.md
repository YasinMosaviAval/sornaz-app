# ساخت APK آفلاین در ویندوز

## بستهٔ منتقل‌شدهٔ ۲۰۲۶/۱۰/۲۲

در این سیستم، محیط منتقل‌شده در
`20261022-windows-offline-kit/runtime` قرار دارد. اسکریپت
`tool/build_apk_offline.ps1` در صورت وجود این محیط و نبود پارامتر صریح
`-Flutter`، ابتدا آن را فعال می‌کند. SDKها و کش‌های قدیمی حذف نشده‌اند.
این پوشه شامل کلید خصوصی است و در Git قرار نمی‌گیرد.

برای کار مستقیم با Flutter، در هر ترمینال PowerShell جدید از ریشهٔ پروژه اجرا کنید:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
. .\20261022-windows-offline-kit\runtime\Activate-Offline.ps1 -Project (Get-Location).Path
```

برای بازسازی تنظیم بسته‌ها پس از تغییر مسیر یا lockfile، به فرمان فعال‌سازی
`-ResolvePackages` اضافه کنید. نصب اولیهٔ کلید مشترک با پشتیبان‌گیری انجام می‌شود؛
در فعال‌سازی روزمره سوییچ `-InstallSharedDebugKey` لازم نیست.
راهنمای بسته مربوط به سورس مبدا است؛ در این worktree اسکریپت ساخت موجود
`tool/build_apk_offline.ps1` است، نه `scripts/build_android.ps1`.

برای بررسی وابستگی‌ها بدون تولید APK، پس از فعال‌سازی:

```powershell
Push-Location android
try { .\gradlew.bat --offline :app:verifyOfflineReleaseDependencies -Ptarget-platform=android-arm64 }
finally { Pop-Location }
```

برای بازگشت، اسکریپت ساخت را با `-Flutter` و مسیر SDK قبلی اجرا کنید و
`android/local.properties` را از پشتیبان `local.properties.before-offline-*`
برگردانید. تنظیمات قبلی Flutter در
`20261022-windows-offline-kit/flutter-settings.before-activation.json` و کلید
قبلی در `%USERPROFILE%\.android\debug.keystore.before-sornaz-*` نگهداری می‌شوند.
برای استفاده از محیط قبلی، ترمینال تازه با متغیرهای محیطی قبلی باز کنید و
مسیرهای Android SDK و JDK قبلی را با `flutter config` تنظیم کنید.
هماهنگی ابزار و کلید، برابری خروجی نهایی را بدون هماهنگی سورس، lockfile و
شمارهٔ ساخت تضمین نمی‌کند.

اعتبارسنجی این انتقال در ۲۰۲۶/۱۰/۲۳: هش ZIP و اندازه و SHA-256 هر
۱۷۷٬۸۳۷ فایل استخراج‌شده پیش از فعال‌سازی تأیید شد. حل بسته‌ها با
`--offline --enforce-lockfile` و بررسی Gradle با ۵۸ artifact کامپایل و
۱۱۱ artifact اجرا موفق بود. نسخه‌ها Flutter 3.47.2، Dart 3.13.2،
JDK 17.0.20.1 و Gradle 8.14 هستند. کلید نصب‌شده با بسته تطابق دارد و
کلید قبلی پشتیبان‌گیری شده است. به‌دلیل تفاوت مالکیت فایل‌های استخراج‌شده،
فقط مسیر دقیق SDK Flutter به `safe.directory` در تنظیمات Git داخل بسته
اضافه شد. APK ساخته نشده و نصب روی گوشی و قطع کامل شبکه آزموده نشده‌اند.

در VS Code از منوی Terminal گزینهٔ New Terminal را انتخاب کنید و در ترمینال
PowerShell این دو دستور را اجرا کنید:

```powershell
cd A:\workspace\android\flutter\sornaz-app
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1
```

### خطای کمبود فضای دیسک

در اجرای ۲۰۲۶/۱۰/۲۸، خطای `java.io.IOException: There is not enough space on the disk`
با کمتر از یک مگابایت فضای آزاد در درایو `A:` بازتولید شد. فضای آزاد درایو
`C:` جای فضای مورد نیاز خروجی پروژه و کش Gradle در `A:` را نمی‌گیرد؛ این
خطا را با افزایش حافظهٔ Java یا حذف کش وابستگی‌ها برطرف نکنید.

اسکریپت، پیش از فعال‌سازی محیط، حل بسته‌ها و ساخت، فضای درایو پروژه و محل
کش Gradle انتخاب‌شده را بررسی می‌کند و در صورت وجود کمتر از ۲ گیگابایت فضای
آزاد با ذکر مسیر متوقف می‌شود. برای تعیین حداقل بیشتر، مثلاً ۴ گیگابایت،
پارامتر `-MinimumFreeSpaceGB 4` را اضافه کنید. این حداقل، تضمین فضای کافی
برای تمام مراحل ساخت نیست؛ اندازهٔ خروجی‌ها و فایل‌های موقت ممکن است بیشتر باشد.
اسکریپت هیچ فایلی را حذف یا به درایو دیگری منتقل نمی‌کند. پس از تأمین فضای
کافی روی درایو اعلام‌شده، همان فرمان بالا را دوباره اجرا کنید.

اگر پس از شکست ناشی از پر شدن دیسک، خطای `Cannot lock execution history cache`
با عبارت `already been locked by this process` باقی ماند، پس از اطمینان از
نبود ساخت فعال و فعال‌سازی محیط آفلاین، `android\gradlew.bat --stop` را اجرا
و سپس فرمان ساخت را تکرار کنید. این کار پردازش Gradle را تازه می‌کند و نیازی
به حذف کش وابستگی‌ها یا تغییر فایل قفل بسته‌ها ندارد.

فایل‌های `java_pid*.hprof` خروجی تشخیصی JVM و شامل حافظهٔ فرایند هستند؛
آن‌ها را در Git یا بستهٔ انتشار قرار ندهید. نادیده‌گرفتن آن‌ها در Git، فضای
اشغال‌شدهٔ دیسک را آزاد نمی‌کند.

اعتبارسنجی ۲۰۲۶/۱۰/۲۸: پس از پشتیبان‌گیری و انتقال فایل‌های میانی Debug و
heap dump به درایو دیگر و تازه‌کردن پردازش Gradle، اسکریپت با کد خروجی صفر
در ۳۴۱٫۹۴۴ ثانیه تمام شد. APK فعلی ARM64 برابر ۱۵۴٬۷۵۷٬۷۷۲ بایت است و
`apksigner verify --verbose` امضای v2 آن را تأیید کرد. SHA-256:
`F69448B6B8E0F6E1D932C07482626D62BB8F651EC2075110FBB332391B1BC864`.
سورس، کش وابستگی‌های آفلاین و خروجی‌های APK قبلی حفظ شدند. بررسی parser و
توقف پیش از فعال‌سازی برای کمبود فضای پروژه و کش Gradle نیز موفق بود؛ نصب
و اجرای این APK روی گوشی و قطع فیزیکی شبکه آزموده نشده‌اند.

خروجی Release برای گوشی‌های ARM64 در این مسیر ساخته می‌شود:

```text
build\app\outputs\flutter-apk\app-release.apk
```

از ۲۰۲۶/۱۰/۰۷ پیش‌فرض اسکریپت فقط ARM64 است. خروجی قبلی ۱۷۵٬۴۷۱٬۸۶۸
بایتی، کتابخانه‌های سه معماری ARM64، ARMv7 و x86_64 را با هم داشت. بررسی
محتوای آن نشان داد حدود ۱۵۷٫۵ مگابایت از حجم APK به فایل‌های بومی این سه
معماری مربوط است. خروجی ARM64 تنها باید به‌طور محسوسی کوچک‌تر باشد، اما
اندازهٔ دقیق آن تا اجرای ساخت جدید مشخص نیست. برای ساخت یک APK شامل هر سه
معماری، پارامتر زیر را صریح وارد کنید:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1 -TargetPlatform android-arm,android-arm64,android-x64
```

برای گوشی‌های ۳۲بیتی می‌توان `-TargetPlatform android-arm` را انتخاب کرد.

برای افزایش شمارهٔ ساخت، مثلاً به ۲:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1 -BuildNumber 2
```

برای ساخت‌های معمولی نیازی به `flutter clean` ندارید. پوشه‌های SDK و کش‌های
ذکرشده در ادامه را نگه دارید و `pub cache repair` اجرا نکنید. تغییر نسخهٔ
Flutter، افزودن یا ارتقای وابستگی‌ها و ساخت برای معماری دیگری ممکن است به
یک‌بار دریافت وابستگی‌های جدید نیاز داشته باشد.

اصلاح ۲۰۲۶/۱۰/۲۲: فایل قفل دریافتی از گیت‌هاب، بدون تغییر `pubspec.yaml`،
منبع بسته‌ها را از `pub.flutter-io.cn` به `pub.dev` تغییر داده و ۳۵ بسته را
به نسخه‌های خارج از کش محلی ارتقا داده بود. این تغییر باعث شکست مرحلهٔ
`pub get --offline --enforce-lockfile` می‌شد. فایل قفل به نسخه‌های قبلیِ
سازگار با کش برگردانده شد؛ بررسی سخت‌گیرانهٔ فایل قفل در اسکریپت حفظ شده است.
ارتقای بعدی وابستگی‌ها باید همراه با آماده‌سازی کش و بررسی آفلاین انجام شود.
پس از اصلاح، حل بسته‌ها با `--offline --enforce-lockfile` و بررسی Gradle
با ۵۸ artifact کامپایل و ۱۱۱ artifact اجرا موفق شد. APK تولید نشده است.
برای بررسی همین مرحله بدون تولید APK، در PowerShell اجرا کنید:

```powershell
$env:PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
$env:FLUTTER_WINDOWS = 'false'
$env:FLUTTER_LINUX = 'false'
flutter pub get --offline --enforce-lockfile
```

این متغیرها در نشست جاری ترمینال باقی می‌مانند؛ برای ادامهٔ کار دسکتاپ،
از ترمینال تازه استفاده کنید. اسکریپت اصلی متغیرهای محیطی را پس از اجرا
به مقدار قبلی برمی‌گرداند.

اصلاح ۲۰۲۶/۱۰/۱۹: شکست ثبت‌شدهٔ ساخت در مرحلهٔ `:app:packageRelease` بوده
و در همان زمان `java_pid10468.hprof` با سقف heap برابر ۲ گیگابایت تولید شده
است؛ شواهد به کمبود حافظهٔ جاوا هنگام بسته‌بندی اشاره دارد. سقف heap در
`android/gradle.properties` به ۴ گیگابایت افزایش یافت و هم‌زمانی workerهای
Gradle و jobهای Cargo به یک کاهش پیدا کرد. فایل‌های کش یا نسخهٔ وابستگی‌ها
تغییر نکرده‌اند. بررسی `verifyOfflineReleaseDependencies` با ۵۸ artifact
کامپایل و ۱۱۱ artifact اجرا در حالت آفلاین موفق بود. این بررسی APK تولید
نمی‌کند و تأیید موفقیت بسته‌بندی نهایی نیازمند اجرای مجدد ساخت APK است.

تنظیم فعلی پروژه، خروجی Release را با کلید debug همین سیستم امضا می‌کند؛
فایل `%USERPROFILE%\.android\debug.keystore` را هم نگه دارید.

آزمون انجام‌شده در ۲۰۲۶/۰۹/۲۲: فرمان بالا با Pub، Gradle و Cargo در حالت
آفلاین و پراکسی غیرقابل‌دسترسی برای فرایند ساخت، با کد خروجی صفر تمام شد.
APK نسخهٔ `1.0.0+1` با حجم ۳۶٬۹۲۴٬۷۱۲ بایت ساخته شد و امضای v2 آن با
`apksigner verify` تأیید شد. اجرای برنامه روی گوشی در این آزمون انجام نشده است.
فایل SHA-256 کنار همین APK قرار دارد. زمان این اجرای اولیه حدود ۲۷ دقیقه بود؛
برای خروجی‌های بعدی، حفظ پوشهٔ `build` از تکرار کارهای بدون تغییر جلوگیری می‌کند.

# Offline Android arm64 release

## FFmpeg audio dependency added in October 2026

Video-to-audio conversion adds `ffmpeg_kit_flutter_new_audio:2.5.7`. Its Dart
package is in the Pub cache, but Android also needs the separate Maven artifact
`com.antonkarpenko:ffmpeg-kit-audio:2.2.3`. Download the following files
from Maven Central and place all three in
`android/offline-maven/com/antonkarpenko/ffmpeg-kit-audio/2.2.3/`:

- https://repo.maven.apache.org/maven2/com/antonkarpenko/ffmpeg-kit-audio/2.2.3/ffmpeg-kit-audio-2.2.3.aar
- https://repo.maven.apache.org/maven2/com/antonkarpenko/ffmpeg-kit-audio/2.2.3/ffmpeg-kit-audio-2.2.3.pom
- https://repo.maven.apache.org/maven2/com/antonkarpenko/ffmpeg-kit-audio/2.2.3/ffmpeg-kit-audio-2.2.3.module

The three files were placed on 2026-10-07. The downloaded POM had a browser
explanation line before its XML; that line was removed so Gradle can parse it.
The AAR's SHA-256 matches the value in its module metadata. The exact version
is routed exclusively to the local Maven repository in
`android/build.gradle`; copying just the AAR into an arbitrary Gradle cache
directory will not reliably satisfy offline resolution. After placing the
files, run the dependency-only verification command below. It does not create
an APK. On 2026-10-07 it passed offline with 58 compile and 111 runtime
artifacts. The locked Dart packages also resolved with `flutter pub get
--offline --enforce-lockfile`.

The first full offline APK run then exposed one plugin-only compile dependency:
`androidx.annotation:annotation:1.9.1`. The FFmpeg plugin is now routed to the
already cached compatible `1.10.0` release in `android/build.gradle`. A second
offline build completed successfully on 2026-10-07. The resulting APK was
renamed in this workspace to `build/app/outputs/flutter-apk/app-release-8.apk`
(175,471,868 bytes; SHA-256
`57A2EA54C6B757E806641D1487FB5CC2DF3815D7CC9AD8926BB8E7B0B50A1981`).
`apksigner verify` passed with a v2 signature, and the APK contains FFmpeg and
metadata_god native libraries for armv7, arm64 and x86_64. Device installation
and runtime behavior were not checked.

The Flutter SDK, Android SDK, Dart packages, Gradle plugins and all artifacts must
already be installed on this machine. --no-pub alone does not make Gradle offline.

The project's android/offline-maven repository includes the story editor's three
previously missing runtime JARs with their original POM/module metadata. Their
SHA-256 hashes are recorded in story-dependencies.sha256.json. Exclusive repository
filters are limited to those exact versions; dependency constraints are preserved.
TLS certificate checks have not been disabled.

Verify Gradle dependency readiness without creating an APK:

    $env:JAVA_HOME = 'C:\dev\sdk\java\jdk-17.0.20.1+1'
    cd android
    .\gradlew.bat :app:verifyOfflineReleaseDependencies --offline -Ptarget-platform=android-arm64

From the Flutter project root, run an actual offline build when needed (after
the initial online preparation has completed):

    powershell -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1

The script resolves the existing lockfile with `pub get --offline
--enforce-lockfile`, then builds with Gradle offline and `--no-pub`. It uses
Flutter from PATH, defaults to arm64, and restores its environment variables
even if the build fails. Optional parameters: `-Flutter <flutter.bat path>` and
`-BuildNumber <number>`. The APK is written to
`build/app/outputs/flutter-apk/app-release.apk`.
The script temporarily disables desktop plugin generation, so Android packaging
does not require Windows Developer Mode, and selects the `pub.flutter-io.cn`
cache matching this project's lockfile.
It also sets `CARGO_NET_OFFLINE=true` for the Rust code in `metadata_god`.
`tool/prepare_offline_native.ps1` makes a small, idempotent change to that
package's cached Windows Cargokit launcher: its nested `dart pub get` honors
`SORNAZ_GRADLE_OFFLINE`. Online behavior is preserved. This step is required
because Flutter's `--no-pub` does not control Cargokit's own package resolver.

The Gradle wrapper uses the official Gradle 8.14 binary distribution instead of
the previous machine's `A:` drive. Its first invocation needs that distribution
downloaded into the wrapper cache, even if Gradle's dependency resolution is
offline. Keep `%USERPROFILE%\.gradle`, the Pub cache (normally
`%LOCALAPPDATA%\Pub\Cache`), the complete Flutter SDK, Android SDK (including
NDK/build-tools/platforms/licenses), and the JDK for subsequent offline builds.
Also retain `%USERPROFILE%\.cargo` and `%USERPROFILE%\.rustup`: the installed
Rust GNU host toolchain, `aarch64-linux-android` target, and cached Cargo crates
are needed by `metadata_god`. Cargokit's Dart dependencies must also be cached.
Copying only the Flutter SDK does not copy the other caches. Regenerate package
configuration on a new machine; it can contain absolute paths to the old user.

The current release configuration signs the APK with the local debug key.

This machine's tools are installed at:

- Flutter: `C:\dev\sdk\flutter-sdk\flutter` (3.47.2)
- Java: `C:\dev\sdk\java\jdk-17.0.20.1+1`
- Android SDK: `C:\dev\sdk\android-sdk` (platforms 31, 33, 34, 35 and 36, build-tools 35.0.0,
  NDK 28.2.13676358, CMake 3.22.1)
- Download archives: `C:\dev\sdk\downloads`

Flutter's local configuration records the Java and Android SDK paths.
`%USERPROFILE%\.gradle\init.d\sornaz-repositories.gradle` adds the Google Maven
mirror to the Flutter SDK's included Gradle build. The latter
has its own repositories; the app's repository list does not cover it. Keep this
local initialization file with the Gradle cache.

The environment switch is opt-in and is read before Gradle plugins are resolved.
New dependencies or SDK versions require preparing their artifacts before going
offline. Keep the local Maven files when copying this checkout to another machine;
they do not replace the rest of that machine's Gradle and SDK caches.

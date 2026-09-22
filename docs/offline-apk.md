# ساخت APK آفلاین در ویندوز

در VS Code از منوی Terminal گزینهٔ New Terminal را انتخاب کنید و در ترمینال
PowerShell این دو دستور را اجرا کنید:

```powershell
cd C:\dev\workspace\android\flutter\sornaz-app
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1
```

خروجی Release برای گوشی‌های ARM64 در این مسیر ساخته می‌شود:

```text
build\app\outputs\flutter-apk\app-release.apk
```

برای افزایش شمارهٔ ساخت، مثلاً به ۲:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1 -BuildNumber 2
```

برای ساخت‌های معمولی نیازی به `flutter clean` ندارید. پوشه‌های SDK و کش‌های
ذکرشده در ادامه را نگه دارید و `pub cache repair` اجرا نکنید. تغییر نسخهٔ
Flutter، افزودن یا ارتقای وابستگی‌ها و ساخت برای معماری دیگری ممکن است به
یک‌بار دریافت وابستگی‌های جدید نیاز داشته باشد.

تنظیم فعلی پروژه، خروجی Release را با کلید debug همین سیستم امضا می‌کند؛
فایل `%USERPROFILE%\.android\debug.keystore` را هم نگه دارید.

آزمون انجام‌شده در ۲۰۲۶/۰۹/۲۲: فرمان بالا با Pub، Gradle و Cargo در حالت
آفلاین و پراکسی غیرقابل‌دسترسی برای فرایند ساخت، با کد خروجی صفر تمام شد.
APK نسخهٔ `1.0.0+1` با حجم ۳۶٬۹۲۴٬۷۱۲ بایت ساخته شد و امضای v2 آن با
`apksigner verify` تأیید شد. اجرای برنامه روی گوشی در این آزمون انجام نشده است.
فایل SHA-256 کنار همین APK قرار دارد. زمان این اجرای اولیه حدود ۲۷ دقیقه بود؛
برای خروجی‌های بعدی، حفظ پوشهٔ `build` از تکرار کارهای بدون تغییر جلوگیری می‌کند.

# Offline Android arm64 release

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

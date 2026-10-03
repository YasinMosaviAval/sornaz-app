# گزارش فاز ۷B تحلیل اجرای موسیقی

## دامنه و وضعیت

این مرحله دو بخش دارد: بستن بیلد تولید اندرویدِ فاز هفت و آماده‌کردن چارچوب کالیبراسیون/اعتبارسنجی با ضبط واقعی ساز. هیچ نمرهٔ آموزشی ساخته نشده و هیچ نتیجه‌ای برای صدای واقعی حدس زده نشده است. قرارداد PCM فاز سه، ABI فاز پنج و مدل‌های فازهای شش و هفت تغییر نکرده‌اند. تغییرات نامرتبطِ موجود در worktree نیز در این مرحله دست‌نخورده مانده‌اند.

## بستن بیلد Release

در فاز هفت بیلد arm64 موفق، ولی بیلد پیش‌فرض سه‌معماری به‌علت نبود `rust-std` برای armv7 و دسترس‌نبودن artifactهای Flutter برای armv7 و x64 شکست خورده بود. نصب targetهای cross-compilation با دستور رسمی `rustup target add` انجام شد؛ [راهنمای Rustup](https://rust-lang.github.io/rustup/cross-compilation.html) تأیید می‌کند که targetها کتابخانهٔ استاندارد معماری مقصد را نصب می‌کنند و Android NDK نیز جداگانه لازم است. NDK 28.2.13676358 و CMake 3.22.1 از قبل نصب بودند. [مستند Flutter](https://docs.flutter.dev/add-to-app/android/project-setup?tab=without-android-studio) سه معماری `armeabi-v7a`، `arm64-v8a` و `x86_64` را برای خروجی AOT اندروید فهرست می‌کند.

| وابستگی | وضعیت اولیه | اقدام و وضعیت کنونی |
| --- | --- | --- |
| Flutter SDK/engine `a804b261645ef8c13eb3d5c44a5c2fb0340c5539` | SDK حاضر؛ Maven محلی فقط arm64 داشت. | `libflutter.so` همان revision برای armv7 و x64 از JARهای کش SDK در artifactهای native-only محلی قرار گرفت؛ اسکریپت `tool/seed_flutter_engine_maven.ps1` نسخه و SHA-256 هر فایل را ثبت می‌کند. artifact arm64 اصلی پروژه حفظ شد. |
| Rust target `armv7-linux-androideabi` | غایب | با `rustup target add --toolchain stable` دانلود و نصب شد. |
| Rust target `x86_64-linux-android` | غایب | با همان دستور دانلود و نصب شد. |
| Rust target `aarch64-linux-android` | نصب بود | حفظ شد. |
| Gradle wrapper 8.14، AGP 8.11.1، Kotlin 2.2.20، JDK 17، Android SDK/NDK | موجود | تغییری لازم نبود؛ هشدارهای سازگاری آیندهٔ Flutter به‌معنی شکست بیلد کنونی نیستند. |
| Dart lockfile و کش pub | موجود | `flutter pub get --offline --enforce-lockfile` در اسکریپت آفلاین اجرا شد؛ هیچ ارتقای نسخه‌ای انجام نشد. |

اسکریپت `tool/build_apk_offline.ps1` اکنون سه معماری را به‌صورت پیش‌فرض می‌سازد و پیش از Gradle، cache محلی Flutter engine را آماده می‌کند. `SORNAZ_GRADLE_OFFLINE=true`، `CARGO_NET_OFFLINE=true` و `pub get --offline` مسیرهای سه مدیر وابستگی را آفلاین نگه می‌دارند. JARهای حجیم armv7/x64 محلی و قابل بازسازی از SDK هستند و در Git ثبت نمی‌شوند. فایل‌های منبع SDK با revision دقیق Flutter تطبیق داده می‌شوند؛ نسخه‌های دیگر نباید بی‌بررسی مخلوط شوند. هر JAR معماری فقط یک ورودی `lib/<abi>/libflutter.so` دارد و شامل کلاس‌های مشترک Flutter نیست. کپی مستقیم `flutter.jar` خام SDK یک بار در `checkReleaseDuplicateClasses` شکست خورد؛ روش استخراج native-only جایگزین شد.

**نتیجهٔ بیلد اول سه‌معماری:** پس از اصلاح JARهای native-only، `assembleRelease` با موفقیت در **۹۵۳٫۳ ثانیه** تمام شد. خروجی `C:\dev\workspace\android\flutter\sornaz-app\build\app\outputs\flutter-apk\app-release.apk` با حجم **۹۳٬۰۶۸٬۹۰۸ بایت** (حدود ۸۸٫۸ MiB طبق Flutter) ساخته شد. زمان ثبت‌شده، زمان Gradle است؛ زمان کل فراخوانی نخست جداگانه اندازه‌گیری نشده است. خطای کپی مستقیم JAR پیش از این بیلد، `checkReleaseDuplicateClasses` بود؛ آن خروجی ناموفق، شاهد بیلد موفق محسوب نمی‌شود.

**تکرار آفلاین:** همان `tool/build_apk_offline.ps1` بدون افزودن ابزار یا پکیج تازه دوباره اجرا شد و **موفق** بود؛ زمان کل اسکریپت **۱۱۵٫۷۴۶ ثانیه** و زمان Gradle **۷۱٫۷ ثانیه** بود. همان مسیر و حجم **۹۳٬۰۶۸٬۹۰۸ بایت** به دست آمد؛ SHA-256: `E1F6E102B0566C3357D3E27D965ECFA6FF274F488F751FCC79FAA1E32CD4447C`. `pub get --offline`، Cargo offline و Gradle offline در اسکریپت فعال بودند. `:app:verifyOfflineReleaseDependencies --offline` جداگانه موفق شد و **۶۰ artifact** در `releaseCompileClasspath` و **۱۱۲ artifact** در `releaseRuntimeClasspath` را تأیید کرد. بنابراین تکرار آفلاین روی **همین رایانه و کش فعلی** ثابت شده است؛ یک ماشین تازه هنوز به cache SDK/Gradle/Pub/Cargo نیاز دارد.

فهرست APK برای هر سه ABI `libflutter.so`، `libmetadata_god.so` و `libmusic_analysis_dsp.so` را نشان داد. روی `libmusic_analysis_dsp.so` ساخته‌شده برای هر سه ABI، `llvm-nm -D` تعداد **صفر** نماد Aubio/`new_fvec`/`del_fvec` یافت؛ CMake اندروید نیز `MA_ENABLE_AUBIO=OFF` دارد. این شواهد Aubio را از مسیر تولید جدا می‌کنند. `apksigner verify --print-certs` امضای معتبر با `CN=Android Debug` را گزارش کرد. **این یک APK Release-mode قابل ساخت و تکرار است، ولی با امضای فعلی برای انتشار رسمی آماده نیست**؛ keystore و تنظیم امضای release متعلق به مالک محصول لازم است و در این مرحله ساخته یا حدس زده نشد.

دستورهای بازتولید در PowerShell، از ریشهٔ مخزن:

```powershell
& 'C:\Users\Lappixel\.cargo\bin\rustup.exe' target add --toolchain stable armv7-linux-androideabi x86_64-linux-android
powershell -NoProfile -ExecutionPolicy Bypass -File .\tool\build_apk_offline.ps1 -Flutter 'C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat'
$env:JAVA_HOME='C:\dev\sdk\java\jdk-17.0.20.1+1'
$env:SORNAZ_GRADLE_OFFLINE='true'
& .\android\gradlew.bat -p android --offline :app:verifyOfflineReleaseDependencies
C:\dev\sdk\flutter-sdk\flutter\bin\flutter.bat test --no-pub test/analysis_audio_test.dart test/music_analysis_ffi_integration_test.dart test/music_analysis_phase6_test.dart test/music_analysis_phase6_integration_test.dart test/music_analysis_phase7_test.dart test/music_analysis_phase7_integration_test.dart test/music_analysis_calibration_test.dart
```

## چارچوب کالیبراسیون و اعتبارسنجی ۷B

`MusicAnalysisCalibrationRunner` یک `CalibrationCase` شامل شناسهٔ امن، نام ساز، منبع فایل/URI، MusicXML و annotationهای اختیاریِ کارشناس را می‌پذیرد. همان `AnalysisAudioPreparer` فاز سه، `MusicAnalysisFfi` فاز پنج با موتور اپن، segmenter فاز شش، aligner فاز شش و assessor فاز هفت را پشت سر هم اجرا می‌کند. PCM موقت در `finally` پاک می‌شود و فایل ضبط‌شدهٔ اصلی تغییر نمی‌کند. stream فیچرها به‌صورت چانک‌محور مصرف می‌شود؛ فقط نت‌های اجراشده و رویدادهای تطبیق در حافظهٔ دارت جمع می‌شوند.

`CalibrationResult` خروجی JSON با نسخهٔ schema و CSV ردیفی می‌دهد. هر ردیف شامل برچسب `matched/wrongNote/missed/extra`، شناسه و pitch مرجع، موقعیت مرجع، زمان شروع/پایان و pitch نت اجراشده، اعتماد pitch، اختلاف cents، اختلاف شروع برحسب beat، نسبت طول، RMS، قدرت نسبی صدا، proxy پوشش طول، تمپوی تخمینی و در صورت وجود annotation دستی، pitch/onset/end حقیقت و خطای نسبت به آن است. JSON همچنین مشخصات منبع، تعداد فریم PCM، تعداد فریم فیچر، شمارش برچسب‌ها و میانهٔ متریک‌ها را دارد. مقدار ناموجود `null` می‌ماند؛ نمرهٔ صفر تا صد وجود ندارد. نام فایل خروجی از شناسهٔ امن ساخته می‌شود و مسیر منبع ضبط در JSON/CSV نوشته نمی‌شود.

برای اجرای یک ضبط محلی روی Android/iOS، فراخواننده یک `AnalysisAudioPreparer(PlatformAnalysisAudioDecoder())` و `MusicAnalysisFfi.open()` به runner می‌دهد، سپس `CalibrationCase` را با مسیر فایل یا `content://` و متن MusicXML می‌سازد و `CalibrationResult.writeTo(outputDirectory)` را فراخوانی می‌کند. کتابخانهٔ نیتیوِ حالت تولید فقط موتور open را انتخاب می‌کند. این API در UI محصول متصل نشده است؛ تست روی دستگاه هنوز انجام نشده است.

| فایل | دلیل |
| --- | --- |
| `tool/seed_flutter_engine_maven.ps1` | بازسازی امن کش Maven موتور Flutter از SDK نصب‌شده. |
| `tool/build_apk_offline.ps1` | پیش‌فرض سه‌معماری و آماده‌سازی کش پیش از بیلد آفلاین. |
| `.gitignore` | خارج‌کردن JAR/POMهای بازتولیدپذیر و حجیم دو معماری از Git. |
| `lib/screens/Notation/music_analysis_calibration.dart` | pipeline داده‌محور و خروجی JSON/CSV. |
| `test/music_analysis_calibration_test.dart` | تست یکپارچهٔ فازهای ۳ تا ۷B و آزمون امنیت نام فایل. |
| همین گزارش | شواهد بیلد و محدودیت‌های دادهٔ واقعی. |

## دادهٔ واقعی، مقایسهٔ موتورها و آزمون‌ها

جست‌وجوی فایل‌های WAV/M4A/MP3/FLAC/AAC/OGG/MusicXML در مخزن و مسیرهای Music، Documents و Downloads کاربر، **هیچ زوج ضبط ساز + مرجع MusicXML و annotation واقعی** پیدا نکرد. تنها فایل‌های صوتی مخزن تیک‌های مترونوم‌اند و به‌عنوان اجرای ساز یا حقیقت‌مبنا استفاده نشدند. `adb devices -l` نیز هیچ دستگاهی نشان نداد. بنابراین تعداد نمونه‌های ساز واقعی **صفر** و نتایج اعتبارسنجی واقعی pitch/onset/tempo و کیفیت تطبیق **ناموجود** است؛ هیچ عدد synthetic به‌عنوان نتیجهٔ ساز واقعی گزارش نمی‌شود.

تست synthetic ساختار خروجی از یک فایل کوتاه signed-16 به PCM فاز سه، موتور اپن واقعیِ host DLL فاز پنج و مدل‌های فاز شش/هفت عبور کرد؛ حفظ فایل اصلی، پاک‌شدن PCM موقت، فیلدهای JSON/CSV، annotation اختیاری و شناسهٔ فایل امن را بررسی کرد. **۲/۲ تست جدید پاس**؛ Dart analyzer روی فایل‌های جدید **No issues found**. مجموعهٔ رگرسیون فازهای ۳ تا ۷B با همان DLL تولیدِ بدون Aubio **۳۱/۳۱ پاس**. suite مستقلِ مقایسهٔ توسعه‌ای Aubio/open در `.native-ab-build` نیز **۴/۴ پاس، ۳۰٫۲۹ ثانیه**؛ این تست synthetic است و هیچ ادعایی دربارهٔ صدای واقعی ساز ندارد. Aubio فقط در بیلد opt-in توسعه‌ای `MA_ENABLE_AUBIO=ON` موجود است؛ Android production با `MA_ENABLE_AUBIO=OFF` پیکربندی شده و نمادهای آن در خروجی تولید یافت نشد.

## وضعیت پلتفرم‌ها، محدودیت و پیشنهاد مبتنی بر شواهد

**Android device:** تست روی دستگاه انجام نشد؛ `adb devices -l` خالی بود. **iOS:** بیلد و تست انجام نشد؛ این میزبان Windows است و Xcode ندارد. بیلد APK حتی در صورت موفقیت، جای تست decoder، FFI و تأخیر روی دستگاه را نمی‌گیرد.

محدودیت اصلی نبود مجموعه‌دادهٔ واقعی و حقیقت‌مبنای زمانی/پیچ است. برای کالیبراسیون بعدی، برای هر ساز هدف چند اجرای تک‌صدایی کوتاه با MusicXML دقیق ضبط شود: نت‌های کشیده و کوتاه، نت‌های تکراری هم‌نام، گام‌های بالا/پایین، تمپوهای کند/متوسط/تند، دینامیک آرام/قوی، سکوت بین نت‌ها، اتاق ساکت و نویز معمول، و چند دستگاه/میکروفون. کارشناس باید onset، offset و pitch هر نت را برچسب بزند. تا آن زمان تغییر آستانه‌های segmentation/alignment یا افزودن نمرهٔ آموزشی بر پایهٔ تیک مترونوم و سینوس توجیه ندارد. فاز بعد باید ابتدا خطاها را روی این corpus گزارش کند، سپس سیاست کالیبراسیون نسخه‌دار را با آزمون مستقلِ خارج از دادهٔ آموزش تعریف کند؛ مسیر production همچنان فقط موتور اپن باشد.

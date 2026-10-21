# خروجی دسکتاپ ویندوز

این خروجی از محیط توسعهٔ `main` و با همان API، تنظیمات ظاهری و داده‌های حساب
اندروید ساخته می‌شود. شناسهٔ برنامه، امضا و تنظیمات بک‌اند تغییر نکرده‌اند.

## سازگاری قابلیت‌ها

- ویدیو: افزونهٔ Windows Media Foundation، بازکردن مسیر فارسی، صدا و روشنایی
  داخل پلیر، تغییر اندازهٔ پنجره هنگام چرخش و بازگرداندن اندازهٔ عمودی هنگام خروج.
- موسیقی و ضبط: پخش ویندوز، کنترل رسانهٔ سیستم، ورودی میکروفون تیونر، انتخاب
  پوشه‌های کتابخانه و ضبط، موج صوتی، برش و جایگزینی با نسخهٔ پشتیبان موقت.
- اکولایزر: پردازش واقعی با FFmpeg و تعویض منبع با حفظ موقعیت و وضعیت پخش.
  تغییر آن روی فایل طولانی به زمان پردازش و فضای موقت نیاز دارد.
- استوری: خواندن عکس و ویدیو، پیش‌نمایش، ترکیب لایهٔ تصویر و خروجی ویدیویی،
  ذخیره و عکس‌برداری با دوربین ویندوز.
- اسناد خصوصی: PDF داخل پردازش برنامه و در حافظه رندر می‌شود؛ سند رمزگشایی‌شده
  به مرورگر یا برنامهٔ بیرونی فرستاده نمی‌شود.
- نت‌نویسی: همان ویرایشگر بسته‌بندی‌شده در مرورگر سیستم و پل محلی محافظت‌شده.
  تنظیمات فونت/رنگ/گردی و انتخاب کشش و پیانو همگام می‌شوند. فایل‌های JSON و
  MusicXML در پوشهٔ انتخابی ذخیره می‌شوند؛ خروجی PDF از چاپ مرورگر استفاده می‌کند.
  ورود نتیجهٔ OMR همچنان پیش‌نمایش و تأیید قبلی را دارد و با مجوز توسعه محدود است.
- تحلیل صوت: کتابخانهٔ `music_analysis_dsp.dll` از همان موتور باز اندروید ساخته
  و کنار برنامه قرار می‌گیرد؛ موتور مقایسه‌ای GPL فعال نمی‌شود.
- اشتراک‌گذاری برنامه: ZIP قابل‌حمل شامل فایل اجرایی، DLLها، دارایی‌های عمومی
  و مجوزها؛ پوشهٔ حساب و اسناد خصوصی در آن قرار نمی‌گیرد.

زنگ تلفن و سرویس اعلان اندروید، قابلیت‌های مختص همان سیستم‌عامل‌اند؛ ویندوز از
کنترل رسانهٔ سیستم استفاده می‌کند. کدک‌های ویدیویی قابل پخش تابع کدک‌های نصب‌شدهٔ
ویندوز هستند. دوربین، میکروفون و کلیدهای فیزیکی رسانه نیازمند آزمون سخت‌افزاری‌اند.

پخش ضبط و مترونوم از یک پل اختصاصی به موتور پایدار موسیقی ویندوز استفاده می‌کند. افزونهٔ جداگانهٔ just_audio ویندوز به دلیل خطای بومی حذف شده است.

چرخهٔ بستن کنترل رسانهٔ سیستم نیز در یک کپی محلی مخصوص ساخت اصلاح شده است؛ منابع COM پیش از خروج آزاد می‌شوند و کلیدهای رسانه روی نخ رابط کاربری تحویل داده می‌شوند. کش مشترک Pub تغییر نمی‌کند. runtime مربوط به FFmpeg نیز تا پایان فرایند در حافظه نگه داشته می‌شود تا نخ‌های داخلی روی DLL آزادشده اجرا نشوند.

## ساخت

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tool/build_windows_offline.ps1 -Flutter C:/dev/sdk/flutter-sdk/flutter/bin/flutter.bat
```

Visual Studio با ابزار C++، Windows SDK، Flutter و هدف Rust
`x86_64-pc-windows-msvc` باید آماده باشند. ساخت سرد به کش Pub/Cargo، بسته‌های
NuGet و کتابخانهٔ FFmpeg ویندوز نیاز دارد؛ نام اسکریپت به معنی امکان دریافت
این وابستگی‌ها بدون شبکه نیست. پس از آماده‌سازی کش‌ها از قفل وابستگی‌ها استفاده
می‌شود. دو افزونهٔ جدید مخصوص ویندوزند و نسخه‌های قبلی اندروید حفظ شده‌اند. رابط صوتی موجود نیز با همان نسخه، وابستگی مستقیم شده است.
لینک افزونه‌ها با junction محلی ساخته می‌شود؛ تغییر Developer Mode لازم نیست.

کل پوشهٔ `build/windows/x64/runner/Release` باید منتقل شود؛ کپی فایل EXE به‌تنهایی
کافی نیست. DLLهای runtime ویژوال‌سی‌پلاس‌پلاس و مجوز کتابخانه‌های بومی نیز بسته‌بندی می‌شوند.

## آزمون

نسخهٔ Release با ۱۹ بررسی بومی روی فایل اجرایی ساخته‌شده و خروج عادی با کد صفر تأیید شد. آزمون‌های واحد مرتبط با تیونر، فایل‌ها، ضبط و موتور صوتی نیز موفق بودند. دوربین، میکروفون واقعی، کلید فیزیکی رسانه و گردش‌های حساب واقعی هنوز آزمون دستی نیاز دارند.

`test/desktop_pitch_test.dart` دقت نت و رد سکوت/نویز را می‌سنجد.
`test/desktop_media_files_test.dart` نگهداری فایل اصلی و جایگزینی امن را می‌سنجد.
آزمون‌های ضبط، برش، استوری، تیونر، تنظیمات نت‌نویسی و پخش اندروید نیز اجرا می‌شوند.
آزمون ساختگی با آزمون روی دستگاه و حساب واقعی یکسان نیست.

برای آزمون بومی بدون ضبط میکروفون یا دوربین:

```powershell
build/windows/x64/runner/Release/sornaz.exe --desktop-smoke-test=C:/dev/workspace/android/flutter/sornaz-app/build/windows-smoke.json
```

این حالت فقط رسانهٔ مصنوعی می‌سازد، پخش بی‌صدا، تبدیل فرمت‌ها، برش، اکولایزر،
استوری، PDF خصوصی، فرادادهٔ Rust و تحلیل صوت را بررسی می‌کند؛ وارد حساب کاربری
نمی‌شود. نتیجه در JSON نوشته می‌شود و موفقیت با بررسی هر ۱۹ مقدار JSON و خروج عادی برنامه تعیین می‌شود.

## انتقال انتخابی

فایل‌های مشترک رسانه در `lib/helpers/desktop_*`، بخش‌های Players، Tuner، Voice Recorder،
Notation، `main.dart` و فایل‌های Windows runner/CMake باید همراه قراردادهای
مربوط منتقل شوند. دو افزونهٔ ویندوز و رابط صوتی به `pubspec.yaml` و `pubspec.lock` وابسته‌اند.
فایل‌های تولیدی، heap dump و `.cxx` جزو تغییرات قابل انتقال نیستند.
اتصال DLL تحلیل و تغییرات OMR به قابلیت‌های آزمایشی موجود وابسته‌اند؛ در انتقال
به نسخه‌ای که این قابلیت‌ها را ندارد، این قسمت‌ها باید جداگانه انتخاب شوند.
هیچ تغییری روی worktree انتشار اعمال نشده است.

## فهرست فایل‌های تغییرکرده

- `docs/windows-desktop.md`
- `lib/components/audio_crop_page.dart`
- `lib/desktop_smoke.dart`
- `lib/helpers/desktop_audio_duration.dart`
- `lib/helpers/desktop_audio_platform.dart`
- `lib/helpers/desktop_distribution.dart`
- `lib/helpers/desktop_library_folders.dart`
- `lib/helpers/desktop_library_paths.dart`
- `lib/helpers/desktop_media_channel.dart`
- `lib/main.dart`
- `lib/screens/Metronome/controller/metronome_controller.dart`
- `lib/screens/Notation/analysis_audio.dart`
- `lib/screens/Notation/desktop_notation_host.dart`
- `lib/screens/Notation/music_analysis_ffi.dart`
- `lib/screens/Notation/notation_settings.dart`
- `lib/screens/Others/ui/pages/share_app.dart`
- `lib/screens/Players/controller/audio_player_controller.dart`
- `lib/screens/Players/library/device_audio_scan.dart`
- `lib/screens/Players/providers/audio_player_provider.dart`
- `lib/screens/Players/services/video_audio_export.dart`
- `lib/screens/Players/ui/components/search_bar.dart`
- `lib/screens/Players/ui/pages/video_crop_page.dart`
- `lib/screens/Players/ui/pages/video_player_page.dart`
- `lib/screens/Players/ui/pages/video_settings_page.dart`
- `lib/screens/Site/chat_media.dart`
- `lib/screens/Social/story_composer.dart`
- `lib/screens/Tuner/audio/desktop_pitch_input.dart`
- `lib/screens/Tuner/audio/pitch_input_native.dart`
- `lib/screens/Tuner/controller/tuner_provider.dart`
- `lib/screens/Voice Recorder/provider/voice_recorder_provider.dart`
- `lib/screens/Voice Recorder/services/file_service_native.dart`
- `lib/screens/Voice Recorder/services/playback_service.dart`
- `lib/screens/Voice Recorder/services/recording_waveforms.dart`
- `lib/screens/Voice Recorder/ui/pages/record_details_page.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/desktop_audio_duration_test.dart`
- `test/desktop_audio_platform_test.dart`
- `test/desktop_media_files_test.dart`
- `test/desktop_pitch_test.dart`
- `test/media_crop_story_revision_test.dart`
- `tool/build_windows_offline.ps1`
- `tool/prepare_windows_plugins.ps1`
- `windows/CMakeLists.txt`
- `windows/flutter/generated_plugin_registrant.cc`
- `windows/flutter/generated_plugins.cmake`
- `windows/runner/CMakeLists.txt`
- `windows/runner/desktop_services.cpp`
- `windows/runner/desktop_services.h`
- `windows/runner/flutter_window.cpp`
- `windows/runner/flutter_window.h`
- `windows/runner/main.cpp`



- `windows/patch_audio_service.cmake`

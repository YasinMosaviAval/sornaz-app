# دسترسی عمومی نت‌نویسی و انتقال به انتشار

در ۲۰۲۶/۱۱/۱۳ ورودی نت‌نویسی در ابزارها، مسیر مستقیم صفحه و انتخاب لیست‌ها برای همهٔ کاربران باز شد. مهمان می‌تواند از دادهٔ محلی استفاده کند؛ احراز هویت سرور، مالکیت نت‌ها و جداسازی حافظه بر اساس شناسهٔ حساب حفظ شده‌اند. OMR و تحلیل آزمایشی در توسعه همچنان مخصوص مدیر هستند. طبق انتخاب کاربر، کد OMR و تحلیل آزمایشی وارد شاخهٔ انتشار نشده است.

در worktree شاخهٔ `release/google-play-v1` فایل‌های ویرایشگر، دارایی‌های `assets/notation/`، فونت Bravura و مجوز آن، میزبان‌های Android/Web/Windows، تنظیمات، دیالوگ‌های مشترک، پیانوی مشترک و مسیرهای ذخیره/PDF منتقل شدند. آداپتور پیانوی تیونر نیز از همان ویجت استفاده می‌کند. تنظیمات نسخه، شناسه و امضای برنامه و مقصدهای گفت‌وگو/حساب کاربری شاخهٔ انتشار حفظ شدند. فایل AGENTS.md هیچ شاخه‌ای منتقل نشد. کامیت، push یا ساخت APK انجام نشده است.

شاخهٔ انتشار برای Windows آداپتور محدود `lib/helpers/desktop_media_channel.dart` فقط برای ذخیرهٔ نت دارد؛ کد رسانه و تحلیل آزمایشی توسعه منتقل نشده است. کلاس‌های Android جدید `NotationStorage` و `NotationPdf` و callbackهای چاپ در MainActivity ثبت شده‌اند. میزبان iOS ثبت موجود NotationStorage را حفظ و فونت چاپ را از دارایی همان نسخه دریافت می‌کند. وابستگی بستهٔ جدید یا تغییر lockfile لازم نیست.

نقطهٔ واحد ضرب در ابتدای قطعه و بالای میزان‌ها در مختصات SVG خود سر نت رسم می‌شود. تابع مشترک `NotationSymbols.beat` در نمایش ابتدای قطعه و چاپ، و مختصات همان glyph در میزان‌های میانی استفاده می‌شوند. فونت Bravura در سند چاپ معرفی و در چاپ iOS در HTML جاسازی شده است. دارایی‌های ویرایشگر توسعه و انتشار یکسان‌اند.

آزمون‌ها: دسترسی مهمان/کاربر عادی/مدیر در هر دو شاخه، منوی انتشار و حفظ مقصدهای گفت‌وگو/حساب، کاتالوگ‌های آفلاین و حفظ دادهٔ چندسازه/چندقسمتی، تأیید حذف، نوار بالا و پیانوی مشترک بررسی شدند. آزمون مرورگری با `NOTATION_ASSETS` روی دارایی‌های انتشار، ساختار تب‌ها، پخش نماهای کامل، ارتفاع ابزارها، حالت فقط‌خواندنی و هندسهٔ شاهین را بررسی می‌کند. `tools/notation_beat_alignment_check.cjs` هم‌ترازی نقطه با سر نت را برای همهٔ کشش‌ها در نمایش و چاپ بررسی می‌کند. تحلیل Dart خطا یا هشدار ندارد؛ پیام‌های info موجود دربارهٔ سبک کد و context در میزبان‌ها باقی هستند.

وب: دو فایل `Modules/Analytics/Resources/Views/sections/sidebar.php` و `Modules/Analytics/Services/MobilePanelNavigation.php` منوی نت‌نویسی را برای کاربران مجاز پنل نشان می‌دهند. تغییر دسترسی فقط منو است و کنترل مالکیت API دست‌نخورده است. انتشار این دو فایل migration ندارد؛ بازگشت با نسخهٔ پیشین آن‌هاست. پس از بارگذاری، ورود با حساب عادی، بازشدن نت‌نویسی و رد ویرایش نت متعلق به حساب دیگر بررسی شود. برای دسترسی به آخرین امکانات، سرویس Notation و دارایی‌های وب باید با قرارداد موجود schema 3 سازگار باشند.

تست واقعی روی Android/iOS و خروجی فایل PDF در این محیط انجام نشده است. مشکل پیشین شروع با صفحهٔ سیاه در نسخهٔ Release نیز بدون آزمون دستگاه واقعی تأییدشده محسوب نمی‌شود؛ انتقال سورس به شاخهٔ انتشار، تأیید آماده‌بودن برای انتشار عمومی نیست.

## Release file inventory

- `android/app/src/main/kotlin/com/example/sornaz/MainActivity.kt`
- `ios/Runner/AppDelegate.swift`
- `ios/Runner/NotationStorage.swift`
- `lib/components/settings_switch_tile.dart`
- `lib/screens/Home/ui/pages/music_tools.dart`
- `lib/screens/Players/services/player_settings.dart`
- `lib/screens/Site/panel_navigation.dart`
- `lib/screens/Site/site_panel_page.dart`
- `lib/screens/Tuner/ui/components/piano_keyboard.dart`
- `pubspec.yaml`
- `test/release_navigation_test.dart`
- `android/app/src/main/kotlin/android/print/NotationPrintCallbacks.kt`
- `android/app/src/main/kotlin/com/example/sornaz/NotationPdf.kt`
- `android/app/src/main/kotlin/com/example/sornaz/NotationStorage.kt`
- `assets/notation/fonts/Bravura.otf`
- `assets/notation/fonts/LICENSE.txt`
- `assets/notation/importer.js`
- `assets/notation/index.html`
- `assets/notation/model.js`
- `assets/notation/notation.css`
- `assets/notation/notation.js`
- `assets/notation/piano_style.js`
- `assets/notation/score_renderer.js`
- `assets/notation/ui_controls.css`
- `assets/notation/ui_controls.js`
- `assets/notation/ui_glyphs.js`
- `assets/notation/ui_symbols.js`
- `assets/notation/vendor/VEXFLOW-LICENSE`
- `assets/notation/vendor/vexflow.js`
- `lib/components/app_async_state.dart`
- `lib/components/app_dialog.dart`
- `lib/components/app_piano_keyboard.dart`
- `lib/components/app_text_input_dialog.dart`
- `lib/components/music_accidental_glyph.dart`
- `lib/components/piano_keyboard_spec.dart`
- `lib/helpers/desktop_media_channel.dart`
- `lib/screens/Notation/browser_notation_host.dart`
- `lib/screens/Notation/browser_notation_stub.dart`
- `lib/screens/Notation/browser_notation_web.dart`
- `lib/screens/Notation/desktop_notation_host.dart`
- `lib/screens/Notation/music_sheets_page.dart`
- `lib/screens/Notation/notation_api.dart`
- `lib/screens/Notation/notation_delete_confirmation.dart`
- `lib/screens/Notation/notation_list_dialog.dart`
- `lib/screens/Notation/notation_piano_keyboard.dart`
- `lib/screens/Notation/notation_settings.dart`
- `lib/screens/Notation/notation_top_bar.dart`
- `lib/screens/Players/ui/components/music_playback_entry.dart`
- `test/notation_delete_confirmation_test.dart`
- `test/notation_instruments_api_test.dart`
- `test/notation_public_access_test.dart`
- `test/notation_scales_api_test.dart`
- `test/notation_top_bar_test.dart`
- `test/shared_piano_keyboard_test.dart`
- `tools/notation_beam_geometry_check.cjs`
- `tools/notation_beat_alignment_check.cjs`
- `tools/notation_breadcrumb_check.cjs`

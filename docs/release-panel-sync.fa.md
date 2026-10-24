# انتقال انتخابی پنل به نسخه انتشار — ۲۰۲۶/۱۰/۲۴

منبع تغییرات پنل: `main` در `57a1802`؛ پایهٔ نسخه انتشار: `b44f93e`.
این انتقال merge کامل main نیست. فایل AGENTS.md مخصوص انتشار حفظ شده است.

## رفتار منتقل‌شده

- منوی احراز‌شدهٔ وب و تب‌های داخلی منابع، از جمله تب‌های نوشته‌ها، رسانه و دیدگاه‌ها.
- فرم‌ها و قراردادهای نسخه دوم جدول، فیلتر، جزئیات و عملیات مجاز؛ ثبت‌نام و تعیین هنرجو، مدرس و کلاس.
- حساب کامل یکپارچه در مسیر فعلی حساب، کاور، دعوت، حریم خصوصی، امنیت و مدیریت دستگاه‌ها.
- داشبورد، امور مالی و خروجی XLSX/PDF، مدیریت سازمان و گالری، حضور و غیاب و لغو جلسه.
- تقویم هفتگی با کنترل‌های مشترک و نمودارهای بومی ردیابی کاربران.

شناسه `com.sornaz`، امضای رسمی، شماره نسخه، پیکربندی backend، تب گفتگو و مقصد حساب نسخه انتشار تغییر نکرده‌اند.
منوی نت‌نویسی آزمایشی در این worktree حذف می‌شود؛ فایل‌های OMR و تحلیل آزمایشی منتقل نشده‌اند.
helper کنترل مخاطب فقط برای رفتار موجود حساب به کار می‌رود و هیچ صفحه آزمایشی به انتشار اضافه نمی‌کند.

## وابستگی و آماده‌سازی

`fl_chart: 1.2.0` با مجوز MIT برای نمودار ردیابی لازم است؛ `equatable: 2.1.0` وابستگی غیرمستقیم آن است.
این دو بسته با کش منتقل‌شده و `flutter pub get --offline` حل شدند. نسخه‌های قبلی بسته‌ها حفظ شده‌اند.
فایل‌های pubspec.yaml و pubspec.lock باید همراه کد منتقل شوند؛ روی سیستم دیگر پس از انتقال،
در محیط فعال مناسب اجرا کنید:

```powershell
flutter pub get --offline --enforce-lockfile
```

در این سیستم، برای کار با SDK موجود، PATH مربوط به Git و Flutter بسته و PUB_CACHE همان بسته
در نشست آزمون انتخاب شده‌اند. اسکریپت Activate-Offline.ps1 مربوط به پروژه توسعه با شناسه
`com.example.sornaz` است؛ آن را برای دورزدن محافظ شناسه روی Release تغییر ندهید.
آزمون‌های Dart به تغییر شناسه یا نصب کلید Debug روی Release نیاز ندارند.

## اعتبارسنجی

تحلیل نهایی lib و test بدون error یا warning و با exit code صفر موفق شد؛ ۷۰۵ پیام info سبکی در کل این دو پوشه باقی است. تحلیل کل مخزن همچنین ابزار داخلی Cargokit را که وابستگی‌های مستقلش آماده نشده‌اند بررسی می‌کند؛ آن نتیجه با تحلیل کد اپلیکیشن یکی نیست.

۱۷۹ تست پنل، حساب، فرم، تقویم، قراردادهای API، دسترسی و مسیریابی انتشار موفق شدند:

```powershell
$tests = @(Get-ChildItem test/panel*_test.dart | ForEach-Object { $_.FullName })
$tests += @(
  'test/dashboard_account_cards_test.dart',
  'test/unified_account_page_test.dart',
  'test/account_plain_sections_test.dart',
  'test/account_production_ui_test.dart',
  'test/branches_mobile_layout_test.dart',
  'test/jalali_date_picker_test.dart',
  'test/app_line_chart_test.dart',
  'test/release_navigation_test.dart'
)
flutter test --no-pub --dart-define=RELEASE_UI=true @tests
flutter analyze --no-pub --no-fatal-infos lib test
```

fixtureهای قدیمی با viewport کافی برای جدول، عنوان فعلی کنترل‌ها، دکمه ذخیره پایین فرم و
قرارداد فعلی جدول هماهنگ شدند. تست باریک ۳۲۰ و ۴۳۰ پیکسل و تست منع ویرایش سطر فقط‌خواندنی حفظ شده‌اند.
تست نامرتبط تماس از مجموعه منتقل‌شده کنار گذاشته شد و کد صفحه تماس تغییر نکرد.
تست جدید انتشار، حذف مقصد نت‌نویسی آزمایشی، حفظ منابع مجاز و رد منوی بدون قرارداد را می‌سنجد.

APK/AAB ساخته نشده، نصب و شروع روی دستگاه، سرویس پیامک/ایمیل و عملیات واقعی حساب یا مالی آزموده نشده‌اند.
موفقیت این تست‌ها تأیید آماده‌بودن برای انتشار عمومی یا رفع مشکل قبلی شروع سیاه روی دستگاه نیست.

## بررسی دستی پیش از انتشار

با داده آزمایشی و API سازگار، ورود و تغییر حساب، منوی هر سه نوع حساب، رد عملیات فاقد مجوز،
ثبت‌نام و تأیید تکراری، تقویم چندشعبه، ذخیره حریم خصوصی و خروجی‌ها روی دستگاه بررسی شوند.
انتشار وب یا migration در این کار انجام نشده است. کاتالوگ پنل سرور باید navigationVersion=1 و قراردادهای فرم/عملیات متناظر را ارائه کند.

## فایل‌های این مجموعه

- `lib/components/app_top_bar_direction.dart`
- `lib/components/charts/app_line_chart.dart`
- `lib/components/jalali_date_picker.dart`
- `lib/helpers/account_presentation.dart`
- `lib/helpers/development_access.dart`
- `lib/screens/Site/branch_color_picker.dart`
- `lib/screens/Site/branches_page.dart`
- `lib/screens/Site/panel_access_badges.dart`
- `lib/screens/Site/panel_account.dart`
- `lib/screens/Site/panel_api.dart`
- `lib/screens/Site/panel_caption.dart`
- `lib/screens/Site/panel_dashboard.dart`
- `lib/screens/Site/panel_filter_contract.dart`
- `lib/screens/Site/panel_finance.dart`
- `lib/screens/Site/panel_form.dart`
- `lib/screens/Site/panel_form_contract.dart`
- `lib/screens/Site/panel_gallery.dart`
- `lib/screens/Site/panel_national_holiday_settings.dart`
- `lib/screens/Site/panel_navigation.dart`
- `lib/screens/Site/panel_organization_filter.dart`
- `lib/screens/Site/panel_page_guidance.dart`
- `lib/screens/Site/panel_parity.dart`
- `lib/screens/Site/panel_presentation.dart`
- `lib/screens/Site/panel_resource_page.dart`
- `lib/screens/Site/panel_schedule_cancellation.dart`
- `lib/screens/Site/panel_schedule_contract.dart`
- `lib/screens/Site/panel_schedule_week.dart`
- `lib/screens/Site/panel_section_card.dart`
- `lib/screens/Site/panel_table_contract.dart`
- `lib/screens/Site/panel_term_attendance.dart`
- `lib/screens/Site/panel_tracking.dart`
- `lib/screens/Site/panel_ui.dart`
- `lib/screens/Site/panel_web_contracts.dart`
- `lib/screens/Site/site_panel_page.dart`
- `lib/screens/Social/social_learning.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/account_plain_sections_test.dart`
- `test/account_production_ui_test.dart`
- `test/app_line_chart_test.dart`
- `test/branches_mobile_layout_test.dart`
- `test/dashboard_account_cards_test.dart`
- `test/fixtures/panel_dialog_contracts.json`
- `test/fixtures/panel_table_contracts.json`
- `test/jalali_date_picker_test.dart`
- `test/panel_dialog_contract_test.dart`
- `test/panel_filter_contract_test.dart`
- `test/panel_finance_expansion_test.dart`
- `test/panel_new_web_workflows_test.dart`
- `test/panel_organization_live_test.dart`
- `test/panel_page_tabs_test.dart`
- `test/panel_parity_completion_test.dart`
- `test/panel_recent_web_changes_test.dart`
- `test/panel_remaining_parity_test.dart`
- `test/panel_request_budget_test.dart`
- `test/panel_requested_improvements_test.dart`
- `test/panel_schedule_views_test.dart`
- `test/panel_shared_layout_test.dart`
- `test/panel_sidebar_contract_test.dart`
- `test/panel_table_contract_test.dart`
- `test/panel_term_assignment_wizard_test.dart`
- `test/panel_top_bar_actions_test.dart`
- `test/panel_visual_revision_test.dart`
- `test/panel_web_parity_test.dart`
- `test/release_navigation_test.dart`
- `test/unified_account_page_test.dart`

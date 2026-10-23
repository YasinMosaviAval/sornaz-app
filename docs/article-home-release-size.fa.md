# خانهٔ مقالات و کاهش حجم انتشار — ۲۰۲۶/۱۰/۲۳

## رفتار جدید

در main، خانه برای مهمان و کاربران غیرمدیر فهرست مقالات است. مدیر سایت طبق سیاست موجود DevelopmentAccess (حساب احرازشدهٔ ID=1 با token معتبر) خانهٔ قبلی را دارد. در release/google-play-v1 همهٔ کاربران، از جمله مدیر، خانهٔ مقالات را دارند. عنوان تب پایین همچنان «خانه» است.

منو، لوگو و چیدمان HomeTopBar حفظ شده‌اند؛ هدر دارای Back صفحهٔ مستقل مقالات وارد خانه نشده است. جست‌وجو اکنون مقالات را فیلتر می‌کند. ArticleProgressBackground به نوار خانه اضافه شده و Scrollbar تعاملی با شعاع مشترک برنامه برای اسکرول سریع وجود دارد. هر صفحه کنترلر اسکرول مستقل دارد تا بازکردن فهرست مستقل از خانه باعث اتصال چند لیست به یک کنترلر نشود. فیلتر و جست‌وجو اسکرول را به ابتدا می‌برند؛ پروگرس پس از جست‌وجو صفر می‌شود.

تایپوگرافی جست‌وجو از theme مشترک گرفته می‌شود. سرریز گذرای دکمهٔ فیلتر در انیمیشن جست‌وجوی خانهٔ مدیر هم اصلاح شده است. فاصلهٔ افقی کارت‌ها و فیلترهای مقالات 12dp و شعاع‌ها از تنظیمات مشترک هستند. تم اختصاصی اضافه نشده است.

## خروجی‌های نهایی

هر دو با شناسهٔ com.sornaz، نسخهٔ 1.0.0+2 و کلید upload موجود ساخته شده‌اند:

- `release_outputs/1.0.0+2/articles-home-final/sornaz-1.0.0+2-all-abis.aab`
- `release_outputs/1.0.0+2/articles-home-final/sornaz-1.0.0+2-arm64.aab`

گزارش دقیق اندازه، SHA-256، معماری‌ها، گواهی و بررسی‌ها در verification.json کنار این دو فایل قرار دارد. این‌ها دو گزینهٔ جایگزین‌اند و برای انتخاب یکی آماده شده‌اند؛ چیزی در Google Play بارگذاری نشده است.

## علت حجم و پاک‌سازی

اندازهٔ AAB قبلی 134.43 MiB بود. اندازه‌گیری آرشیو نشان داد حدود 39.76 MiB نمادهای عیب‌یابی native، حدود 73.3 MiB کتابخانه‌های سه معماری و حدود 9.55 MiB صوت تمرین فاصله هستند. بنابراین فرض اینکه 70–80٪ حجم مربوط به امکانات حذف‌شده است با محتوای فایل مطابقت نداشت.

فقط در release، 487 فایل حذف شد: 451 asset، 20 فایل Dart مربوط به نت‌نویسی و تمرین فاصله، دو فایل Kotlin نت‌نویسی و تست‌های منسوخ همان بخش‌ها. تست ناوبری موجود در فایل مشترک main_tabs_notation_test.dart حفظ شد. مسیرهای زیر پاک‌سازی شدند:

- assets/notation و فایل‌های صوتی interval_piano، interval_guitar، interval_violin، interval_viola و interval_cello و اعلان مجوز مخصوص آن‌ها.
- lib/screens/Notation و lib/screens/IntervalRecognition و صفحهٔ غیرقابل‌دسترسی solfege_practice_page.dart.
- NotationStorage.kt و NotationPdf.kt و اتصالشان در MainActivity.
- ثبت assetهای حذف‌شده در pubspec.yaml.

تمام این بخش‌ها در main حفظ شده‌اند؛ OMR و تحلیل عملکرد آزمایشی توسعه تغییر نکرده‌اند. بررسی پس از پاک‌سازی، با decode مسیرهای import دارای فاصله، 235 فایل قابل‌دسترسی و صفر import شکسته یا ارجاع به ماژول‌های حذف‌شده نشان داد. فایل import-audit-after-cleanup.json در release_outputs/size-audit ثبت شده است. اسکن اولیهٔ قبل از decode فقط تشخیصی بود و مبنای حذف ضبط صدا قرار نگرفت؛ ضبط صدا حفظ شده است.

FFmpeg حذف نشده چون VideoAudioExport در قابلیت منتشرشدهٔ تبدیل ویدیو به صدا به آن نیاز دارد. flutter_pitch_detection نیز حفظ شده: تیونر به‌جای import مستقیم Dart، کانال native آن را فراخوانی می‌کند. حذف براساس نام package یا صرفاً نبود import مستقیم می‌توانست تیونر را خراب کند. فونت‌های قابل انتخاب، پخش‌کننده‌ها، ضبط، تیونر، مترونوم و منابعشان حفظ شده‌اند.

Flutter در حالت target-platform=android-arm64 به‌تنهایی native libraryهای سایر افزونه‌ها را نگه می‌داشت. برای BundleArm64 از فیلتر صریح arm64-v8a در Android و گزینهٔ مستند جلوگیری از بازنویسی این فیلتر توسط Flutter استفاده شده؛ خروجی نهایی از نظر ABI بررسی می‌شود. حالت Bundle همهٔ معماری‌ها را حفظ می‌کند.

تلاش برای debugSymbolLevel=NONE با کنترل نهایی Flutter 3.47.2 شکست خورد، چون آن کنترل وجود .sym را معیار قرار می‌دهد. تغییر پیشنهادی برای جایگزینی این کنترل با بررسی سفارشی در بازبینی خودکار رد شد و اجرا نشد. ساخت نهایی با SYMBOL_TABLE و تمام کنترل‌های استاندارد Flutter موفق شد؛ SDK یا کنترل‌های Flutter دست‌کاری نشده‌اند. نمادهای عیب‌یابی برای مسیر استاندارد نگه داشته شده‌اند و در دانلود معمول گوشی محاسبه نمی‌شوند.

## تست‌ها

- main: home_articles_test، home_revision_test و development_audience_test موفق؛ حفظ خانهٔ مدیر و دسترسی امکانات آزمایشی بررسی شد.
- هر دو شاخه: شش تست چیدمان خانه در عرض‌های 320، 375 و 430 و دو تم؛ موفق.
- هر دو شاخه: نه تست site_panel_academy_test با انتظار جدید خانه؛ موفق.
- release: خانهٔ مقالات برای مهمان، ID=2 و ID=1؛ جست‌وجو، بازنشانی پروگرس، اسکرول و بازکردن فهرست مستقل؛ موفق.
- release: release_navigation_test، تست ناوبری حفظ‌شده، drawer_accounts_test و video_audio_export_test؛ موفق.
- تحلیل ایستا در فایل‌های رابط تغییرکرده: بدون error یا warning؛ 11 پیام info مربوط به قواعد سبک، عمدتاً کد خانهٔ قدیمی، باقی است.
- یک تست قدیمی نامرتبط در profile_home_test به نام dashboard uses real completion counts and opens saved courses هنوز قرارداد قدیمی Social API و تب ذخیره‌شده‌ها را انتظار دارد، درحالی‌که AccountDashboardBody فعلی از PanelApi استفاده می‌کند؛ اجرای اولیهٔ آن شکست خورد. کد حساب کاربری برای این درخواست تغییر نکرد و موفقیت کل مجموعهٔ تست‌ها ادعا نمی‌شود. تست‌های چیدمان خانهٔ همین فایل جداگانه اجرا و موفق شدند.

## فایل‌های اصلی تغییرکرده

در هر دو شاخه: articles_page.dart، articles_list.dart، article_item.dart، expanding_search_bar.dart، learning_home.dart و تست‌های مرتبط. در انتشار AppScrollBehavior از main انتخابی منتقل شد.

فقط انتشار: pubspec.yaml، تنظیم ABI و SYMBOL_TABLE در android/app/build.gradle، پاک‌سازی MainActivity و فایل‌های بالا، حالت BundleArm64 و کنترل ABI در scripts/build_android.ps1 و مستندات.

## حدود تأیید و انتقال

پاک‌سازی فقط مخصوص انتشار است و نباید به main منتقل شود. تغییر UI از ابتدا در main پیاده و سپس انتخابی به انتشار اعمال شد؛ انتقال UI انجام شده است. هیچ وابستگی جدید به OMR/تحلیل آزمایشی اضافه نشده و هیچ AGENTS.md جایگزین نشده است.

applicationId، کلید امضا و backend همان تنظیمات تأییدشدهٔ قبلی‌اند. وب تغییر نکرد. فایل key.properties محلی و خارج از Git است. خروجی‌های قبلی برای سابقه حفظ شدند و وارد AAB جدید نمی‌شوند. هیچ commit یا push انجام نشده است.

آزمون واقعی از مسیر Google Play و دستگاه با صفحهٔ حافظهٔ 16KB باقی است. تأیید این گزارش مربوط به ساخت، تست‌های ذکرشده، هم‌ترازی استاتیک و گوشی Samsung متصل است و به معنی پذیرش خودکار فروشگاه یا تأیید همهٔ دستگاه‌ها نیست.
## نتیجهٔ نهایی ثبت‌شده

| خروجی | اندازهٔ AAB (MiB) | معماری‌ها | دانلود برآوردشدهٔ همین گوشی (بایت) |
|---|---:|---|---:|
| all-abis | 124.12 | arm64-v8a, armeabi-v7a, x86_64 | @{value=31352292,31352292; PSPath=C:\dev\workspace\android\flutter\sornaz-app-release\release_outputs\1.0.0+2\20261023-112354-687-7af217\device-download-size.csv; PSParentPath=C:\dev\workspace\android\flutter\sornaz-app-release\release_outputs\1.0.0+2\20261023-112354-687-7af217; PSChildName=device-download-size.csv; PSDrive=; PSProvider=; ReadCount=2} |
| arm64 | 46.09 | arm64-v8a | @{value=31352292,31352292; PSPath=C:\dev\workspace\android\flutter\sornaz-app-release\release_outputs\1.0.0+2\20261023-112837-053-39a883\device-download-size.csv; PSParentPath=C:\dev\workspace\android\flutter\sornaz-app-release\release_outputs\1.0.0+2\20261023-112837-053-39a883; PSChildName=device-download-size.csv; PSDrive=; PSProvider=; ReadCount=2} |

هر دو AAB با bundletool اعتبارسنجی شدند؛ jarsigner امضا را تأیید کرد. 30 کتابخانهٔ ELF64 در نسخهٔ همهٔ معماری‌ها و 15 کتابخانه در ARM64 هم‌ترازی حداقل16KB داشتند. امضای چهار split هر گزینه و هم‌ترازی ZIP آن‌ها تأیید شد. هیچ asset مربوط به interval یا notation در AAB نهایی باقی نمانده است.

هر دو گزینه از همان AAB نهایی به splitهای گوشی تبدیل و با نسخهٔ2 روی Samsung SM-A266B به‌روزرسانی شدند؛ داده‌های برنامه پاک نشد. UI مقالات، اسکرول سریع و پیشرفت topBar دیده شد. در نسخهٔ ARM64 نهایی، جست‌وجوی Music نتیجهٔ خالی داد و پس‌زمینهٔ پروگرس به صفر برگشت؛ بستن جست‌وجو مقالات و عنوان خانه را بازگرداند. در لاگ بررسی‌شده خطای بحرانی Flutter/Android ثبت نشد. تصاویر در device-evidence کنار فایل‌هاست.

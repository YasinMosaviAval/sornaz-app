# میزان‌نمای مستقل بخش‌ها در وب و Flutter

در فرم شروع و ویرایش مشخصات، گزینهٔ «عدم تغییر میزان» با نماد دایره و خط حذف شده است. این فرم همیشه یک میزان‌نمای واقعی، حالت دستی یا «میزان آزاد (بدون میزان)» دارد. گزینهٔ وراثت در ابزار تغییر میزان داخل نت حفظ شده است؛ حذف فقط به دو فرم مشخصات مربوط است.

هر قسمت یا زیربخش اکنون میزان مستقل دارد. مثلاً در یک قطعه می‌توان زیربخش اول را ۴/۴، زیربخش بعد را آزاد و قسمت بعد را ۳/۴ نوشت. بخش یا زیربخش خالی بسازید، مشخصات آن را باز کنید و میزان‌نما را انتخاب کنید؛ تغییر، نت‌ها یا میزان بخش‌های دیگر را بازنویسی نمی‌کند. تغییر بین حالت آزاد و میزان‌بندی برای بخش دارای نت عمداً رد می‌شود؛ برای این تغییر، بخش خالی انتخاب یا ایجاد کنید. تغییر عددی میزان‌نما نیز باید با ظرفیت نت‌های همان بخش سازگار باشد.

ذخیره و بازگشایی، JSON، پخش «کل قسمت/کل نت»، نمای تمام سازها و PDF ترکیب مترها را حفظ می‌کنند. در بخش آزاد، زمان هر نت/سکوت مستقل از تمپو است؛ میزان‌نما، خط میزان و سکوت تکمیل‌کننده رسم نمی‌شوند. بخش عددی پس از بخش آزاد دوباره میزان‌نما و رفتار عادی خود را دارد. نام سازها در نمای تمام سازها حفظ می‌شود. MusicXML برای قطعه‌ای که هر بخش آزاد دارد با پیام روشن به JSON/PDF ارجاع می‌دهد.

## قرارداد و ایمنی داده

- `metadata.time` پیش‌فرض ساز است؛ `score.time`، `score.sections[].time` و `score.subsections[].time` مقدار اختیاری مستقل هر بخش/زیربخش‌اند. زیربخش‌های داخل قسمت‌های دیگر نیز همین قرارداد را دارند.
- مقدار حذف‌شده از قرارداد قدیمی، پیش‌فرض همان ساز را استفاده می‌کند؛ رشتهٔ خالی، null و میزان‌نمای نامعتبر رد می‌شوند. بخش تازه، متر بخش فعلی را به‌عنوان مقدار آغازین می‌گیرد. هنگام ذخیرهٔ UI، override برابر پیش‌فرض حذف می‌شود تا دادهٔ تکراری نماند.
- اتصال بخش‌ها فقط نسخهٔ نمایشی را می‌سازد و تغییر واقعی متر را در مرز بخش نگه می‌دارد. نت‌ها، موقعیت‌ها و ساختار اصلی داده عوض نمی‌شوند. مدل و رندر هر دو متر مؤثر همان بخش/میزان را می‌خوانند.
- `notation_schema` همچنان ۳ است. نویسندهٔ سازگار با این قابلیت، `notation_section_meters: true` می‌فرستد. سرور بازنویسی قطعهٔ دارای override را از کلاینت قدیمی بدون این اعلام قابلیت با ۴۰۹ رد می‌کند؛ مالکیت و نسخهٔ هم‌زمان نیز همچنان بررسی می‌شوند. این پرچم مجوز امنیتی نمی‌دهد.
- آداپتور وب و Dart پرچم سازگاری را در آپلود صریح می‌فرستند. ذخیرهٔ محلی به‌تنهایی درخواست نوشتن به سرور نمی‌فرستد و جداسازی حساب‌ها باقی است.
- تصحیح نوشتاری، متر مؤثر بخش عددی را می‌خواند و بخش آزاد را رد می‌کند. جدول، ستون، کلاس، migration یا وابستگی تازه‌ای نداریم.

## انتشار وب

ابتدا نسخهٔ پشتیبان سازگار بگیرید. دو PHP زیر باید پیش از فعال‌شدن رابط یا اپ جدید روی سرور حاضر باشند. سپس دارایی‌ها ترجیحاً اتمی جایگزین شوند:

1. `Modules/Notation/Services/NotationService.php`
2. `Modules/Education/Services/MusicPracticeNotation.php`
3. `assets/notation/model.js`
4. `assets/notation/importer.js`
5. `assets/notation/score_renderer.js`
6. `assets/notation/web_storage.js`
7. `assets/notation/notation.js`

این تغییر بر پایهٔ بستهٔ کامل متر آزاد است. اگر اصلاح قبلی منوی آن هنوز منتشر نشده، `assets/notation/ui_glyphs.js`، `assets/notation/ui_controls.js`، `assets/notation/ui_controls.css` و `assets/notation/notation.css` نیز باید همراه همان نسخه حاضر باشند. قالب موجود PHP دارایی‌ها را نسخه‌گذاری می‌کند؛ صفحه‌های باز قدیمی برای ویرایش دادهٔ جدید باید مجدداً بارگذاری شوند. وابستگی Composer و تنظیمات محیطی تغییر نکرده است.

## انتقال انتخابی Flutter

در worktree توسعه پیاده شده است. برای انتقال همراه با پشتیبانی متر آزاد، این فایل‌های runtime با هم منتقل شوند:

- هشت فایل `assets/notation/model.js`، `importer.js`، `score_renderer.js`، `notation.js`، `notation.css`، `ui_glyphs.js`، `ui_controls.js` و `ui_controls.css`.
- `lib/screens/Notation/notation_api.dart` برای پرچم سازگاری آپلود.

آزمون‌های `test/notation_free_meter_api_test.dart`، `tools/notation_section_meters_model_check.cjs` و `tools/notation_section_meters_check.cjs` و راهنما نیز منتقل شوند. پیش‌نیازهای فعلی نت‌نویس، Bravura و پیانوی مشترک باید موجود باشند. هیچ وابستگی تازه به OMR یا تحلیل آزمایشی اضافه نشده؛ کد آن‌ها، `AGENTS.md`، شناسهٔ برنامه، امضا و تنظیمات backend تغییر نمی‌کنند. worktree انتشار تغییر نکرده و APK/AAB یا خروجی برنامه ساخته نشده است.

## بازگشت و آزمون پس از انتقال

پیش از ایجاد دادهٔ جدید، می‌توان مجموعهٔ runtime قبلی را هماهنگ بازیابی کرد. پس از ایجاد قطعهٔ مختلط، بازگشت کامل به خواننده یا اعتبارسنج قدیمی ایمن نیست؛ پشتیبانی جدید خواندن و محافظت نویسندهٔ قدیمی باید بماند. داده، ذخیرهٔ حساب یا JSON پشتیبان را حذف نکنید و برای اصلاح رابط از نسخه‌ای استفاده کنید که قرارداد بخش‌ها را حفظ می‌کند. سرور قدیمی ممکن است override را رد یا نادیده بگیرد؛ انتشار رابط/اپ پیش از PHP سازگار مجاز نیست. این محدودیت در برنامه‌ریزی بازگشت لحاظ شود.

روی سرور تست، قطعهٔ ۴/۴ با نت بسازید، زیربخش آزاد با زمان ۰٫۲۵ ثانیه و قسمت ۳/۴ اضافه کنید. در هر فرم، نبود گزینهٔ دایره و خط را بررسی کنید. ذخیرهٔ محلی، بازگشایی، آپلود، دریافت مجدد، انتخاب هر بخش، واگرد/ازنو، پخش کل و PDF باید مترها را حفظ کنند. نت ۴/۴ قدیمی هم باز و پخش شود. خواندن/ویرایش خصوصی توسط کاربر دیگر و ذخیرهٔ نسخهٔ قبلی باید رد شود. کلاینت قدیمی بدون اعلام قابلیت نباید دادهٔ مختلط را بازنویسی کند.

## آزمون‌های محلی

```sh
node scripts/notation_section_meters_test.cjs
php scripts/notation_section_meters_test.php
node scripts/notation_section_meters_browser_test.cjs
node tools/notation_section_meters_check.cjs
```

سه دستور اول در وب و دستور آخر در Flutter اجرا می‌شوند. مدل، JSON، پیش‌فرض آزاد با override عددی، بخش‌های چندسازه، اتصال بدون تغییر داده، زمان پخش و ورودی نامعتبر بررسی می‌شوند. آزمون PHP از SQLite موقت در حافظه برای save/show/update، رد کاربر دیگر، کلاینت قدیمی، نسخهٔ تکراری و حفظ اطلاعات استفاده می‌کند؛ فقط نحو `FOR UPDATE` در آداپتور آزمون حذف می‌شود. این آزمون تأیید قفل MySQL نیست. MySQL آزمایشی پورت ۳۳۱۹ در دسترس نبود.

هشت سناریوی مرورگر وب/اپ در فارسی/انگلیسی و عرض ۳۹۰/۱۲۸۰، انتخاب‌گر واقعی هر دو فرم، ساخت ۴/۴ + آزاد + ۳/۴، واگرد/ازنو، ذخیره/بازگشایی، پخش و PDF را بررسی می‌کنند. آزمون Dart نیز SharedPreferences و payload آپلود صریح مختلط را می‌سنجد؛ HTTP آن ساختگی است. آزمون‌های Flutter مرتبط موفق‌اند؛ تحلیل Dart خطا ندارد و فقط پیام سبکی موجود `avoid_single_cascade_in_expression_statements` در API گزارش می‌شود. نحو PHP/JavaScript و diff بررسی می‌شوند. آزمون واقعی دستگاه، چاپ سیستم‌عامل و سرور اصلی انجام نشده و چیزی منتشر نشده است.

پس از اصلاح نهاییِ حذف مقدار تکراری متر ریشه، هر هشت سناریوی مختلط و شانزده سناریوی متر آزاد (چهار وب و دوازده پل native اپ) دوباره موفق شدند. آزمون ذخیره تأیید می‌کند override برابر پیش‌فرض در ریشه نیز حذف می‌شود. آزمون PHP همچنین محاسبهٔ تمرین عددی با پیش‌فرض آزاد و رد بخش آزاد در تمرین را بررسی می‌کند. مجموع هفت مجموعهٔ مرتبط Flutter، ۲۹ آزمون موفق دارد. بررسی نگهداری PHP همچنان بدهی اندازهٔ متدهای موجود، از جمله `NotationService::validate`، را گزارش می‌کند؛ این بررسی موفق اعلام نمی‌شود.

مجموعهٔ کامل وب با `node scripts/run-release-tests.cjs --browser` در دو بخش اجرا و تکمیل شد: **۱۴۸ از ۱۵۵ مجموعه موفق**. هفت شکست همان موارد ثبت‌شدهٔ قبلی‌اند: `music-practice-integration-test.php` (فایل مفقود)، `music_practice_browser_test.cjs` (وابسته به همان فایل)، `sidebar_identity_render_test.php`، `notation_symbol_controls_browser_test.cjs`، `notation_shared_features_browser_test.cjs`، `panel_notation_form_browser_test.cjs` و `panel_notation_frame_browser_test.cjs`. تأیید کامل انتشار صادر نشده است. گزارش‌های محلی `storage/notation-section-meters-release-tests.log` و `storage/notation-section-meters-release-rest.log` و جمع‌بندی شمارش یکتای آزمون‌ها در `storage/notation-section-meters-release-result.json` هستند؛ شمارندهٔ ادامهٔ اجرا یک خلاصهٔ خطای تکراری PowerShell را نیز شمرده بود و نتیجهٔ تجمیعی این تکرار را حذف می‌کند. آزمون‌های اختصاصی پس از آخرین اصلاح runtime مجدداً موفق شدند.

## پیام کامیت پیشنهادی برای هر پروژه

این متن‌ها پیشنهادی‌اند؛ کامیت یا push انجام نشده است. تغییرات نامرتبط موجود نباید به این کامیت‌ها اضافه شوند.

وب:

```text
feat(notation): support independent meters across score sections

Remove the no-change time signature option from creation and metadata forms.
Allow sections and subsections to mix free and numeric meters while preserving
per-note seconds, JSON round trips, playback, instrument labels and PDF output.
Validate section overrides on the server and protect mixed scores from legacy
writers using an explicit client capability flag and existing version checks.
Add model, persistence, authorization and browser coverage plus deployment and
rollback instructions. Preserve compatibility with existing scores.
```

Flutter:

```text
feat(notation): add free and mixed section meters to the Flutter editor

Expose free meter in the native notation workflow and remove the no-change
option from creation and metadata forms. Support note and rest durations from
0.01 to 5 seconds and independent numeric or free meters for empty sections.
Preserve mixed meters through local storage, explicit uploads, playback and PDF,
and advertise section-meter support in upload requests.
Add native bridge, model and API persistence coverage and document selective
transfer requirements. Keep release identity and signing settings unchanged.
```

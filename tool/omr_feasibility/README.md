# آزمایش مستقل OMR

این پوشه یک نمونهٔ واقعی پردازش تصویر با Dart و `package:image` است. به رابط برنامه، دوربین یا ویرایشگر متصل نیست و مدل یادگیری ماشین اجرا نمی‌کند. ورودی آن پیکسل‌های PNG و خروجی‌اش JSON شامل حامل‌ها، کلیدهای احتمالی، سرنت‌ها، ارتفاع‌های احتمالی، خطوط میزان، گروه‌های آکورد احتمالی و موارد نامطمئن است. زمان‌بندی نت‌ها، سکوت‌ها و بیشتر کشش‌ها هنوز قابل استخراج نیستند؛ مقادیر مجهول در JSON برابر `null` یا `unresolved` هستند.

از همین پوشه اجرا کنید:

```powershell
dart pub get
dart printed_score_probe.dart treble.png
powershell -ExecutionPolicy Bypass -File test_probe.ps1
dart evaluate.dart
```

`fixture_ground_truth.json` دادهٔ مرجع دست‌نویس از تعریف قطعه‌ها در `render_fixtures.html` است و از خروجی موتور ساخته نشده است. هشت PNG چاپی با نسخهٔ VexFlow موجود در پروژه تولید شده‌اند: ملودی سل، ملودی فا، ریتم و سکوت، علائم تغییر ارتفاع، پیانو، آکورد پیانو، دو سیستم و تصویر خالی. `treble_skew3.png` چرخش سه‌درجه‌ای نمونهٔ ملودی است. برای بازتولید تصویرها در محیطی دارای Chrome و Dart:

```powershell
powershell -ExecutionPolicy Bypass -File generate_fixtures.ps1
dart evaluate.dart
```

نتایج اندازه‌گیری‌شده در `evaluation_results.json` و تفسیر و محدودیت‌ها در `../../OMR_ENGINE_DEVELOPMENT_REPORT.md` ثبت شده‌اند. این مجموعه فقط تصاویر تولیدشدهٔ تمیز دارد؛ عکس واقعی دوربین هنوز ارزیابی نشده است. معیار `pitchMultisetMatches` ترتیب رخدادها یا زمان‌بندی را نمی‌سنجد، بنابراین معیار دقت OMR کامل نیست.

تصویر قدیمی `scale.png` و دادهٔ مرجع `scale.expected.json` از `examples/` مخزن [Sheet-Music-Interpreter](https://github.com/Luckolite/Sheet-Music-Interpreter) در کامیت `eb301ffafc7a69d55c03f8ad7efbc6335666a944` هستند. مجوز Apache-2.0 در `UPSTREAM_LICENSE` و اطلاعیهٔ منبع در `UPSTREAM_NOTICE` حفظ شده‌اند. SHA-256 تصویر `3e9205cc2223f79f421b668d228aed5c501cb3ca136ab05eb09afc24d2a47cbd` است.

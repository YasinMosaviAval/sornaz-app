# آزمایش مستقل OMR

این پوشه به رابط کاربری و ویرایشگر برنامه متصل نیست. `printed_score_probe.dart` یک آزمایش پردازش تصویر کلاسیک است؛ مدل TensorFlow Lite را اجرا **نمی‌کند** و یک موتور کامل OMR نیست. تصویر `scale.png` و دادهٔ مرجع `scale.expected.json` از `examples/` مخزن [Sheet-Music-Interpreter](https://github.com/Luckolite/Sheet-Music-Interpreter) در کامیت `eb301ffafc7a69d55c03f8ad7efbc6335666a944` کپی شده‌اند. مجوز Apache-2.0 در `UPSTREAM_LICENSE` و اطلاعیهٔ منبع در `UPSTREAM_NOTICE` حفظ شده‌اند. SHA-256 تصویر `3e9205cc2223f79f421b668d228aed5c501cb3ca136ab05eb09afc24d2a47cbd` است.

با Dart و وابستگی `image` اجرا می‌شود. از همین پوشه:

```powershell
dart pub get
dart printed_score_probe.dart scale.png
powershell -ExecutionPolicy Bypass -File test_probe.ps1
```

خروجی JSON شامل خطوط حامل، سرنت‌ها، ارتفاع فرضی با کلید سل، خطوط میزان و زمان/حافظهٔ فرایند است. کلید واقعاً تشخیص داده نمی‌شود؛ `midiIfTreble` فقط نتیجهٔ فرض کلید سل است. مقدار `duration: null` به معنی نامشخص‌بودن کشش است. فهرست `unsupported` سایر قابلیت‌های پیاده‌سازی‌نشده را نشان می‌دهد.

گزارش نتیجه و محدودیت‌های آزمایش در `../../OMR_FEASIBILITY_REPORT.md` است.

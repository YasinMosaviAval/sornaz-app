# فرم‌های پنل مطابق وب

فایل‌های این تغییر در اپ: `lib/screens/Site/panel_api.dart`، `panel_form.dart`، `panel_form_contract.dart`، `panel_resource_page.dart` و `branch_color_picker.dart`؛ آزمون `test/panel_dialog_contract_test.dart` و fixture آن در `test/fixtures/panel_dialog_contracts.json`؛ و همین مستند. در وب: `Modules/Analytics/Services/MobilePanelCatalog.php`، `Modules/Analytics/Controllers/Api/MobilePanelController.php`، `scripts/mobile_panel_dialog_test.php`، `scripts/mobile_panel_test.php`، `scripts/run-release-tests.cjs` و `docs/mobile-dialog-parity-deployment.fa.md`.

تعریف فیلدها و شرط‌های فرم از کاتالوگ API می‌آید. اپ با هدر `X-Sornaz-Panel-Forms: 2` قرارداد جدید را درخواست می‌کند و برای عملیات دارای `formContractVersion: 2` فقط فیلدهای تعریف‌شده و قابل نمایش را ارسال می‌کند؛ فیلدهای ثابت و پنهان سازمان با `submitWhenHidden` حفظ می‌شوند. کلاینت و سرور قدیمی نیز مسیر قبلی را حفظ می‌کنند.

`panel_form_contract.dart` مقدار اولیه، گزینه‌های وابسته، نقش متناسب با قرارداد و سازمان، سطح‌های مجاز درس، شرط سن والد، شرط وضعیت ترم، اعتبارسنجی مجموعه‌ها، تاریخ‌وساعت و آماده‌سازی payload فرم‌های وب را انجام می‌دهد. ارسال موفق فرم جدید تنها یک‌بار انجام می‌شود؛ خطای API دیالوگ را نمی‌بندد و ورودی کاربر حفظ می‌شود. فیلدهای اضافهٔ قدیمی نظرسنجی نوشته به فرم جدید تحمیل نمی‌شوند؛ پشتیبانی قدیمی حفظ شده است.

`test/fixtures/panel_dialog_contracts.json` از کاتالوگ واقعی PHP ساخته شده و دادهٔ کاربر ندارد. دستور بازتولید و فایل‌های لازم سرور در `docs/mobile-dialog-parity-deployment.fa.md` پروژهٔ وب آمده‌اند. آزمون‌های `panel_dialog_contract_test.dart` انتخاب‌های وابسته، مقدار اولیهٔ ویرایش، حالت‌های شرطی، payload و ذخیرهٔ ناموفق/تلاش مجدد را با همین قرارداد بررسی می‌کنند.

رنگ، قلم و شعاع کنترل‌ها از ظاهر مشترک برنامه گرفته می‌شوند. وابستگی تازه‌ای نصب نشده و این قابلیت به OMR یا تحلیل عملکرد آزمایشی وابسته نیست. برای انتقال انتخابی، کد فرم‌ساز و API پنل، فایل تازهٔ قرارداد و آزمون/fixture آن همراه اصلاح کاتالوگ و کنترلر وب منتقل شوند. تغییرات قبلی و منتشرنشدهٔ پنل نیز باید در مقصد موجود باشند. هیچ بیلد یا انتشار روی سرور اصلی انجام نشده است؛ تأیید دیداری روی گوشی و آزمون یکپارچهٔ سرور تست هنوز لازم است.

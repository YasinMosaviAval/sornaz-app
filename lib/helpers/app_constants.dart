class AppConstants {
  // ثابت‌های API
  static const String apiBaseUrl = 'https://sornaz.com/wp-json/wp/v2/';
  static const String apiKey =
      'your_api_key_here'; // از environment variables لود کن برای امنیت

  // ثابت‌های UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;

  // Strings رایج (برای localization بهتره از app_localizations استفاده کن، اما اینجا نمونه)
  static const String appName = 'Sornaz Music App';
  static const String errorMessage = 'An error occurred. Please try again.';
  static const String loadingText = 'Loading...';

  // ثابت‌های مرتبط با موسیقی
  static const int maxPlaylistSize = 100;
  static const String defaultMusicImage = 'assets/images/default_music.png';

  // ثابت‌های روت‌ها (اگر از GoRouter استفاده می‌کنی، اینجا نگه دار)
  static const String routeHome = '/home';
  static const String routeProfile = '/profile';

  // ثابت‌های تم
  static const String fontFamily = 'Vazir';

  // می‌تونی ثابت‌های بیشتری اضافه کنی (مثل enums برای انواع موسیقی: pop, rock, etc.)
}

/*
Use Case


import 'package:sornaz_music_app/helpers/app_constants.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppConstants.appName)), // استفاده از string ثابت
      body: Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding), // استفاده از padding ثابت
        child: Text(AppConstants.loadingText), // نمایش متن لودینگ
      ),
    );
  }
}
*/



/*
لیست کامل APIهای REST وردپرس (پیش‌فرض)
سلام! وردپرس از نسخه ۴.۷ به بعد، یک REST API داخلی داره که endpoints (نقاط انتهایی) مشخصی رو ارائه می‌ده. این API بر پایه JSON کار می‌کنه و از آدرس /wp-json/ شروع می‌شه. لیست کامل endpoints پیش‌فرض (بدون پلاگین‌های اضافی) بر اساس مستندات رسمی وردپرس (تا نسخه ۶.۶+) در جدول زیر اومده. این لیست شامل namespace wp/v2 (اصلی) و چند namespace دیگه مثل wp/v1 یا سفارشی می‌شه، اما تمرکز روی پیش‌فرضه.
نکته مهم:

برای دیدن لیست دقیق سایت خودت، به آدرس https://yoursite.com/wp-json/ برو – این index همه endpoints موجود رو نشون می‌ده.
endpoints می‌تونن با پلاگین‌ها (مثل WooCommerce) یا تم‌ها گسترش پیدا کنن.
روش‌های HTTP: GET (خواندن)، POST (ایجاد)، PUT/PATCH (ویرایش)، DELETE (حذف).

جدول endpoints اصلی (wp/v2 namespace)




Endpointتوضیح مثال استفاده
/wp/v2/postsمدیریت پست‌ها (آهنگ‌ها، مقالات و غیره)
GET /wp-json/wp/v2/posts – لیست پست‌ها/wp/v2/posts/{id}پست خاص
GET /wp-json/wp/v2/posts/123 – پست با ID 123/wp/v2/pagesمدیریت صفحاتGET /wp-json/wp/v2/pages – لیست صفحات/wp/v2/pages/{id}صفحه خاصGET /wp-json/wp/v2/pages/456 – صفحه با ID 456/wp/v2/mediaمدیریت رسانه‌ها (تصاویر، فایل‌های صوتی)GET /wp-json/wp/v2/media – لیست فایل‌ها/wp/v2/media/{id}رسانه خاصPOST /wp-json/wp/v2/media – آپلود فایل/wp/v2/usersمدیریت کاربرانGET /wp-json/wp/v2/users – لیست کاربران (نیاز به auth)/wp/v2/users/{id}کاربر خاصGET /wp-json/wp/v2/users/me – کاربر فعلی/wp/v2/users/meکاربر لاگین‌شدهPATCH /wp-json/wp/v2/users/me – ویرایش پروفایل/wp/v2/commentsمدیریت کامنت‌هاGET /wp-json/wp/v2/comments – لیست کامنت‌ها/wp/v2/comments/{id}کامنت خاصPOST /wp-json/wp/v2/comments – ارسال کامنت/wp/v2/taxonomiesمدیریت taxonomyها (دسته‌بندی‌ها)GET /wp-json/wp/v2/taxonomies – لیست taxonomyها/wp/v2/categoriesدسته‌بندی‌های پستGET /wp-json/wp/v2/categories – لیست دسته‌ها/wp/v2/categories/{id}دسته خاص
POST /wp-json/wp/v2/categories – ایجاد دسته/wp/v2/tagsتگ‌های پستGET /wp-json/wp/v2/tags – لیست تگ‌ها/wp/v2/tags/{id}تگ خاص
DELETE /wp-json/wp/v2/tags/789 – حذف تگ/wp/v2/post-typesانواع پست (post, page, custom)
GET /wp-json/wp/v2/types – لیست انواع پست/wp/v2/post-types/{type}نوع پست خاص
GET /wp-json/wp/v2/types/post – جزئیات پست/wp/v2/statusesوضعیت‌های پست (draft, publish)
GET /wp-json/wp/v2/statuses – لیست وضعیت‌ها/wp/v2/searchجستجو در محتوا
GET /wp-json/wp/v2/search?search=keyword – جستجو/wp/v2/settingsتنظیمات سایت
GET /wp-json/wp/v2/settings – تنظیمات عمومی (نیاز به auth)/wp/v2/settingsویرایش تنظیمات
POST /wp-json/wp/v2/settings – تغییر تنظیمات
namespaceهای دیگر (کمتر استفاده‌شده)

wp/v1: قدیمی‌تر، برای batch operations (مثل /wp/v1/batch).
oembed/1.0: برای embed کردن محتوا (/wp-json/oembed/1.0/embed?url=...).
**block-directory/1`: برای بلوک‌های Gutenberg (اگر فعال باشه).

پارامترهای رایج برای همه endpoints

?per_page=10 – تعداد نتایج (حداکثر 100).
?page=2 – صفحه‌بندی.
?search=query – جستجو.
?orderby=date – مرتب‌سازی (date, title, etc.).
?status=publish – فیلتر بر اساس وضعیت.
برای auth: از Application Passwords یا JWT استفاده کن (header: Authorization: Basic ...).

مثال درخواست با curl
bashcurl -X GET "https://yoursite.com/wp-json/wp/v2/posts?per_page=5"
خروجی: JSON با لیست پست‌ها.
اگر سایت خاصی مد نظرته (با URL)، بگو تا endpoints سفارشی‌ش رو چک کنم (با ابزارهای جستجو). یا اگر می‌خوای کد فلاتر برای فراخوانی یکی از این‌ها، بگو! 😊
*/
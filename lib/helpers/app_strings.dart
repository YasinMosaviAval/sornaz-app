// ignore_for_file: constant_identifier_names

import 'package:sornaz/helpers/app_images.dart';

class AppStrings {
  // Shared labels for learning, profiles and drawer pages.
  static const learningEn = <String, String>{
    'auth.sign_in_title': 'Sign in to your account',
    'auth.register_title': 'Create an account',
    'auth.register_intro': 'Enter your details to sign up',
    'auth.email_method': 'Sign up with email',
    'auth.phone_method': 'Sign up with mobile',
    'auth.phone_label': 'Mobile number',
    'auth.username_hint':
        'Username: 3–100 characters; English letters, numbers and underscores only.',
    'auth.username_valid': 'Username format is valid.',
    'auth.username_invalid':
        'Use 3–100 characters: English letters, numbers and underscores only.',
    'auth.strength': 'Password strength',
    'auth.upper': 'Uppercase English letter',
    'auth.lower': 'Lowercase English letter',
    'auth.number': 'Number',
    'auth.special': 'Special character',
    'auth.length': 'More than 8 characters',
    'auth.very_weak': 'Very weak',
    'auth.medium': 'Medium',
    'auth.strong': 'Strong',
    'auth.very_strong': 'Very strong',
    'auth.terms_link': 'Terms and conditions',
    'auth.terms_accept': 'I accept the',
    'auth.required': 'Please complete the required fields.',
    'auth.invalid_phone':
        'Enter a valid mobile number in the format 09123456789.',
    'auth.invalid_email': 'Enter a valid email address.',
    'auth.weak_password':
        'Use at least 8 characters and meet at least 3 password strength criteria.',
    'auth.password_mismatch': 'Passwords do not match.',
    'auth.terms_required': 'Please accept the terms and conditions.',
    'auth.otp_title': 'Verification code',
    'auth.otp_prompt': 'Enter the 6-digit code sent to:',
    'auth.cancel': 'Cancel',
    'auth.verify': 'Verify and sign up',
    'Music Sheet': 'Music Sheet',
    'Music Sheets': 'Music Sheets',
    'Notation': 'Notation',
    'This article is unavailable in this language. Check your connection.':
        'This article is unavailable in this language. Check your connection.',
    'Could not load comments.': 'Could not load comments.',
    'Comments may contain up to 3,000 characters.':
        'Comments may contain up to 3,000 characters.',
    'Guest User': 'Guest User',
    'Your comment is awaiting approval.': 'Your comment is awaiting approval.',
    'Could not submit comment. Try again.':
        'Could not submit comment. Try again.',
    'This article is unavailable in the selected language.':
        'This article is unavailable in the selected language.',
    'Cancel': 'Cancel',
    'Read article': 'Read article',
    'Could not open article.': 'Could not open article.',
    'Could not open link.': 'Could not open link.',
    'Insert link': 'Insert link',
    'Insert': 'Insert',
    'Enter a valid link.': 'Enter a valid link.',
    'Unapproved': 'Unapproved',
    'Reply': 'Reply',
    'Retry': 'Retry',
    'Published: ': 'Published: ',
    'Updated: ': 'Updated: ',
    'views': 'views',
    'Rate this article': 'Rate this article',
    'User comments': 'User comments',
    'No comments have been posted for this article yet.':
        'No comments have been posted for this article yet.',
    'Load more comments': 'Load more comments',
    'Submit a new comment': 'Submit a new comment',
    'Reply to ': 'Reply to ',
    'Cancel reply': 'Cancel reply',
    'Full name': 'Full name',
    'Email': 'Email',
    'Your comment': 'Your comment',
    'Submitting…': 'Submitting…',
    'Submit comment': 'Submit comment',
    'Related articles': 'Related articles',
    'با ایجاد حساب یا استفاده از خدمات سرناز، این قوانین و تغییرات بعدی آن را می‌پذیرید.':
        'با ایجاد حساب یا استفاده از خدمات سرناز، این قوانین و تغییرات بعدی آن را می‌پذیرید.',
    'اطلاعات ثبت‌نام باید صحیح باشد و مسئولیت حفظ امنیت رمز عبور و فعالیت‌های حساب بر عهده کاربر است.':
        'اطلاعات ثبت‌نام باید صحیح باشد و مسئولیت حفظ امنیت رمز عبور و فعالیت‌های حساب بر عهده کاربر است.',
    'محتوای دوره‌ها، مقالات و فایل‌های آموزشی صرفاً برای استفاده شخصی هنرجو است و انتشار، فروش یا کپی‌برداری بدون مجوز کتبی ممنوع است.':
        'محتوای دوره‌ها، مقالات و فایل‌های آموزشی صرفاً برای استفاده شخصی هنرجو است و انتشار، فروش یا کپی‌برداری بدون مجوز کتبی ممنوع است.',
    'شهریه دوره‌ها طبق تعرفه‌های اعلام‌شده دریافت می‌شود. شرایط استرداد وجه مطابق آیین‌نامه مالی آموزشگاه خواهد بود.':
        'شهریه دوره‌ها طبق تعرفه‌های اعلام‌شده دریافت می‌شود. شرایط استرداد وجه مطابق آیین‌نامه مالی آموزشگاه خواهد بود.',
    'اطلاعات شخصی کاربران محرمانه نگهداری می‌شود و جز در موارد قانونی یا با رضایت کاربر در اختیار شخص ثالث قرار نمی‌گیرد.':
        'Personal information is kept confidential and is only shared with third parties with your consent or when required by law.',
    'هرگونه محتوای توهین‌آمیز، اسپم یا نقض حقوق دیگران در پیام‌ها، نظرات و پروفایل ممنوع است و می‌تواند به تعلیق حساب منجر شود.':
        'هرگونه محتوای توهین‌آمیز، اسپم یا نقض حقوق دیگران در پیام‌ها، نظرات و پروفایل ممنوع است و می‌تواند به تعلیق حساب منجر شود.',
    'آموزشگاه می‌تواند این قوانین را به‌روزرسانی کند. ادامه استفاده از خدمات پس از اعلام تغییرات به منزله پذیرش نسخه جدید است.':
        'آموزشگاه می‌تواند این قوانین را به‌روزرسانی کند. ادامه استفاده از خدمات پس از اعلام تغییرات به منزله پذیرش نسخه جدید است.',
    'Menu': 'Menu',
    'Search course, topic, mentor…': 'Search course, topic, mentor…',
    'Course filters': 'Course filters',
    'New blog': 'New blog',
    'Could not load articles.': 'Could not load articles.',
    'No articles found.': 'No articles found.',
    'New courses': 'New courses',
    'Could not load courses.': 'Could not load courses.',
    'No matching courses.': 'No matching courses.',
    'Updated courses': 'Updated courses',
    'lessons': 'lessons',
    'Start learning': 'Start learning',
    'Instructors & authors': 'Instructors & authors',
    'Music tools': 'Music tools',
    'https://sornaz.com/': 'https://sornaz.com/',
    'https://t.me/sornaz_music_application':
        'https://t.me/sornaz_music_application',
    'https://www.youtube.com/@sornaz.academy/':
        'https://www.youtube.com/@sornaz.academy/',
    'https://www.instagram.com/sornaz.ac':
        'https://www.instagram.com/sornaz.ac',
    'mailto:sornaz.ac@gmail.com': 'mailto:sornaz.ac@gmail.com',
    'از صفحه ثبت‌نام، مشخصات خود را وارد کنید و کد تأیید ۶ رقمی را ثبت کنید.':
        'Enter your details on the registration page and submit the six-digit verification code.',
    'بله، در صفحه ورود یا ثبت‌نام گزینه ادامه بدون ورود را انتخاب کنید.':
        'Yes. Select Continue as guest on the sign-in or registration page.',
    'از منوی برنامه وارد صفحه تماس با ما شوید و پیام خود را ارسال کنید.':
        'Open Contact us from the app menu and send your message.',
    'Free': 'Free',
    'IRT': 'IRT',
    'View course': 'View course',
    'Filter': 'Filter',
    'Clear': 'Clear',
    'Rating': 'Rating',
    '& up': '& up',
    'Video duration': 'Video duration',
    'Hours': 'Hours',
    'Categories': 'Categories',
    'Set filters': 'Set filters',
    'Filters': 'Filters',
    'No results in these filters & keyword':
        'No results in these filters & keyword',
    'Try another filter or keyword.': 'Try another filter or keyword.',
    'Courses': 'Courses',
    'What is your review?': 'What is your review?',
    'Do you recommend this course?': 'Do you recommend this course?',
    'YES': 'YES',
    'NO': 'NO',
    'Leave your review for this course': 'Leave your review for this course',
    'Successfully submitted': 'Successfully submitted',
    'Thank you for the valuable feedback.':
        'Thank you for the valuable feedback.',
    'Close': 'Close',
    'Submit review': 'Submit review',
    'Report an issue': 'Report an issue',
    'Send': 'Send',
    'Report submitted.': 'Report submitted.',
    'Course link copied.': 'Course link copied.',
    'students': 'students',
    'Review': 'Review',
    'About': 'About',
    'Q&A': 'Q&A',
    'Like': 'Like',
    'Dislike': 'Dislike',
    'Share': 'Share',
    'Related courses': 'Related courses',
    'reviews': 'reviews',
    'Resources & downloadable files': 'Resources & downloadable files',
    'Enroll to access course resources.': 'Enroll to access course resources.',
    'Summary': 'Summary',
    'sections': 'sections',
    'lectures': 'lectures',
    'hours': 'hours',
    'Description': 'Description',
    'Schedule learning time': 'Schedule learning time',
    'Choose a time to study this course.':
        'Choose a time to study this course.',
    'Get started': 'Get started',
    'Course instructor': 'Course instructor',
    'View profile': 'View profile',
    'Reviews': 'Reviews',
    'Write a review': 'Write a review',
    'No reviews yet.': 'No reviews yet.',
    'Ask the first question.': 'Ask the first question.',
    'Replying to a question': 'Replying to a question',
    'Ask something…': 'Ask something…',
    'Connecting…': 'Connecting…',
    'Enroll': 'Enroll',
    'English title': 'English title',
    'English description': 'English description',
    'Persian category': 'Persian category',
    'English category': 'English category',
    'Total video duration (seconds)': 'Total video duration (seconds)',
    'Original price (IRT)': 'Original price (IRT)',
    'Teaching language': 'Teaching language',
    'Course level': 'Course level',
    'Summary and prerequisites': 'Summary and prerequisites',
    'English summary': 'English summary',
    'Public preview video ID': 'Public preview video ID',
    'Add resource': 'Add resource',
    'Title': 'Title',
    'Add': 'Add',
    'Course details': 'Course details',
    'Upload preview video': 'Upload preview video',
    'Upload the preview separately from private lesson files.':
        'Upload the preview separately from private lesson files.',
    'Upload learning file': 'Upload learning file',
    'Save changes': 'Save changes',
    'Remove': 'Remove',
    'Download course': 'Download course',
    'Completed · undo': 'Completed · undo',
    'Mark lesson complete': 'Mark lesson complete',
    'View all': 'View all',
    'Course': 'Course',
    'Downloads': 'Downloads',
    'Download from a purchased course. Internet is needed to verify access when opening saved files.':
        'Download from a purchased course. Internet is needed to verify access when opening saved files.',
    'Edit profile': 'Edit profile',
    'Public profile': 'Public profile',
    'Learning progress': 'Learning progress',
    'Choose a course to start learning.': 'Choose a course to start learning.',
    'Finished courses': 'Finished courses',
    'Completed courses will appear here.':
        'Completed courses will appear here.',
    'Achievements': 'Achievements',
    'First lesson': 'First lesson',
    'Ten lessons': 'Ten lessons',
    'First course': 'First course',
    'Three courses': 'Three courses',
    'Earned': 'Earned',
    'Not earned yet': 'Not earned yet',
    'Create and manage courses': 'Create and manage courses',
    'Saved': 'Saved',
    'Authors': 'Authors',
    'Posts': 'Posts',
    'Nothing saved yet.': 'Nothing saved yet.',
    'View saved posts': 'View saved posts',
    'Notifications': 'Notifications',
    'Account': 'Account',
    'Direct messages': 'Direct messages',
    'Notify me about new messages': 'Notify me about new messages',
    'Following': 'Following',
    'New followers': 'New followers',
    'Activity': 'Activity',
    'Post likes': 'Post likes',
    'When someone likes your post': 'When someone likes your post',
    'These settings apply to in-app notifications.':
        'These settings apply to in-app notifications.',
    'User profile': 'User profile',
    'Connection failed. Please try again.':
        'Connection failed. Please try again.',
    'Lesson note': 'Lesson note',
    'Save': 'Save',
    'Playback speed': 'Playback speed',
    'Unable to play video.': 'Unable to play video.',
    'Your space': 'Your space',
    'Join the music community': 'Join the music community',
    'Sign in or register': 'Sign in or register',
    'My music space': 'My music space',
    'Feed': 'Feed',
    'Profile': 'Profile',
    'حذف از ذخیره‌شده‌ها': 'Remove bookmark',
    'ذخیره': 'Save',
    'دانلود کامل شد؛ فایل‌ها در بخش دانلودهای پروفایل هستند.':
        'Download complete. Files are available in Profile downloads.',
    'دانلود دوره': 'Download course',
    'تلاش دوباره برای دریافت پیشرفت': 'Retry loading progress',
    'تکمیل شد؛ لغو علامت': 'Completed · undo',
    'این درس را تکمیل کردم': 'Mark lesson complete',
    'دایرکت': 'Direct messages',
    'پیام جدید': 'New message',
    'برای شروع گفتگو، کاربری را از صفحه جست‌وجو انتخاب کنید.':
        'Choose a user from search to start a conversation.',
    '📎 فایل پیوست (قابل مشاهده در سایت)': 'Attachment (view on the website)',
    'پیام خصوصی…': 'Private message…',
    'ارسال': 'Send',
    'پست': 'Post',
    'اعلان‌ها': 'Notifications',
    'هنوز اعلانی ندارید.': 'No notifications yet.',
    'پاسخ ارسال شد.': 'Reply sent.',
    'بستن استوری': 'Close story',
    'استوری بعدی': 'Next story',
    'پاسخ به استوری…': 'Reply to story…',
    'ارسال پاسخ': 'Send reply',
    'آدرس رسانه معتبر نیست.': 'Invalid media address.',
    'سرویس پاسخ معتبر نداد. دوباره تلاش کنید.':
        'Invalid server response. Please try again.',
    'عملیات انجام نشد.': 'The operation failed.',
    'فایل انتخاب‌شده در دسترس نیست.': 'The selected file is unavailable.',
    'مدیریت دوره‌ها': 'Manage courses',
    'خریدهای من': 'My purchases',
    'دوره‌های آموزشی': 'Courses',
    'فروشگاه': 'Catalog',
    'دوره‌های من': 'My courses',
    'ساخت دوره جدید': 'Create a course',
    'هنوز دوره‌ای در این بخش نیست.': 'No courses in this section yet.',
    'منتشرشده': 'Published',
    'پیش‌نویس': 'Draft',
    'ویرایش دوره': 'Edit course',
    'رمز اختصاصی درس': 'Lesson password',
    'رمز درس': 'Password',
    'آدرس درگاه معتبر نیست.': 'Invalid payment gateway address.',
    'درگاه باز نشد.': 'Could not open the payment gateway.',
    'دوره آموزشی': 'Course',
    'دریافت رایگان دوره': 'Enroll for free',
    'دسترسی به همه درس‌ها فعال است': 'Access to all lessons is active',
    'سرفصل‌ها': 'Curriculum',
    'عنوان و قیمت صحیح وارد کنید.': 'Enter a valid title and price.',
    'دوره برای فروش منتشر شد.': 'Course published for sale.',
    'پیش‌نویس ذخیره شد.': 'Draft saved.',
    'ابتدا عنوان دوره را وارد کنید.': 'Enter a course title first.',
    'فصل جدید': 'New chapter',
    'عنوان فصل': 'Chapter title',
    'افزودن درس': 'Add lesson',
    'ویرایش درس': 'Edit lesson',
    'عنوان درس': 'Lesson title',
    'متن و توضیحات': 'Text and description',
    'رمز اختصاصی (خالی = بدون تغییر)': 'Password (leave blank to keep current)',
    'این بخش حذف شود؟': 'Delete this section?',
    'حذف': 'Delete',
    'تغییرات ذخیره نشده‌اند': 'Unsaved changes',
    'بدون ذخیره خارج می‌شوید؟': 'Leave without saving?',
    'ادامه ویرایش': 'Keep editing',
    'خروج': 'Leave',
    'استودیوی ساخت دوره': 'Course studio',
    'عنوان دوره': 'Course title',
    'معرفی دوره و پیش‌نیازها': 'Course description and prerequisites',
    'قیمت به تومان (صفر = رایگان)': 'Price in IRT (0 = free)',
    'انتخاب تصویر جلد': 'Choose cover image',
    'فصل‌ها و درس‌ها': 'Chapters and lessons',
    'افزودن فصل': 'Add chapter',
    'در حال ذخیره یا آپلود…': 'Saving or uploading…',
    'تغییرات ذخیره نشده': 'Unsaved changes',
    'اطلاعات ذخیره شده': 'Changes saved',
    'ذخیره پیش‌نویس': 'Save draft',
    'انتشار برای فروش': 'Publish for sale',
    'بالاتر': 'Move up',
    'پایین‌تر': 'Move down',
    'حذف فصل': 'Delete chapter',
    'حذف درس': 'Delete lesson',
    'آپلود تصویر / ویدیو': 'Upload image / video',
    'ابتدا دوره را تهیه کنید.': 'Enroll in the course first.',
    'ابتدا رمز درس‌های قفل‌شده را در صفحه دوره وارد کنید.':
        'Unlock password-protected lessons on the course page first.',
    'حجم این دوره برای دانلود یکجا بیشتر از یک گیگابایت است.':
        'This course exceeds the 1 GB bulk download limit.',
    'دسترسی به فایل تأیید نشد.': 'File access could not be verified.',
    'اندازه فایل معتبر نیست.': 'Invalid file size.',
    'دانلود کامل نشد؛ دوباره تلاش کنید.':
        'Download incomplete. Please try again.',
    'دسترسی به دوره تأیید نشد.': 'Course access could not be verified.',
    'این فایل دانلود نشده؛ دوره را دوباره دانلود کنید.':
        'This file is missing. Download the course again.',
    'فایل قابل نمایش نیست.': 'This file cannot be displayed.',
    'دانلودها': 'Downloads',
    'برای دانلود، وارد صفحه دوره خریداری‌شده شوید. هنگام باز کردن فایل، اتصال اینترنت برای تأیید دسترسی لازم است.':
        'Download from a purchased course. Internet is needed to verify access when opening saved files.',
    'هنوز دوره‌ای دانلود نشده است.': 'No downloaded courses yet.',
    'حذف دانلود': 'Remove download',
    'حذف فایل‌های دانلودشده؟': 'Delete downloaded files?',
    'ثبت': 'Submit',
    'ویرایش پروفایل': 'Edit profile',
    'پروفایل عمومی': 'Public profile',
    'ذخیره‌شده‌ها': 'Saved',
    'تنظیمات اعلان': 'Notifications',
    'پیشرفت یادگیری': 'Learning progress',
    'برای شروع یادگیری یک دوره انتخاب کنید.':
        'Choose a course to start learning.',
    'دوره‌های تکمیل‌شده': 'Finished courses',
    'با تکمیل درس‌ها، دوره‌ها اینجا نمایش داده می‌شوند.':
        'Completed courses will appear here.',
    'دستاوردها': 'Achievements',
    'اولین درس': 'First lesson',
    'ده درس': 'Ten lessons',
    'اولین دوره': 'First course',
    'سه دوره': 'Three courses',
    'به دست آمد': 'Earned',
    'هنوز تکمیل نشده': 'Not earned yet',
    'ساخت و مدیریت دوره': 'Create and manage courses',
    'هنوز دوره‌ای تهیه نکرده‌اید.': 'You have not enrolled in any courses yet.',
    'نویسندگان': 'Authors',
    'پست‌ها': 'Feed',
    'هنوز چیزی ذخیره نکرده‌اید.': 'Nothing saved yet.',
    'حذف نشان': 'Remove bookmark',
    'نمایش پست‌های ذخیره‌شده': 'View saved posts',
    'اعلان‌های دریافتی': 'Incoming notifications',
    'حساب کاربری': 'Account',
    'پیام خصوصی': 'Direct messages',
    'اعلان دریافت پیام جدید': 'Notify me about new messages',
    'دنبال‌کنندگان': 'Following',
    'دنبال‌کننده جدید': 'New followers',
    'فعالیت‌ها': 'Activity',
    'پسندیدن پست‌ها': 'Post likes',
    'وقتی کسی پست شما را می‌پسندد': 'When someone likes your post',
    'این تنظیمات برای اعلان‌های داخل اپ است.':
        'These settings apply to in-app notifications.',
    'پروفایل کاربر': 'User profile',
    'دنبال می‌کنید': 'Following',
    'دنبال کردن': 'Follow',
    'دنبال‌شونده‌ها': 'Following',
    'لینک باز نشد.': 'Could not open the link.',
    'هنوز پستی منتشر نشده است.': 'No posts published yet.',
    'کشف کاربران': 'Discover people',
    'جست‌وجوی نام کاربری': 'Search username',
    'کاربری پیدا نشد.': 'No users found.',
    'تغییر تصویر پروفایل': 'Change profile picture',
    'نام نمایشی را وارد کنید.': 'Enter a display name.',
    'نام نمایشی': 'Display name',
    'درباره من': 'About me',
    'لینک‌های عمومی': 'Public links',
    'آدرس معتبر https وارد کنید.': 'Enter a valid HTTPS address.',
    'انتخاب تصویر پروفایل': 'Choose profile picture',
    'انتخاب کاور': 'Choose cover',
    'ذخیره تغییرات': 'Save changes',
    'پست‌های ذخیره‌شده': 'Saved posts',
    'هنوز پستی ذخیره نکرده‌اید.': 'No saved posts yet.',
    'برای استوری تصویر یا ویدیو انتخاب کنید.':
        'Choose an image or video for your story.',
    'استوری جدید': 'New story',
    'پست جدید': 'New post',
    'لحظه‌های موسیقایی شما، برای ۲۴ ساعت': 'Your musical moments, for 24 hours',
    'اجرای تازه، تمرین امروز یا تجربه‌ات را منتشر کن.':
        'Share a performance, today\'s practice or your experience.',
    'انتخاب تصویر یا ویدیو': 'Choose image or video',
    'تصویر تا ۱۰ مگابایت · ویدیو تا ۱۰۰ مگابایت':
        'Images up to 10 MB · Videos up to 100 MB',
    'در حال ارسال؛ صفحه را باز نگه دارید.': 'Uploading; keep this page open.',
    'انتشار': 'Publish',
    'پخش ویدیو ممکن نشد.': 'Unable to play video.',
    'توقف': 'Pause',
    'پخش': 'Play',
    'پنل کاربری': 'Your space',
    'به جمع اهالی موسیقی بپیوندید': 'Join the music community',
    'ورود یا ثبت‌نام': 'Sign in or register',
    'دوره جدید': 'New course',
    'دنیای موسیقی من': 'My music space',
    'پست‌ها و استوری‌ها': 'Posts and stories',
    'جست‌وجوی کاربران': 'Search people',
    'استوری من': 'My story',
    'هنوز پستی منتشر نشده؛ اولین اجرای خود را به اشتراک بگذارید.':
        'No posts yet. Share your first performance.',
    'در حال دریافت…': 'Loading…',
    'نمایش بیشتر': 'Load more',
    'ساخت محتوا': 'Create content',
    'پروفایل': 'Profile',
    'حذف پست': 'Delete post',
    'این پست حذف شود؟': 'Delete this post?',
    'حالت تاریک': 'Dark mode',
    'نمایش برنامه با تم تاریک': 'Use the dark appearance',
    'برنامه': 'App',
    'نشان‌شده‌ها': 'Bookmarks',
    'محتواهایی که نشان می‌کنید در این بخش نمایش داده می‌شوند.':
        'Your bookmarked content appears here.',
    'اشتراک‌گذاری برنامه': 'Share app',
    'پرسش‌های متداول': 'FAQ',
    'دستاوردها و روند پیشرفت آموزشی شما در این بخش نمایش داده می‌شود.':
        'Your achievements and learning progress appear here.',
    'حریم خصوصی': 'Privacy policy',
    'جامعه': 'Community',
    'تماس با ما': 'Contact us',
    'عضویت': 'Membership',
    'جزئیات عضویت و خدمات حساب شما پس از فعال شدن طرح‌های عضویت اینجا قرار می‌گیرد.':
        'Membership details and account services will appear here when membership plans become available.',
    'حساب من': 'My account',
    'ورود با حساب دیگر': 'Sign in with another account',
    'خروج از حساب': 'Sign out',
    'حساب‌های کاربری': 'Accounts',
    'افزودن حساب کاربری': 'Add account',
    'چطور در سرناز ثبت‌نام کنم؟': 'How do I register with Sornaz?',
    'آیا بدون حساب کاربری می‌توانم از برنامه استفاده کنم؟':
        'Can I use the app without an account?',
    'چطور با پشتیبانی تماس بگیرم؟': 'How do I contact support?',
    'متن پیام را وارد کنید.': 'Enter your message.',
    'پیام شما ارسال شد. در اولین فرصت پاسخ می‌دهیم.':
        'Your message was sent. We will reply as soon as possible.',
    'ارسال پیام انجام نشد؛ اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.':
        'Message not sent. Check your connection and try again.',
    'ارتباط با ما — ارسال پیام جدید': 'Contact us — New message',
    'نام و نام خانوادگی': 'Full name',
    'ایمیل پاسخ (اختیاری)': 'Reply email (optional)',
    'موضوع': 'Subject',
    'متن پیام *': 'Message *',
    'ارسال پیام': 'Send message',
    'سایت سرناز': 'Sornaz website',
    'کانال تلگرام': 'Telegram channel',
    'کانال یوتیوب': 'YouTube channel',
    'صفحه اینستاگرام': 'Instagram page',
    'ایمیل': 'Email',
    'برنامه‌ای برای باز کردن این پیوند پیدا نشد.':
        'No app was found to open this link.',
    'اشتراک‌گذاری فایل نصب در این دستگاه ممکن نشد. از لینک سایت استفاده کنید.':
        'Could not share the installer on this device. Use the website link.',
    'سرناز را به دوستان خود معرفی کنید و در شبکه‌های اجتماعی همراه ما باشید.':
        'Introduce Sornaz to your friends and follow us on social media.',
    'آماده‌سازی فایل نصب…': 'Preparing installer…',
    'ارسال فایل نصبی برنامه': 'Share app installer',
    'درس': 'lessons',
    'رایگان': 'Free',
    'تومان': 'IRT',
    'مشاهده دوره': 'View course',
    'فیلتر': 'Filter',
    'پاک کردن': 'Clear',
    'امتیاز': 'Rating',
    'و بالاتر': '& up',
    'مدت ویدیو': 'Video duration',
    'ساعت': 'hours',
    'دسته‌بندی‌ها': 'Categories',
    'اعمال فیلترها': 'Set filters',
    'جست‌وجوی دوره، موضوع، مدرس…': 'Search course, topic, mentor…',
    'فیلترها': 'Filters',
    'نتیجه‌ای برای فیلتر و جست‌وجو پیدا نشد':
        'No results in these filters & keyword',
    'فیلترها یا عبارت جست‌وجو را تغییر دهید.': 'Try another filter or keyword.',
    'دوره‌ها': 'Courses',
    'نظر شما چیست؟': 'What is your review?',
    'این دوره را پیشنهاد می‌کنید؟': 'Do you recommend this course?',
    'بله': 'YES',
    'خیر': 'NO',
    'نظر خود درباره این دوره را بنویسید': 'Leave your review for this course',
    'با موفقیت ثبت شد': 'Successfully submitted',
    'از بازخورد ارزشمند شما سپاسگزاریم.':
        'Thank you for the valuable feedback.',
    'بستن': 'Close',
    'ثبت نظر': 'Write a review',
    'گزارش مشکل': 'Report an issue',
    'انصراف': 'Cancel',
    'گزارش ثبت شد.': 'Report submitted.',
    'لینک دوره کپی شد.': 'Course link copied.',
    'هنرجو': 'students',
    'درس‌ها': 'Courses',
    'منابع': 'Review',
    'درباره': 'About',
    'پرسش‌وپاسخ': 'Q&A',
    'پسندیدن': 'Like',
    'نپسندیدن': 'Dislike',
    'اشتراک‌گذاری': 'Share',
    'دوره‌های مرتبط': 'Related courses',
    'نظر': 'reviews',
    'منابع و فایل‌های قابل دانلود': 'Resources & downloadable files',
    'برای مشاهده منابع ابتدا دوره را تهیه کنید.':
        'Enroll to access course resources.',
    'خلاصه': 'Summary',
    'فصل': 'sections',
    'توضیحات': 'Description',
    'زمان یادگیری را برنامه‌ریزی کنید': 'Schedule learning time',
    'برای یادگیری این دوره زمان مشخصی انتخاب کنید.':
        'Choose a time to study this course.',
    'شروع کنید': 'Get started',
    'مدرس دوره': 'Course instructor',
    'مشاهده پروفایل': 'View profile',
    'نظرات': 'Reviews',
    'هنوز نظری ثبت نشده است.': 'No reviews yet.',
    'اولین پرسش را مطرح کنید.': 'Ask the first question.',
    'در حال پاسخ به پرسش': 'Replying to a question',
    'پرسشی مطرح کنید…': 'Ask something…',
    'در حال اتصال…': 'Connecting…',
    'ثبت‌نام در دوره': 'Enroll',
    'مشاهده همه': 'View all',
    'ارتباط برقرار نشد. دوباره تلاش کنید.':
        'Connection failed. Please try again.',
    'تلاش دوباره': 'Retry',
    'منو': 'Menu',
    'فیلتر دوره‌ها': 'Course filters',
    'تازه‌های وبلاگ': 'New blog',
    'مقاله‌ها دریافت نشدند.': 'Could not load articles.',
    'مقاله‌ای پیدا نشد.': 'No articles found.',
    'دوره‌های جدید': 'New courses',
    'دوره‌ها دریافت نشدند.': 'Could not load courses.',
    'دوره‌ای با این مشخصات پیدا نشد.': 'No matching courses.',
    'دوره‌های به‌روزشده': 'Updated courses',
    'برای شروع یادگیری': 'Start learning',
    'مدرسان و نویسندگان': 'Instructors & authors',
  };
  static const learningFa = <String, String>{
    'auth.sign_in_title': 'ورود به حساب کاربری',
    'auth.register_title': 'ایجاد حساب کاربری',
    'auth.register_intro': 'برای عضویت اطلاعات خود را وارد کنید',
    'auth.email_method': 'ثبت‌نام با ایمیل',
    'auth.phone_method': 'ثبت‌نام با موبایل',
    'auth.phone_label': 'شماره موبایل',
    'auth.username_hint':
        'نام کاربری: حداقل ۳ و حداکثر ۱۰۰ کاراکتر، فقط حروف انگلیسی، عدد و _',
    'auth.username_valid': 'نام کاربری صحیح است.',
    'auth.username_invalid':
        'نام کاربری باید ۳ تا ۱۰۰ کاراکتر و فقط شامل حروف انگلیسی، عدد و _ باشد.',
    'auth.strength': 'قدرت رمز عبور',
    'auth.upper': 'حرف بزرگ انگلیسی',
    'auth.lower': 'حرف کوچک انگلیسی',
    'auth.number': 'عدد',
    'auth.special': 'کاراکتر ویژه',
    'auth.length': 'بیشتر از ۸ کاراکتر',
    'auth.very_weak': 'بسیار ضعیف',
    'auth.medium': 'متوسط',
    'auth.strong': 'قوی',
    'auth.very_strong': 'بسیار قوی',
    'auth.terms_link': 'قوانین و شرایط',
    'auth.terms_accept': 'را می پذیرم',
    'auth.required': 'لطفاً فیلدهای ضروری را تکمیل کنید.',
    'auth.invalid_phone': 'شماره موبایل معتبر با قالب 09123456789 وارد کنید.',
    'auth.invalid_email': 'ایمیل معتبر وارد کنید.',
    'auth.weak_password':
        'رمز عبور باید حداقل ۸ کاراکتر باشد و حداقل ۳ معیار قدرت رمز را داشته باشد.',
    'auth.password_mismatch': 'رمز عبور و تکرار آن یکسان نیست.',
    'auth.terms_required': 'پذیرش قوانین الزامی است.',
    'auth.otp_title': 'کد تأیید',
    'auth.otp_prompt': 'کد ۶ رقمی ارسال‌شده را وارد کنید:',
    'auth.cancel': 'انصراف',
    'auth.verify': 'تأیید و ثبت‌نام',
    'Music Sheet': 'نت‌های موسیقی',
    'Music Sheets': 'نت‌های موسیقی',
    'Notation': 'نت‌نویسی',
    'This article is unavailable in this language. Check your connection.':
        'مقاله در این زبان در دسترس نیست؛ اتصال اینترنت را بررسی کنید.',
    'Could not load comments.': 'دریافت نظرات ممکن نشد.',
    'Comments may contain up to 3,000 characters.':
        'حداکثر طول نظر ۳۰۰۰ نویسه است.',
    'Guest User': 'کاربر مهمان',
    'Your comment is awaiting approval.':
        'نظر شما ثبت شد و در انتظار تأیید است.',
    'Could not submit comment. Try again.':
        'ارسال نظر ممکن نشد؛ دوباره تلاش کنید.',
    'This article is unavailable in the selected language.':
        'این مقاله در زبان انتخاب‌شده در دسترس نیست.',
    'Cancel': 'انصراف',
    'Read article': 'مطالعه مقاله',
    'Could not open article.': 'باز کردن مقاله ممکن نشد.',
    'Could not open link.': 'باز کردن لینک ممکن نشد.',
    'Insert link': 'افزودن لینک',
    'Insert': 'افزودن',
    'Enter a valid link.': 'لینک معتبر وارد کنید.',
    'Unapproved': 'تأیید نشده',
    'Reply': 'پاسخ',
    'Retry': 'تلاش دوباره',
    'Published: ': 'تاریخ انتشار: ',
    'Updated: ': 'به‌روزرسانی: ',
    'views': 'بازدید',
    'Rate this article': 'امتیاز به این مقاله',
    'User comments': 'نظرات کاربران',
    'No comments have been posted for this article yet.':
        'هنوز نظری برای این مقاله ثبت نشده است.',
    'Load more comments': 'نمایش نظرات بیشتر',
    'Submit a new comment': 'ارسال نظر جدید',
    'Reply to ': 'پاسخ به ',
    'Cancel reply': 'لغو پاسخ',
    'Full name': 'نام و نام خانوادگی',
    'Email': 'ایمیل',
    'Your comment': 'نظر شما',
    'Submitting…': 'در حال ارسال…',
    'Submit comment': 'ارسال نظر',
    'Related articles': 'مقاله‌های مرتبط',
    'با ایجاد حساب یا استفاده از خدمات سرناز، این قوانین و تغییرات بعدی آن را می‌پذیرید.':
        '۱. پذیرش قوانین',
    'اطلاعات ثبت‌نام باید صحیح باشد و مسئولیت حفظ امنیت رمز عبور و فعالیت‌های حساب بر عهده کاربر است.':
        '۲. حساب کاربری',
    'محتوای دوره‌ها، مقالات و فایل‌های آموزشی صرفاً برای استفاده شخصی هنرجو است و انتشار، فروش یا کپی‌برداری بدون مجوز کتبی ممنوع است.':
        '۳. محتوای آموزشی',
    'شهریه دوره‌ها طبق تعرفه‌های اعلام‌شده دریافت می‌شود. شرایط استرداد وجه مطابق آیین‌نامه مالی آموزشگاه خواهد بود.':
        '۴. پرداخت و انصراف',
    'اطلاعات شخصی کاربران محرمانه نگهداری می‌شود و جز در موارد قانونی یا با رضایت کاربر در اختیار شخص ثالث قرار نمی‌گیرد.':
        'اطلاعات شخصی کاربران محرمانه نگهداری می‌شود و جز در موارد قانونی یا با رضایت کاربر در اختیار شخص ثالث قرار نمی‌گیرد.',
    'هرگونه محتوای توهین‌آمیز، اسپم یا نقض حقوق دیگران در پیام‌ها، نظرات و پروفایل ممنوع است و می‌تواند به تعلیق حساب منجر شود.':
        '۶. رفتار کاربران',
    'آموزشگاه می‌تواند این قوانین را به‌روزرسانی کند. ادامه استفاده از خدمات پس از اعلام تغییرات به منزله پذیرش نسخه جدید است.':
        '۷. تغییرات قوانین',
    'Menu': 'منو',
    'Search course, topic, mentor…': 'جست‌وجوی دوره، موضوع، مدرس…',
    'Course filters': 'فیلتر دوره‌ها',
    'New blog': 'تازه‌های وبلاگ',
    'Could not load articles.': 'مقاله‌ها دریافت نشدند.',
    'No articles found.': 'مقاله‌ای پیدا نشد.',
    'New courses': 'دوره‌های جدید',
    'Could not load courses.': 'دوره‌ها دریافت نشدند.',
    'No matching courses.': 'دوره‌ای با این مشخصات پیدا نشد.',
    'Updated courses': 'دوره‌های به‌روزشده',
    'lessons': 'درس',
    'Start learning': 'برای شروع یادگیری',
    'Instructors & authors': 'مدرسان و نویسندگان',
    'Music tools': 'ابزار موسیقی',
    'https://sornaz.com/': 'سایت سرناز',
    'https://t.me/sornaz_music_application': 'کانال تلگرام',
    'https://www.youtube.com/@sornaz.academy/': 'کانال یوتیوب',
    'https://www.instagram.com/sornaz.ac': 'صفحه اینستاگرام',
    'mailto:sornaz.ac@gmail.com': 'ایمیل',
    'از صفحه ثبت‌نام، مشخصات خود را وارد کنید و کد تأیید ۶ رقمی را ثبت کنید.':
        'از صفحه ثبت‌نام، مشخصات خود را وارد کنید و کد تأیید ۶ رقمی را ثبت کنید.',
    'بله، در صفحه ورود یا ثبت‌نام گزینه ادامه بدون ورود را انتخاب کنید.':
        'بله، در صفحه ورود یا ثبت‌نام گزینه ادامه بدون ورود را انتخاب کنید.',
    'از منوی برنامه وارد صفحه تماس با ما شوید و پیام خود را ارسال کنید.':
        'از منوی برنامه وارد صفحه تماس با ما شوید و پیام خود را ارسال کنید.',
    'Free': 'رایگان',
    'IRT': 'تومان',
    'View course': 'مشاهده دوره',
    'Filter': 'فیلتر',
    'Clear': 'پاک کردن',
    'Rating': 'امتیاز',
    '& up': 'و بالاتر',
    'Video duration': 'مدت ویدیو',
    'Hours': 'ساعت',
    'Categories': 'دسته‌بندی‌ها',
    'Set filters': 'اعمال فیلترها',
    'Filters': 'فیلترها',
    'No results in these filters & keyword':
        'نتیجه‌ای برای فیلتر و جست‌وجو پیدا نشد',
    'Try another filter or keyword.': 'فیلترها یا عبارت جست‌وجو را تغییر دهید.',
    'Courses': 'دوره‌ها',
    'What is your review?': 'نظر شما چیست؟',
    'Do you recommend this course?': 'این دوره را پیشنهاد می‌کنید؟',
    'YES': 'بله',
    'NO': 'خیر',
    'Leave your review for this course': 'نظر خود درباره این دوره را بنویسید',
    'Successfully submitted': 'با موفقیت ثبت شد',
    'Thank you for the valuable feedback.':
        'از بازخورد ارزشمند شما سپاسگزاریم.',
    'Close': 'بستن',
    'Submit review': 'ثبت نظر',
    'Report an issue': 'گزارش مشکل',
    'Send': 'ارسال',
    'Report submitted.': 'گزارش ثبت شد.',
    'Course link copied.': 'لینک دوره کپی شد.',
    'students': 'هنرجو',
    'Review': 'منابع',
    'About': 'درباره',
    'Q&A': 'پرسش‌وپاسخ',
    'Like': 'پسندیدن',
    'Dislike': 'نپسندیدن',
    'Share': 'اشتراک‌گذاری',
    'Related courses': 'دوره‌های مرتبط',
    'reviews': 'نظر',
    'Resources & downloadable files': 'منابع و فایل‌های قابل دانلود',
    'Enroll to access course resources.':
        'برای مشاهده منابع ابتدا دوره را تهیه کنید.',
    'Summary': 'خلاصه',
    'sections': 'فصل',
    'lectures': 'درس',
    'hours': 'ساعت',
    'Description': 'توضیحات',
    'Schedule learning time': 'زمان یادگیری را برنامه‌ریزی کنید',
    'Choose a time to study this course.':
        'برای یادگیری این دوره زمان مشخصی انتخاب کنید.',
    'Get started': 'شروع کنید',
    'Course instructor': 'مدرس دوره',
    'View profile': 'مشاهده پروفایل',
    'Reviews': 'نظرات',
    'Write a review': 'ثبت نظر',
    'No reviews yet.': 'هنوز نظری ثبت نشده است.',
    'Ask the first question.': 'اولین پرسش را مطرح کنید.',
    'Replying to a question': 'در حال پاسخ به پرسش',
    'Ask something…': 'پرسشی مطرح کنید…',
    'Connecting…': 'در حال اتصال…',
    'Enroll': 'ثبت‌نام در دوره',
    'English title': 'عنوان انگلیسی',
    'English description': 'توضیحات انگلیسی',
    'Persian category': 'دسته‌بندی فارسی',
    'English category': 'دسته‌بندی انگلیسی',
    'Total video duration (seconds)': 'مدت کل ویدیوها (ثانیه)',
    'Original price (IRT)': 'قیمت قبل از تخفیف (تومان)',
    'Teaching language': 'زبان آموزش',
    'Course level': 'سطح دوره',
    'Summary and prerequisites': 'خلاصه و پیش‌نیازها',
    'English summary': 'خلاصه انگلیسی',
    'Public preview video ID': 'شناسه ویدیوی معرفی عمومی',
    'Add resource': 'افزودن منبع',
    'Title': 'عنوان',
    'Add': 'افزودن',
    'Course details': 'جزئیات تکمیلی دوره',
    'Upload preview video': 'آپلود ویدیوی معرفی',
    'Upload the preview separately from private lesson files.':
        'ویدیوی معرفی باید جدا از فایل‌های خصوصی درس‌ها آپلود شود.',
    'Upload learning file': 'آپلود فایل آموزشی',
    'Save changes': 'ذخیره تغییرات',
    'Remove': 'حذف',
    'Download course': 'دانلود دوره',
    'Completed · undo': 'تکمیل شد؛ لغو علامت',
    'Mark lesson complete': 'این درس را تکمیل کردم',
    'View all': 'مشاهده همه',
    'Course': 'دوره آموزشی',
    'Downloads': 'دانلودها',
    'Download from a purchased course. Internet is needed to verify access when opening saved files.':
        'برای دانلود، وارد صفحه دوره خریداری‌شده شوید. هنگام باز کردن فایل، اتصال اینترنت برای تأیید دسترسی لازم است.',
    'Edit profile': 'ویرایش پروفایل',
    'Public profile': 'پروفایل عمومی',
    'Learning progress': 'پیشرفت یادگیری',
    'Choose a course to start learning.':
        'برای شروع یادگیری یک دوره انتخاب کنید.',
    'Finished courses': 'دوره‌های تکمیل‌شده',
    'Completed courses will appear here.':
        'با تکمیل درس‌ها، دوره‌ها اینجا نمایش داده می‌شوند.',
    'Achievements': 'دستاوردها',
    'First lesson': 'اولین درس',
    'Ten lessons': 'ده درس',
    'First course': 'اولین دوره',
    'Three courses': 'سه دوره',
    'Earned': 'به دست آمد',
    'Not earned yet': 'هنوز تکمیل نشده',
    'Create and manage courses': 'ساخت و مدیریت دوره',
    'Saved': 'ذخیره‌شده‌ها',
    'Authors': 'نویسندگان',
    'Posts': 'پست‌ها',
    'Nothing saved yet.': 'هنوز چیزی ذخیره نکرده‌اید.',
    'View saved posts': 'نمایش پست‌های ذخیره‌شده',
    'Notifications': 'تنظیمات اعلان',
    'Account': 'حساب کاربری',
    'Direct messages': 'پیام خصوصی',
    'Notify me about new messages': 'اعلان دریافت پیام جدید',
    'Following': 'دنبال‌کنندگان',
    'New followers': 'دنبال‌کننده جدید',
    'Activity': 'فعالیت‌ها',
    'Post likes': 'پسندیدن پست‌ها',
    'When someone likes your post': 'وقتی کسی پست شما را می‌پسندد',
    'These settings apply to in-app notifications.':
        'این تنظیمات برای اعلان‌های داخل اپ است.',
    'User profile': 'پروفایل کاربر',
    'Connection failed. Please try again.':
        'ارتباط برقرار نشد. دوباره تلاش کنید.',
    'Lesson note': 'یادداشت درس',
    'Save': 'ذخیره',
    'Playback speed': 'سرعت پخش',
    'Unable to play video.': 'پخش ویدیو ممکن نشد.',
    'Your space': 'پنل کاربری',
    'Join the music community': 'به جمع اهالی موسیقی بپیوندید',
    'Sign in or register': 'ورود یا ثبت‌نام',
    'My music space': 'دنیای موسیقی من',
    'Feed': 'پست‌ها',
    'Profile': 'پروفایل',
    'حذف از ذخیره‌شده‌ها': 'حذف از ذخیره‌شده‌ها',
    'ذخیره': 'ذخیره',
    'دانلود کامل شد؛ فایل‌ها در بخش دانلودهای پروفایل هستند.':
        'دانلود کامل شد؛ فایل‌ها در بخش دانلودهای پروفایل هستند.',
    'دانلود دوره': 'دانلود دوره',
    'تلاش دوباره برای دریافت پیشرفت': 'تلاش دوباره برای دریافت پیشرفت',
    'تکمیل شد؛ لغو علامت': 'تکمیل شد؛ لغو علامت',
    'این درس را تکمیل کردم': 'این درس را تکمیل کردم',
    'دایرکت': 'دایرکت',
    'پیام جدید': 'پیام جدید',
    'برای شروع گفتگو، کاربری را از صفحه جست‌وجو انتخاب کنید.':
        'برای شروع گفتگو، کاربری را از صفحه جست‌وجو انتخاب کنید.',
    '📎 فایل پیوست (قابل مشاهده در سایت)':
        '📎 فایل پیوست (قابل مشاهده در سایت)',
    'پیام خصوصی…': 'پیام خصوصی…',
    'ارسال': 'ارسال',
    'پست': 'پست',
    'اعلان‌ها': 'اعلان‌ها',
    'هنوز اعلانی ندارید.': 'هنوز اعلانی ندارید.',
    'پاسخ ارسال شد.': 'پاسخ ارسال شد.',
    'بستن استوری': 'بستن استوری',
    'استوری بعدی': 'استوری بعدی',
    'پاسخ به استوری…': 'پاسخ به استوری…',
    'ارسال پاسخ': 'ارسال پاسخ',
    'آدرس رسانه معتبر نیست.': 'آدرس رسانه معتبر نیست.',
    'سرویس پاسخ معتبر نداد. دوباره تلاش کنید.':
        'سرویس پاسخ معتبر نداد. دوباره تلاش کنید.',
    'عملیات انجام نشد.': 'عملیات انجام نشد.',
    'فایل انتخاب‌شده در دسترس نیست.': 'فایل انتخاب‌شده در دسترس نیست.',
    'مدیریت دوره‌ها': 'مدیریت دوره‌ها',
    'خریدهای من': 'خریدهای من',
    'دوره‌های آموزشی': 'دوره‌های آموزشی',
    'فروشگاه': 'فروشگاه',
    'دوره‌های من': 'دوره‌های من',
    'ساخت دوره جدید': 'ساخت دوره جدید',
    'هنوز دوره‌ای در این بخش نیست.': 'هنوز دوره‌ای در این بخش نیست.',
    'منتشرشده': 'منتشرشده',
    'پیش‌نویس': 'پیش‌نویس',
    'ویرایش دوره': 'ویرایش دوره',
    'رمز اختصاصی درس': 'رمز اختصاصی درس',
    'رمز درس': 'رمز درس',
    'آدرس درگاه معتبر نیست.': 'آدرس درگاه معتبر نیست.',
    'درگاه باز نشد.': 'درگاه باز نشد.',
    'دوره آموزشی': 'دوره آموزشی',
    'دریافت رایگان دوره': 'دریافت رایگان دوره',
    'دسترسی به همه درس‌ها فعال است': 'دسترسی به همه درس‌ها فعال است',
    'سرفصل‌ها': 'سرفصل‌ها',
    'عنوان و قیمت صحیح وارد کنید.': 'عنوان و قیمت صحیح وارد کنید.',
    'دوره برای فروش منتشر شد.': 'دوره برای فروش منتشر شد.',
    'پیش‌نویس ذخیره شد.': 'پیش‌نویس ذخیره شد.',
    'ابتدا عنوان دوره را وارد کنید.': 'ابتدا عنوان دوره را وارد کنید.',
    'فصل جدید': 'فصل جدید',
    'عنوان فصل': 'عنوان فصل',
    'افزودن درس': 'افزودن درس',
    'ویرایش درس': 'ویرایش درس',
    'عنوان درس': 'عنوان درس',
    'متن و توضیحات': 'متن و توضیحات',
    'رمز اختصاصی (خالی = بدون تغییر)': 'رمز اختصاصی (خالی = بدون تغییر)',
    'این بخش حذف شود؟': 'این بخش حذف شود؟',
    'حذف': 'حذف',
    'تغییرات ذخیره نشده‌اند': 'تغییرات ذخیره نشده‌اند',
    'بدون ذخیره خارج می‌شوید؟': 'بدون ذخیره خارج می‌شوید؟',
    'ادامه ویرایش': 'ادامه ویرایش',
    'خروج': 'خروج',
    'استودیوی ساخت دوره': 'استودیوی ساخت دوره',
    'عنوان دوره': 'عنوان دوره',
    'معرفی دوره و پیش‌نیازها': 'معرفی دوره و پیش‌نیازها',
    'قیمت به تومان (صفر = رایگان)': 'قیمت به تومان (صفر = رایگان)',
    'انتخاب تصویر جلد': 'انتخاب تصویر جلد',
    'فصل‌ها و درس‌ها': 'فصل‌ها و درس‌ها',
    'افزودن فصل': 'افزودن فصل',
    'در حال ذخیره یا آپلود…': 'در حال ذخیره یا آپلود…',
    'تغییرات ذخیره نشده': 'تغییرات ذخیره نشده',
    'اطلاعات ذخیره شده': 'اطلاعات ذخیره شده',
    'ذخیره پیش‌نویس': 'ذخیره پیش‌نویس',
    'انتشار برای فروش': 'انتشار برای فروش',
    'بالاتر': 'بالاتر',
    'پایین‌تر': 'پایین‌تر',
    'حذف فصل': 'حذف فصل',
    'حذف درس': 'حذف درس',
    'آپلود تصویر / ویدیو': 'آپلود تصویر / ویدیو',
    'ابتدا دوره را تهیه کنید.': 'ابتدا دوره را تهیه کنید.',
    'ابتدا رمز درس‌های قفل‌شده را در صفحه دوره وارد کنید.':
        'ابتدا رمز درس‌های قفل‌شده را در صفحه دوره وارد کنید.',
    'حجم این دوره برای دانلود یکجا بیشتر از یک گیگابایت است.':
        'حجم این دوره برای دانلود یکجا بیشتر از یک گیگابایت است.',
    'دسترسی به فایل تأیید نشد.': 'دسترسی به فایل تأیید نشد.',
    'اندازه فایل معتبر نیست.': 'اندازه فایل معتبر نیست.',
    'دانلود کامل نشد؛ دوباره تلاش کنید.': 'دانلود کامل نشد؛ دوباره تلاش کنید.',
    'دسترسی به دوره تأیید نشد.': 'دسترسی به دوره تأیید نشد.',
    'این فایل دانلود نشده؛ دوره را دوباره دانلود کنید.':
        'این فایل دانلود نشده؛ دوره را دوباره دانلود کنید.',
    'فایل قابل نمایش نیست.': 'فایل قابل نمایش نیست.',
    'دانلودها': 'دانلودها',
    'برای دانلود، وارد صفحه دوره خریداری‌شده شوید. هنگام باز کردن فایل، اتصال اینترنت برای تأیید دسترسی لازم است.':
        'برای دانلود، وارد صفحه دوره خریداری‌شده شوید. هنگام باز کردن فایل، اتصال اینترنت برای تأیید دسترسی لازم است.',
    'هنوز دوره‌ای دانلود نشده است.': 'هنوز دوره‌ای دانلود نشده است.',
    'حذف دانلود': 'حذف دانلود',
    'حذف فایل‌های دانلودشده؟': 'حذف فایل‌های دانلودشده؟',
    'ثبت': 'ثبت',
    'ویرایش پروفایل': 'ویرایش پروفایل',
    'پروفایل عمومی': 'پروفایل عمومی',
    'ذخیره‌شده‌ها': 'ذخیره‌شده‌ها',
    'تنظیمات اعلان': 'تنظیمات اعلان',
    'پیشرفت یادگیری': 'پیشرفت یادگیری',
    'برای شروع یادگیری یک دوره انتخاب کنید.':
        'برای شروع یادگیری یک دوره انتخاب کنید.',
    'دوره‌های تکمیل‌شده': 'دوره‌های تکمیل‌شده',
    'با تکمیل درس‌ها، دوره‌ها اینجا نمایش داده می‌شوند.':
        'با تکمیل درس‌ها، دوره‌ها اینجا نمایش داده می‌شوند.',
    'دستاوردها': 'دستاوردها',
    'اولین درس': 'اولین درس',
    'ده درس': 'ده درس',
    'اولین دوره': 'اولین دوره',
    'سه دوره': 'سه دوره',
    'به دست آمد': 'به دست آمد',
    'هنوز تکمیل نشده': 'هنوز تکمیل نشده',
    'ساخت و مدیریت دوره': 'ساخت و مدیریت دوره',
    'هنوز دوره‌ای تهیه نکرده‌اید.': 'هنوز دوره‌ای تهیه نکرده‌اید.',
    'نویسندگان': 'نویسندگان',
    'پست‌ها': 'پست‌ها',
    'هنوز چیزی ذخیره نکرده‌اید.': 'هنوز چیزی ذخیره نکرده‌اید.',
    'حذف نشان': 'حذف نشان',
    'نمایش پست‌های ذخیره‌شده': 'نمایش پست‌های ذخیره‌شده',
    'اعلان‌های دریافتی': 'اعلان‌های دریافتی',
    'حساب کاربری': 'حساب کاربری',
    'پیام خصوصی': 'پیام خصوصی',
    'اعلان دریافت پیام جدید': 'اعلان دریافت پیام جدید',
    'دنبال‌کنندگان': 'دنبال‌کنندگان',
    'دنبال‌کننده جدید': 'دنبال‌کننده جدید',
    'فعالیت‌ها': 'فعالیت‌ها',
    'پسندیدن پست‌ها': 'پسندیدن پست‌ها',
    'وقتی کسی پست شما را می‌پسندد': 'وقتی کسی پست شما را می‌پسندد',
    'این تنظیمات برای اعلان‌های داخل اپ است.':
        'این تنظیمات برای اعلان‌های داخل اپ است.',
    'پروفایل کاربر': 'پروفایل کاربر',
    'دنبال می‌کنید': 'دنبال می‌کنید',
    'دنبال کردن': 'دنبال کردن',
    'دنبال‌شونده‌ها': 'دنبال‌شونده‌ها',
    'لینک باز نشد.': 'لینک باز نشد.',
    'هنوز پستی منتشر نشده است.': 'هنوز پستی منتشر نشده است.',
    'کشف کاربران': 'کشف کاربران',
    'جست‌وجوی نام کاربری': 'جست‌وجوی نام کاربری',
    'کاربری پیدا نشد.': 'کاربری پیدا نشد.',
    'تغییر تصویر پروفایل': 'تغییر تصویر پروفایل',
    'نام نمایشی را وارد کنید.': 'نام نمایشی را وارد کنید.',
    'نام نمایشی': 'نام نمایشی',
    'درباره من': 'درباره من',
    'لینک‌های عمومی': 'لینک‌های عمومی',
    'آدرس معتبر https وارد کنید.': 'آدرس معتبر https وارد کنید.',
    'انتخاب تصویر پروفایل': 'انتخاب تصویر پروفایل',
    'انتخاب کاور': 'انتخاب کاور',
    'ذخیره تغییرات': 'ذخیره تغییرات',
    'پست‌های ذخیره‌شده': 'پست‌های ذخیره‌شده',
    'هنوز پستی ذخیره نکرده‌اید.': 'هنوز پستی ذخیره نکرده‌اید.',
    'برای استوری تصویر یا ویدیو انتخاب کنید.':
        'برای استوری تصویر یا ویدیو انتخاب کنید.',
    'استوری جدید': 'استوری جدید',
    'پست جدید': 'پست جدید',
    'لحظه‌های موسیقایی شما، برای ۲۴ ساعت':
        'لحظه‌های موسیقایی شما، برای ۲۴ ساعت',
    'اجرای تازه، تمرین امروز یا تجربه‌ات را منتشر کن.':
        'اجرای تازه، تمرین امروز یا تجربه‌ات را منتشر کن.',
    'انتخاب تصویر یا ویدیو': 'انتخاب تصویر یا ویدیو',
    'تصویر تا ۱۰ مگابایت · ویدیو تا ۱۰۰ مگابایت':
        'تصویر تا ۱۰ مگابایت · ویدیو تا ۱۰۰ مگابایت',
    'در حال ارسال؛ صفحه را باز نگه دارید.':
        'در حال ارسال؛ صفحه را باز نگه دارید.',
    'انتشار': 'انتشار',
    'پخش ویدیو ممکن نشد.': 'پخش ویدیو ممکن نشد.',
    'توقف': 'توقف',
    'پخش': 'پخش',
    'پنل کاربری': 'پنل کاربری',
    'به جمع اهالی موسیقی بپیوندید': 'به جمع اهالی موسیقی بپیوندید',
    'ورود یا ثبت‌نام': 'ورود یا ثبت‌نام',
    'دوره جدید': 'دوره جدید',
    'دنیای موسیقی من': 'دنیای موسیقی من',
    'پست‌ها و استوری‌ها': 'پست‌ها و استوری‌ها',
    'جست‌وجوی کاربران': 'جست‌وجوی کاربران',
    'استوری من': 'استوری من',
    'هنوز پستی منتشر نشده؛ اولین اجرای خود را به اشتراک بگذارید.':
        'هنوز پستی منتشر نشده؛ اولین اجرای خود را به اشتراک بگذارید.',
    'در حال دریافت…': 'در حال دریافت…',
    'نمایش بیشتر': 'نمایش بیشتر',
    'ساخت محتوا': 'ساخت محتوا',
    'پروفایل': 'پروفایل',
    'حذف پست': 'حذف پست',
    'این پست حذف شود؟': 'این پست حذف شود؟',
    'حالت تاریک': 'حالت تاریک',
    'نمایش برنامه با تم تاریک': 'نمایش برنامه با تم تاریک',
    'برنامه': 'برنامه',
    'نشان‌شده‌ها': 'نشان‌شده‌ها',
    'محتواهایی که نشان می‌کنید در این بخش نمایش داده می‌شوند.':
        'محتواهایی که نشان می‌کنید در این بخش نمایش داده می‌شوند.',
    'اشتراک‌گذاری برنامه': 'اشتراک‌گذاری برنامه',
    'پرسش‌های متداول': 'پرسش‌های متداول',
    'دستاوردها و روند پیشرفت آموزشی شما در این بخش نمایش داده می‌شود.':
        'دستاوردها و روند پیشرفت آموزشی شما در این بخش نمایش داده می‌شود.',
    'حریم خصوصی': 'حریم خصوصی',
    'جامعه': 'جامعه',
    'تماس با ما': 'تماس با ما',
    'عضویت': 'عضویت',
    'جزئیات عضویت و خدمات حساب شما پس از فعال شدن طرح‌های عضویت اینجا قرار می‌گیرد.':
        'جزئیات عضویت و خدمات حساب شما پس از فعال شدن طرح‌های عضویت اینجا قرار می‌گیرد.',
    'حساب من': 'حساب من',
    'ورود با حساب دیگر': 'ورود با حساب دیگر',
    'خروج از حساب': 'خروج از حساب',
    'حساب‌های کاربری': 'حساب‌های کاربری',
    'افزودن حساب کاربری': 'افزودن حساب کاربری',
    'چطور در سرناز ثبت‌نام کنم؟': 'چطور در سرناز ثبت‌نام کنم؟',
    'آیا بدون حساب کاربری می‌توانم از برنامه استفاده کنم؟':
        'آیا بدون حساب کاربری می‌توانم از برنامه استفاده کنم؟',
    'چطور با پشتیبانی تماس بگیرم؟': 'چطور با پشتیبانی تماس بگیرم؟',
    'متن پیام را وارد کنید.': 'متن پیام را وارد کنید.',
    'پیام شما ارسال شد. در اولین فرصت پاسخ می‌دهیم.':
        'پیام شما ارسال شد. در اولین فرصت پاسخ می‌دهیم.',
    'ارسال پیام انجام نشد؛ اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.':
        'ارسال پیام انجام نشد؛ اتصال اینترنت را بررسی کنید و دوباره تلاش کنید.',
    'ارتباط با ما — ارسال پیام جدید': 'ارتباط با ما — ارسال پیام جدید',
    'نام و نام خانوادگی': 'نام و نام خانوادگی',
    'ایمیل پاسخ (اختیاری)': 'ایمیل پاسخ (اختیاری)',
    'موضوع': 'موضوع',
    'متن پیام *': 'متن پیام *',
    'ارسال پیام': 'ارسال پیام',
    'سایت سرناز': 'سایت سرناز',
    'کانال تلگرام': 'کانال تلگرام',
    'کانال یوتیوب': 'کانال یوتیوب',
    'صفحه اینستاگرام': 'صفحه اینستاگرام',
    'ایمیل': 'ایمیل',
    'برنامه‌ای برای باز کردن این پیوند پیدا نشد.':
        'برنامه‌ای برای باز کردن این پیوند پیدا نشد.',
    'اشتراک‌گذاری فایل نصب در این دستگاه ممکن نشد. از لینک سایت استفاده کنید.':
        'اشتراک‌گذاری فایل نصب در این دستگاه ممکن نشد. از لینک سایت استفاده کنید.',
    'سرناز را به دوستان خود معرفی کنید و در شبکه‌های اجتماعی همراه ما باشید.':
        'سرناز را به دوستان خود معرفی کنید و در شبکه‌های اجتماعی همراه ما باشید.',
    'آماده‌سازی فایل نصب…': 'آماده‌سازی فایل نصب…',
    'ارسال فایل نصبی برنامه': 'ارسال فایل نصبی برنامه',
    'درس': 'درس',
    'رایگان': 'رایگان',
    'تومان': 'تومان',
    'مشاهده دوره': 'مشاهده دوره',
    'فیلتر': 'فیلتر',
    'پاک کردن': 'پاک کردن',
    'امتیاز': 'امتیاز',
    'و بالاتر': 'و بالاتر',
    'مدت ویدیو': 'مدت ویدیو',
    'ساعت': 'ساعت',
    'دسته‌بندی‌ها': 'دسته‌بندی‌ها',
    'اعمال فیلترها': 'اعمال فیلترها',
    'جست‌وجوی دوره، موضوع، مدرس…': 'جست‌وجوی دوره، موضوع، مدرس…',
    'فیلترها': 'فیلترها',
    'نتیجه‌ای برای فیلتر و جست‌وجو پیدا نشد':
        'نتیجه‌ای برای فیلتر و جست‌وجو پیدا نشد',
    'فیلترها یا عبارت جست‌وجو را تغییر دهید.':
        'فیلترها یا عبارت جست‌وجو را تغییر دهید.',
    'دوره‌ها': 'دوره‌ها',
    'نظر شما چیست؟': 'نظر شما چیست؟',
    'این دوره را پیشنهاد می‌کنید؟': 'این دوره را پیشنهاد می‌کنید؟',
    'بله': 'بله',
    'خیر': 'خیر',
    'نظر خود درباره این دوره را بنویسید': 'نظر خود درباره این دوره را بنویسید',
    'با موفقیت ثبت شد': 'با موفقیت ثبت شد',
    'از بازخورد ارزشمند شما سپاسگزاریم.': 'از بازخورد ارزشمند شما سپاسگزاریم.',
    'بستن': 'بستن',
    'ثبت نظر': 'ثبت نظر',
    'گزارش مشکل': 'گزارش مشکل',
    'انصراف': 'انصراف',
    'گزارش ثبت شد.': 'گزارش ثبت شد.',
    'لینک دوره کپی شد.': 'لینک دوره کپی شد.',
    'هنرجو': 'هنرجو',
    'درس‌ها': 'درس‌ها',
    'منابع': 'منابع',
    'درباره': 'درباره',
    'پرسش‌وپاسخ': 'پرسش‌وپاسخ',
    'پسندیدن': 'پسندیدن',
    'نپسندیدن': 'نپسندیدن',
    'اشتراک‌گذاری': 'اشتراک‌گذاری',
    'دوره‌های مرتبط': 'دوره‌های مرتبط',
    'نظر': 'نظر',
    'منابع و فایل‌های قابل دانلود': 'منابع و فایل‌های قابل دانلود',
    'برای مشاهده منابع ابتدا دوره را تهیه کنید.':
        'برای مشاهده منابع ابتدا دوره را تهیه کنید.',
    'خلاصه': 'خلاصه',
    'فصل': 'فصل',
    'توضیحات': 'توضیحات',
    'زمان یادگیری را برنامه‌ریزی کنید': 'زمان یادگیری را برنامه‌ریزی کنید',
    'برای یادگیری این دوره زمان مشخصی انتخاب کنید.':
        'برای یادگیری این دوره زمان مشخصی انتخاب کنید.',
    'شروع کنید': 'شروع کنید',
    'مدرس دوره': 'مدرس دوره',
    'مشاهده پروفایل': 'مشاهده پروفایل',
    'نظرات': 'نظرات',
    'هنوز نظری ثبت نشده است.': 'هنوز نظری ثبت نشده است.',
    'اولین پرسش را مطرح کنید.': 'اولین پرسش را مطرح کنید.',
    'در حال پاسخ به پرسش': 'در حال پاسخ به پرسش',
    'پرسشی مطرح کنید…': 'پرسشی مطرح کنید…',
    'در حال اتصال…': 'در حال اتصال…',
    'ثبت‌نام در دوره': 'ثبت‌نام در دوره',
    'مشاهده همه': 'مشاهده همه',
    'ارتباط برقرار نشد. دوباره تلاش کنید.':
        'ارتباط برقرار نشد. دوباره تلاش کنید.',
    'تلاش دوباره': 'تلاش دوباره',
    'منو': 'منو',
    'فیلتر دوره‌ها': 'فیلتر دوره‌ها',
    'تازه‌های وبلاگ': 'تازه‌های وبلاگ',
    'مقاله‌ها دریافت نشدند.': 'مقاله‌ها دریافت نشدند.',
    'مقاله‌ای پیدا نشد.': 'مقاله‌ای پیدا نشد.',
    'دوره‌های جدید': 'دوره‌های جدید',
    'دوره‌ها دریافت نشدند.': 'دوره‌ها دریافت نشدند.',
    'دوره‌ای با این مشخصات پیدا نشد.': 'دوره‌ای با این مشخصات پیدا نشد.',
    'دوره‌های به‌روزشده': 'دوره‌های به‌روزشده',
    'برای شروع یادگیری': 'برای شروع یادگیری',
    'مدرسان و نویسندگان': 'مدرسان و نویسندگان',
  };

  static const font_iran_sans = 'font_iran_sans,';
  static const font_iran_yekan = 'font_iran_yekan,';
  static const font_kalameh = 'font_kalameh,';
  static const font_tahrir = 'font_tahrir,';
  static const font_sahel = 'font_sahel,';
  static const font_vazir = 'font_vazir,';
  static const font_peyda = 'font_peyda,';
  static const select_font_description = 'select_font_description,';
  static const select_font_title = 'select_font_title,';

  static const application_name = 'applicationName';
  static const application_fullname = 'applicationFullname';
  static const application_email = 'applicationEmail';

  static const faq_title = 'faqTitle';
  static const home_title = 'homeTitle';
  static const blogs_title = 'blogsTitle';
  static const tuner_title = 'tunerTitle';
  static const splash_title = 'splashTitle';
  static const courses_title = 'coursesTitle';
  static const authors_title = 'authorsTitle';
  static const profile_title = 'profileTitle';
  static const sign_up_title = 'signUpTitle';
  static const sign_in_title = 'signInTitle';
  static const about_us_title = 'aboutUsTitle';
  static const articles_title = 'articlesTitle';
  static const settings_title = 'settingsTitle';
  static const metronome_title = 'metronomeTitle';
  static const onboarding_title = 'onboardingTitle';
  static const contact_us_title = 'contactUsTitle';
  static const music_sheet_title = 'musicSheetTitle';
  static const music_player_title = 'musicPlayerTitle';
  static const privacy_policy_title = 'privacyPolicyTitle';
  static const voice_recorder_title = 'voiceRecorderTitle';
  static const forgot_password_title = 'forgotPasswordTitle';
  static const article_detail_page_title = 'articleDetailPageTitle';
  static const onboarding_title_0 = 'onboarding_title_0';
  static const onboarding_subtitle_0 = 'onboarding_subtitle_0';
  static const onboarding_title_1 = 'onboarding_title_1';
  static const onboarding_subtitle_1 = 'onboarding_subtitle_1';
  static const onboarding_title_2 = 'onboarding_title_2';
  static const onboarding_subtitle_2 = 'onboarding_subtitle_2';
  static const dont_have_an_account = 'dont have an account';
  static const sign_in_with_google = 'sign in with google';
  static const forgot_password = 'forgot password';
  static const remember_me = 'remember me';
  static const password = 'password';
  static const email = 'email';
  static const sign_in_description = 'sign in description';
  static const sent_otp_via_email = 'sent otp via email';
  static const sent_otp_via_phone_number = 'sent otp via phone number';
  static const phone_number = 'phone number';
  static const send_otp_via_email = 'send otp via email';
  static const send_otp_via_phone_number = 'send otp via phone number';
  static const send_otp_code = 'send otp code';
  static const already_have_an_account = 'already have an account';
  static const bookmark = 'bookmark';
  static const share_app = 'share app';
  static const achievements = 'achievements';
  static const community = 'community';
  static const share_feedback = 'share feedback';
  static const membership = 'membership';
  static const my_account = 'my account';
  static const switch_acount = 'switch account';
  static const logout = 'logout account';
  static const top_active_authors = 'top active Authors';
  static const push_notifications = 'push notifications';
  static const push_notifications_subtitle = 'push_notifications_subtitle';
  static const new_course_alerts = 'new course alerts';
  static const new_course_alerts_description = 'new_course_alerts_description';
  static const dataTitle = 'data title';
  static const use_wifi = 'use wiFi';
  static const use_wifi_description = 'use wifi description';
  static const auto_download = 'auto download';
  static const auto_download_description = 'auto download description';
  static const two_times_press_back_button_for_exit_application =
      'two times press back button for exit application';
  static const home_searchbar_hint = 'homeSearchbarHint';
  static const new_courses_title = 'newCoursesTitle';
  static const last_blog_title = 'lastBlogTitle';
  static const view_all_link = 'viewAllLink';
  static const no_title = 'noTitle';
  static const error_in_loading = 'errorInLoading';
  static const failed_to_load_posts = 'failedToLoadPosts';
  static const failed_to_load_categories = 'failedToLoadCategories';
  static const previous_button = 'previousButton';
  static const next_button = 'nextButton';
  static const start_button = 'startButton';
  static const dark_mode = 'darkMode';
  static const dark_mode_description = 'darkModeDescription';
  static const music_player_search_hint = 'musicPlayerSearchHint';
  static const audio_file_not_found = 'audioFileNotFound';
  static const press_back_to_exit = 'pressBackToExit';
  static const no_records_file = 'noRecordsFile';
  static const all = 'all';
  static const without_title = 'withoutTitle';
  static const without_briefs = 'withoutBriefs';
  static const send_comment = 'sendComment';
  static const comment = 'comment';
  static const comments = 'comments';
  static const without_comments = 'withoutComments';
  static const unknown = 'unknown';
  static const load_more_comments = 'loadMoreComments';
  static const write_your_comments = 'writeYourComments';
  static const take_your_point_to_article = 'takeYourPointToArticle';
  static const similar_articles = 'similarArticles';
  static const writer = 'writer';
  static const error_in_sending_comment = 'errorInSendingComment';
  static const guest_user = 'guestUser';
  static const without_content = 'withoutContent';
  static const notification_title = 'notificationTitle';
  static const appearance_title = 'appearanceTitle';
  static const elements = 'elements';
  static const font_size = 'fontSize';
  static const font_size_description = 'fontSizeDescription';
  static const font_weight = 'fontWeight';
  static const font_weight_description = 'fontWeightDescription';
  static const grant_audio_permission = 'grantAudioPermission';
  static const error_loading_files = 'errorLoadingFiles';
  static const set_base_frequency = 'setBaseFrequency';
  static const hz = 'hz';
  static const hertz = 'hertz';
  static const cents = 'cents';
  static const stop = 'stop';
  static const pause = 'pause';
  static const play = 'play';
  static const launch = 'launch';
  static const launch_again = 'launchAgain';
  static const bpm = 'bpm';
  static const timing = 'timing';
  static const volume = 'volume';
  static const language_mode = 'languageMode';
  static const language_mode_description = 'languageModeDescription';

  static const record_date_title = 'RecordDateTitle';
  static const filename_title = 'FilenameTitle';

  static const about_us_page_title = 'aboutUsPageTitle';
  static const about_us_our_mission_title = 'aboutUsOurMissionTitle';
  static const about_us_our_vision_title = 'aboutUsOurVisionTitle';
  static const about_us_our_values_title = 'aboutUsOurValuesTitle';
  static const about_us_our_story_title = 'aboutUsOurStoryTitle';
  static const about_us_our_team_title = 'aboutUsOurTeamTitle';
  static const about_us_key_features_title = 'aboutUsKeyFeaturesTitle';
  static const about_us_our_commitment_title = 'aboutUsOurCommitmentTitle';
  static const about_us_contact_information_title =
      'aboutUsContactInformationTitle';
  static const about_us_page_description = 'aboutUsPageDescription';
  static const about_us_our_mission_description =
      'aboutUsOurMissionDescription';
  static const about_us_our_vision_description = 'aboutUsOurVisionDescription';
  static const about_us_our_values_description = 'aboutUsOurValuesDescription';
  static const about_us_our_story_description = 'aboutUsOurStoryDescription';
  static const about_us_our_team_description = 'aboutUsOurTeamDescription';
  static const about_us_key_features_description =
      'aboutUsKeyFeaturesDescription';
  static const about_us_our_commitment_description =
      'aboutUsOurCommitmentDescription';
  static const about_us_contact_information_description =
      'aboutUsContactInformationDescription';
  static const audio_list_preparing_folders = 'audioListPreparingFolders';
  static const music_player_scanning_files = 'musicPlayerScanningFiles';
  static const music_player_scanned_files = 'musicPlayerScannedFiles';
  static const song_information_no_song_playing =
      'songInformationNoSongPlaying';
  static const audio_player_provider_changed_filename =
      'audioPlayerProviderChangedFilename';
  static const audio_player_provider_remove_from_list =
      'audioPlayerProviderRemoveFromList';
  static const audio_player_provider_delete_from_memory =
      'audioPlayerProviderDeleteFromMemory';
  static const folder_list_view_preparing_folders =
      'folderListViewPreparingFolders';
  static const folder_list_view_song = 'folderListViewSong';
  static const audio_controls_1x_speed = 'audioControls1xSpeed';
  static const file_action_change_filename = "fileActionChangeFilename";
  static const file_action_remove = "fileActionRemove";
  static const file_action_new_filename = "fileActionNewFilename";
  static const file_action_discard = "fileActionDiscard";
  static const file_action_save = "fileActionSave";
  static const file_action_changed_filename = "fileActionChangedFilename";
  static const file_action_error_in_changed_filename =
      "fileActionErrorInChangedFilename";
  static const file_action_remove_file = "fileActionRemoveFile";
  static const file_action_remove_file_from_list_or_memory =
      "fileActionRemoveFileFromListOrMemory";
  static const file_action_remove_file_from_list =
      "fileActionRemoveFileFromList";
  static const file_action_removed_file_from_list =
      "fileActionRemovedFileFromList";
  static const file_action_error_in_removed_file_from_list =
      "fileActionErrorInRemovedFileFromList";
  static const file_action_delete_file_from_memory =
      "fileActionDeleteFileFromMemory";
  static const file_action_deleted_file_from_memory =
      "fileActionDeletedFileFromMemory";
  static const file_action_error_in_deleted_file_from_memory =
      "fileActionErrorInDeletedFileFromMemory";
  static const waveform_widget_zoom_label = "waveformWidgetZoomLabel";
  static const song_information_title = 'songInformationTitle';
  static const song_information_artists = 'songInformationArtists';
  static const song_information_album = 'songInformationAlbum';
  static const song_information_genre = 'songInformationGenre';
  static const song_information_year = 'songInformationYear';
  static const song_information_duration = 'songInformationDuration';
  static const song_information_bitrate = 'songInformationBitrate';
  static const record_details_record_information =
      'recordDetailsRecordInformation';
  static const delete_button_widget_delete = 'deleteButtonWidgetDelete';
  static const delete_button_widget_confirm_delete =
      'deleteButtonWidgetConfirmDelete';
  static const delete_button_widget_delete_question_before_filename_part =
      'deleteButtonWidgetDeleteQuestionBeforeFilenamePart';
  static const delete_button_widget_delete_question_after_filename_part =
      'deleteButtonWidgetDeleteQuestionAfterFilenamePart';
  static const delete_button_widget_discard_button =
      'deleteButtonWidgetDiscardButton';
  static const delete_button_widget_confirm_delete_button =
      'deleteButtonWidgetConfirmDeleteButton';
  static const rename_button_widget_rename = 'renameButtonWidgetRename';
  static const rename_button_widget_new_filename =
      'renameButtonWidgetNewFilename';
  static const rename_button_widget_discard = 'renameButtonWidgetDiscard';
  static const rename_button_widget_save = 'renameButtonWidgetSave';

  static const voice_recorder_microphone_and_storage_access_permissions =
      'voice_recorder_microphone_and_storage_access_permissions';
  static const voice_recorder_file_deleted = 'voiceRecorderFileDeleted';
  static const voice_recorder_file_restored = 'voiceRecorderFileRestored';
  static const voice_recorder_label_restore = 'voiceRecorderLabelRestore';
  static const voice_recorder_delete_recording = 'voiceRecorderDeleteRecording';
  static const voice_recorder_confirm_delete_before_filename =
      'voiceRecorderConfirmDeleteBeforeFilename';
  static const voice_recorder_confirm_delete_after_filename =
      'voiceRecorderConfirmDeleteAfterFilename';
  static const voice_recorder_no = 'voiceRecorderNo';
  static const voice_recorder_yes_delete = 'voiceRecorderYesDelete';
  static const voice_recorder_delete_message_before_filename =
      'voiceRecorderDeleteMessageBeforeFilename';
  static const voice_recorder_delete_message_after_filename =
      'voiceRecorderDeleteMessageAfterFilename';
  static const voice_recorder_rename_file = 'voiceRecorderRenameFile';
  static const voice_recorder_new_filename = 'voiceRecorderNewFilename';
  static const voice_recorder_discard = 'voiceRecorderDiscard';
  static const voice_recorder_save = 'voiceRecorderSave';
  static const voice_recorder_filename_changed_before_filename =
      'voiceRecorderFilenameChangedBeforeFilename';
  static const voice_recorder_filename_changed_after_filename =
      'voiceRecorderFilenameChangedAfterFilename';
  static const voice_recorder_error_in_renaming =
      'voiceRecorderErrorInRenaming';

  static const tuner_settings_title = 'tunerSettingsTitle';
  static const metronome_settings_title = 'metronomeSettingsTitle';
  static const volumes = 'volumes';
  static const tools = 'tools';
  static const show_bars_division_title = 'showBarsDivisionTilte';
  static const show_bars_division_subtitle = 'showBarsDivisionSubtilte';
  static const show_tap_tempo_title = 'showTapTempoTitle';
  static const show_tap_tempo_subtitle = 'showTapTempoSubtitle';
  static const enable_timer_stopwatch_title = 'enableTimerStopwatchTitle';
  static const enable_timer_stopwatch_subtitle = 'enableTimerStopwatchSubtitle';
  static const enable_bars_stopwatch_title = 'enableBarsStopwatchTitle';
  static const enable_bars_stopwatch_subtitle = 'enableBarsStopwatchSubitle';

  static const frequency = 'frequency';
  static const note_stretch = 'noteStretch';
  static const starting_octave = 'startingOctave';
  static const number_of_octaves = 'numberOfOctaves';
  static const highlight_a4_key = 'highlightA4Key';
  static const enable_a4_key_highlight = 'enableA4KeyHighlight';
  static const frequencies_on_white_keys = 'frequenciesOnWhiteKeys';
  static const enable_frequency_display_on_white_keys =
      'enableFrequencyDisplayOnWhiteKeys';
  static const frequencies_on_black_keys = 'frequenciesOnBlackKeys';
  static const enable_frequency_display_on_black_keys =
      'enableFrequencyDisplayOnBlackKeys';
  static const quarter_tones = 'quarterTones';
  static const enable_iranian_quarter_tones = 'enableIranianQuarterTones';

  static const update = 'update';

  static const need_permission = 'needPermission';
  static const need_permission_for_scanning_audio_files =
      'needPermissionForScanningAudioFiles';
  static const later = 'later';
  static const go_to_settings = 'goToSettings';

  static const bass = 'bass';
  static const mid = 'mid';
  static const treble = 'treble';

  static const memory = 'memory';

  static const show_all_folders = 'showAllFolders';
  static const show_folders_contains_audio_files =
      'showFoldersContainsAudioFiles';
  static const no_folder_or_audio_file_found_in_this_path =
      'noFolderOrAudioFileFoundInThisPath';

  static const coming_soon = 'comingSoon';
  static const timer = 'Timer';
  static const bars = 'Bars';
  static const minute = 'minute';
  static const second = 'second';

  static const delete_confirm_dialog_title = 'deleteConfirmDialogTitle';
  static const delete_confirm_dialog_content_before_filename =
      'deleteConfirmDialogContentBeforeFilename';
  static const delete_confirm_dialog_content_after_filename =
      'deleteConfirmDialogContentAfterFilename';
  static const delete_confirm_dialog_cancel_button =
      'deleteConfirmDialogCancelButton';
  static const delete_confirm_dialog_delete_button =
      'deleteConfirmDialogDeleteButton';

  static const voice_recorder_recording_icon_button_tooltip =
      'voiceRecorderRecordingIconButtonTooltip';
  static const voice_recorder_bookmark_text_button =
      'voiceRecorderBookmarkTextButton';

  static const recording_list_title = 'recordingListTitle';
  static const recording_list_search_hint = 'recordingListSearchHint';
  static const recording_list_multi_item_selected =
      'recordingListMultiItemSelected';
  static const recording_list_share = 'recordingListShare';
  static const recording_list_favorite = 'recordingListFavorite';
  static const recording_list_rename = 'recordingListRename';
  static const recording_list_delete = 'recordingListDelete';
  static const recording_list_multi_item_delete_content =
      'recordingListMultiItemDeleteContent';
  static const recording_list_delete_content = 'recordingListDeleteContent';

  static const audio_library_manager_preparing = 'audioLibraryManagerPreparing';
  static const audio_library_manager_fininshed_loading_from_memory =
      'audioLibraryManagerFininshedLoadingFromMemory';
  static const audio_library_manager_calculating_audio_files =
      'audioLibraryManagerCalculatingAudioFiles';
  static const audio_library_manager_error_in_loading =
      'audioLibraryManagerErrorInLoading';
  static const audio_file_loader_calculating = 'audioFileLoaderCalculating';
  static const audio_library_manager_fininshed_calculating =
      'audioLibraryManagerFininshedCalculating';

  static const utton = '';

  static List<Map<String, dynamic>> getOnboardingPages(String lang) {
    final isEn = lang == 'en';

    return [
      {
        'image': AppImages.onboarding_image_0,
        'title': isEn
            ? AppStrings.en['onboarding_title_0']!
            : AppStrings.fa['onboarding_title_0']!,
        'subtitle': isEn
            ? AppStrings.en['onboarding_subtitle_0']!
            : AppStrings.fa['onboarding_subtitle_0']!,
        'buttons': [AppStrings.next_button],
      },
      {
        'image': AppImages.onboarding_image_1,
        'title': isEn
            ? AppStrings.en['onboarding_title_1']!
            : AppStrings.fa['onboarding_title_1']!,
        'subtitle': isEn
            ? AppStrings.en['onboarding_subtitle_1']!
            : AppStrings.fa['onboarding_subtitle_1']!,
        'buttons': [AppStrings.previous_button, AppStrings.next_button],
      },
      {
        'image': AppImages.onboarding_image_2,
        'title': isEn
            ? AppStrings.en['onboarding_title_2']!
            : AppStrings.fa['onboarding_title_2']!,
        'subtitle': isEn
            ? AppStrings.en['onboarding_subtitle_2']!
            : AppStrings.fa['onboarding_subtitle_2']!,
        'buttons': [AppStrings.previous_button, AppStrings.start_button],
      },
    ];
  }

  static const allKeys = [
    select_font_title,
    select_font_description,
    font_iran_sans,
    font_iran_yekan,
    font_kalameh,
    font_tahrir,
    font_sahel,
    font_vazir,
    font_peyda,
    application_name,
    application_fullname,
    application_email,
    faq_title,
    home_title,
    blogs_title,
    tuner_title,
    splash_title,
    sign_up_title,
    sign_in_title,
    courses_title,
    authors_title,
    profile_title,
    about_us_title,
    articles_title,
    settings_title,
    metronome_title,
    contact_us_title,
    onboarding_title,
    music_sheet_title,
    music_player_title,
    privacy_policy_title,
    voice_recorder_title,
    forgot_password_title,
    article_detail_page_title,
    onboarding_title_0,
    onboarding_subtitle_0,
    onboarding_title_1,
    onboarding_subtitle_1,
    onboarding_title_2,
    onboarding_subtitle_2,
    dont_have_an_account,
    sign_in_with_google,
    forgot_password,
    remember_me,
    password,
    email,
    sign_in_description,
    sent_otp_via_email,
    sent_otp_via_phone_number,
    phone_number,
    send_otp_via_email,
    send_otp_via_phone_number,
    send_otp_code,
    already_have_an_account,
    bookmark,
    share_app,
    achievements,
    community,
    share_feedback,
    membership,
    my_account,
    switch_acount,
    logout,
    top_active_authors,
    push_notifications,
    push_notifications_subtitle,
    new_course_alerts,
    new_course_alerts_description,
    dataTitle,
    use_wifi,
    use_wifi_description,
    auto_download,
    auto_download_description,
    two_times_press_back_button_for_exit_application,
    home_searchbar_hint,
    new_courses_title,
    last_blog_title,
    view_all_link,
    no_title,
    error_in_loading,
    failed_to_load_posts,
    failed_to_load_categories,
    previous_button,
    next_button,
    start_button,
    dark_mode,
    dark_mode_description,
    music_player_search_hint,
    audio_file_not_found,
    press_back_to_exit,
    no_records_file,
    all,
    without_title,
    without_briefs,
    send_comment,
    comment,
    comments,
    without_comments,
    unknown,
    load_more_comments,
    write_your_comments,
    take_your_point_to_article,
    similar_articles,
    writer,
    error_in_sending_comment,
    guest_user,
    without_content,
    notification_title,
    appearance_title,
    elements,
    font_size,
    font_size_description,
    font_weight,
    font_weight_description,
    grant_audio_permission,
    error_loading_files,
    set_base_frequency,
    hz,
    hertz,
    cents,
    stop,
    pause,
    play,
    launch,
    launch_again,
    bpm,
    timing,
    volume,
    language_mode,
    language_mode_description,

    record_date_title,
    filename_title,

    about_us_page_title,
    about_us_our_mission_title,
    about_us_our_vision_title,
    about_us_our_values_title,
    about_us_our_story_title,
    about_us_our_team_title,
    about_us_key_features_title,
    about_us_our_commitment_title,
    about_us_contact_information_title,
    about_us_page_description,
    about_us_our_mission_description,
    about_us_our_vision_description,
    about_us_our_values_description,
    about_us_our_story_description,
    about_us_our_team_description,
    about_us_key_features_description,
    about_us_our_commitment_description,
    about_us_contact_information_description,
    audio_list_preparing_folders,
    music_player_scanning_files,
    music_player_scanned_files,
    song_information_no_song_playing,
    audio_player_provider_changed_filename,
    audio_player_provider_remove_from_list,
    audio_player_provider_delete_from_memory,
    folder_list_view_preparing_folders,
    folder_list_view_song,
    audio_controls_1x_speed,
    file_action_change_filename,
    file_action_remove,
    file_action_new_filename,
    file_action_discard,
    file_action_save,
    file_action_changed_filename,
    file_action_error_in_changed_filename,
    file_action_remove_file,
    file_action_remove_file_from_list_or_memory,
    file_action_remove_file_from_list,
    file_action_removed_file_from_list,
    file_action_error_in_removed_file_from_list,
    file_action_delete_file_from_memory,
    file_action_deleted_file_from_memory,
    file_action_error_in_deleted_file_from_memory,
    waveform_widget_zoom_label,
    song_information_title,
    song_information_artists,
    song_information_album,
    song_information_genre,
    song_information_year,
    song_information_duration,
    song_information_bitrate,
    record_details_record_information,
    delete_button_widget_delete,
    delete_button_widget_confirm_delete,
    delete_button_widget_delete_question_before_filename_part,
    delete_button_widget_delete_question_after_filename_part,
    delete_button_widget_discard_button,
    delete_button_widget_confirm_delete_button,
    rename_button_widget_rename,
    rename_button_widget_new_filename,
    rename_button_widget_discard,
    rename_button_widget_save,
    voice_recorder_file_deleted,
    voice_recorder_microphone_and_storage_access_permissions,
    voice_recorder_file_restored,
    voice_recorder_label_restore,
    voice_recorder_delete_recording,
    voice_recorder_confirm_delete_before_filename,
    voice_recorder_confirm_delete_after_filename,
    voice_recorder_no,
    voice_recorder_yes_delete,
    voice_recorder_delete_message_before_filename,
    voice_recorder_delete_message_after_filename,
    voice_recorder_rename_file,
    voice_recorder_new_filename,
    voice_recorder_discard,
    voice_recorder_save,
    voice_recorder_filename_changed_before_filename,
    voice_recorder_filename_changed_after_filename,
    voice_recorder_error_in_renaming,
    tuner_settings_title,
    metronome_settings_title,
    volumes,
    tools,
    show_bars_division_title,
    show_bars_division_subtitle,
    show_tap_tempo_title,
    show_tap_tempo_subtitle,
    enable_timer_stopwatch_title,
    enable_timer_stopwatch_subtitle,
    enable_bars_stopwatch_title,
    enable_bars_stopwatch_subtitle,
    frequency,
    timer,
    bars,
    minute,
    second,
    coming_soon,
    frequency,
    note_stretch,
    starting_octave,
    number_of_octaves,
    highlight_a4_key,
    enable_a4_key_highlight,
    frequencies_on_white_keys,
    enable_frequency_display_on_white_keys,
    frequencies_on_black_keys,
    enable_frequency_display_on_black_keys,
    quarter_tones,
    enable_iranian_quarter_tones,
    update,
    need_permission,
    need_permission_for_scanning_audio_files,
    later,
    go_to_settings,
    bass,
    mid,
    treble,
    memory,
    show_all_folders,
    show_folders_contains_audio_files,
    no_folder_or_audio_file_found_in_this_path,

    delete_confirm_dialog_title,
    delete_confirm_dialog_content_before_filename,
    delete_confirm_dialog_content_after_filename,
    delete_confirm_dialog_cancel_button,
    delete_confirm_dialog_delete_button,

    voice_recorder_recording_icon_button_tooltip,
    voice_recorder_bookmark_text_button,

    recording_list_title,
    recording_list_search_hint,
    recording_list_multi_item_selected,
    recording_list_share,
    recording_list_favorite,
    recording_list_rename,
    recording_list_delete,
    recording_list_multi_item_delete_content,
    recording_list_delete_content,

    audio_library_manager_preparing,
    audio_library_manager_fininshed_loading_from_memory,
    audio_library_manager_calculating_audio_files,
    audio_library_manager_error_in_loading,
    audio_file_loader_calculating,
    audio_library_manager_fininshed_calculating,
  ];

  static const en = {
    ...learningEn,
    select_font_title: 'Select Font',
    select_font_description: 'Select your Favorite Font',
    font_iran_sans: 'Iran SansX',
    font_iran_yekan: 'Iran Yekan',
    font_kalameh: 'Kalameh',
    font_tahrir: 'Tahrir',
    font_sahel: 'Sahel',
    font_vazir: 'Vazir',
    font_peyda: 'Peyda',
    application_name: 'Sornaz',
    application_fullname: 'Sornaz Music Application',
    application_email: 'sornaz.ac@gmail.com',
    faq_title: 'FAQ',
    home_title: 'Home',
    blogs_title: 'Blogs',
    tuner_title: 'Tuner',
    splash_title: 'Splash',
    sign_up_title: 'Sign Up',
    sign_in_title: 'Sign In',
    courses_title: 'Courses',
    authors_title: 'Authors',
    profile_title: 'Profile',
    about_us_title: 'About Us',
    articles_title: 'Articles',
    settings_title: 'Settings',
    metronome_title: 'Metronome',
    contact_us_title: 'Contact Us',
    onboarding_title: 'Onboarding',
    music_sheet_title: 'Music Sheet',
    music_player_title: 'Music Player',
    privacy_policy_title: 'Privacy Policy',
    voice_recorder_title: 'Voice Recorder',
    forgot_password_title: 'Forgot Password',
    article_detail_page_title: 'Article Detail Page',

    onboarding_title_0: 'Theory and practice complete each other.',
    onboarding_subtitle_0:
        'Real progress comes from blending musical knowledge - consistent practice.',
    onboarding_title_1: 'Lasting learning takes time.',
    onboarding_subtitle_1:
        'Musical progress requires patience, regular training, and structured learning.',
    onboarding_title_2: 'Music begins with the basics.',
    onboarding_subtitle_2:
        'True learning starts with understanding the foundations and core principles of music.',

    dont_have_an_account: 'Don\'t have an account? Sign up',
    sign_in_with_google: 'Sign In with Google',
    forgot_password: 'Have you forgotten your password?',
    remember_me: 'Remember me',
    password: 'Password',
    email: 'Email',
    sign_in_description: 'Welcome! Please sign in to your account',
    sent_otp_via_email: 'OTP code has been sent via your email',
    sent_otp_via_phone_number: 'OTP code has been sent via your phone number',
    phone_number: 'Phone Number',
    send_otp_via_email: 'Sent OTP code with Email',
    send_otp_via_phone_number: 'Sent OTP code with Phone Number',
    send_otp_code: 'Send OTP Code',
    already_have_an_account: 'Already have an account? Sign In',

    bookmark: 'Bookmark',
    share_app: 'Share App',
    achievements: 'Achievements',
    community: 'Community',
    share_feedback: 'Share Feedback',
    membership: 'Membership',
    my_account: 'My Account',
    switch_acount: 'Switch to Another Account',
    logout: 'Logout Account',
    top_active_authors: 'Top Active Authors',

    push_notifications: 'Push Notifications',
    push_notifications_subtitle: 'Get notified of app alerts',
    new_course_alerts: 'New course alerts',
    new_course_alerts_description: 'Know when instructors upload',

    dataTitle: 'Data',
    use_wifi: 'Use WiFi',
    use_wifi_description: 'App will use wifi over data',

    auto_download: 'Auto-download',
    auto_download_description: 'Courses will automatically save to your device',

    two_times_press_back_button_for_exit_application:
        'Press again BACK Button for Exit Application',

    home_searchbar_hint: 'Search Blogs',
    new_courses_title: 'New Courses',
    last_blog_title: 'Last Blog',
    view_all_link: 'View all',

    no_title: 'No Title',
    error_in_loading: 'Error loading data',
    failed_to_load_posts: 'Failed to load posts',
    failed_to_load_categories: 'Failed to load categories',

    previous_button: 'Previous',
    next_button: 'Next',
    start_button: 'Start',

    dark_mode: 'Dark Mode',
    dark_mode_description: 'Enable dark appearance',

    music_player_search_hint: 'Search in audio files ...',
    audio_file_not_found: 'Audio file not found!',
    press_back_to_exit: 'Press again BACK Button to exit',

    no_records_file: 'No records found',

    all: 'All',
    without_title: 'Without Title',
    without_briefs: 'Without Briefs',

    send_comment: 'Send Comment',
    comment: 'Comment',
    comments: 'Comments',
    without_comments: 'Without Comments',

    unknown: 'Unknown',
    load_more_comments: 'Load More Comments',
    write_your_comments: 'Write your comments',
    take_your_point_to_article: 'Your rate for this article',

    similar_articles: 'Similar Articles',
    writer: 'Writer',

    error_in_sending_comment: 'Error in sending comment',
    guest_user: 'Guest User',
    without_content: 'Without Content',

    notification_title: 'Notification',
    appearance_title: 'Appearance',
    elements: 'Elements',
    font_size: 'Font Size',
    font_size_description: 'Set Font Size',
    font_weight: 'Font Weight',
    font_weight_description: 'Set Font Weight',

    grant_audio_permission:
        'Please grant permission to access audio files in the app settings.',
    error_loading_files: 'Error loading files',

    set_base_frequency: 'Set Base Frequency (A4) : ',
    hz: 'Hz',
    hertz: 'HERTZ',
    cents: 'CENTS',

    stop: 'Stop',
    pause: 'Pause',
    play: 'Play',

    launch: 'Launch',
    launch_again: 'Launch Again',

    bpm: 'BPM',
    timing: 'Timing',
    volume: 'Volume',

    language_mode: 'Language',
    language_mode_description: 'Switch to Persian',

    record_date_title: 'Record Date :',
    filename_title: 'Filename :',

    about_us_page_title: 'About Us – Sornaz Education App',
    about_us_our_mission_title: 'Our Mission',
    about_us_our_vision_title: 'Our Vision',
    about_us_our_values_title: 'Our Values',
    about_us_our_story_title: 'Our Story',
    about_us_our_team_title: 'Our Team',
    about_us_key_features_title: 'Key Features',
    about_us_our_commitment_title: 'Our Commitment to Users and Artists',
    about_us_contact_information_title: 'Contact Information',
    about_us_page_description:
        """The Sornaz Education App is designed to help music students learn more effectively. Sornaz not only supports learners throughout their educational journey but also serves as a powerful assistant for teachers and instructors. Our goal is to provide all the tools and resources that students and educators need in a single, unified platform.
With features such as audio playback, sound recording, and other essential tools, Sornaz is also useful for general users who enjoy working with music.""",
    about_us_our_mission_description:
        """Our mission at Sornaz is to simplify the music-learning process. We strive to create a clear, structured environment where learners can track, measure, and manage their progress easily. Providing high-quality educational content and offering practical tools for instructors to plan and monitor student development is a core part of this mission.""",
    about_us_our_vision_description:
        """Our vision is to build a complete and accessible music-education space for all music enthusiasts. Through smart progress-tracking tools, charts, and personalized guidance, Sornaz aims to make the learning process more transparent, engaging, and effective.
We hope to cultivate a community where music education is enjoyable, organized, and available to everyone.""",
    about_us_our_values_description:
        """At Sornaz, quality education is our top priority.
We believe today’s learners are tomorrow’s artists, and we aim to accompany them on their journey toward growth with reliable tools, well-designed educational materials, and personalized study paths.
We also support teachers by offering customizable planning tools that help them guide their students more efficiently and professionally.""",
    about_us_our_story_description:
        """Many music students struggle with confusion and a lack of direction during their learning journey. Limited access to experienced instructors and the absence of a structured learning path often result in years of slow progress or repetitive study without meaningful improvement.
Sornaz was born to solve this problem—created as a helpful companion for students, providing them with clarity, structure, and access to quality instruction. By offering educational content and tools designed for real progress, Sornaz stands by learners every step of the way.""",
    about_us_our_team_description:
        """The Sornaz Music Education App is currently developed by Yasin Mousavi-Avval, who handles the complete design and development of the product.
During the early stages of the project, Maedeh Rasti contributed as the graphic designer. She created the app’s name and designed its official logo.""",
    about_us_key_features_description:
        """In its initial release, Sornaz provides the following tools and features:

Educational articles and learning materials

Music player

Sound recorder

Metronome

Tuner

We plan to add many more features in the future and welcome user feedback to help us improve the app and enhance the learning experience.""",
    about_us_our_commitment_description:
        """At Sornaz, we are committed to supporting musicians, learners, and music lovers.
We continuously work to understand their needs and improve the app’s tools and functionalities, ensuring that Sornaz grows into a reliable and valuable resource for the entire music community.""",
    about_us_contact_information_description: """📧 Email: sornaz.ac@gmail.com

📱 Social Media:

https://www.instagram.com/sornaz.ac/

https://www.youtube.com/@sornaz.academy

🌐 Website: https://sornaz.com""",

    audio_list_preparing_folders: "Preparing Folders ...",
    music_player_scanning_files: "Scanning Files ...",
    music_player_scanned_files: "Scanned Files ...",
    song_information_no_song_playing: "No Song Playing",
    audio_player_provider_changed_filename: "Changed Filename",
    audio_player_provider_remove_from_list: "Remove From List",
    audio_player_provider_delete_from_memory: "Delete From Memory",
    folder_list_view_preparing_folders: "Preparing Folders ...",
    folder_list_view_song: "Song",
    audio_controls_1x_speed: "1x (Normal)",
    file_action_change_filename: "Rename",
    file_action_remove: "Remove",
    file_action_new_filename: "New name (without extension)",
    file_action_discard: "Discard",
    file_action_save: "Save",
    file_action_changed_filename: "File name changed",
    file_action_error_in_changed_filename:
        "Error renaming file (a file with the same name may already exist)",
    file_action_remove_file: "Remove file",
    file_action_remove_file_from_list_or_memory:
        "Remove from the list only, or delete permanently from storage?",
    file_action_remove_file_from_list: "Remove from list",
    file_action_removed_file_from_list: "Removed from list",
    file_action_error_in_removed_file_from_list: "Error removing from list",
    file_action_delete_file_from_memory: "Delete from storage",
    file_action_deleted_file_from_memory: "File deleted from storage",
    file_action_error_in_deleted_file_from_memory: "Error deleting file",
    waveform_widget_zoom_label: "Zoom",
    song_information_title: 'Title',
    song_information_artists: 'Artists',
    song_information_album: 'Album',
    song_information_genre: 'Genre',
    song_information_year: 'Year',
    song_information_duration: 'Duration',
    song_information_bitrate: 'Bitrate',
    record_details_record_information: "Record Information",
    delete_button_widget_delete: "Delete",
    delete_button_widget_confirm_delete: "Confirm Delete",
    delete_button_widget_delete_question_before_filename_part:
        "Are you Sure for Delete «",
    delete_button_widget_delete_question_after_filename_part: "»?",
    delete_button_widget_discard_button: "Discard",
    delete_button_widget_confirm_delete_button: "Yes, Delete Files",
    rename_button_widget_rename: "Rename",
    rename_button_widget_new_filename: "New Filename",
    rename_button_widget_discard: "Discard",
    rename_button_widget_save: "Save",
    voice_recorder_microphone_and_storage_access_permissions:
        "Microphone and storage access permissions are required.",
    voice_recorder_file_deleted: "File deleted",
    voice_recorder_file_restored: "File restored",
    voice_recorder_label_restore: "Restore",
    voice_recorder_delete_recording: "Delete recording",
    voice_recorder_confirm_delete_before_filename:
        "Are you sure you want to delete the file “",
    voice_recorder_confirm_delete_after_filename: "”?",
    voice_recorder_no: "No",
    voice_recorder_yes_delete: "Yes, delete",
    voice_recorder_delete_message_before_filename: "File “",
    voice_recorder_delete_message_after_filename: "” has been deleted",
    voice_recorder_rename_file: "Rename file",
    voice_recorder_new_filename: "New name",
    voice_recorder_discard: "Cancel",
    voice_recorder_save: "Save",
    voice_recorder_filename_changed_before_filename: "File name changed to “",
    voice_recorder_filename_changed_after_filename: "”.",
    voice_recorder_error_in_renaming: "Error renaming file!",

    tuner_settings_title: 'Tuner Settings',
    metronome_settings_title: 'Metronome Settings',
    volumes: 'Volumes',
    tools: 'Tools',
    show_bars_division_title: 'Show Bars Division',
    show_bars_division_subtitle: 'Set ON for showing bars division',
    show_tap_tempo_title: 'Show Tap Tempo',
    show_tap_tempo_subtitle: 'set ON for Showing Tap Tempo',
    enable_timer_stopwatch_title: 'Enable Timer Stopwatch',
    enable_timer_stopwatch_subtitle: 'set ON for Enable Timer Stopwatch',
    enable_bars_stopwatch_title: 'Enable Bars Stopwatch',
    enable_bars_stopwatch_subtitle: 'set ON for Enable Bars Stopwatch',
    frequency: 'Frequency',
    timer: 'Timer',
    bars: 'Bars',
    minute: 'minute',
    second: 'second',
    coming_soon: 'Coming Soon...',

    note_stretch: "Note Stretch",
    starting_octave: "Starting Octave",
    number_of_octaves: "Number of Octaves",
    highlight_a4_key: "Highlight A4 Key",
    enable_a4_key_highlight: "Enable A4 key highlight",
    frequencies_on_white_keys: "Frequencies on White Keys",
    enable_frequency_display_on_white_keys:
        "Enable frequency display on white keys",
    frequencies_on_black_keys: "Frequencies on Black Keys",
    enable_frequency_display_on_black_keys:
        "Enable frequency display on black keys",
    quarter_tones: "Quarter Tones",
    enable_iranian_quarter_tones: "Enable Persian/Iranian quarter tones",
    update: "Update",

    need_permission: "Need Permission",
    need_permission_for_scanning_audio_files:
        "Need Permission for Scanning Audio Files from your Device Memory. Please Active Permission from AppSettings",
    later: "Later",
    go_to_settings: "Go to Settings",

    bass: 'Bass',
    mid: 'Mid',
    treble: 'Treble',

    memory: 'Memory',

    show_all_folders: "Show All Folders",
    show_folders_contains_audio_files: "Show Folders Contains Audio Files",
    no_folder_or_audio_file_found_in_this_path:
        "No Folder or Audio File Found in this Path",

    delete_confirm_dialog_title: 'Delete recording',
    delete_confirm_dialog_content_before_filename: 'Delete',
    delete_confirm_dialog_content_after_filename: '?',
    delete_confirm_dialog_cancel_button: 'Cancel',
    delete_confirm_dialog_delete_button: 'Delete',

    voice_recorder_recording_icon_button_tooltip: "Recordings",
    voice_recorder_bookmark_text_button: "BOOKMARK",

    recording_list_title: "Recordings List",
    recording_list_search_hint: "Search recordings...",
    recording_list_multi_item_selected: "selected",
    recording_list_share: 'Share',
    recording_list_favorite: 'Favorite',
    recording_list_rename: 'Rename',
    recording_list_delete: 'Delete',

    recording_list_multi_item_delete_content: 'Delete Files?',
    recording_list_delete_content: 'Delete?',

    audio_library_manager_preparing: 'Preparing...',
    audio_library_manager_fininshed_loading_from_memory:
        'Fininshed Loading from Memory',
    audio_library_manager_calculating_audio_files: 'Calculating Audio Files...',
    audio_library_manager_error_in_loading: 'Error in Loading',
    audio_file_loader_calculating: 'Calculating...',
    audio_library_manager_fininshed_calculating: 'Fininshed Calculating',

    // ======================================================
    // ======================================================
    // ======================================================
    // ======================================================
    // ======================================================
    // ======================================================
  };

  static const fa = {
    ...learningFa,
    select_font_title: 'انتخاب فونت',
    select_font_description: 'فونت دلخواه خود را انتخاب کنید',
    font_iran_sans: 'ایران سنس',
    font_iran_yekan: 'ایران یکان',
    font_kalameh: 'کلمه',
    font_tahrir: 'تحریر',
    font_sahel: 'ساحل',
    font_vazir: 'وزیر',
    font_peyda: 'پیدا',
    application_name: 'سُرناز',
    application_fullname: 'برنامه موسیقی سرناز',
    application_email: 'sornaz.ac@gmail.com',
    faq_title: 'سوالات متداول',
    home_title: 'خانه',
    blogs_title: 'بلاگ‌ها',
    tuner_title: 'تیونر',
    splash_title: 'اسپلش',
    sign_up_title: 'ثبت نام',
    sign_in_title: 'ورود',
    courses_title: 'دوره‌ها',
    authors_title: 'نویسندگان',
    profile_title: 'پروفایل',
    about_us_title: 'درباره ما',
    articles_title: 'مقالات',
    settings_title: 'تنظیمات',
    metronome_title: 'مترونوم',
    contact_us_title: 'تماس با ما',
    onboarding_title: 'آن‌بوردینگ',
    music_sheet_title: 'نت موسیقی',
    music_player_title: 'پلیر موسیقی',
    privacy_policy_title: 'سیاست حریم خصوصی',
    voice_recorder_title: 'ضبط صدا',
    forgot_password_title: 'فراموشی رمز عبور',
    article_detail_page_title: 'جزئیات مقاله',

    onboarding_title_0: 'تئوری و تمرین یکدیگر را تکمیل می‌کنند.',
    onboarding_subtitle_0:
        'پیشرفت واقعی از ترکیب دانش موسیقی و تمرین مستمر حاصل می‌شود.',
    onboarding_title_1: 'یادگیری پایدار زمان می‌برد.',
    onboarding_subtitle_1:
        'پیشرفت موسیقی نیازمند صبر، تمرین منظم و یادگیری ساختاریافته است.',
    onboarding_title_2: 'موسیقی با اصول پایه آغاز می‌شود.',
    onboarding_subtitle_2:
        'یادگیری واقعی با درک اصول و پایه‌های موسیقی شروع می‌شود.',

    dont_have_an_account: 'آیا اکانت ندارید؟ ثبت نام',
    sign_in_with_google: 'ثبت نام با گوگل',
    // forgot_password: 'فراموشی رمز عبور',
    forgot_password: 'رمز عبور خود را فراموش کرده اید؟',
    remember_me: 'مرا به خاطر بسپار',
    password: 'رمز عبور',
    email: 'ایمیل',
    sign_in_description: 'خوش آمدید! لطفا وارد حساب خود شوید',
    sent_otp_via_email: 'کد تأیید از طریق ایمیل برای شما ارسال شد.',
    sent_otp_via_phone_number: 'کد تأیید از طریق شماره تلفن برای شما ارسال شد.',
    phone_number: 'شماره تلفن',
    send_otp_via_email: 'ارسال کد تایید از طریق ایمیل',
    send_otp_via_phone_number: 'ارسال کد تایید از طریق شماره تلفن',
    send_otp_code: 'ارسال کد تایید',
    already_have_an_account: 'هم اکنون حساب کاربری دارید؟ وارد شوید',
    bookmark: 'نشانه گذاری',
    share_app: 'ارسال برنامه',
    achievements: 'دستاوردها',
    community: 'جامعه',
    share_feedback: 'ارسال بازخورد',
    membership: 'عضویت',
    my_account: 'حساب من',
    switch_acount: 'تغییر به حساب دیگر',
    logout: 'خروج از حساب',
    top_active_authors: 'نویسندگان فعال برتر',
    push_notifications: 'اعلان‌ها',
    push_notifications_subtitle: 'دریافت اعلان‌های هشدار اپلیکیشن',
    new_course_alerts: 'اعلان دوره‌های جدید',
    new_course_alerts_description:
        'زمان بارگذاری دوره توسط اساتید را مطلع شوید',
    dataTitle: 'داده‌ها',
    use_wifi: 'استفاده از وای‌فای',
    use_wifi_description:
        'اپلیکیشن وای‌فای را نسبت به دیتای موبایل ترجیح می‌دهد',
    auto_download: 'دانلود خودکار',
    auto_download_description:
        'دوره‌ها به‌صورت خودکار روی دستگاه شما ذخیره می‌شوند',

    two_times_press_back_button_for_exit_application:
        'برای خروج دوباره دکمه برگشت را بزنید',
    home_searchbar_hint: 'جستجوی بلاگ‌ها',

    new_courses_title: 'دوره‌های جدید',
    last_blog_title: 'آخرین بلاگ',
    view_all_link: 'مشاهده همه',
    no_title: 'بدون عنوان',
    error_in_loading: 'خطا در بارگذاری',
    failed_to_load_posts: 'خطا در بارگزاری پست‌ها',
    failed_to_load_categories: 'خطا در بارگزاری دسته بندی ها',
    previous_button: 'قبلی',
    next_button: 'بعدی',
    start_button: 'شروع',

    dark_mode: 'تم تیره',
    dark_mode_description: 'اگر روشن باشد، تم اپ تاریک است',

    music_player_search_hint: 'جستجو در فایل‌های صوتی...',
    audio_file_not_found: 'فایل صوتی یافت نشد!',
    press_back_to_exit: 'برای خروج دوباره دکمه بازگشت را بزنید',
    no_records_file: 'هیچ ضبطی انجام نشده',
    all: 'همه',
    without_title: 'بدون عنوان',
    without_briefs: 'بدون خلاصه',
    send_comment: 'ارسال کامنت',
    comment: 'کامنت',
    comments: 'کامنت‌ها',
    without_comments: 'بدون کامنت',
    unknown: 'نامشخص',
    load_more_comments: 'بارگذاری کامنت‌های بیشتر',
    write_your_comments: 'نظر خود را بنویسید',
    take_your_point_to_article: 'امتیاز شما به مقاله',
    similar_articles: 'مقالات پیشنهادی',
    writer: 'نویسنده',
    error_in_sending_comment: 'خطا در ارسال کامنت',
    guest_user: 'کاربر مهمان',
    without_content: 'بدون محتوا',

    notification_title: 'اطلاعیه',
    appearance_title: 'ظاهر',
    elements: 'ابزار',
    font_size: 'اندازه متن',
    font_size_description: 'اندازه متن اپلیکیشن',
    font_weight: 'ضخامت متن',
    font_weight_description: 'ضخامت متن اپلیکیشن',

    grant_audio_permission: 'لطفا اجازه دسترسی به فایل‌های صوتی را بدهید',
    error_loading_files: 'خطا در بارگذاری فایل‌ها',
    set_base_frequency: 'تنظیم فرکانس مبنا (A4) : ',
    hz: 'هرتز',
    hertz: 'هرتز',
    cents: 'سنت',
    stop: 'توقف کامل',
    pause: 'توقف',
    play: 'پخش',
    launch: 'راه‌اندازی',
    launch_again: 'راه‌اندازی مجدد',
    bpm: 'تمپو (BPM)',
    timing: 'زمان‌بندی',
    volume: 'حجم صدا',
    language_mode: 'زبان',
    language_mode_description: 'تغییر به زبان انگلیسی',

    record_date_title: "تاریخ ضبط :",
    filename_title: "نام فایل :",

    about_us_page_title: 'درباره ما – برنامه آموزشی سرناز',
    about_us_our_mission_title: 'ماموریت ما',
    about_us_our_vision_title: 'چشم‌انداز ما',
    about_us_our_values_title: 'ارزش‌های ما',
    about_us_our_story_title: 'داستان شکل‌گیری سرناز',
    about_us_our_team_title: 'تیم سرناز',
    about_us_key_features_title: 'ویژگی‌های اصلی برنامه',
    about_us_our_commitment_title: 'تعهد ما به هنرمندان و کاربران',
    about_us_contact_information_title: 'راه‌های ارتباطی',
    about_us_page_description:
        """برنامه آموزشی سرناز با هدف کمک به هنرجویان موسیقی برای یادگیری مؤثرتر طراحی شده است. سرناز علاوه بر اینکه یک همراه آموزشی برای هنرجویان است، به عنوان یک دستیار قدرتمند برای اساتید و مدرسین نیز عمل می‌کند. ما در تلاش هستیم تا تمامی نیازهای آموزشی هنرجویان و آموزگاران را در یک بستر یکپارچه فراهم کنیم. همچنین امکاناتی مانند پخش فایل صوتی، ضبط صدا و ابزارهای کاربردی دیگر باعث شده سرناز برای کاربران عادی نیز قابل استفاده و مفید باشد.""",
    about_us_our_mission_description:
        """ماموریت ما در سرناز، ساده‌سازی مسیر یادگیری موسیقی است. ما تلاش می‌کنیم محیطی فراهم کنیم که هنرجویان بتوانند بدون پیچیدگی‌های رایج، روند پیشرفت خود را مشاهده و مدیریت کنند. ارائه محتوا و ابزارهای آموزشی باکیفیت و ایجاد بستری برای برنامه‌ریزی آموزشی اساتید، بخشی از این مأموریت است.""",
    about_us_our_vision_description:
        """چشم‌انداز سرناز، ایجاد یک فضای آموزشی کامل برای علاقه‌مندان به موسیقی است؛ فضایی که به واسطه ابزارها و نمودارهای تحلیلی، روند یادگیری و پیشرفت هر فرد را شفاف و قابل سنجش کند. ما به دنبال ساختن جامعه‌ای هستیم که در آن آموزش موسیقی برای همه افراد در دسترس، ساخت‌یافته و لذت‌بخش باشد.""",
    about_us_our_values_description:
        """در سرناز، ارائه آموزش باکیفیت در اولویت است.
ما باور داریم که هنرجویان امروز، هنرمندان فردا هستند؛ بنابراین تلاش می‌کنیم با ابزارها، محتوا و برنامه‌ریزی دقیق، آن‌ها را در مسیر رشد همراهی کنیم.
از سوی دیگر، اساتید و آموزگاران موسیقی می‌توانند با استفاده از قابلیت‌های برنامه‌ریزی و مدیریت پیشرفت سرناز، تجربه آموزشی دقیق‌تر و شخصی‌سازی‌شده‌تری برای هنرجویان خود فراهم کنند.""",
    about_us_our_story_description:
        """در دنیای موسیقی، بسیاری از هنرجویان با مشکل سردرگمی در مسیر یادگیری مواجه می‌شوند. نبود دسترسی آسان به اساتید متخصص، و عدم وجود یک مسیر آموزشی مشخص، باعث می‌شود بسیاری از هنرجویان سال‌ها بدون پیشرفت چشمگیر در یک چرخه تکرار گرفتار شوند.
سرناز از همین نیاز شکل گرفت؛ تا همیار و همراهی مطمئن در کنار هنرجویان باشد و مسیر آموزشی را برای آن‌ها روشن‌تر و قابل مدیریت کند. فراهم کردن دسترسی به آموزگاران باتجربه و ارائه محصولات آموزشی مناسب، بخشی از رسالتی است که سرناز برای خود تعریف کرده است.""",
    about_us_our_team_description:
        """توسعه برنامه آموزشی سرناز توسط آقای یاسین موسوی‌اول انجام می‌شود. تمامی مراحل طراحی، ایجاد و بهبود امکانات برنامه بر عهده ایشان است.
در مراحل اولیه شکل‌گیری پروژه، سرکار خانم مائده راستی به عنوان گرافیست همراه تیم بودند و انتخاب نام «سرناز» و طراحی لوگوی رسمی برنامه نیز توسط ایشان انجام شده است.""",
    about_us_key_features_description:
        """در نسخه اولیه، سرناز ابزارها و امکانات زیر را برای کاربران فراهم کرده است:

مقالات و آموزش‌های تخصصی موسیقی

پخش‌کننده موسیقی

ابزار ضبط صدا

مترونوم

تیونر

ما در مسیر توسعه، قصد داریم امکانات بیشتری را به سرناز اضافه کنیم و با آغوش باز از پیشنهادهای کاربران برای ارتقای کیفیت برنامه استقبال می‌کنیم.""",
    about_us_our_commitment_description:
        """تمام تلاش ما در سرناز حمایت از هنرمندان، هنرجویان و علاقه‌مندان موسیقی است. ما متعهدیم نیازهای آموزشی و عملی این جامعه را بشناسیم و امکانات برنامه را به‌صورت مداوم در جهت ارتقای تجربه کاربری و کیفیت آموزش بهبود دهیم.""",
    about_us_contact_information_description: """📧 ایمیل: sornaz.ac@gmail.com

📱 شبکه‌های اجتماعی:

https://www.instagram.com/sornaz.ac/

https://www.youtube.com/@sornaz.academy

🌐 وب‌سایت: https://sornaz.com""",

    audio_list_preparing_folders: "در حال آماده‌سازی پوشه‌ها ...",
    music_player_scanning_files: "در حال اسکن فایل‌ها ...",
    music_player_scanned_files: "فایل اسکن شد",
    song_information_no_song_playing: "هیچ آهنگی در حال پخش نیست",
    audio_player_provider_changed_filename: "نام فایل تغییر کرد",
    audio_player_provider_remove_from_list: "فایل از لیست حذف شد",
    audio_player_provider_delete_from_memory: "فایل از حافظه پاک شد",
    folder_list_view_preparing_folders: "در حال آماده‌سازی پوشه‌ها ...",
    folder_list_view_song: "آهنگ",
    audio_controls_1x_speed: "1x سرعت طبیعی",
    file_action_change_filename: "تغییر نام",
    file_action_remove: "حذف",
    file_action_new_filename: "نام جدید (بدون پسوند)",
    file_action_discard: "انصراف",
    file_action_save: "ذخیره",
    file_action_changed_filename: "نام فایل تغییر کرد",
    file_action_error_in_changed_filename:
        "خطا در تغییر نام (ممکن است فایل مشابه وجود داشته باشد)",
    file_action_remove_file: "حذف فایل",
    file_action_remove_file_from_list_or_memory:
        "حذف فقط از لیست یا حذف کامل از حافظه؟",
    file_action_remove_file_from_list: "حذف از لیست",
    file_action_removed_file_from_list: "از لیست حذف شد",
    file_action_error_in_removed_file_from_list: "خطا در حذف از لیست",
    file_action_delete_file_from_memory: "حذف از حافظه",
    file_action_deleted_file_from_memory: "فایل از حافظه حذف شد",
    file_action_error_in_deleted_file_from_memory: "خطا در حذف فایل",
    waveform_widget_zoom_label: "بزرگنمایی",
    song_information_title: 'عنوان',
    song_information_artists: 'هنرمند',
    song_information_album: 'آلبوم',
    song_information_genre: 'ژانر',
    song_information_year: 'سال',
    song_information_duration: 'مدت',
    song_information_bitrate: 'بیت ریت',
    record_details_record_information: "جزئیات ضبط",
    delete_button_widget_delete: "حذف",
    delete_button_widget_confirm_delete: "تأیید حذف",
    delete_button_widget_delete_question_before_filename_part:
        "آیا از حذف فایل «",
    delete_button_widget_delete_question_after_filename_part: "» مطمئن هستی؟",
    delete_button_widget_discard_button: "خیر",
    delete_button_widget_confirm_delete_button: "بله، حذف شود",
    rename_button_widget_rename: "تغییر نام",
    rename_button_widget_new_filename: "نام جدید",
    rename_button_widget_discard: "انصراف",
    rename_button_widget_save: "ذخیره",
    voice_recorder_microphone_and_storage_access_permissions:
        "اجازه دسترسی به میکروفون و حافظه لازم است",
    voice_recorder_file_deleted: "فایل حذف شد",
    voice_recorder_file_restored: "فایل برگردانده شد",
    voice_recorder_label_restore: "برگرداندن",
    voice_recorder_delete_recording: "حذف ضبط",
    voice_recorder_confirm_delete_before_filename: "آیا از حذف فایل «",
    voice_recorder_confirm_delete_after_filename: "» مطمئن هستید؟",
    voice_recorder_no: "خیر",
    voice_recorder_yes_delete: "بله، حذف کن",
    voice_recorder_delete_message_before_filename: "فایل «",
    voice_recorder_delete_message_after_filename: "» حذف شد",
    voice_recorder_rename_file: "تغییر نام فایل",
    voice_recorder_new_filename: "نام جدید",
    voice_recorder_discard: "انصراف",
    voice_recorder_save: "ذخیره",
    voice_recorder_filename_changed_before_filename: "نام فایل به «",
    voice_recorder_filename_changed_after_filename: "» تغییر کرد.",
    voice_recorder_error_in_renaming: "خطا در تغییر نام!",

    tuner_settings_title: 'تنظیمات تیونر',
    metronome_settings_title: 'تنظیمات مترونوم',
    volumes: 'حجم صدا',
    tools: 'ابزارها',
    show_bars_division_title: 'تقسیم‌ میزان‌ها',
    show_bars_division_subtitle: 'برای نمایش تقسیم‌ میزان‌ها روشن کنید',
    show_tap_tempo_title: 'تعیین سرعت با ضربه',
    show_tap_tempo_subtitle: 'برای نمایش تعیین سرعت با ضربه روشن کنید',
    enable_timer_stopwatch_title: 'کرنومتر زمانی',
    enable_timer_stopwatch_subtitle: 'برای فعال‌سازی کرنومتر زمانی روشن کنید',
    enable_bars_stopwatch_title: 'شمارش میزان‌ها',
    enable_bars_stopwatch_subtitle: 'برای فعال‌سازی شمارش میزان‌ها روشن کنید',
    frequency: "فرکانس",
    timer: 'زمان',
    bars: 'میزان',
    minute: 'دقیقه',
    second: 'ثانیه',
    coming_soon: 'به زودی ...',

    note_stretch: "کشش نت",
    starting_octave: "اکتاو پیانو",
    number_of_octaves: "تعداد اکتاو",
    highlight_a4_key: "هایلایت کلید A4",
    enable_a4_key_highlight: "برای هایلایت کلید A4 روشن کنید",
    frequencies_on_white_keys: "فرکانس کلیدهای سفید",
    enable_frequency_display_on_white_keys:
        "برای نمایش فرکانس روی کلیدهای سفید روشن کنید",
    frequencies_on_black_keys: "فرکانس کلیدهای سیاه",
    enable_frequency_display_on_black_keys:
        "برای نمایش فرکانس روی کلیدهای سیاه روشن کنید",
    quarter_tones: "ربع پرده‌ها",
    enable_iranian_quarter_tones:
        "برای نمایش ربع پرده‌های موسیقی ایرانی روشن کنید",
    update: "آپدیت",
    need_permission: "دسترسی لازم است",
    need_permission_for_scanning_audio_files:
        "برای اسکن فایل‌های موسیقی، دسترسی به حافظه دستگاه لازم است. لطفاً در تنظیمات برنامه مجوز را فعال کنید.",
    later: "بعداً",
    go_to_settings: "رفتن به تنظیمات",
    // ======================================================
    // ======================================================
    // ======================================================
    bass: 'بم',
    mid: 'میانی',
    treble: 'زیر',
    // ======================================================
    // ======================================================
    // ======================================================
    memory: 'حافظه',
    show_all_folders: "نمایش همه فولدرها",
    show_folders_contains_audio_files: "فقط فولدرهای دارای آهنگ",
    no_folder_or_audio_file_found_in_this_path:
        "هیچ فولدر یا آهنگی در این مسیر یافت نشد",
    delete_confirm_dialog_title: 'حذف فایل ضبط شده',
    delete_confirm_dialog_content_before_filename: 'آیا فایل',
    delete_confirm_dialog_content_after_filename: 'حذف شود؟',
    delete_confirm_dialog_cancel_button: 'خیر',
    delete_confirm_dialog_delete_button: 'حذف',
    voice_recorder_recording_icon_button_tooltip: "ضبط ها",
    voice_recorder_bookmark_text_button: "نشانه گذاری",
    recording_list_title: "لیست فایل های ضبط شده",
    recording_list_search_hint: "جستجو...",
    recording_list_multi_item_selected: "انتخاب شده",
    recording_list_share: 'ارسال',
    recording_list_favorite: 'علاقمندی',
    recording_list_rename: 'تغییر نام',
    recording_list_delete: 'حذف',
    recording_list_multi_item_delete_content: 'فایل حذف شود؟',
    recording_list_delete_content: 'حذف شود؟',
    audio_library_manager_preparing: 'در حال آماده‌سازی...',
    audio_library_manager_fininshed_loading_from_memory:
        'بارگذاری از حافظه تکمیل شد',
    audio_library_manager_calculating_audio_files: 'در حال شمارش فایل‌ها...',
    audio_library_manager_error_in_loading: 'خطا در بارگذاری',
    audio_file_loader_calculating: 'در حال شمارش...',
    audio_library_manager_fininshed_calculating: 'شمارش تمام شد',
  };
}

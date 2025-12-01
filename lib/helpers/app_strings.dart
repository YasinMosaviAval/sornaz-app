// ignore_for_file: constant_identifier_names

import 'package:sornaz/helpers/app_images.dart';

class AppStrings {
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
  static const elements = 'elements';
  static const text_size = 'textSize';
  static const text_size_description = 'textSizeDescription';
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

  // ===============================================================
  // ===============================================================
  // ===============================================================
  // ===============================================================
  static const String epmty_text = '';
  static const String empty_duration_time = '--:--';
  static const String sample_email = 'bruno203@gmail.com';
  static const String sample_phone = '0911223344';
  static const String sample_username = 'bruno203';
  // ===============================================================
  // ===============================================================
  // ===============================================================
  // ===============================================================

  static const allKeys = [
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
    elements,
    text_size,
    text_size_description,
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
  ];

  static const en = {
    application_name: 'Sornaz',
    application_fullname: 'Sornaz Music App',
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
    forgot_password: 'Forgot password?',
    remember_me: 'Remember me',
    password: 'Password',
    email: 'Email',
    sign_in_description:
        'Sign into your account - access all of your courses now.',
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
    elements: 'Elements',
    text_size: 'Text Size',
    text_size_description: 'Set text size',

    grant_audio_permission:
        'Please grant permission to access audio files in the app settings.',
    error_loading_files: 'Error loading files',

    set_base_frequency: 'Set Base Frequency (A4)',
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
  };

  static const fa = {
    application_name: 'سرناز',
    application_fullname: 'اپلیکیشن موسیقی سرناز',
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
    forgot_password: 'رمز عبور را فراموش کردید؟',
    remember_me: 'برای من یادآوری کن',
    password: 'رمز عبور',
    email: 'ایمیل',
    sign_in_description:
        'وارد حساب کاربری خود شوید تا به تمامی درس ها دسترسی پیدا کنید.',
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
    failed_to_load_posts: 'خطا در لود پست‌ها',
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
    unknown: 'ناشناس',
    load_more_comments: 'بارگذاری کامنت‌های بیشتر',
    write_your_comments: 'نظر خود را بنویسید',
    take_your_point_to_article: 'امتیاز شما به مقاله',
    similar_articles: 'مقالات پیشنهادی',
    writer: 'نویسنده',
    error_in_sending_comment: 'خطا در ارسال کامنت',
    guest_user: 'کاربر مهمان',
    without_content: 'بدون محتوا',

    notification_title: 'اطلاعیه',
    elements: 'ابزار',
    text_size: 'اندازه متن',
    text_size_description: 'اندازه متن اپلیکیشن',

    grant_audio_permission: 'لطفا اجازه دسترسی به فایل‌های صوتی را بدهید',
    error_loading_files: 'خطا در بارگذاری فایل‌ها',
    set_base_frequency: 'تنظیم فرکانس مبنا (A4)',
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
  };
}

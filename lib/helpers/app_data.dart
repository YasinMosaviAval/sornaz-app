// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Home/home.dart';
import 'package:sornaz/screens/Onboarding/splash.dart';
import 'package:sornaz/screens/Others/about_us.dart';
import 'package:sornaz/screens/Others/settings.dart';
import 'package:sornaz/screens/Players/music_palyer.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// گسترش AppData برای صفحات جدید
class AppData extends ChangeNotifier {
  bool _isDark = false;
  bool _isPersian = true;
  bool get isDark => _isDark;
  bool get isPersian => _isPersian;
  double textSize = 14.0;
  bool pushNotifications = true;
  bool newCourseAlerts = false;
  bool useWifiOverData = true;
  bool autoDownload = true;

  // داده‌های پروفایل
  String profileName = 'Thanh Pham Cong';
  String profileEmail = 'bruno203@gmail.com';
  String profileTitle = 'Freelance student';
  int profileCourses = 3205;
  String profileImage = 'https://via.placeholder.com/100?text=Profile';

  String _fontFamily = AppTypography.default_font_family;

  String get fontFamily => _fontFamily;

  void updateFontFamily(String font) {
    _fontFamily = font;
    notifyListeners();
  }

  // لیست Saved Courses
  final List<Map<String, dynamic>> savedCourses = List.generate(
    3,
    (index) => {
      'title': 'Wireframe & Prototype',
      'instructor': 'Jasmine Sophia',
      'price': 14.99,
      'lessons': 10,
      'image': 'https://via.placeholder.com/200?text=Course',
    },
  );

  // لیست Saved Authors
  final List<Map<String, dynamic>> savedAuthors = List.generate(
    5,
    (index) => {
      'name': 'Bruno Pham',
      'courses': 5,
      'image': 'https://via.placeholder.com/50?text=Author',
    },
  );

  // لیست Downloads
  final List<Map<String, dynamic>> downloads = List.generate(
    4,
    (index) => {
      'title': 'Wireframe & Prototype',
      'lesson': 'Lesson 1',
      'progress': 0.0,
      'time': '05:00',
      'image': 'https://via.placeholder.com/200?text=Download',
    },
  );

  // لیست Notifications
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'Account',
      'title': 'Please verify your email',
      'subtitle': 'Sent to email@mail.com',
      'action': 'Verify email',
    },
    {
      'type': 'Following',
      'title': 'John Smith added new course',
      'subtitle': '10min ago',
      'action': 'View course',
    },
    {
      'type': 'Activity',
      'title': 'Your premium trial is expiring soon',
      'subtitle': 'Cancel before May 07 to avoid charges',
    },
    {
      'type': 'Activity',
      'title': 'Your premium trial is expiring soon',
      'subtitle': 'Cancel before May 07 to avoid charges',
    },
  ];

  // پیشرفت‌ها
  final List<Map<String, dynamic>> progressItems = [
    {'title': 'Figma UI/UX Design', 'progress': 0.56, 'videos': '56/86 Videos'},
  ];

  // Finished Courses
  final List<String> finishedCourses = List.generate(
    5,
    (index) => 'Vikram Singh',
  );

  // Achievements
  final List<String> achievements = List.generate(4, (index) => 'Department');

  String leaderType = 'Leave Type';

  void toggleDarkMode(bool value) {
    _isDark = value;
    notifyListeners();
  }

  void toggleLanguageMode(bool value) {
    _isPersian = value;
    notifyListeners();
  }

  void updateProfile(String field, String value) {
    if (field == 'name') profileName = value;
    if (field == 'email') profileEmail = value;
    notifyListeners();
  }

  void saveChanges() {
    // لاجیک ذخیره
  }

  // داده‌های کورس‌ها
  final List<Map<String, dynamic>> courses = List.generate(
    3,
    (index) => {
      'title': 'UX/UI Design Crash Course',
      'instructor': 'Jasmine Pham',
      'description':
          'Design & Development. Illustrator. Learn how to becoming professional Illustrator Now.',
      'price': 24.92,
      'oldPrice': 89.90,
      'rating': 4.5,
      'reviews': 1200,
      'image': 'https://via.placeholder.com/200?text=Course',
    },
  );

  // فیلترها
  final List<String> selectedFilters = [];

  void toggleFilter(String filter) {
    if (selectedFilters.contains(filter)) {
      selectedFilters.remove(filter);
    } else {
      selectedFilters.add(filter);
    }
    notifyListeners();
  }

  // داده‌های جزئیات کورس
  final Map<String, dynamic> courseDetail = {
    'title': 'VUE JS SCRATCH COURSE',
    'price': 22.40,
    'likes': 35,
    'comments': 123,
    'shares': 12,
    'instructor': 'Steven Arnatovic',
    'studio': 'Kitani Studio',
    'rating': 4.8,
    'reviews': 1812,
    'summary':
        'Any kind of audiences and cringe-worthy conversational Dips you connect. Biting Impression.',
    'overview':
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus, ut interdum tellus elit sed risus. Maecenas eget condimentum velit, sit amet feugiat lectus.',
    'chapters': [
      {
        'title': 'Chapter 1 Course Overview',
        'lessons': '3 Lessons',
        'expanded': false,
        'sublessons': [
          {'title': 'Intro to UI Design', 'duration': '10:30'},
          {'title': 'Viewing an article', 'duration': '15:45'},
        ],
      },
      {
        'title': 'Chapter 2 Curriculum',
        'lessons': '5 Lessons',
        'expanded': false,
        'sublessons': [],
      },
    ],
    'instructorInfo': 'Mai Sakurajima Sensai. Adjust the setting on general.',
    // 'reviews': [
    //   {'user': 'John Doe', 'comment': 'This course is amazing!'},
    //   {'user': 'Jane Smith', 'comment': 'Very informative.'},
    // ],
    'qna': [
      {'user': 'Addison Rae', 'comment': 'Is anyone else learning english?'},
      {
        'user': 'Zyon Brown',
        'comment': '@Galaza Yeah me too, this is just too good.',
      },
    ],
    'downloadableFiles': [
      {'name': 'Practice PDF File', 'type': 'pdf', 'action': 'Download'},
      {
        'name': 'Email Templates',
        'type': 'Word document',
        'action': 'Download',
      },
    ],
    'curriculumVideos': [
      {
        'title': 'Intro to 3D Design and Rendering',
        'instructor': 'Audrey Day',
        'duration': '1h 5m',
      },
      {
        'title': 'Photography and DSLR Maintenance',
        'instructor': 'Steve White',
        'duration': '2h 30m',
      },
    ],
    'videoUrl':
        'https://via.placeholder.com/300?text=Video', // placeholder برای ویدیو
  };

  void toggleChapterExpansion(int index) {
    courseDetail['chapters'][index]['expanded'] =
        !courseDetail['chapters'][index]['expanded'];
    notifyListeners();
  }

  // داده‌های نمونه برای پروفایل مربی
  final Map<String, dynamic> instructorProfile = {
    'name': 'Thanh Pham Cong',
    'title': 'Freelance student',
    'courses': 12,
    'following': 28,
    'followers': 21000,
    'profileImage': 'https://via.placeholder.com/100?text=Instructor',
    'overview':
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus, ut interdum tellus elit sed risus. View more',
    'lastEventImage': 'https://via.placeholder.com/200?text=LastEvent',
    'lastEventText':
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus.',
    'achievements': [
      'Department',
      'Department',
      'Department',
      'Department',
    ], // کارت‌ها
    'leaderType': 'Leave Type',
  };

  // لیست کورس‌ها
  final List<Map<String, dynamic>> instructorCourses = [
    {
      'title': 'UX/UI Design Crash Course',
      'instructor': 'Jasmine Pham',
      'description':
          'More than Illustrator Experience Now. Learn how to becoming professional Illustrator Now.',
      'price': 24.92,
      'oldPrice': 89.90,
      'lessons': 10,
      'image': 'https://via.placeholder.com/200?text=Course1',
    },
    {
      'title': 'UX/UI Design Crash Course',
      'instructor': 'Jasmine Pham',
      'description': 'Design & Development.',
      'price': 24.92,
      'oldPrice': 89.90,
      'lessons': 10,
      'image': 'https://via.placeholder.com/200?text=Course2',
    },
  ];

  // لیست Following/Followers
  final List<Map<String, dynamic>> followingList = List.generate(
    5,
    (index) => {
      'name': 'James Harbor',
      'title': 'Computer Science',
      'image': 'https://via.placeholder.com/50?text=User',
    },
  );

  // لیست Recommended
  final List<Map<String, dynamic>> recommendedList = List.generate(
    4,
    (index) => {
      'name': 'Katy Walker',
      'title': 'Culinary Skills',
      'image': 'https://via.placeholder.com/50?text=Recommended',
    },
  );

  // برای چت (placeholder)
  final String chatImage = 'https://via.placeholder.com/300?text=Unicorn';

  // داده‌های نمونه برای Music Sheets
  final List<Map<String, String>> musicSheets = List.generate(
    5,
    (index) => {'title': 'Nostalgia', 'artist': 'Yanni - Yasin Moosavi'},
  );

  // داده‌های فرم Notation
  String notationTitle = '';
  String subtitle = '';
  String composer = '';
  String arranger = '';
  String lyricist = '';
  String copyright = 'Sornaz';
  String instrument = 'Tar';
  String keySignature = 'Thanh Pham';
  String timeSignature = 'Time Signature';
  String tempoText = 'Allegro';
  String noteType = 'White';
  String metronomeMark = '100';

  // برای نمایش نت (placeholder)
  final String notationDisplay = '''
  ♭ b ♭ b
  ♭ b ♭ b
  ♭ b ♭ b
  ♭ b ♭ b
  ♭ b ♭ b
  ♭ b ♭ b
  | ♭ b ♭ b | sfz | sfz
  | ♭ b | ffz | ffz
  | ♭ b | ff | ffz
  | ♭ b | ff | ff
  | ♭ b | sf | sfz
  | ♭ b | > | ffz
  | ♭ b | sf | ffz
  | ♭ b | ff | ff
  | ♭ b | r | ffz
  | ♭ b | p | 
  | ♭ b | pp | 
  | ♭ b | ppp | 
  | ♭ b | n | 
  | ♭ b | f | 
  | ♭ b | mp | 
  | ♭ b | mf | 
  | ♭ b | sf | 
  | ♭ b | fz | 
  | ♭ b | sfz | 
  | ♭ b | rf | 
  | ♭ b | rfz | 
  | ♭ b | sfp | 
  | ♭ b | sfpp | 
  | ♭ b | sffz | 
  | ♭ b | fp | 
  | ♭ b | fpp | 
  | ♭ b | > | 
  | ♭ b | < | 
  | ♭ b | ^ | 
  | ♭ b | . | 
  | ♭ b | - | 
  | ♭ b | _ | 
  | ♭ b | Tr | 
  | ♭ b | Pr | 
  | ♭ b | T | 
  | ♭ b | + | 
  | ♭ b | u | 
  | ♭ b | d | 
  | ♭ b | o | 
  | ♭ b | x | 
  | ♭ b | # | 
  | ♭ b | b | 
  | ♭ b | n | 
  ''';

  // متدهای update برای فرم
  void updateNotationField(String field, String value) {
    switch (field) {
      case 'title':
        notationTitle = value;
        break;
      case 'subtitle':
        subtitle = value;
        break;
      case 'composer':
        composer = value;
        break;
      case 'arranger':
        arranger = value;
        break;
      case 'lyricist':
        lyricist = value;
        break;
      case 'copyright':
        copyright = value;
        break;
      case 'instrument':
        instrument = value;
        break;
      case 'keySignature':
        keySignature = value;
        break;
      case 'timeSignature':
        timeSignature = value;
        break;
      case 'tempoText':
        tempoText = value;
        break;
      case 'noteType':
        noteType = value;
        break;
      case 'metronomeMark':
        metronomeMark = value;
        break;
    }
    notifyListeners();
  }

  void startWriting() {
    // لاجیک شروع نوشتن نت، مثلاً رفتن به viewer
  }

  // برای OTP
  bool isEmailMode = true; // سوئیچ بین ایمیل و تلفن
  int resendTimer = 48;
  // Timer? _timer;
  bool canResend = false;

  void startResendTimer() {
    canResend = false;
    resendTimer = 48;
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   if (resendTimer > 0) {
    //     resendTimer--;
    //     notifyListeners();
    //   } else {
    //     canResend = true;
    //     timer.cancel();
    //     notifyListeners();
    //   }
    // });
  }

  void resendOtp() {
    if (canResend) {
      startResendTimer();
      // لاجیک واقعی resend
    }
  }

  void toggleMode(bool isEmail) {
    isEmailMode = isEmail;
    notifyListeners();
  }

  // FAQ - Settings
  // داده‌های صفحات با جزئیات از تصاویر
  final String aboutUsTitle1 = 'Why are my courses gone?';
  final String aboutUsText1 =
      'Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.';
  final String aboutUsTitle2 =
      'What can I do if I downloaded them on my phone?';
  final String aboutUsText2 =
      'Morem ipsum dolor sit amet, consectetur adipiscing elit. Etiam eu turpis molestie, dictum est a, mattis tellus. Sed dignissim, metus nec fringilla accumsan, risus sem sollicitudin lacus, ut interdum tellus elit sed risus. Maecenas eget condimentum velit, sit amet feugiat lectus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Praesent auctor purus luctus enim egestas, ac scelerisque ante pulvinar. Donec ut rhoncus ex. Suspendisse ac rhoncus nisl, eu tempor urna. Curabitur vel bibendum lorem. Morbi convallis convallis diam sit amet lacinia. Aliquam in elementum tellus.\n\nCurabitur tempor quis eros tempus lacinia. Nam bibendum pellentesque quam a convallis. Sed ut vulputate nisi. Integer in felis sed leo vestibulum venenatis. Suspendisse quis arcu sem. Aenean feugiat ex eu vestibulum vestibulum. Morbi a eleifend magna. Nam metus lacus, porttitor eu mauris a, blandit ultrices nibh. Mauris sit amet magna non ligula vestibulum eleifend. Nulla varius volutpat turpis sed lacinia. Nam eget mi in purus lobortis eleifend. Sed nec ante dictum sem condimentum ullamcorper quis venenatis nisi. Proin vitae facilisis nisi, ac posuere leo.';

  final String contactUsTitle = 'Why are my courses gone?';
  final String contactUsText =
      'Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.';

  final List<Map<String, String>> faqItems = [
    {'question': 'Commonly asked questions', 'answer': ''}, // عنوان
    {'question': 'Why are my courses gone?', 'answer': 'Frequently asked'},
    {'question': 'How do I cancel Premium?', 'answer': 'Frequently asked'},
    {'question': 'How is the learning method in this app?', 'answer': ''},
    {'question': 'Is this app suitable for beginners?', 'answer': ''},
    {
      'question': 'Does it support languages other than English?',
      'answer':
          'Yes, we support multiple languages such as English, Spanish, Palestinian, German, Japanese, Korean and more.',
    },
    {'question': 'Can it be accessed offline?', 'answer': ''},
    {'question': 'Is this app safe to use?', 'answer': ''},
    {'question': 'How do I contact customer support?', 'answer': ''},
    {'question': 'What can we help with?', 'answer': ''}, // عنوان
    {'question': 'Payments and Subscriptions', 'answer': ''},
    {'question': 'Course Availability', 'answer': ''},
  ];

  final String termsPrivacyTitle = 'Privacy';
  final String termsPrivacyText =
      'Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.';
  final String termsPoliciesTitle = 'Policies';
  final String termsPoliciesText =
      'Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.';
  final String termsUspTitle = 'USP';
  final String termsUspText =
      'Sorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc vulputate libero et velit interdum, ac aliquet odio mattis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Curabitur tempus urna at turpis condimentum lobortis.';

  final List<Map<String, String>> paymentItems = [
    {'question': 'How do I change cards?', 'answer': 'Frequently asked'},
    {'question': 'Update billing info', 'answer': 'Frequently asked'},
    {'question': 'Cancel trial early', 'answer': 'Frequently asked'},
    {'question': 'Changing region', 'answer': 'Frequently asked'},
    {'question': 'What\'s included Standard?', 'answer': 'Frequently asked'},
    {'question': 'Other Categories', 'answer': ''}, // عنوان
    {'question': 'Translations and Language', 'answer': ''},
    {'question': 'About Instructors', 'answer': ''},
  ];

  // داده‌های نمونه (می‌تونی از API لود کنی)
  final List<Map<String, String>> blogs = [
    {
      'image': 'https://via.placeholder.com/150?text=Blog1',
      'title': 'Blog Title 1',
      'time': '3 min read',
    },
    {
      'image': 'https://via.placeholder.com/150?text=Blog2',
      'title': 'Blog Title 2',
      'time': '3 min read',
    },
  ];

  final Map<String, dynamic> newCourse = {
    'title': 'Iranian Music Radif',
    'instructor': 'Yasin Mosavi Aval',
    'description':
        'Speaking about "Radif", "Dastgah", "Avaz", "Goshe" and all of things about Iranian Music Radif',
  };

  final Map<String, dynamic> updatedCourse = {
    'image': 'https://via.placeholder.com/300x200?text=UpdatedCourse',
    'title': 'Biggest Sound Harmonics (2)',
    'instructor': 'Harmony Gray',
    'rating': 4.53,
  };

  final List<Map<String, String>> importantCourses = List.generate(
    3,
    (_) => {'title': 'Basic Theory', 'lessons': '12 Lesson'},
  );

  final List<String> authors = List.generate(6, (_) => 'Julien');

  void togglePushNotifications(bool value) {
    pushNotifications = value;
    notifyListeners();
  }

  void toggleNewCourseAlerts(bool value) {
    newCourseAlerts = value;
    notifyListeners();
  }

  void toggleUseWifiOverData(bool value) {
    useWifiOverData = value;
    notifyListeners();
  }

  void toggleAutoDownload(bool value) {
    autoDownload = value;
    notifyListeners();
  }

  void updateTextSize(double value) {
    textSize = value;
    notifyListeners();
  }

  // FAQ - Settings End

  // Bottom Nav Bar
  int _bottomNavIndex = 0; // اضافه شد

  int get bottomNavIndex => _bottomNavIndex;

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }

  // void toggleLanguage() {
  //   _isPersian = !_isPersian;
  //   notifyListeners();
  // }

  void setBottomNavIndex(int index) {
    _bottomNavIndex = index;
    notifyListeners(); // مهم: برای آپدیت رنگ
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    // final GoRouter router = GoRouter(
    //   routes: [GoRoute(path: '/', builder: (context, state) => HomePage())],
    // );

    // MaterialApp.router(routerConfig: router);

    return Consumer2<LocaleProvider, AppData>(
      builder: (context, localeProvider, appData, child) {
        // final GoRouter router = GoRouter(
        //   routes: [
        //     GoRoute(
        //       path: '/',
        //       builder: (context, state) => const SplashScreen(),
        //     ),
        //     GoRoute(
        //       path: '/home',
        //       builder: (context, state) => const HomePage(),
        //     ),
        //     GoRoute(
        //       path: '/settings',
        //       builder: (context, state) => const SettingsPage(),
        //     ),
        //     GoRoute(
        //       path: '/about',
        //       builder: (context, state) => const AboutUsPage(),
        //     ),
        //     GoRoute(
        //       path: '/music_player',
        //       builder: (context, state) => const MusicPlayerPage(),
        //     ),
        //   ],
        // );
        return MaterialApp(
          // routerConfig: router,
          debugShowCheckedModeBanner: false,
          title: AppStrings.application_fullname.translate(context),
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en', ''), Locale('fa', '')],
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return localeProvider.locale;
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: lightTheme(appData),
          darkTheme: darkTheme(appData),
          themeMode: appData.isDark ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const HomePage(),
            '/about': (_) => const AboutUsPage(),
            '/settings': (_) => const SettingsPage(),
            '/music_player': (_) => const MusicPlayerPage(),
          },
        );
      },
    );
  }

  ThemeData darkTheme(AppData appData) {
    return ThemeData(
      primarySwatch: Colors.yellow,
      // primarySwatch: AppColors.primary_dark as MaterialColor,
      secondaryHeaderColor: AppColors.secondary_dark,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background_dark,
      cardColor: AppColors.background_dark,
      fontFamily: appData.fontFamily,
      textTheme: TextTheme(
        headlineMedium: AppTypography.myAppDarkThemeHeadlineMedium(),
        bodyMedium: AppTypography.myAppDarkThemeBodyMedium(),
      ),
    );
  }

  ThemeData lightTheme(AppData appData) {
    return ThemeData(
      primarySwatch: Colors.blue,
      // primarySwatch: AppColors.primary_light,
      secondaryHeaderColor: AppColors.secondary_light,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background_light,
      cardColor: AppColors.background_light,
      fontFamily: appData.fontFamily,
      textTheme: TextTheme(
        headlineMedium: AppTypography.myAppLightThemeHeadlineMedium(),
        bodyMedium: AppTypography.myAppLightThemeBodyMedium(),
      ),
    );
  }
}

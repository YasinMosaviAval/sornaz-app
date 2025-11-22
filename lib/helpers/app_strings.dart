// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_images.dart';

class AppStrings extends ChangeNotifier {
  static const String applicationName = "Sornaz";
  static const String applicationFullname = "Sornaz Music App";
  static const String applicationEmail = "sornaz.ac@gmail.com";

  static const String faqTitle = "FAQ";
  static const String homeTitle = "Home";
  static const String blogsTitle = "Blogs";
  static const String tunerTitle = "Tuner";
  static const String splashTitle = "Splash";
  static const String signUpTitle = "Sign Up";
  static const String signInTitle = "Sign In";
  static const String coursesTitle = "Courses";
  static const String authorsTitle = "Authors";
  static const String profileTitle = "Profile";
  static const String aboutUsTitle = "About Us";
  static const String articlesTitle = "Articles";
  static const String settingsTitle = "Settings";
  static const String metronomeTitle = "Metronome";
  static const String contactUsTitle = "Contact Us";
  static const String onboardingTitle = "Onboarding";
  static const String musicSheetTitle = "Music Sheet";
  static const String musicPlayerTitle = "Music Player";
  static const String privacyPolicyTitle = "Privacy Policy";
  static const String voiceRecorderTitle = "Voice Recorder";
  static const String forgotPasswordTitle = "Forgot Password";
  static const String articleDetailPageTitle = "Article Detail Page";

  // static const String Title = "Home";

  // Splash - Onboarding
  static const List<Map<String, dynamic>> onboardingPages = [
    {
      'image': AppImages.onboarding_image_0,
      'title': 'Theory and practice complete each other.',
      'subtitle':
          'Real progress comes from blending musical knowledge - consistent practice.',
      'buttons': [next_button],
      // 'dotColor': Colors.yellow,
    },
    {
      'image': AppImages.onboarding_image_1,
      'title': 'Lasting learning takes time.',
      'subtitle':
          'Musical progress requires patience, regular training, and structured learning.',
      'buttons': [previous_button, next_button],
      // 'dotColor': Colors.blue,
    },
    {
      'image': AppImages.onboarding_image_2,
      'title': 'Music begins with the basics.',
      'subtitle':
          'True learning starts with understanding the foundations and core principles of music.',
      'buttons': [previous_button, start_button],
      // 'dotColor': Colors.pink,
    },
  ];

  static const String home_searchbar_hint_text = 'Search Blogs';
  // 'Search course, topic, mentor ...';

  static const String new_courses_title = 'New Courses';
  static const String last_blog_title = 'Last Blog';
  static const String view_all_link = 'View all';
  static const String no_title = 'No Title';
  static const String epmtyText = '';

  static const String error_in_loading = 'Some Error accoured in Loading';
  static const String faild_to_load_posts = 'Failed to load recent posts';

  static const String previous_button = 'Previous';
  static const String next_button = 'Next';
  static const String start_button = 'Start';
  // Splash - Onboarding End

  static const String dont_have_an_account = 'Don\'t have an account? Sign up';
  static const String sign_in_with_google = 'Sign In with Google';
  static const String signUp = "Sign Up";
  static const String signIn = "Sign In";
  static const String forgot_password = 'Forgot password?';
  static const String remember_me = 'Remember me';
  static const String password = 'Password';
  static const String email = 'Email';
  static const String signin_description =
      'Sign into your account - access all of your courses now.';

  // داده‌های نمونه برای لاگین
  static const String sample_email = 'bruno203@gmail.com';
  static const String sample_phone = '0911223344';
  static const String sample_username = 'bruno203';

  static const String sent_otp_via_email =
      'OTP code has been sent via your email';
  static const String sent_otp_via_phone_number =
      'OTP code has been sent via your phone number';
  static const String phone_number = 'Phone Number';
  static const String send_otp_via_email = 'Sent OTP code with Email';
  static const String send_otp_via_phone_number =
      'Sent OTP code with Phone Number';
  static const String send_otp_code = 'Send OTP Code';

  static const String already_have_an_account =
      'Already have an account? Sign In';

  static const String dark_mode = 'Dark Mode';

  static const String dark_mode_description =
      'If it is ON, your app theme is Dark';

  static const String bookmark = 'Bookmark';

  static const String share_app = 'Share App';

  static const String achievements = 'Achievements';

  static const String community = 'Community';

  static const String share_feedback = 'Share Feedback';

  static const String membership = 'Membership';

  static const String my_account = 'My Account';

  static const String switch_acount = 'Switch to Another Account';

  static const String logout = 'Logout Account';

  static const String top_active_authors = 'Top Active Authors';

  static const String music_player_searchbar_hint = "Search in audio files ...";
  static const String music_player_searchbar_hint_fa =
      "جستجو در فایل‌ های صوتی ...";

  static const String audio_file_not_found = 'Audio Files Not Found!';
  static const String audio_file_not_found_fa = 'فایل صوتی یافت‌ نشد!';

  static const String two_times_press_back_button_for_exit_application =
      'Press again BACK Button for Exit Application';
  static const String two_times_press_back_button_for_exit_application_fa =
      'برای خروج دوباره دکمه برگشت را بزنید';
}

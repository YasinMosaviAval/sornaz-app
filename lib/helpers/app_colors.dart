// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary_light = Color.fromARGB(255, 0, 100, 251);
  static Color primary_light100 = primary_light.withAlpha(25);
  static Color primary_light200 = primary_light.withAlpha(50);
  static Color primary_light300 = primary_light.withAlpha(75);
  static Color primary_light400 = primary_light.withAlpha(100);
  static Color primary_light500 = primary_light.withAlpha(125);
  static Color primary_light600 = primary_light.withAlpha(150);
  static Color primary_light700 = primary_light.withAlpha(175);
  static Color primary_light800 = primary_light.withAlpha(200);
  static Color primary_light900 = primary_light.withAlpha(225);
  

  static const Color secondary_light = Color.fromARGB(255, 193, 158, 50);
  static Color secondary_light100 = secondary_light.withAlpha(25);
  static Color secondary_light200 = secondary_light.withAlpha(50);
  static Color secondary_light300 = secondary_light.withAlpha(75);
  static Color secondary_light400 = secondary_light.withAlpha(100);
  static Color secondary_light500 = secondary_light.withAlpha(125);
  static Color secondary_light600 = secondary_light.withAlpha(150);
  static Color secondary_light700 = secondary_light.withAlpha(175);
  static Color secondary_light800 = secondary_light.withAlpha(200);
  static Color secondary_light900 = secondary_light.withAlpha(225);


  static const Color background_light = Color.fromARGB(255, 255, 255, 255);
  static const Color button_text_primary_light = Color.fromARGB(255, 255, 255, 255);
  
  static const Color surface_light = Color.fromARGB(255, 241, 241, 241);
  static const Color shadow_light = Color.fromARGB(30, 241, 241, 241);

  static const Color text_primary_light = Color.fromARGB(255, 0, 0, 0);

  static const Color text_secondary_light = Color.fromARGB(155, 31, 31, 31);
  static const Color unselected_item_light = Color.fromARGB(75, 31, 31, 31);
  static const Color clicked_light = Color.fromARGB(30, 31, 31, 31);
  static const Color hovered_light = Color.fromARGB(15, 31, 31, 31);
  static const Color border_light = Color.fromARGB(30, 31, 31, 31);

  // static const Color background_light = Color.fromARGB(255, 255, 255, 255);
  // static const Color button_text_primary_light = Color.fromARGB(255, 255, 255, 255);

  // static const Color surface_light = Color.fromARGB(255, 241, 241, 241);
  // static const Color shadow_light = Color.fromARGB(30, 241, 241, 241);

  // static const Color text_primary_light = Color.fromARGB(255, 0, 0, 0);

  // static const Color text_secondary_light = Color.fromARGB(155, 31, 31, 31);
  // static const Color unselected_item_light = Color.fromARGB(75, 31, 31, 31);
  // static const Color clicked_light = Color.fromARGB(30, 31, 31, 31);
  // static const Color hovered_light = Color.fromARGB(15, 31, 31, 31);
  // static const Color border_light = Color.fromARGB(30, 31, 31, 31);

  static const Color primary_dark = Color.fromARGB(255, 193, 158, 50);
  static const Color secondary_dark = Color.fromARGB(255, 0, 100, 251);
  static const Color background_dark = Color.fromARGB(255, 0, 0, 0);
  static const Color surface_dark = Color.fromARGB(255, 31, 31, 31);
  static const Color shadow_dark = Color.fromARGB(30, 31, 31, 31);
  static const Color text_primary_dark = Color.fromARGB(255, 255, 255, 255);
  static const Color text_secondary_dark = Color.fromARGB(155, 241, 241, 241);
  static const Color button_text_primary_dark = Color.fromARGB(255, 0, 0, 0);
  static const Color unselected_item_dark = Color.fromARGB(100, 241, 241, 241);
  static const Color clicked_dark = Color.fromARGB(30, 241, 241, 241);
  static const Color hovered_dark = Color.fromARGB(15, 241, 241, 241);
  static const Color border_dark = Color.fromARGB(30, 241, 241, 241);


  static const Color error = Color.fromRGBO(244, 67, 54, 1);
  static const Color success = Color.fromRGBO(76, 175, 80, 1);
  static const Color warning = Color.fromRGBO(255, 152, 0, 1);
  static const Color info = Color.fromRGBO(75, 181, 246, 1);


/*
  static const MaterialColor blue = MaterialColor(_bluePrimaryValue, <int, Color>{
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(_bluePrimaryValue),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(0xFF1565C0),
    900: Color(0xFF0D47A1),
  });
  static const int _bluePrimaryValue = 0xFF2196F3;


  static LinearGradient successGradient(bool isDark) {
    return LinearGradient(
      colors: isDark ? [successDark, successDark.withOpacity(0.7)] : [success, success.withOpacity(0.7)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }


  static BoxShadow defaultShadow(bool isDark) {
    return BoxShadow(
      color: isDark ? Colors.black.withAlpha(50) : Colors.grey.withAlpha(20),
      spreadRadius: 2,
      blurRadius: 8,
      offset: const Offset(0, 4),
    );
  }


  static Color getPrimary(bool isDark) => isDark ? primaryDark : primary;
  static Color getSecondary(bool isDark) => isDark ? secondaryDark : secondary;
  static Color getBackground(bool isDark) => isDark ? backgroundDark : background;
  static Color getSurface(bool isDark) => isDark ? surfaceDark : surface;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) =>  isDark ? textSecondaryDark : textSecondary;
  static Color getError(bool isDark) => isDark ? errorDark : error;
  static Color getSuccess(bool isDark) => isDark ? successDark : success;
  static Color getWarning(bool isDark) => isDark ? warningDark : warning;
*/


  // final bool isDark = Provider.of<AppData>(context).isDark;
  // final bool isDarken = context.watch<AppData>().isDark;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color app_drawer_item_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color app_drawer_item_message_box_decoration_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color app_drawer_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color app_drawer_box_decoration_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;


  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color settings_switch_tile_enabled_title_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color settings_switch_tile_not_enabled_title_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color settings_switch_tile_enabled_subtitle_color({required bool isDark}) =>isDark ? AppColors.text_primary_dark.withAlpha(200) : AppColors.text_primary_light.withAlpha(200);
  static Color settings_switch_tile_not_enabled_subtitle_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark.withAlpha(200) : AppColors.text_secondary_light.withAlpha(200);
  static Color settings_switch_tile_active_thumb_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color settings_switch_tile_inactive_thumb_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color settings_switch_tile_active_track_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color settings_switch_tile_inactive_track_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color settings_section_header_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color settings_section_header_box_decoration_color({required bool isDark}) => isDark ? AppColors.hovered_dark : AppColors.hovered_light;
  static Color settings_section_header_divider_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.clicked_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================


  static Color component_search_bar_prefix_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color component_search_bar_suffix_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color component_search_bar_fill_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color bottom_nav_snack_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color bottom_nav_item_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color bottom_nav_selected_item_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color bottom_nav_unselected_item_color({required bool isDark}) => isDark ? AppColors.unselected_item_dark : AppColors.unselected_item_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================


  static Color sornaz_app_bar_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color sornaz_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================


  static Color app_typography_headline1_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_headline2_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_headline3_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_headline4_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_headline5_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_headline6_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body0_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body1_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body2_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body3_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body4_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_body_reverse0_text_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color app_typography_body_reverse1_text_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color app_typography_body_reverse2_text_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color app_typography_body_reverse3_text_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color app_typography_body_reverse4_text_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color app_typography_subtitle1_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color app_typography_subtitle2_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color app_typography_subtitle3_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color app_typography_subtitle4_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color app_typography_subtitle_reverse1_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_light : AppColors.text_secondary_dark;
  static Color app_typography_subtitle_reverse2_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_light : AppColors.text_secondary_dark;
  static Color app_typography_subtitle_reverse3_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_light : AppColors.text_secondary_dark;
  static Color app_typography_subtitle_reverse4_text_color({required bool isDark}) => isDark ? AppColors.text_secondary_light : AppColors.text_secondary_dark;
  static Color app_typography_link1_text_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color app_typography_link2_text_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color app_typography_link3_text_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color app_typography_button_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_caption_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color app_typography_overline_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color article_item_box_decoration_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.hovered_light;


  static Color article_list_selected_box_decoration_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color article_list_unselected_box_decoration_color({required bool isDark}) =>  isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color articles_page_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color articles_page_body_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;


  static Color blog_carousel_decoration_color({required bool isDark}) => isDark? AppColors.primary_dark : AppColors.primary_light; // =============
  static Color blog_carousel_foreground_decoration_color({required bool isDark}) => isDark? AppColors.secondary_dark : AppColors.secondary_light;

  static Color blog_card_border_color(bool isDark) => isDark ? AppColors.border_dark : AppColors.border_light;
  static Color blog_card_decoration_color(bool isDark) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color blog_card_box_shadow_color(bool isDark) => isDark ? AppColors.shadow_dark : AppColors.shadow_light;
  static Color blog_card_empty_image_color(bool isDark) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color article_details_page_app_bar_foreground_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_details_page_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;

  static Color article_details_page_app_bar_base_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color article_details_page_app_bar_progress_color({required bool isDark}) => isDark ? AppColors.primary_dark.withAlpha(50) : AppColors.primary_light.withAlpha(50);
  static Color article_details_page_app_bar_progress2_color({required bool isDark}) => isDark ? AppColors.primary_dark.withAlpha(50) : AppColors.primary_light.withAlpha(50);


  static Color article_content_html_body({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color article_content_html_a({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color article_content_html_p({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h1({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h2({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h3({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h4({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h5({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color article_content_html_h6({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color home_body_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color home_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color home_header_menu_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================


  static Color note_length_name_box_selected_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color note_length_name_box_unselected_color({required bool isDark}) => Colors.transparent;


  static Color bpm_slider_active_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color bpm_slider_inactive_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;


  static Color labled_slider_active_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color labled_slider_inactive_color({required bool isDark}) =>isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;


  static Color metronome_button_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color time_signature_row_decoration_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.clicked_light;
  static Color time_signature_row_drop_down_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color metronome_settings_page_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color metronome_settings_page_leading_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color stop_mode_section_selected_timer_lable_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color stop_mode_section_unselected_timer_lable_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color stop_mode_section_checkmark_color({required bool isDark}) => isDark? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color stop_mode_section_selected_color({required bool isDark}) => isDark? AppColors.primary_dark : AppColors.primary_light;
  static Color stop_mode_section_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color stop_mode_section_border_color({required bool isDark}) => Colors.transparent;


  static Color metronome_page_background_color({required bool isDark}) => isDark? AppColors.background_dark : AppColors.background_light;
  static Color metronome_page_tapping_icon_active_decoration_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color metronome_page_tapping_icon_inactive_decoration_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.clicked_light;
  static Color metronome_page_tapping_icon_active_color({required bool isDark}) => isDark ? AppColors.text_primary_light : AppColors.text_primary_dark;
  static Color metronome_page_tapping_icon_inactive_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color metronome_page_accent_beat_icon_active_decoration_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color metronome_page_accent_beat_icon_inactive_decoration_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.clicked_light;
  static Color metronome_page_accent_beat_icon_active_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color metronome_page_accent_beat_icon_inactive_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color metronome_page_drop_down_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color metronome_page_icon_enabled_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color metronome_page_icon_disabled_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color splash_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color about_us_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color settings_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color settings_list_tile_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color settings_list_tile_border_color({required bool isDark}) => isDark ? AppColors.border_dark : AppColors.border_light;
  static Color settings_list_tile_decoration_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color settings_slider_active_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color settings_slider_inactive_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color settings_drop_down_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color settings_icon_enabled_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color music_player_is_scanning_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;


  static Color music_player_equalizer_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;


  static Color music_player_bottom_player_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color music_player_audio_slider_active_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color music_player_audio_slider_inactive_color({required bool isDark}) => isDark ? AppColors.border_dark : AppColors.border_light;


  static Color music_player_breadcrumb_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color music_player_breadcrumb_back_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  // static Color music_player_flat_list_view_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color music_player_flat_list_view_decoration_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;


  static Color music_player_song_information_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  // static Color music_player_song_information_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color music_player_search_bar_prefix_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color music_player_search_bar_cursor_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color music_player_search_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color music_player_search_bar_icon_theme_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color music_player_audio_item_border_color({required bool isDark}) => isDark ? AppColors.border_dark : AppColors.border_light;
  static Color music_player_audio_item_playing_background_color({required bool isDark}) => isDark ? AppColors.clicked_dark : AppColors.clicked_light;
  static Color music_player_audio_item_not_playing_background_color({required bool isDark}) => Colors.transparent;
  static Color music_player_audio_item_playing_icon_background_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color music_player_audio_item_not_playing_icon_background_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;


  // static Color music_player_audio_controls_main_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color music_player_audio_controls_main_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color music_player_audio_controls_sub_level_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color music_player_audio_controls_sub_level_active_icon_color({required bool isDark}) =>isDark ? AppColors.primary_dark : AppColors.primary_light;


  static Color music_player_folder_list_view_leading_icon_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color music_player_folder_list_view_trailing_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color tuner_page_background_color({required bool isDark}) =>  isDark ? AppColors.background_dark : AppColors.background_light;


  static Color tuner_frequency_box_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color tuner_frequency_box_in_range_frequency_color({required bool isDark}) => AppColors.success.withAlpha(100);
  static Color tuner_frequency_box_not_in_range_frequency_color({required bool isDark}) => AppColors.success.withAlpha(30);
  static Color tuner_frequency_box_line_color({required bool isDark}) => Colors.orange;
  static Color tuner_frequency_box_point_color({required bool isDark}) => Colors.orange;


  static Color tuner_settings_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color tuner_settings_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color tuner_piano_keyboard_top_border_color({required bool isDark}) => Colors.white;
  static Color tuner_piano_keyboard_a4_key_color({required bool isDark}) => Colors.lightBlueAccent;
  static Color tuner_piano_keyboard_active_white_key_color({required bool isDark}) => Colors.yellow;
  static Color tuner_piano_keyboard_inactive_white_key_color({required bool isDark}) => Colors.white;
  static Color tuner_piano_keyboard_border_key_color({required bool isDark}) => Colors.black;
  static Color tuner_piano_keyboard_active_not_white_key_color({required bool isDark}) => Colors.orange;
  // static Color tuner_piano_keyboard_active_not_white_key_lable_color({required bool isDark}) => Colors.white70;
  static Color tuner_piano_keyboard_inactive_koron_key_color({required bool isDark}) => AppColors.unselected_item_light;
  static Color tuner_piano_keyboard_inactive_sori_key_color({required bool isDark}) => AppColors.text_secondary_light;
  static Color tuner_piano_keyboard_inactive_black_key_color({required bool isDark}) => Colors.black;

  // ===================================================================================================================================================================
  // ===================================================================================================================================================================
  // ===================================================================================================================================================================

  static Color voice_recorder_basic_waveform_decoration_color({required bool isDark}) => isDark ? AppColors.surface_dark.withAlpha(150) : AppColors.surface_light.withAlpha(150);


  static Color voice_recorder_delete_button_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_delete_button_icon_style_color({required bool isDark}) => AppColors.error;


  static Color voice_recorder_rename_button_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_rename_button_icon_style_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;


  static Color voice_recorder_record_details_page_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark: AppColors.surface_light;
  static Color voice_recorder_record_details_page_app_bar_foreground_color({required bool isDark}) => isDark ? AppColors.text_primary_dark: AppColors.text_primary_light;
  static Color voice_recorder_record_details_page_background_color({required bool isDark}) => isDark? AppColors.background_dark : AppColors.background_light;
  static Color voice_recorder_record_details_page_waveform_player_view_background_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;


  // static Color voice_recorder_waveform_color({required bool isDark}) => Colors.blue;


  static Color voice_recorder_app_waveform_painter_active_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_app_waveform_painter_inactive_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color voice_recorder_app_waveform_painter_minor_tick_color({required bool isDark}) => isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  static Color voice_recorder_app_waveform_painter_major_tick_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  // static Color voice_recorder_app_waveform_painter_time_text_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;


  static Color voice_recorder_recordings_list_page_app_bar_foreground_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_recordings_list_page_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_selected_file_card_color({required bool isDark}) => isDark ? AppColors.primary_dark.withAlpha(20) : AppColors.primary_light.withAlpha(20);
  static Color voice_recorder_recordings_list_page_not_selected_file_card_color({required bool isDark}) => isDark ? AppColors.background_dark.withAlpha(200) : AppColors.background_light.withAlpha(200);
  static Color voice_recorder_recordings_list_page_card_border_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_card_leading_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_recordings_list_page_card_trailing_icons_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_recordings_list_page_dialog_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_dialog_confirm_delete_text_color({required bool isDark}) => AppColors.error;
  static Color voice_recorder_recordings_list_page_selection_bottom_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_selection_bottom_bar_border_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_recordings_list_page_selection_bottom_bar_delete_icon_color({required bool isDark}) => AppColors.error;
  static Color voice_recorder_recordings_list_page_rename_save_text_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;


  static Color voice_recorder_favorite_icon_active_color({required bool isDark}) => AppColors.error;
  static Color voice_recorder_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_app_bar_background_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_body_background_color({required bool isDark}) => isDark ? AppColors.background_dark : AppColors.background_light;
  static Color voice_recorder_bookmark_text_color({required bool isDark}) => isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color voice_recorder_bookmark_icon_color({required bool isDark}) =>  isDark ? AppColors.primary_dark : AppColors.primary_light;
  static Color voice_recorder_stop_icon_background_color({required bool isDark}) => Colors.transparent;
  static Color voice_recorder_stop_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_record_button_border_color({required bool isDark}) => isDark ? AppColors.surface_dark : AppColors.surface_light;
  static Color voice_recorder_record_button_inactive_background_color({required bool isDark}) => Colors.transparent;
  static Color voice_recorder_record_button_active_background_color({required bool isDark}) =>  AppColors.error;
  static Color voice_recorder_pause_icon_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_play_icon_background_color({required bool isDark}) => Colors.transparent;
  static Color voice_recorder_play_icon_active_color({required bool isDark}) => isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  static Color voice_recorder_play_icon_inactive_color({required bool isDark}) => isDark ? AppColors.unselected_item_dark : AppColors.unselected_item_light;


  static const Color voice_recorder_waveform_player_color = Colors.blue;
  static Color voice_recorder_waveform_player_play_icon_color({required bool isDark}) => isDark? AppColors.text_primary_dark: AppColors.text_primary_light;
  static Color voice_recorder_waveform_player_pause_icon_color({required bool isDark}) => isDark? AppColors.text_primary_dark: AppColors.text_primary_light;
  static Color voice_recorder_waveform_player_playhead_color({required bool isDark}) => Colors.red;














}

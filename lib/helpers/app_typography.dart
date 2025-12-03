// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
// import 'package:path/path.dart';
// import 'package:provider/provider.dart';
// import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';
// import 'package:provider/provider.dart';
// import 'package:sornaz/helpers/app_data.dart';

/*
/// ----------------------------
/// FONT FAMILY LIST
/// ----------------------------
class AppFonts {
  static const String defaultFont = iran_sansx_fn;

  static const String iran_sansx_fn = 'iran_sansx_fn';
  static const String iran_sansx = 'iran_sansx';
  static const String iran_yekan_fn = 'iran_yekan_fn';
  static const String iran_yekan = 'iran_yekan';
  static const String kalameh_fn = 'kalameh_fn';
  static const String kalameh = 'kalameh';
  static const String peyda = 'peyda';
  static const String tahrir = 'tahrir';
  static const String sahel_fn = 'sahel_fn';
  static const String sahel = 'sahel';
  static const String vazir_fn = 'vazir_fn';
  static const String vazir = 'vazir';

  /// 🟦 لیست فونت‌ها برای دراپ‌داون
  static const List<String> allFonts = [
    iran_sansx_fn,
    iran_sansx,
    iran_yekan_fn,
    iran_yekan,
    kalameh_fn,
    kalameh,
    peyda,
    tahrir,
    sahel_fn,
    sahel,
    vazir_fn,
    vazir,
  ];
}

/// --------------------------------------------------------
///  DYNAMIC TYPOGRAPHY SYSTEM
/// --------------------------------------------------------
class AppTypography {
  /// گرفتن فونت انتخاب شده از Provider
  static String getFontFamily(BuildContext context) {
    return context.watch<AppData>().selectedFontFamily;
  }

  /// گرفتن سایز متنی انتخاب شده
  static double scale(BuildContext context) {
    return context.watch<AppData>().textSize / 16; // نسبت‌دهی
  }

  /// رنگ داینامیک
  static Color primaryColor(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    return isDark ? AppColors.text_primary_dark : AppColors.text_primary_light;
  }

  static Color secondaryColor(BuildContext context) {
    final isDark = context.watch<AppData>().isDark;
    return isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light;
  }

  /// --------------------
  /// HEADLINES
  /// --------------------

  static TextStyle headline1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 32 * scale(context),
        fontWeight: FontWeight.w900,
      );

  static TextStyle headline2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 28 * scale(context),
        fontWeight: FontWeight.w800,
      );

  static TextStyle headline3(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 24 * scale(context),
        fontWeight: FontWeight.w700,
      );

  static TextStyle headline4(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 20 * scale(context),
        fontWeight: FontWeight.w600,
      );

  /// --------------------
  /// BODY TEXT
  /// --------------------

  static TextStyle body1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 16 * scale(context),
      );

  static TextStyle body2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 14 * scale(context),
      );

  /// --------------------
  /// SUBTITLES
  /// --------------------

  static TextStyle subtitle1(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 16 * scale(context),
        fontWeight: FontWeight.w500,
      );

  static TextStyle subtitle2(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 14 * scale(context),
        fontWeight: FontWeight.w500,
      );

  /// --------------------
  /// SMALL TEXTS
  /// --------------------

  static TextStyle caption(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 12 * scale(context),
      );

  static TextStyle overline(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: secondaryColor(context),
        fontSize: 10 * scale(context),
        letterSpacing: 1.5,
      );

  /// --------------------
  /// BUTTON
  /// --------------------

  static TextStyle button(BuildContext context) => TextStyle(
        fontFamily: getFontFamily(context),
        color: primaryColor(context),
        fontSize: 14 * scale(context),
        fontWeight: FontWeight.w600,
      );
}

*/
class AppTypography {
  // static final isDark = Provider.of<AppData>(context as BuildContext).isDark;
  static final isDark = false;
  static const String default_font_family = 'iran_sansx_fn';
  static const String iran_sansx_fn = 'iran_sansx_fn';
  static const String iran_sansx = 'iran_sansx';
  static const String iran_yekan_fn = 'iran_yekan_fn';
  static const String iran_yekan = 'iran_yekan';
  static const String kalameh_fn = 'kalameh_fn';
  static const String kalameh = 'kalameh';
  static const String peyda = 'peyda';
  static const String tahrir = 'tahrir';
  static const String sahel_fn = 'sahel_fn';
  static const String sahel = 'sahel';
  static const String vazir_fn = 'vazir_fn';
  static const String vazir = 'vazir';

  // primary text color
  static TextStyle headline1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(32),
      fontWeight: FontWeight.w900,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(28),
      fontWeight: FontWeight.w800,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline3() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(24),
      fontWeight: FontWeight.w700,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline4() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(20),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline5() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(18),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline6() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      // wordSpacing: 1,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  // primary text color
  static TextStyle body1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      // wordSpacing: 1,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  // secondary text color
  static TextStyle subtitle1() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      // wordSpacing: 1,
      // letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle2() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      // wordSpacing: 1,
      // letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle3() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(12),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      // wordSpacing: 1,
      // letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle caption() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(12),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle overline() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(10),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 1.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle button() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(14),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static double _responsiveSize(double baseSize) {
    // مثلاً بر اساس MediaQuery (در ویجت استفاده کن)
    // return baseSize * (MediaQuery.of(context).size.width / 375); // 375 = iPhone SE
    return baseSize; // ساده – می‌تونی responsive کنی
  }

  static void changeGlobalFont(String newFontFamily) {
    // نیاز به rebuild اپ داره – می‌تونی در AppData ذخیره کنی
  }

  static TextStyle musicTitle() {
    return TextStyle(
      fontFamily: default_font_family,
      fontSize: _responsiveSize(18),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      wordSpacing: 1,
      letterSpacing: 0.5,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle routerPageNotFound = TextStyle();

  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================

  static TextStyle blogCardTitle = TextStyle(fontSize: AppSpacing.space_12);
  static TextStyle blogCardTime = TextStyle(
    fontSize: AppSpacing.space_10,
    color: Colors.grey,
  );

  static TextStyle appDrawerApplicationFullname() => headline6();
  static TextStyle appDrawerApplicationEmail() => subtitle2();
  // static TextStyle appDrawerSwitchAcountItem() => body1();
  // static TextStyle appDrawerHeaderItemPart() => body2();
  static TextStyle appDrawerItemTitle() => body2();
  static TextStyle appDrawerItemsubtitle() => subtitle2();

  static TextStyle blogCarouselErrorInLoading() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle blogCarouselTitle() => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle blogCarouselDate() => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
    fontSize: 10,
  );

  static TextStyle bottomNavSnackBar() => TextStyle();
  static TextStyle headerSectionTitle() => TextStyle();
  static TextStyle headerSectionViewAllLink() => TextStyle();

  static TextStyle languageSwitchTileTitle() =>
      TextStyle(fontWeight: FontWeight.w500);

  static TextStyle languageSwitchTileSubtitle() => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle noFileFoundMessage() => TextStyle(
    fontSize: AppSpacing.space_20,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle sectionTitleTitle() => TextStyle(
    fontSize: AppSpacing.space_18,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.w900,
  );

  static TextStyle sectionTitleViewAllLink() => TextStyle(
    color: isDark ? AppColors.primary_dark : AppColors.primary_light,
  );

  static TextStyle homeApplicationTitle() => TextStyle(
    fontSize: AppSpacing.space_18,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.w700,
  );

  static TextStyle aboutUsAppBarTitle() => TextStyle();
  static TextStyle aboutUsTitle() => TextStyle();
  static TextStyle aboutUsBody() => TextStyle();

  static TextStyle articlesErrorInLoading() => TextStyle();
  static TextStyle articlesReleaseDate() => TextStyle(
    fontSize: AppSpacing.space_10,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle articlesTitle() => TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: AppSpacing.space_12,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle articlesBrief() => TextStyle(
    fontSize: AppSpacing.space_10,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle articlesDetailPageErrorInSendingComment() => TextStyle();
  static TextStyle articlesDetailPageLoadMoreComments() => TextStyle();
  static TextStyle articlesDetailPageCommentsListTitle() =>
      TextStyle(fontSize: AppSpacing.space_18, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageCommentsListEmptyTitle() =>
      TextStyle(fontSize: AppSpacing.space_16, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageSendStarPoint() => TextStyle();
  static TextStyle articlesDetailPageWriteComment() => TextStyle();
  static TextStyle articlesDetailPageSendCommentButton() => TextStyle();
  static TextStyle articlesDetailPageSimilarArticlesTitle() =>
      TextStyle(fontSize: AppSpacing.space_18, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageSimilarArticlesItemTitle() => TextStyle();
  static TextStyle articlesDetailPageSimilarArticlesItemSubtitle() =>
      TextStyle();
  static TextStyle articlesDetailPageArticlesTitle() => TextStyle(
    fontSize: AppSpacing.space_18,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle articlesDetailPageArticleCommentsListTitle() => TextStyle();
  static TextStyle articlesDetailPageArticleCommentsListSubtitle() =>
      TextStyle();
  static TextStyle articlesDetailPageArticleCommentsListDate() => TextStyle(
    fontSize: AppSpacing.space_12,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle articlesDetailPageArticleCommentsListReleaseDate() =>
      TextStyle(
        fontSize: AppSpacing.space_14,
        color: isDark
            ? AppColors.text_secondary_dark
            : AppColors.text_secondary_light,
      );
  static TextStyle articlesDetailPageArticlesAuthorsName() => TextStyle(
    fontSize: AppSpacing.space_14,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle musicPlayerNotGrantedPermissionSnackBar() => TextStyle();
  static TextStyle musicPlayerErrorInLoadingSnackBar() => TextStyle();
  static TextStyle musicPlayerAudioWidgetDurationTime() => TextStyle();
  static TextStyle musicPlayerAudioWidgetPositionTime() => TextStyle();
  static TextStyle musicPlayerAudioFileNotFound() => TextStyle();
  static TextStyle musicPlayerPlayingAudioFile() => TextStyle(
    fontSize: AppSpacing.space_14,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.w500,
  );

  static TextStyle musicPlayerNotPlayingAudioFile() => TextStyle(
    fontSize: AppSpacing.space_14,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.normal,
    // fontWeight: isCurrentlyPlaying
    //     ? FontWeight.w900
    //     : FontWeight.normal,
  );

  static TextStyle musicPlayerAudioItemDurationTime() => TextStyle(
    fontSize: AppSpacing.space_12,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle musicPlayerAudioItemAddress() => TextStyle(
    fontSize: AppSpacing.space_12,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle metronomeAppBar() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeBPM() => TextStyle(
    fontSize: AppSpacing.space_24,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeTiming() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeVolume() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeLaunchButton() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomePlayPauseButton() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeStopButton() => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle tunerCentDifference() => TextStyle(
    fontSize: AppSpacing.space_20,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerCentUnitTitle() => TextStyle(
    fontSize: AppSpacing.space_16,
    fontWeight: FontWeight.w300,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle tunerNoteOctave() => TextStyle(
    fontSize: AppSpacing.space_24,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerNoteName() => TextStyle(
    fontSize: AppSpacing.space_48,
    fontWeight: FontWeight.bold,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerNearNoteFrequency() => TextStyle(
    fontSize: AppSpacing.space_20,
    fontWeight: FontWeight.w500,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerHertzUnitTitle() => TextStyle(
    fontSize: AppSpacing.space_16,
    fontWeight: FontWeight.w300,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle tunerDetectedFrequency() => TextStyle(
    fontSize: AppSpacing.space_24,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerA4Frequency() => TextStyle(
    fontSize: AppSpacing.space_16,
    fontWeight: FontWeight.w700,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle tunerSetBaseFrequency() => TextStyle(
    fontSize: AppSpacing.space_16,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle voiceRecorderNotGrantedPermissionSnackBar() => caption();
  static TextStyle voiceRecorderFilename() => headline6();
  static TextStyle voiceRecorderDate() => caption();
  static TextStyle voiceRecorderDeleteFileSnackBar() => caption();
  static TextStyle voiceRecorderRestoreFileSnackBar() => caption();
  static TextStyle voiceRecorderDeleteFileDialogueTitle() => headline5();
  static TextStyle voiceRecorderDeleteFileDialogueContent() => body1();
  static TextStyle voiceRecorderDeleteFileDialogueCancelButton() => body2();
  static TextStyle voiceRecorderDeleteFileDialogueConfirmButton() => body2();
  static TextStyle voiceRecorderDeleteFileMessageSnackBar() => caption();
  static TextStyle voiceRecorderRenameFileDialogueTitle() => headline5();
  static TextStyle voiceRecorderRenameFileDialogueCancelButton() => body2();
  static TextStyle voiceRecorderRenameFileDialogueConfirmButton() => body1();
  static TextStyle voiceRecorderRenameFileMessageSnackBar() => caption();
  static TextStyle voiceRecorderRenameFileErrorMessageSnackBar() => caption();
  static TextStyle voiceRecorderRecordingTimer() => headline3();

  static TextStyle recordDetailsFilenameTitle() => TextStyle(
    fontSize: 18,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle recordDetailsFilename() =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static TextStyle recordDetailsRecordDate() =>
      TextStyle(fontSize: 20, color: Colors.grey);
  static TextStyle recordDetailsAppBar() => TextStyle();
  static TextStyle recordDetailsRecordDateTitle() => TextStyle(fontSize: 18);
  static TextStyle recordDetailsRenameTitle() => TextStyle();
  static TextStyle recordDetailsRenameDialogueTitle() => TextStyle();
  static TextStyle recordDetailsRenameDialogueCancelButton() => TextStyle();
  static TextStyle recordDetailsRenameDialogueConfirmButton() => TextStyle();
  static TextStyle recordDetailsDeleteDialogueLabel() => TextStyle();
  static TextStyle recordDetailsDeleteDialogueTitle() => TextStyle();
  static TextStyle recordDetailsDeleteDialogueContent() => TextStyle();
  static TextStyle recordDetailsDeleteDialogueCancelButton() => TextStyle();
  static TextStyle recordDetailsDeleteDialogueConfirmButton() => TextStyle();

  static TextStyle settingsAppBar() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle settingsSectionTitle() => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  static TextStyle settingsItemTitle() =>
      TextStyle(fontWeight: FontWeight.w500);
  static TextStyle settingsItemSubtitle() => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle settingsItemContent() => TextStyle();
  static TextStyle settingsDropdownItem() => TextStyle();

  static TextStyle? waveformPainterSeconds() =>
      TextStyle(fontSize: 10, color: Colors.grey.shade500);

  static TextStyle? searchBarText() =>
      TextStyle(fontSize: AppSpacing.space_12, fontWeight: FontWeight.w600);
  static TextStyle? searchBarHint() => TextStyle(
    fontWeight: FontWeight.w500,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle? myAppDarkThemeHeadlineMedium() => TextStyle(
    color: AppColors.text_primary_dark,
    fontWeight: FontWeight.bold,
  );
  static TextStyle? myAppDarkThemeBodyMedium() => TextStyle(
    color: AppColors.text_secondary_dark,
    fontSize: 12,
    // fontSize: appData.textSize,
  );

  static TextStyle? myAppLightThemeHeadlineMedium() => TextStyle(
    color: AppColors.text_primary_light,
    fontWeight: FontWeight.bold,
  );
  static TextStyle? myAppLightThemeBodyMedium() => TextStyle(
    color: AppColors.text_secondary_dark,
    fontSize: 12,
    // fontSize: appData.textSize,
  );
}

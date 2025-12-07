// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class AppTypography {
  static final isDark = false;
  static const int default_font_size_type = 1;

  static const String default_font_family = 'iran_sansx_fn';
  static const String iran_sansx_fn = 'iran_sansx_fn';
  static const String iran_yekan_fn = 'iran_yekan_fn';
  static const String iran_sansx = 'iran_sansx';
  static const String iran_yekan = 'iran_yekan';
  static const String kalameh_fn = 'kalameh_fn';
  static const String sahel_fn = 'sahel_fn';
  static const String vazir_fn = 'vazir_fn';
  static const String kalameh = 'kalameh';
  static const String tahrir = 'tahrir';
  static const String sahel = 'sahel';
  static const String vazir = 'vazir';
  static const String peyda = 'peyda';

  //*** */ primary text color
  static TextStyle headline1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 24),
      fontWeight: FontWeight.w900,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 20),
      fontWeight: FontWeight.w800,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 18),
      fontWeight: FontWeight.w700,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline4(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 16),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline5(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle headline6(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  //*** */ primary text color
  static TextStyle body0(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 48),
      fontWeight: FontWeight.w700,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 16),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 12),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  //*** */ secondary text color
  static TextStyle subtitle1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 12),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle caption(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 12),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle overline(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 10),
      fontWeight: FontWeight.normal,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle button(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.w600,
      color: isDark
          ? AppColors.text_primary_dark
          : AppColors.text_primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static double _responsiveSize(BuildContext context, double baseSize) {
    final appData = Provider.of<AppData>(context);
    return baseSize + appData.textSize;
  }

  // ================================================================================================================================
  static TextStyle tunerCentDifference(BuildContext context) => body1(context);
  static TextStyle tunerCentUnitTitle(BuildContext context) =>
      subtitle1(context);
  static TextStyle tunerNoteOctave(BuildContext context) => body1(context);
  static TextStyle tunerNoteName(BuildContext context) => body0(context);
  static TextStyle tunerHertzUnitTitle(BuildContext context) =>
      subtitle1(context);
  static TextStyle tunerNearNoteFrequency(BuildContext context) =>
      body1(context);
  static TextStyle tunerSetBaseFrequency(BuildContext context) =>
      subtitle1(context);
  static TextStyle tunerA4Frequency(BuildContext context) => body1(context);
  static TextStyle tunerDetectedFrequency(BuildContext context) =>
      body1(context);

  // static TextStyle tunerCentDifference(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_20,
  //   fontWeight: FontWeight.w500,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerCentUnitTitle(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_16,
  //   fontWeight: FontWeight.w300,
  //   color: isDark
  //       ? AppColors.text_secondary_dark
  //       : AppColors.text_secondary_light,
  // );
  // static TextStyle tunerNoteOctave(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_24,
  //   fontWeight: FontWeight.bold,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerNoteName(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_48,
  //   fontWeight: FontWeight.bold,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerNearNoteFrequency(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_20,
  //   fontWeight: FontWeight.w500,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerHertzUnitTitle(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_16,
  //   fontWeight: FontWeight.w300,
  //   color: isDark
  //       ? AppColors.text_secondary_dark
  //       : AppColors.text_secondary_light,
  // );
  // static TextStyle tunerDetectedFrequency(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_24,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerA4Frequency(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_16,
  //   fontWeight: FontWeight.w700,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // static TextStyle tunerSetBaseFrequency(BuildContext context) => TextStyle(
  //   fontSize: AppSpacing.space_16,
  //   color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  // );
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle routerPageNotFound = TextStyle();
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle appDrawerApplicationFullname(BuildContext context) =>
      headline4(context);
  static TextStyle appDrawerApplicationEmail(BuildContext context) =>
      subtitle2(context);
  // static TextStyle appDrawerSwitchAcountItem(BuildContext context)=> body1(context);
  // static TextStyle appDrawerHeaderItemPart(BuildContext context)=> body2(context);
  static TextStyle appDrawerItemTitle(BuildContext context) => body2(context);
  static TextStyle appDrawerItemsubtitle(BuildContext context) =>
      subtitle2(context);

  static TextStyle aboutUsAppBarTitle(BuildContext context) =>
      headline3(context);
  static TextStyle aboutUsTitle(BuildContext context) => headline2(context);
  static TextStyle aboutUsBody(BuildContext context) => body2(context);

  static TextStyle settingsAppBarTitle(BuildContext context) =>
      headline3(context);
  static TextStyle settingsSectionTitle(BuildContext context) =>
      headline6(context);
  static TextStyle settingsItemTitle(BuildContext context) =>
      headline5(context);
  static TextStyle settingsItemSubtitle(BuildContext context) =>
      subtitle3(context);

  // // @formatter:off
  static TextStyle settingsItemContent(BuildContext context) => body3(context);
  static TextStyle settingsDropdownItem(BuildContext context) => body3(context);

  // // @formatter:on

  static TextStyle languageSwitchTileTitle(BuildContext context) =>
      settingsItemTitle(context);
  static TextStyle languageSwitchTileSubtitle(BuildContext context) =>
      settingsItemSubtitle(context);

  static TextStyle musicPlayerAudioWidgetDurationTime(BuildContext context) =>
      body3(context);
  static TextStyle musicPlayerAudioWidgetPositionTime(BuildContext context) =>
      body3(context);
  static TextStyle musicPlayerPlayingAudioFile(BuildContext context) =>
      body3(context);

  static TextStyle musicPlayerNotPlayingAudioFile(BuildContext context) =>
      body3(context);

  static TextStyle musicPlayerAudioItemDurationTime(BuildContext context) =>
      subtitle3(context);

  static TextStyle musicPlayerAudioItemAddress(BuildContext context) =>
      subtitle3(context);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================

  static TextStyle blogCardTitle(BuildContext context) =>
      TextStyle(fontSize: AppSpacing.space_12);
  static TextStyle blogCardTime(BuildContext context) =>
      TextStyle(fontSize: AppSpacing.space_10, color: Colors.grey);
  // static TextStyle blogCarouselErrorInLoading(BuildContext context) =>
  //     headline1(context);
  static TextStyle blogCarouselErrorInLoading(BuildContext context) =>
      TextStyle(
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
      );
  static TextStyle blogCarouselTitle(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle blogCarouselDate(BuildContext context) => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
    fontSize: 10,
  );

  static TextStyle bottomNavSnackBar(BuildContext context) => TextStyle();
  static TextStyle headerSectionTitle(BuildContext context) => TextStyle();
  static TextStyle headerSectionViewAllLink(BuildContext context) =>
      TextStyle();

  static TextStyle noFileFoundMessage(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_20,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle sectionTitleTitle(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_18,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.w900,
  );

  static TextStyle sectionTitleViewAllLink(BuildContext context) => TextStyle(
    color: isDark ? AppColors.primary_dark : AppColors.primary_light,
  );

  static TextStyle homeApplicationTitle(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_18,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
    fontWeight: FontWeight.w700,
  );

  static TextStyle articlesErrorInLoading(BuildContext context) => TextStyle();
  static TextStyle articlesReleaseDate(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_10,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle articlesTitle(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: AppSpacing.space_12,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );
  static TextStyle articlesBrief(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_10,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle articlesDetailPageErrorInSendingComment(
    BuildContext context,
  ) => TextStyle();
  static TextStyle articlesDetailPageLoadMoreComments(BuildContext context) =>
      TextStyle();
  static TextStyle articlesDetailPageCommentsListTitle(BuildContext context) =>
      TextStyle(fontSize: AppSpacing.space_18, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageCommentsListEmptyTitle(
    BuildContext context,
  ) => TextStyle(fontSize: AppSpacing.space_16, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageSendStarPoint(BuildContext context) =>
      TextStyle();
  static TextStyle articlesDetailPageWriteComment(BuildContext context) =>
      TextStyle();
  static TextStyle articlesDetailPageSendCommentButton(BuildContext context) =>
      TextStyle();
  static TextStyle articlesDetailPageSimilarArticlesTitle(
    BuildContext context,
  ) => TextStyle(fontSize: AppSpacing.space_18, fontWeight: FontWeight.bold);
  static TextStyle articlesDetailPageSimilarArticlesItemTitle(
    BuildContext context,
  ) => TextStyle();
  static TextStyle articlesDetailPageSimilarArticlesItemSubtitle(
    BuildContext context,
  ) => TextStyle();
  static TextStyle articlesDetailPageArticlesTitle(BuildContext context) =>
      TextStyle(
        fontSize: AppSpacing.space_18,
        fontWeight: FontWeight.bold,
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
      );
  static TextStyle articlesDetailPageArticleCommentsListTitle(
    BuildContext context,
  ) => TextStyle();
  static TextStyle articlesDetailPageArticleCommentsListSubtitle(
    BuildContext context,
  ) => TextStyle();
  static TextStyle articlesDetailPageArticleCommentsListDate(
    BuildContext context,
  ) => TextStyle(
    fontSize: AppSpacing.space_12,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle articlesDetailPageArticleCommentsListReleaseDate(
    BuildContext context,
  ) => TextStyle(
    fontSize: AppSpacing.space_14,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );
  static TextStyle articlesDetailPageArticlesAuthorsName(
    BuildContext context,
  ) => TextStyle(
    fontSize: AppSpacing.space_14,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle musicPlayerNotGrantedPermissionSnackBar(
    BuildContext context,
  ) => TextStyle();
  static TextStyle musicPlayerErrorInLoadingSnackBar(BuildContext context) =>
      TextStyle();
  static TextStyle musicPlayerAudioFileNotFound(BuildContext context) =>
      TextStyle();

  static TextStyle metronomeAppBar(BuildContext context) => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeBPM(BuildContext context) => TextStyle(
    fontSize: AppSpacing.space_24,
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeTiming(BuildContext context) => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeVolume(BuildContext context) => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeLaunchButton(BuildContext context) => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomePlayPauseButton(BuildContext context) => TextStyle(
    color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light,
  );

  static TextStyle metronomeStopButton(BuildContext context) => TextStyle(
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  static TextStyle voiceRecorderNotGrantedPermissionSnackBar(
    BuildContext context,
  ) => caption(context);
  static TextStyle voiceRecorderFilename(BuildContext context) =>
      headline6(context);
  static TextStyle voiceRecorderDate(BuildContext context) => caption(context);
  static TextStyle voiceRecorderDeleteFileSnackBar(BuildContext context) =>
      caption(context);
  static TextStyle voiceRecorderRestoreFileSnackBar(BuildContext context) =>
      caption(context);
  static TextStyle voiceRecorderDeleteFileDialogueTitle(BuildContext context) =>
      headline5(context);
  static TextStyle voiceRecorderDeleteFileDialogueContent(
    BuildContext context,
  ) => body1(context);
  static TextStyle voiceRecorderDeleteFileDialogueCancelButton(
    BuildContext context,
  ) => body2(context);
  static TextStyle voiceRecorderDeleteFileDialogueConfirmButton(
    BuildContext context,
  ) => body2(context);
  static TextStyle voiceRecorderDeleteFileMessageSnackBar(
    BuildContext context,
  ) => caption(context);
  static TextStyle voiceRecorderRenameFileDialogueTitle(BuildContext context) =>
      headline5(context);
  static TextStyle voiceRecorderRenameFileDialogueCancelButton(
    BuildContext context,
  ) => body2(context);
  static TextStyle voiceRecorderRenameFileDialogueConfirmButton(
    BuildContext context,
  ) => body1(context);
  static TextStyle voiceRecorderRenameFileMessageSnackBar(
    BuildContext context,
  ) => caption(context);
  static TextStyle voiceRecorderRenameFileErrorMessageSnackBar(
    BuildContext context,
  ) => caption(context);
  static TextStyle voiceRecorderRecordingTimer(BuildContext context) =>
      headline3(context);

  static TextStyle recordDetailsFilenameTitle(BuildContext context) =>
      TextStyle(
        fontSize: 18,
        color: isDark
            ? AppColors.text_primary_dark
            : AppColors.text_primary_light,
      );
  static TextStyle recordDetailsFilename(BuildContext context) =>
      TextStyle(fontSize: 22, fontWeight: FontWeight.bold);
  static TextStyle recordDetailsRecordDate(BuildContext context) =>
      TextStyle(fontSize: 20, color: Colors.grey);
  static TextStyle recordDetailsAppBar(BuildContext context) => TextStyle();
  static TextStyle recordDetailsRecordDateTitle(BuildContext context) =>
      TextStyle(fontSize: 18);
  static TextStyle recordDetailsRenameTitle(BuildContext context) =>
      TextStyle();
  static TextStyle recordDetailsRenameDialogueTitle(BuildContext context) =>
      TextStyle();
  static TextStyle recordDetailsRenameDialogueCancelButton(
    BuildContext context,
  ) => TextStyle();
  static TextStyle recordDetailsRenameDialogueConfirmButton(
    BuildContext context,
  ) => TextStyle();
  static TextStyle recordDetailsDeleteDialogueLabel(BuildContext context) =>
      TextStyle();
  static TextStyle recordDetailsDeleteDialogueTitle(BuildContext context) =>
      TextStyle();
  static TextStyle recordDetailsDeleteDialogueContent(BuildContext context) =>
      TextStyle();
  static TextStyle recordDetailsDeleteDialogueCancelButton(
    BuildContext context,
  ) => TextStyle();
  static TextStyle recordDetailsDeleteDialogueConfirmButton(
    BuildContext context,
  ) => TextStyle();

  static TextStyle? waveformPainterSeconds(BuildContext context) =>
      TextStyle(fontSize: 10, color: Colors.grey.shade500);

  static TextStyle? searchBarText(BuildContext context) =>
      TextStyle(fontSize: AppSpacing.space_12, fontWeight: FontWeight.w600);
  static TextStyle? searchBarHint(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w500,
    color: isDark
        ? AppColors.text_secondary_dark
        : AppColors.text_secondary_light,
  );

  // static TextStyle? myAppDarkThemeHeadlineMedium(BuildContext context) =>
  //     TextStyle(
  //       color: AppColors.text_primary_dark,
  //       fontWeight: FontWeight.bold,
  //     );
  // static TextStyle? myAppDarkThemeBodyMedium(BuildContext context) => TextStyle(
  //   color: AppColors.text_secondary_dark,
  //   fontSize: 12,
  //   // fontSize: appData.textSize,
  // );

  // static TextStyle? myAppLightThemeHeadlineMedium(BuildContext context) =>
  //     TextStyle(
  //       color: AppColors.text_primary_light,
  //       fontWeight: FontWeight.bold,
  //     );
  // static TextStyle? myAppLightThemeBodyMedium(BuildContext context) =>
  //     TextStyle(
  //       color: AppColors.text_secondary_dark,
  //       fontSize: 12,
  //       // fontSize: appData.textSize,
  //     );
}

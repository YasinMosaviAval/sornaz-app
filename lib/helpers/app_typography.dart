// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';

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

  static TextStyle body4(BuildContext context) {
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
  
  static TextStyle subtitle4(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 10),
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

  //*** */ primary color
  static TextStyle link1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 16),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.primary_dark
          : AppColors.primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle link2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 14),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.primary_dark
          : AppColors.primary_light,
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle link3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveSize(context, 12),
      fontWeight: FontWeight.w500,
      color: isDark
          ? AppColors.primary_dark
          : AppColors.primary_light,
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




  // Text(
  //   title,
  //   style: AppTypography.settingsSectionTitle(context).copyWith(
  //     color: textColor,
  //   ),
  // ),
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle routerPageNotFound = TextStyle();
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle appDrawerApplicationFullname(BuildContext context) => headline4(context);
  static TextStyle appDrawerApplicationEmail(BuildContext context) => subtitle2(context);
  // static TextStyle appDrawerSwitchAcountItem(BuildContext context)=> body1(context);
  // static TextStyle appDrawerHeaderItemPart(BuildContext context)=> body2(context);
  static TextStyle appDrawerItemTitle(BuildContext context) => body2(context);
  static TextStyle appDrawerItemsubtitle(BuildContext context) => subtitle2(context);
  // ================================================================================================================================
  static TextStyle tunerCentDifference(BuildContext context) => body1(context);
  static TextStyle tunerCentUnitTitle(BuildContext context) => subtitle1(context);
  static TextStyle tunerNoteOctave(BuildContext context) => body1(context);
  static TextStyle tunerNoteName(BuildContext context) => body0(context);
  static TextStyle tunerHertzUnitTitle(BuildContext context) => subtitle1(context);
  static TextStyle tunerNearNoteFrequency(BuildContext context) => body1(context);
  static TextStyle tunerSetBaseFrequency(BuildContext context) => subtitle1(context);
  static TextStyle tunerA4Frequency(BuildContext context) => body1(context);
  static TextStyle tunerDetectedFrequency(BuildContext context) => body1(context);
  // ================================================================================================================================
  static TextStyle aboutUsAppBarTitle(BuildContext context) => headline3(context);
  static TextStyle aboutUsTitle(BuildContext context) => headline6(context);
  static TextStyle aboutUsBody(BuildContext context) => body3(context);
  // ================================================================================================================================
  static TextStyle settingsAppBarTitle(BuildContext context) => headline3(context);
  static TextStyle settingsSectionTitle(BuildContext context) => headline6(context);
  static TextStyle settingsItemTitle(BuildContext context) => body2(context);
  static TextStyle settingsItemSubtitle(BuildContext context) => subtitle4(context);
  static TextStyle settingsItemContent(BuildContext context) => body3(context);
  static TextStyle settingsDropdownItem(BuildContext context) => body3(context);
  // ================================================================================================================================
  static TextStyle languageSwitchTileTitle(BuildContext context) => settingsItemTitle(context);
  static TextStyle languageSwitchTileSubtitle(BuildContext context) => settingsItemSubtitle(context);
  // ================================================================================================================================
  static TextStyle musicPlayerAudioWidgetDurationTime(BuildContext context) => body3(context);
  static TextStyle musicPlayerAudioWidgetPositionTime(BuildContext context) => body3(context);
  static TextStyle musicPlayerPlayingAudioFile(BuildContext context) => body3(context);
  static TextStyle musicPlayerNotPlayingAudioFile(BuildContext context) => body3(context);
  static TextStyle musicPlayerAudioItemDurationTime(BuildContext context) => subtitle3(context);
  static TextStyle musicPlayerAudioItemAddress(BuildContext context) => subtitle3(context);
  static TextStyle musicPlayerNotGrantedPermissionSnackBar(BuildContext context) => body3(context);
  static TextStyle musicPlayerErrorInLoadingSnackBar(BuildContext context) => body3(context);
  static TextStyle musicPlayerAudioFileNotFound(BuildContext context) => headline5(context);
  static TextStyle musicPlayerSpeedMenuItem(BuildContext context) => body2(context);
  static TextStyle musicPlayerAudioFolderListViewTitle(BuildContext context) => body3(context);
  static TextStyle musicPlayerBreadCrumb(BuildContext context) => body3(context);
  static TextStyle musicPlayerBreadCrumbSubDirectory(BuildContext context) => body3(context);
  static TextStyle musicPlayerBreadCrumbSlashes(BuildContext context) => subtitle3(context);
  static TextStyle musicPlayerFolderViewTitle(BuildContext context) => body3(context);
  static TextStyle musicPlayerFolderViewSubtitle(BuildContext context) => subtitle3(context);

  static TextStyle musicPlayerScanningFiles(BuildContext context) => headline3(context);
  static TextStyle musicPlayerScannedFiles(BuildContext context) => body1(context);
  static TextStyle musicPlayerCurrentFileAddress(BuildContext context) => subtitle3(context);
  // ================================================================================================================================
  static TextStyle metronomeAppBar(BuildContext context) => headline3(context);
  static TextStyle metronomeBPM(BuildContext context) => body1(context);
  static TextStyle metronomeTiming(BuildContext context) => body1(context);
  static TextStyle metronomeVolume(BuildContext context) => body1(context);
  static TextStyle metronomeLaunchButton(BuildContext context) => body2(context);
  static TextStyle metronomePlayPauseButton(BuildContext context) => body2(context);
  static TextStyle metronomeStopButton(BuildContext context) => subtitle2(context);
  // ================================================================================================================================
  static TextStyle voiceRecorderNotGrantedPermissionSnackBar(BuildContext context) => caption(context);
  static TextStyle voiceRecorderFilename(BuildContext context) => headline6(context);
  static TextStyle voiceRecorderDate(BuildContext context) => subtitle3(context);
  static TextStyle voiceRecorderDeleteFileSnackBar(BuildContext context) => caption(context);
  static TextStyle voiceRecorderRestoreFileSnackBar(BuildContext context) => caption(context);

  static TextStyle voiceRecorderDeleteFileDialogueTitle(BuildContext context) => headline4(context);
  static TextStyle voiceRecorderDeleteFileDialogueContent(BuildContext context) => body2(context);
  static TextStyle voiceRecorderDeleteFileDialogueCancelButton(BuildContext context) => subtitle3(context);
  static TextStyle voiceRecorderDeleteFileDialogueConfirmButton(BuildContext context) => body3(context);
  static TextStyle voiceRecorderDeleteFileMessageSnackBar(BuildContext context) => caption(context);
  
  static TextStyle voiceRecorderRenameFileDialogueTitle(BuildContext context) => headline4(context);
  static TextStyle voiceRecorderRenameFileDialogueCancelButton(BuildContext context) => subtitle3(context);
  static TextStyle voiceRecorderRenameFileDialogueConfirmButton(BuildContext context) => body3(context);
  static TextStyle voiceRecorderRenameFileDialogueTextField(BuildContext context) => body3(context);
  static TextStyle voiceRecorderRenameFileMessageSnackBar(BuildContext context) => caption(context);
  static TextStyle voiceRecorderRenameFileErrorMessageSnackBar(BuildContext context) => caption(context);
  static TextStyle voiceRecorderRecordingTimer(BuildContext context) => headline3(context);
  // ================================================================================================================================
  static TextStyle recordDetailsAppBar(BuildContext context) => headline3(context);
  static TextStyle recordDetailsFilename(BuildContext context) => body1(context);
  static TextStyle recordDetailsRecordDate(BuildContext context) => body1(context);
  static TextStyle recordDetailsFilenameTitle(BuildContext context) => subtitle1(context);
  static TextStyle recordDetailsRecordDateTitle(BuildContext context) =>subtitle1(context);
  
  static TextStyle recordDetailsRenameTitle(BuildContext context) => body2(context);
  static TextStyle recordDetailsRenameDialogueTitle(BuildContext context) => headline4(context);
  static TextStyle recordDetailsRenameDialogueCancelButton(BuildContext context) => subtitle3(context);
  static TextStyle recordDetailsRenameDialogueConfirmButton(BuildContext context) => body3(context);

  static TextStyle recordDetailsDeleteDialogueTitle(BuildContext context) => headline4(context);
  static TextStyle recordDetailsDeleteDialogueLabel(BuildContext context) => body2(context);
  static TextStyle recordDetailsDeleteDialogueContent(BuildContext context) => body2(context);
  static TextStyle recordDetailsDeleteDialogueCancelButton(BuildContext context) => subtitle3(context);
  static TextStyle recordDetailsDeleteDialogueConfirmButton(BuildContext context) => body3(context);
  // ================================================================================================================================
  static TextStyle articlesErrorInLoading(BuildContext context) => headline4(context);
  static TextStyle articlesReleaseDate(BuildContext context) => subtitle4(context);
  static TextStyle articlesTitle(BuildContext context) => headline6(context);
  static TextStyle articlesBrief(BuildContext context) => subtitle4(context);
  // ================================================================================================================================
  static TextStyle articlesDetailPageErrorInSendingComment(BuildContext context,) => headline4(context);
  static TextStyle articlesDetailPageLoadMoreComments(BuildContext context) => headline4(context);
  static TextStyle articlesDetailPageCommentsListTitle(BuildContext context) => headline3(context);
  static TextStyle articlesDetailPageCommentsListEmptyTitle(BuildContext context) => headline3(context);
  static TextStyle articlesDetailPageSendStarPoint(BuildContext context) => body3(context);
  static TextStyle articlesDetailPageWriteComment(BuildContext context) => body3(context);
  static TextStyle articlesDetailPageSendCommentButton(BuildContext context) => body3(context);
  static TextStyle articlesDetailPageSimilarArticlesTitle(BuildContext context) => headline3(context);
  static TextStyle articlesDetailPageSimilarArticlesItemTitle(BuildContext context) => body3(context);
  static TextStyle articlesDetailPageSimilarArticlesItemSubtitle(BuildContext context) => subtitle3(context);
  static TextStyle articlesDetailPageArticlesTitle(BuildContext context) => headline3(context);
  static TextStyle articlesDetailPageArticleCommentsListTitle(BuildContext context) => headline5(context);
  static TextStyle articlesDetailPageArticleCommentsListSubtitle(BuildContext context) => body3(context);
  static TextStyle articlesDetailPageArticleCommentsListDate(BuildContext context) => subtitle3(context);
  static TextStyle articlesDetailPageArticleCommentsListReleaseDate(BuildContext context) => subtitle2(context);
  static TextStyle articlesDetailPageArticlesAuthorsName(BuildContext context) => subtitle2(context);
  // ================================================================================================================================
  static TextStyle blogCardTitle(BuildContext context) => body3(context);
  static TextStyle blogCardTime(BuildContext context) => subtitle3(context);
  static TextStyle blogCarouselErrorInLoading(BuildContext context) => headline4(context);
  static TextStyle blogCarouselTitle(BuildContext context) => headline6(context);
  static TextStyle blogCarouselDate(BuildContext context) => subtitle3(context);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================


  static TextStyle bottomNavSnackBar(BuildContext context) => body3(context);

  static TextStyle headerSectionTitle(BuildContext context) => headline4(context);
  static TextStyle headerSectionViewAllLink(BuildContext context) => link3(context);

  static TextStyle noFileFoundMessage(BuildContext context) => headline4(context);

  static TextStyle sectionTitleTitle(BuildContext context) => headline3(context);
  static TextStyle sectionTitleViewAllLink(BuildContext context) => link3(context);

  static TextStyle homeApplicationTitle(BuildContext context) => headline3(context);
  
  
  static TextStyle waveformPainterSeconds(BuildContext context) => subtitle3(context);
  
  static TextStyle searchBarText(BuildContext context) => body1(context);
  static TextStyle searchBarHint(BuildContext context) => subtitle3(context);
}

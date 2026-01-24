// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' show FontSize, Style, Width;
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_colors.dart';

class AppTypography {
  // static final isDark = false;
  static const int default_font_size_type = 1;
  static const int default_font_weight_type = 1;

  static const String default_font_family = AppConstants.DEFAULT_FONT_FAMILY;
  static const String iran_sansx_fa = AppConstants.IRAN_SANSX_FA;
  static const String iran_sansx_en = AppConstants.IRAN_SANSX_EN;
  static const String iran_yekan_fa = AppConstants.IRAN_YEKAN_FA;
  static const String iran_yekan_en = AppConstants.IRAN_YEKAN_EN;
  static const String kalameh_fa = AppConstants.KALAMEH_FA;
  static const String kalameh_en = AppConstants.KALAMEH_EN;
  static const String sahel_fa = AppConstants.SAHEL_FA;
  static const String sahel_en = AppConstants.SAHEL_EN;
  static const String vazir_fa = AppConstants.VAZIR_FA;
  static const String vazir_en = AppConstants.VAZIR_EN;
  static const String peyda = AppConstants.PEYDA;

  //*** */ primary text color
  static TextStyle headline1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 24),
      fontWeight: _responsiveFontWeight(context, FontWeight.w700),
      color: AppColors.app_typography_headline1_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 20),
      fontWeight: _responsiveFontWeight(context, FontWeight.w700),
      color: AppColors.app_typography_headline2_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 18),
      fontWeight: _responsiveFontWeight(context, FontWeight.w700),
      color: AppColors.app_typography_headline3_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w600),
      color: AppColors.app_typography_headline4_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_headline5_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_headline6_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 48),
      fontWeight: _responsiveFontWeight(context, FontWeight.w700),
      color: AppColors.app_typography_body0_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body1_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body2_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body3_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 10),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body4_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  //*** */ primary text color
  static TextStyle body_reverse0(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 48),
      fontWeight: _responsiveFontWeight(context, FontWeight.w700),
      color: AppColors.app_typography_body_reverse0_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body_reverse1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body_reverse1_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body_reverse2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body_reverse2_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body_reverse3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body_reverse3_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle body_reverse4(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 10),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_body_reverse4_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle1_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle2_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle3_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 10),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle4_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  //*** */ secondary text color
  static TextStyle subtitle_reverse1(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle_reverse1_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle_reverse2(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle_reverse2_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static TextStyle subtitle_reverse3(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle_reverse3_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }
  
  static TextStyle subtitle_reverse4(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    return TextStyle(
      fontFamily: appData.fontFamily,
      fontSize: _responsiveFontSize(context, 10),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_subtitle_reverse4_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 16),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_link1_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_link2_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w500),
      color: AppColors.app_typography_link3_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 12),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_caption_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 10),
      fontWeight: _responsiveFontWeight(context, FontWeight.w400),
      color: AppColors.app_typography_overline_text_color(isDark: isDark),
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
      fontSize: _responsiveFontSize(context, 14),
      fontWeight: _responsiveFontWeight(context, FontWeight.w600),
      color: AppColors.app_typography_button_text_color(isDark: isDark),
      letterSpacing: -0.01,
      fontStyle: FontStyle.normal,
      textBaseline: TextBaseline.alphabetic,
      overflow: TextOverflow.visible,
    );
  }

  static double _responsiveFontSize(BuildContext context, double baseSize) {
    final appData = Provider.of<AppData>(context);
    return baseSize + appData.fontSize;
  }

  static FontWeight _responsiveFontWeight(
    BuildContext context,
    FontWeight baseWeight,
  ) {
    final appData = Provider.of<AppData>(context, listen: false);

    final base = baseWeight.index * 100 + 100; 
    // w400.index = 3 → 400

    final adjusted = base + (appData.fontWeight * 100);

    final clamped = adjusted.clamp(100, 900);

    return FontWeight.values[(clamped ~/ 100) - 1];
  }

  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle routerPageNotFound = TextStyle();
  // ================================================================================================================================
  // ================================================================================================================================
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
  // ================================================================================================================================
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
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle aboutUsAppBarTitle(BuildContext context) => headline3(context);
  static TextStyle aboutUsTitle(BuildContext context) => headline6(context);
  static TextStyle aboutUsBody(BuildContext context) => body3(context);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle settingsAppBarTitle(BuildContext context) => headline3(context);
  static TextStyle settingsSectionTitle(BuildContext context) => headline6(context);
  static TextStyle settingsItemTitle(BuildContext context) => body2(context);
  static TextStyle settingsItemSubtitle(BuildContext context) => subtitle4(context);
  static TextStyle settingsItemContent(BuildContext context) => body3(context);
  static TextStyle settingsDropdownItem(BuildContext context) => body3(context);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle languageSwitchTileTitle(BuildContext context) => settingsItemTitle(context);
  static TextStyle languageSwitchTileSubtitle(BuildContext context) => settingsItemSubtitle(context);
  // ================================================================================================================================
  // ================================================================================================================================
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
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle metronomeAppBar(BuildContext context) => headline3(context);
  static TextStyle metronomeBPM(BuildContext context) => body1(context);
  static TextStyle metronomeTiming(BuildContext context) => body1(context);
  static TextStyle metronomeVolume(BuildContext context) => body1(context);
  static TextStyle metronomeLaunchButton(BuildContext context) => body2(context);
  static TextStyle metronomePlayPauseButton(BuildContext context) => body2(context);
  static TextStyle metronomeStopButton(BuildContext context) => subtitle2(context);
  // ================================================================================================================================
  // ================================================================================================================================
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
  static TextStyle voiceRecorderRecordingTimer(BuildContext context) => body0(context).copyWith(fontWeight: _responsiveFontWeight(context, FontWeight.w300));
  // ================================================================================================================================
  // ================================================================================================================================
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
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle RecordingsListAppBarTitle(BuildContext context) => headline3(context);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle articlesErrorInLoading(BuildContext context) => headline4(context);
  static TextStyle articlesReleaseDate(BuildContext context) => subtitle4(context);
  static TextStyle articlesTitle(BuildContext context) => headline6(context);
  static TextStyle articlesBrief(BuildContext context) => subtitle4(context);
  // ================================================================================================================================
  // ================================================================================================================================
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
  // ================================================================================================================================
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



  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle settingsSwitchTileItemTitle(BuildContext context, Color effectiveTitleColor) => AppTypography.settingsItemTitle(context).copyWith(color: effectiveTitleColor);
  static TextStyle settingsSwitchTileItemSubtitle(BuildContext context, Color effectiveSubtitleColor) => AppTypography.settingsItemSubtitle(context).copyWith(color: effectiveSubtitleColor);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle settingsSectionHeaderTitle(BuildContext context, Color textColor) => AppTypography.settingsSectionTitle(context).copyWith(color: textColor);
  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================
  static TextStyle sornazAppBarTitle(BuildContext context, Color textColor) => AppTypography.headline3(context).copyWith(color: textColor);

  // ================================================================================================================================
  // ================================================================================================================================
  // ================================================================================================================================

  static Style articleContentHtmlA({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_a(isDark: isDark), textDecoration: TextDecoration.underline, fontWeight: _responsiveFontWeight(context, FontWeight.w400));
  static Style articleContentHtmlP({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_p(isDark: isDark), fontWeight: _responsiveFontWeight(context, FontWeight.w400));
  static Style articleContentHtmlH1({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h1(isDark: isDark), fontSize: FontSize(20), fontWeight: _responsiveFontWeight(context, FontWeight.w700));
  static Style articleContentHtmlH2({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h2(isDark: isDark), fontSize: FontSize(18), fontWeight: _responsiveFontWeight(context, FontWeight.w700));
  static Style articleContentHtmlH3({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h3(isDark: isDark), fontSize: FontSize(16), fontWeight: _responsiveFontWeight(context, FontWeight.w700));
  static Style articleContentHtmlH4({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h4(isDark: isDark), fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w600));
  static Style articleContentHtmlH5({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h5(isDark: isDark), fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w600));
  static Style articleContentHtmlH6({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_h6(isDark: isDark), fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w600));
  static Style articleContentHtmlEm({required BuildContext context, required bool isDark}) => Style(fontStyle: FontStyle.italic, fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w400));
  static Style articleContentHtmlImg({required BuildContext context, required bool isDark}) => Style(width: Width(300), fontWeight: _responsiveFontWeight(context, FontWeight.w400));
  static Style articleContentHtmlBody({required BuildContext context, required bool isDark}) => Style(color: AppColors.article_content_html_body(isDark: isDark), fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w400));
  static Style articleContentHtmlStrong({required BuildContext context, required bool isDark}) => Style(fontSize: FontSize(14), fontWeight: _responsiveFontWeight(context, FontWeight.w700));


  static TextStyle articlesListSelectedCategory(BuildContext context) => AppTypography.body_reverse2(context);
  static TextStyle articlesListUnselectedCategory(BuildContext context) => AppTypography.body2(context);


  static TextStyle articleDetailsPageAppBar(BuildContext context) => AppTypography.headline3(context);


  static TextStyle timeSignatureDropDownItemLabel(BuildContext context) => AppTypography.body1(context);
  static TextStyle timeSignatureSelectedDivisionNumber(BuildContext context) => AppTypography.body1(context);
  static TextStyle timeSignatureUnelectedDivisionNumber(BuildContext context) => AppTypography.subtitle1(context);


  static TextStyle metronomePageDropDownItem(BuildContext context) => AppTypography.body2(context);
  static TextStyle metronomeLabeledSlider(BuildContext context) => AppTypography.body2(context);


  static TextStyle metronomeBpmHeaderNumber(BuildContext context) => AppTypography.body0(context);
  static TextStyle metronomeBpmHeaderUnit(BuildContext context) => AppTypography.subtitle3(context);
  static TextStyle metronomeBpmHeaderName(BuildContext context) => AppTypography.subtitle1(context);


  static TextStyle musicPlayerAudioControlsSpeed(BuildContext context) => AppTypography.body1(context);


  static TextStyle musicPlayerFolderListViewSwitchText(BuildContext context) => AppTypography.body2(context);


  static TextStyle songInformationLabel(BuildContext context) => AppTypography.body1(context);
  static TextStyle songInformationValue(BuildContext context) => AppTypography.body1(context);


  static TextStyle pianoKeyboardWhiteKeyLabel(BuildContext context) => AppTypography.body3(context);
  static TextStyle pianoKeyboardWhiteKeyFrequency(BuildContext context) => AppTypography.body4(context);
  static TextStyle pianoKeyboardNotWhiteKeyLable(BuildContext context, double fontSize) => AppTypography.subtitle3(context).copyWith(fontSize: fontSize);


  static TextStyle voiceRecorderBookmarkTextButton(BuildContext context, bool isDark) => AppTypography.body3(context).copyWith(color: AppColors.voice_recorder_bookmark_text_color(isDark: isDark));


  static TextStyle voiceRecorderAppWaveformPainterTimeText(BuildContext context) => AppTypography.body4(context);
  static TextStyle voiceRecorderConfirmDelete(BuildContext context, bool isDark) => AppTypography.body2(context).copyWith(color: AppColors.voice_recorder_recordings_list_page_dialog_confirm_delete_text_color(isDark: isDark));
  static TextStyle recordingListMultiItemSelected(BuildContext context) => AppTypography.body2(context);
  static TextStyle recordingListDialogTitle(BuildContext context) => AppTypography.headline3(context);
  static TextStyle recordingListDialogContent(BuildContext context) => AppTypography.body1(context);
  static TextStyle recordingListDiscardDialog(BuildContext context) => AppTypography.subtitle3(context);
  static TextStyle recordingsListRenameSaveText(BuildContext context, bool isDark) =>AppTypography.body2(context).copyWith(color: AppColors.voice_recorder_recordings_list_page_rename_save_text_color(isDark: isDark), fontWeight: _responsiveFontWeight(context, FontWeight.w600));






}

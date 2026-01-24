import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Players/providers/folder_navigator_provider.dart';

class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final nav = context.watch<FolderNavigatorProvider>();

    // final parts = nav.breadcrumbParts;
    final bool canGoBack = nav.pathHistory.length > 1;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16, vertical: AppSpacing.space_8),
      color: AppColors.music_player_breadcrumb_background_color(isDark: isDark),
      child: Row(
        children: [
          if (canGoBack)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: AppColors.music_player_breadcrumb_back_icon_color(isDark: isDark)
              ),
              onPressed: () => nav.goBackReal(),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(AppConstants.FOLDER_IMAGE),
                  SizedBox(width: AppSpacing.space_8),
                  Text(
                    nav.rootDir?.path.split("/").last ?? AppStrings.memory.translate(context),
                    style: AppTypography.musicPlayerBreadCrumb(context)
                  ),
                  for (var part in nav.breadcrumbParts)
                    Row(
                      children: [
                        Text(" / ", style: AppTypography.musicPlayerBreadCrumbSlashes(context)),
                        Text(part, style: AppTypography.musicPlayerBreadCrumbSubDirectory(context)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/folder_navigator_provider.dart';

class BreadcrumbWidget extends StatelessWidget {
  const BreadcrumbWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final nav = context.watch<FolderNavigatorProvider>();
    final parts = nav.breadcrumbParts;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.space_16, vertical: AppSpacing.space_8),
      color: isDark? AppColors.background_dark : AppColors.background_light,
      child: Row(
        children: [
          if (parts.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? AppColors.text_primary_dark : AppColors.text_primary_light
              ),
              onPressed: () => nav.goBack(),
            ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text("📁 "),
                  SizedBox(width: AppSpacing.space_8),
                  Text(
                    nav.rootDir!.path.split("/").last,
                    style: AppTypography.musicPlayerBreadCrumb(context)
                  ),
                  for (var p in parts)
                    Row(
                      children: [
                        Text(" / ", style: AppTypography.musicPlayerBreadCrumbSlashes(context)),
                        Text(p, style: AppTypography.musicPlayerBreadCrumbSubDirectory(context)),
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

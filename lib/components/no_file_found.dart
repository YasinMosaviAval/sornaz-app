import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';

class NoFilesFoundWidget extends StatelessWidget {
  const NoFilesFoundWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<AppData>(context).isDark;

    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: AppSpacing.space_20,
          color: isDark
              ? AppColors.text_primary_dark
              : AppColors.text_primary_light,
        ),
      ),
    );
  }
}

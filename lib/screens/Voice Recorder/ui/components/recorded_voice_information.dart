import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';

class RecordedVoiceInformationWidget extends StatelessWidget {
  const RecordedVoiceInformationWidget({
    super.key,
    required this.fileName,
    required this.jalaliDate,
    required this.isDark,
  });

  final String fileName;
  final String jalaliDate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.filename_title.translate(context),
          style: AppTypography.recordDetailsFilenameTitle(context),
        ),
        const SizedBox(height: AppSpacing.space_8),
        Text(fileName, style: AppTypography.recordDetailsFilename(context)),
        const SizedBox(height: AppSpacing.space_16),
        Text(
          AppStrings.record_date_title.translate(context),
          style: AppTypography.recordDetailsRecordDateTitle(context),
        ),
        const SizedBox(height: AppSpacing.space_8),
        Text(jalaliDate, style: AppTypography.recordDetailsRecordDate(context)),
      ],
    );
  }
}

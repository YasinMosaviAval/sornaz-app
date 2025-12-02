import 'package:flutter/material.dart';
import 'package:sornaz/helpers/app_typography.dart';

class NoFilesFoundWidget extends StatelessWidget {
  const NoFilesFoundWidget({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message, style: AppTypography.noFileFoundMessage),
    );
  }
}

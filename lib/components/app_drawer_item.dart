import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_navigation.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AppDrawerItem extends StatelessWidget {
  const AppDrawerItem({
    required this.icon,
    required this.text,
    required this.link,
    this.messageColor = Colors.white,
    this.message = '',
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget link;
  final Color messageColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final bool isDark = appData.isDark;
    return ListTile(
      leading: Icon(icon),
      iconColor: isDark
          ? AppColors.text_secondary_dark
          : AppColors.text_secondary_light,
      title: Text(text, style: AppTypography.appDrawerItemTitle(context)),

      trailing: message == ''
          ? SizedBox()
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space_8,
              ),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message,
                style: AppTypography.appDrawerItemsubtitle(context),
              ),
            ),
      onTap: () => navigateWithFade(context, link),
    );
  }
}

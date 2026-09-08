import 'package:sornaz/components/app_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AppDrawerItem extends StatelessWidget {
  const AppDrawerItem({
    required this.icon,
    required this.text,
    required this.link,
    this.message = '',
    super.key,
  });

  final IconData icon;
  final String text;
  final Widget link;
  final String message;

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final bool isDark = appData.isDark;
    return ListTile(
      minTileHeight: 44,
      leading: Icon(icon),
      iconColor: AppColors.app_drawer_item_icon_color(isDark: isDark),
      title: AppText(text, style: AppTypography.appDrawerItemTitle(context)),
      trailing: message == ''
          ? SizedBox()
          : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space_8,
              ),
              decoration: BoxDecoration(
                color: AppColors.app_drawer_item_message_box_decoration_color(
                  isDark: isDark,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                message,
                style: AppTypography.appDrawerItemsubtitle(context),
              ),
            ),
      onTap: () {
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(MaterialPageRoute(builder: (_) => link));
      },
    );
  }
}

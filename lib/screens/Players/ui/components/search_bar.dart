import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';

class SearchBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const SearchBarWidget({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.read<AudioPlayerProvider>();

    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      titleTextStyle: AppTypography.searchBarText(context),
      title: TextField(
        onChanged: provider.filter,
        decoration: InputDecoration(
          hintText: AppStrings.music_player_search_hint.translate(context),
          hintStyle: AppTypography.searchBarHint(context),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.music_player_search_bar_prefix_icon_color(isDark: isDark),
          ),
        ),
        cursorColor: AppColors.music_player_search_bar_cursor_color(isDark: isDark),
        style: AppTypography.searchBarText(context),
      ),
      backgroundColor: AppColors.music_player_search_bar_background_color(isDark: isDark),
      iconTheme: IconThemeData(color: AppColors.music_player_search_bar_icon_theme_color(isDark: isDark)),
    );
  }
}

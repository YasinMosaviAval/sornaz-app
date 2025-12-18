
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/audio/audio_player_provider.dart';
import 'package:sornaz/helpers/app_images.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';

class NowPlayingInfoTab extends StatelessWidget {
  const NowPlayingInfoTab({super.key});
  @override
  Widget build(BuildContext context) {
    // final appData = context.watch<AppData>();
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final audio = context.watch<AudioPlayerProvider>();

    if (audio.currentIndex == -1) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light
        ),
        child: Center(
          child: Text(
            AppStrings.song_information_no_song_playing.translate(context),
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ),
      );
    }

    final meta = audio.currentMetadata;
    final title = meta?.title ?? audio.currentAudio?.fileName.substring(0, audio.currentAudio?.fileName.lastIndexOf('.')) ?? AppStrings.unknown.translate(context);
    final artist = meta?.artist ?? AppStrings.unknown.translate(context);
    final album = meta?.album ?? AppStrings.unknown.translate(context);
    final genre = meta?.genre ?? AppStrings.unknown.translate(context);
    final year = meta?.year?.toString() ?? AppStrings.unknown.translate(context);
    final durationStr = meta?.duration?.toString().split('.').first ?? formatDuration(audio.duration);
    final bitrate = meta?.bitrate != null ? '${meta?.bitrate} ${AppStrings.bitrate_unit}' : AppStrings.unknown.translate(context);
    // final bitrate = AppStrings.unknown.translate(context);


    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.background_dark : AppColors.background_light
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.sizedBoxH24(),
            Center(
              child: meta?.artwork != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        meta!.artwork!,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                      ),
                    )
                  // : const Icon(Icons.music_note, size: 200),
                  : Image.asset(
                      isDark ? AppImages.logo_dark : AppImages.logo_light,
                      height: AppSpacing.space_200
                    ),
            ),
            AppSpacing.sizedBoxH24(),
            _info(AppStrings.song_information_title.translate(context), title, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_artists.translate(context), artist, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_album.translate(context), album, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_genre.translate(context), genre, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_year.translate(context), year, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_duration.translate(context), durationStr, AppStrings.unknown.translate(context)),
            _info(AppStrings.song_information_bitrate.translate(context), bitrate, AppStrings.unknown.translate(context)),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String? value, String localizationValue) {
    if (value == null || value.isEmpty || value == localizationValue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'lyrics.dart';
import 'package:sornaz/components/app_top_bar_direction.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_constants.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/screens/Players/providers/audio_player_provider.dart';

class NowPlayingInfoTab extends StatelessWidget {
  const NowPlayingInfoTab({super.key});
  @override
  Widget build(BuildContext context) {
    // final appData = context.watch<AppData>();
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final audio = context.watch<AudioPlayerProvider>();

    if (audio.currentAudio == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.music_player_song_information_background_color(
            isDark: isDark,
          ),
        ),
        child: Center(
          child: Text(
            AppStrings.song_information_no_song_playing.translate(context),
            style: AppTypography.musicPlayerNotPlayingAudioFile(context),
          ),
        ),
      );
    }

    final meta = audio.currentMetadata;
    final title = meta?.title?.isNotEmpty == true
        ? meta!.title!
        : audio.currentAudio!.fileName;
    final artist = meta?.artist ?? AppStrings.unknown.translate(context);
    final album = meta?.album ?? AppStrings.unknown.translate(context);
    final genre = meta?.genre ?? AppStrings.unknown.translate(context);
    final year =
        meta?.year?.toString() ?? AppStrings.unknown.translate(context);
    final bitrate = meta?.bitrate != null
        ? '${meta?.bitrate} ${AppConstants.BITRATE_UNIT}'
        : AppStrings.unknown.translate(context);
    // final bitrate = AppStrings.unknown.translate(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.music_player_song_information_background_color(
          isDark: isDark,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.sizedBoxH32(),
            Center(
              child: meta?.artwork != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        meta!.artwork!,
                        width: 260,
                        height: 260,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const DefaultSongCover(),
                      ),
                    )
                  // : const Icon(Icons.music_note, size: 200),
                  : const DefaultSongCover(),
            ),
            AppSpacing.sizedBoxH32(),
            _info(
              AppStrings.song_information_title.translate(context),
              title,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            _info(
              AppStrings.song_information_artists.translate(context),
              artist,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            _info(
              AppStrings.song_information_album.translate(context),
              album,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            _info(
              AppStrings.song_information_genre.translate(context),
              genre,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            _info(
              AppStrings.song_information_year.translate(context),
              year,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            _info(
              AppStrings.song_information_bitrate.translate(context),
              bitrate,
              AppStrings.unknown.translate(context),
              isDark,
              context,
            ),
            for (final entry in <String, String>{
              'path': audio.currentAudio!.file.path,
              ...?meta?.details,
            }.entries)
              if (![
                'title',
                'artist',
                'album',
                'genre',
                'year',
                'durationMs',
                'duration',
                'filename',
                'folder',
                'bitrate',
              ].contains(entry.key))
                _info(
                  socialText(
                    context,
                    const {
                          'filename': 'نام فایل',
                          'folder': 'پوشه',
                          'path': 'مسیر فایل',
                          'albumArtist': 'هنرمند آلبوم',
                          'author': 'پدیدآورنده',
                          'composer': 'آهنگساز',
                          'writer': 'نویسنده',
                          'date': 'تاریخ انتشار',
                          'track': 'شماره آهنگ',
                          'disc': 'شماره دیسک',
                          'compilation': 'آلبوم مجموعه',
                          'mime': 'نوع فایل',
                          'codec': 'کدک',
                          'sampleRate': 'نرخ نمونه‌برداری (Hz)',
                          'channels': 'تعداد کانال‌ها',
                          'bitsPerSample': 'عمق بیت',
                          'tracks': 'تعداد جریان‌ها',
                          'fileSize': 'حجم فایل (بایت)',
                          'modified': 'آخرین تغییر',
                        }[entry.key] ??
                        entry.key,
                    const {
                          'filename': 'File name',
                          'folder': 'Folder',
                          'path': 'File path',
                          'albumArtist': 'Album artist',
                          'sampleRate': 'Sample rate (Hz)',
                          'bitsPerSample': 'Bit depth',
                          'fileSize': 'File size (bytes)',
                          'modified': 'Last modified',
                        }[entry.key] ??
                        entry.key,
                  ),
                  entry.value,
                  '',
                  isDark,
                  context,
                ),
          ],
        ),
      ),
    );
  }

  Widget _info(
    String label,
    String? value,
    String localizationValue,
    bool isDark,
    BuildContext context,
  ) {
    if (value == null || value.isEmpty || value == localizationValue)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DefaultSongCover extends StatelessWidget {
  const DefaultSongCover({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 260,
    height: 260,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Icon(
      Icons.album,
      size: 140,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class SongDetailsPage extends StatelessWidget {
  const SongDetailsPage({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppTopBarDirection(
        child: AppBar(
          title: Text(socialText(context, 'اطلاعات ترانه', 'Song details')),
          bottom: TabBar(
            tabs: [
              Tab(text: socialText(context, 'متن', 'Lyrics')),
              Tab(text: socialText(context, 'اطلاعات', 'Information')),
            ],
          ),
        ),
      ),
      body: TabBarView(
        children: [const SongLyricsTab(), const NowPlayingInfoTab()],
      ),
    ),
  );
}

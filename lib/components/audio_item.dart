import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/components/audio_file_actions.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/provider/audio_player_provider.dart';
import 'package:sornaz/components/marquee_text.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/helpers/app_typography.dart';

class AudioItem extends StatelessWidget {
  final AudioFile audio;
  final bool isPlaying;
  final int index;

  const AudioItem({
    super.key, 
    required this.audio,
    required this.isPlaying,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.read<AudioPlayerProvider>();
    final file = provider.filteredFiles[index];

    return Container(
      key: ValueKey(file.file.path),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.8,
          color: isDark ? AppColors.border_dark : AppColors.border_light,
        ),
        color: isPlaying
            ? isDark
                  ? AppColors.clicked_dark
                  : AppColors.clicked_light
            : Colors.transparent,
      ),
      child: GestureDetector(
        onLongPress: () => showFileOptions(context, audio),
        // onLongPress: () => _showFileOptions(context, file, index),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.space_24,
            vertical: AppSpacing.space_2,
          ),
          leading: Icon(
            isPlaying ? Icons.pause_circle_filled :  Icons.play_circle_filled,
            color: isPlaying
                ? (isDark ? AppColors.text_primary_dark : AppColors.text_primary_light)
                : (isDark ? AppColors.text_secondary_dark : AppColors.text_secondary_light),
            size: AppSpacing.space_32,
          ),
          minTileHeight: AppSpacing.space_24,
          title: isPlaying
              ? MarqueeText(
                text: audio.fileName.substring(0, audio.fileName.lastIndexOf('.')), 
                textStyle: AppTypography.musicPlayerPlayingAudioFile(context)
              )
              : Text(
                  audio.fileName.substring(0, audio.fileName.lastIndexOf('.')),
                  style: AppTypography.musicPlayerNotPlayingAudioFile(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.space_4),
              Row(
                children: [
                  Text(
                    formatDuration(audio.duration),
                    style: AppTypography.musicPlayerAudioItemDurationTime(context),
                  ),
                  SizedBox(width: AppSpacing.space_16),
                  Expanded(
                    child: Text(
                      audio.folderName.substring(1),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textDirection: TextDirection.ltr,
                      style: AppTypography.musicPlayerAudioItemAddress(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => provider.play(index),
        ),
      ),
    );
  }
}

/*
void _showFileOptions(BuildContext context, AudioFile file, int index) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text("تغییر نام"),
            onTap: () {
              Navigator.pop(context);
              _renameFile(context, file);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text("حذف"),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(context, file, index);
            },
          ),
        ],
      );
    },
  );
}

void _confirmDelete(BuildContext context, AudioFile file, int index) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("حذف فایل"),
      content: Text("می‌خوای فقط از لیست حذف بشه یا از حافظه هم پاک بشه؟"),
      actions: [
        TextButton(
          child: Text("انصراف"),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text("فقط از لیست"),
          onPressed: () {
            Provider.of<AudioPlayerProvider>(context, listen: false)
                .removeFromList(file);

            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text("حذف از حافظه"),
          onPressed: () {
            Provider.of<AudioPlayerProvider>(context, listen: false)
                .deleteFromDevice(file);

            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

void _renameFile(BuildContext context, AudioFile file) {
  TextEditingController controller =
      TextEditingController(text: file.fileName);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("تغییر نام فایل"),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(hintText: "نام     جدید"),
      ),
      actions: [
        TextButton(
          child: Text("انصراف"),
          onPressed: () => Navigator.pop(context),
        ),
        TextButton(
          child: Text("ذخیره"),
          onPressed: () {
            Provider.of<AudioPlayerProvider>(context, listen: false)
                .renameFile(file, controller.text.trim());

            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
*/
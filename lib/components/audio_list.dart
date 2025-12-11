import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/components/audio_file_actions.dart';
import 'package:sornaz/components/audio_item.dart';
import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_strings.dart';
import 'package:sornaz/helpers/app_translations.dart';
import 'package:sornaz/helpers/app_typography.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class AudioList extends StatelessWidget {
  const AudioList({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;
    final provider = context.watch<AudioPlayerProvider>();

    if (provider.isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
        child: Center(child: CircularProgressIndicator()
        )
      );
    }
    
    if (provider.filteredFiles.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
        child: Center(
          child: Text(
            AppStrings.audio_file_not_found.translate(context), 
            style: AppTypography.musicPlayerAudioFileNotFound(context)
          )
        ),
      );
    }

    return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.background_dark : AppColors.background_light,
        ),
      child: ListView.builder(
        itemCount: provider.filteredFiles.length,
        itemBuilder: (context, index) {
          final audio = provider.filteredFiles[index];
          return GestureDetector(
            key: ValueKey(audio.file.path),
            onLongPress: () => showFileOptions(context, audio),
            // onLongPress: () => _showFileOptions(context, audio, index),
            child: AudioItem(
              audio: audio,
              isPlaying: provider.currentIndex == index,
              index: index,
            ),
          );
        }
      ),
    );
  }
}

/*
void _showFileOptions(BuildContext context, AudioFile file, int index) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('تغییر نام'),
              onTap: () {
                Navigator.pop(ctx); // close bottom sheet
                _showRenameDialog(context, file);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('حذف'),
              onTap: () {
                Navigator.pop(ctx); // close bottom sheet
                _showDeleteConfirm(context, file);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showRenameDialog(BuildContext context, AudioFile file) {
  final controller = TextEditingController(text: file.fileName.split('.').first);

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('تغییر نام فایل'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'نام جدید (بدون پسوند)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('انصراف'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final success = Provider.of<AudioPlayerProvider>(context, listen: false).renameFile(file, newName);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(await success ? 'تغییر نام با موفقیت انجام شد' : 'خطا در تغییر نام — احتمالاً فایل مقصد وجود دارد'),
                ),
              );
            },
            child: Text('ذخیره'),
          ),
        ],
      );
    },
  );
}

void _showDeleteConfirm(BuildContext context, AudioFile file) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text('حذف فایل'),
        content: Text('می‌خوای این فایل فقط از لیست حذف بشه یا از حافظه دستگاه هم پاک بشه؟'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('انصراف'),
          ),
          TextButton(
            onPressed: () {
              // فقط از لیست حذف کن
              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
              final removed = provider.removeFromList(file);
              Navigator.of(context).pop(); // بستن دیالوگ
              Navigator.of(context).pop(); // بستن bottom sheet (اگر باز مانده)

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(removed ? 'فایل از لیست حذف شد' : 'حذف از لیست انجام نشد')),
              );
            },
            child: Text('فقط از لیست'),
          ),
          TextButton(
            onPressed: () async {
              final success = Provider.of<AudioPlayerProvider>(context, listen: false).deleteFromDevice(file);

              Navigator.of(context).pop(); // بستن دیالوگ
              Navigator.of(context).pop(); // بستن bottom sheet (اگر باز مانده)

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(await success ? 'فایل از حافظه حذف شد' : 'خطا در حذف فایل')),
              );
            },
            child: Text('حذف از حافظه'),
          ),
        ],
      );
    },
  );
}
*/
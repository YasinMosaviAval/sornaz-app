import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/classes/audio_file.dart';
import 'package:sornaz/provider/audio_player_provider.dart';


void showFileOptions(BuildContext context, AudioFile file) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetCtx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("تغییر نام"),
            onTap: () {
              Navigator.pop(sheetCtx); // بستن bottom sheet
              showRenameDialog(context, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text("حذف"),
            onTap: () {
              Navigator.pop(sheetCtx); // بستن bottom sheet
              showDeleteConfirm(context, file);
            },
          ),
        ],
      );
    },
  );
}


void showRenameDialog(BuildContext context, AudioFile file) {
  final controller = TextEditingController(
    text: file.fileName.split('.').first,
  );

  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text("تغییر نام فایل"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "نام جدید (بدون پسوند)"),
        ),
        actions: [
          TextButton(
            child: const Text("انصراف"),
            onPressed: () => Navigator.pop(dialogCtx),
          ),
          TextButton(
            child: const Text("ذخیره"),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

              // ❗️ ابتدا دیالوگ را ببند
              Navigator.pop(dialogCtx);

              // ❗️ سپس async را در microtask انجام بده تا context مشکلی نداشته باشد
              Future.microtask(() async {
                final success = await provider.renameFile(
                  file,
                  "$newName.${file.fileName.split('.').last}", // حفظ پسوند
                );

                // ❗️ چک mounted برای امنیت
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "نام فایل تغییر کرد"
                          : "خطا در تغییر نام (ممکن است فایل مشابه وجود داشته باشد)",
                    ),
                  ),
                );
              });
            },
          ),
        ],
      );
    },
  );
}


void showDeleteConfirm(BuildContext context, AudioFile file) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return AlertDialog(
        title: const Text("حذف فایل"),
        content: const Text("حذف فقط از لیست یا حذف کامل از حافظه؟"),
        actions: [

          TextButton(
            child: const Text("انصراف"),
            onPressed: () => Navigator.pop(dialogCtx),
          ),

          TextButton(
            child: const Text("حذف از لیست"),
            onPressed: () {
              Navigator.pop(dialogCtx);

              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);
              final removed = provider.removeFromList(file);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        removed ? "از لیست حذف شد" : "خطا در حذف از لیست"),
                  ),
                );
              }
            },
          ),

          TextButton(
            child: const Text("حذف از حافظه"),
            onPressed: () {
              final provider = Provider.of<AudioPlayerProvider>(context, listen: false);

              Navigator.pop(dialogCtx);

              Future.microtask(() async {
                final success = await provider.deleteFromDevice(file);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        success ? "فایل از حافظه حذف شد" : "خطا در حذف فایل"),
                  ),
                );
              });
            },
          ),
        ],
      );
    },
  );
}

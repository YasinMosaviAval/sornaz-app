// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:sornaz/components/waveform_widget.dart';
// import 'package:sornaz/helpers/app_colors.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:sornaz/helpers/app_locale_provider.dart';
import 'package:sornaz/helpers/app_spacing.dart';
import 'package:sornaz/helpers/app_typography.dart';

class RecordDetailsPage extends StatefulWidget {
  final File file;
  final Function(String) onRename;
  final Function() onDelete;
  final String jalaliDate;

  const RecordDetailsPage({
    super.key,
    required this.file,
    required this.onRename,
    required this.onDelete,
    required this.jalaliDate,
  });

  @override
  State<RecordDetailsPage> createState() => _RecordDetailsPageState();
}

class _RecordDetailsPageState extends State<RecordDetailsPage> {
  late Future<List<int>> waveformFuture;
  late Future<Duration> durationFuture;

  double zoom = 1.0;

  @override
  void initState() {
    super.initState();
    waveformFuture = _loadWaveform(widget.file);
    durationFuture = _getAudioDuration(widget.file.path);
  }

  Future<List<int>> _loadWaveform(File file) async {
    final tmp = File("${file.path}.waveform");
    final stream = JustWaveform.extract(audioInFile: file, waveOutFile: tmp);
    final last = await stream.last;
    return last.waveform?.data ?? <int>[];
  }

  Future<Duration> _getAudioDuration(String path) async {
    final player = AudioPlayer();
    await player.setSource(DeviceFileSource(path));
    final duration = await player.getDuration() ?? Duration.zero;
    await player.dispose();
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.file.path.split('/').last.replaceAll(".m4a", "");
    final appData = Provider.of<AppData>(context);
    final isDark = appData.isDark;

    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    // final theme = Theme.of(context);
    final bool isEnglish = localeProvider.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text("جزئیات ضبط", style: AppTypography.recordDetailsAppBar()),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.space_16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordedVoiceInformationWidget(
                fileName: fileName,
                jalaliDate: widget.jalaliDate,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              const Divider(),

              Expanded(
                child: FutureBuilder<List<int>>(
                  future: waveformFuture,
                  builder: (context, waveformSnap) {
                    if (!waveformSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return FutureBuilder<Duration>(
                      future: durationFuture,
                      builder: (context, durationSnap) {
                        if (!durationSnap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return WaveformPlayerView(
                          samples: waveformSnap.data!,
                          duration: durationSnap.data!,
                          filePath: widget.file.path,
                          color: isDark ? Colors.white : Colors.blue,
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RenameButtonWidget(
                    controller: TextEditingController(text: fileName),
                    onRename: widget.onRename,
                  ),
                  const SizedBox(width: AppSpacing.space_16),
                  DeleteButtonWidget(
                    onDelete: widget.onDelete,
                    file: widget.file,
                    onUndoRestore: (restoredFile, bytes) async {
                      await restoredFile.writeAsBytes(bytes);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveformViewer extends StatelessWidget {
  final List<int> waveformDataPairs; // min/max pairs
  final Color color;
  final double zoom;

  const WaveformViewer({
    super.key,
    required this.waveformDataPairs,
    required this.color,
    this.zoom = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // number of pixels represented in data
    final pixelCount = waveformDataPairs.length ~/ 2;
    // choose a base pixel width and multiply by zoom
    final basePixelWidth = 1.0;
    final totalWidth = (pixelCount * basePixelWidth) * zoom;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: CustomPaint(
        size: Size(totalWidth.clamp(200.0, double.infinity), double.infinity),
        painter: _WaveformPainter(pairs: waveformDataPairs, color: color),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<int> pairs;
  final Color color;

  _WaveformPainter({required this.pairs, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (pairs.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final pixelCount = pairs.length ~/ 2;
    // horizontal spacing
    final dx = size.width / (pixelCount == 0 ? 1 : pixelCount);

    // samples in just_waveform are PCM sample min/max pairs
    // normalise by typical 16-bit range (32768)
    const normaliser = 32768.0;

    for (int i = 0; i < pixelCount; i++) {
      final minVal = pairs[i * 2];
      final maxVal = pairs[i * 2 + 1];

      // normalize to [-1,1]
      final minNorm = minVal / normaliser;
      final maxNorm = maxVal / normaliser;

      // convert to y coordinates
      final yTop = midY - (maxNorm * midY);
      final yBottom = midY - (minNorm * midY);

      final x = i * dx + dx / 2; // center the vertical line in the pixel slot

      canvas.drawLine(Offset(x, yTop), Offset(x, yBottom), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.pairs != pairs || oldDelegate.color != color;
  }
}

/* ---------- UI small components (kept same as yours) ---------- */

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
      children: [
        Text("نام فایل:", style: AppTypography.recordDetailsFilenameTitle()),
        const SizedBox(height: AppSpacing.space_8),
        Text(fileName, style: AppTypography.recordDetailsFilename()),
        const SizedBox(height: AppSpacing.space_16),
        Text("تاریخ ضبط:", style: AppTypography.recordDetailsRecordDateTitle()),
        const SizedBox(height: AppSpacing.space_8),
        Text(jalaliDate, style: AppTypography.recordDetailsRecordDate()),
      ],
    );
  }
}

class RenameButtonWidget extends StatelessWidget {
  const RenameButtonWidget({
    super.key,
    required this.controller,
    required this.onRename,
  });

  final TextEditingController controller;
  final Function(String) onRename;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: Text(
          "تغییر نام",
          style: AppTypography.recordDetailsRenameTitle(),
        ),
        onPressed: () async {
          final newName = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                "تغییر نام فایل",
                style: AppTypography.recordDetailsRenameDialogueTitle(),
              ),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: "نام جدید",
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "انصراف",
                    style:
                        AppTypography.recordDetailsRenameDialogueCancelButton(),
                  ),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: Text(
                    "ذخیره",
                    style:
                        AppTypography.recordDetailsRenameDialogueConfirmButton(),
                  ),
                ),
              ],
            ),
          );

          if (newName != null && newName.isNotEmpty) {
            onRename(newName);
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}

class DeleteButtonWidget extends StatelessWidget {
  const DeleteButtonWidget({
    super.key,
    required this.onDelete,
    required this.file,
    required this.onUndoRestore,
  });

  final Function() onDelete;
  final File file;
  final Future<void> Function(File restoredFile, List<int> bytes) onUndoRestore;

  @override
  Widget build(BuildContext context) {
    final fileName = file.path.split('/').last;
    return Expanded(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.delete_forever),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        label: Text(
          "حذف",
          style: AppTypography.recordDetailsDeleteDialogueLabel(),
        ),
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                "تأیید حذف",
                style: AppTypography.recordDetailsDeleteDialogueTitle(),
              ),
              content: Text(
                "آیا از حذف فایل «$fileName» مطمئن هستی؟",
                style: AppTypography.recordDetailsDeleteDialogueContent(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    "خیر",
                    style:
                        AppTypography.recordDetailsDeleteDialogueCancelButton(),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    "بله، حذف شود",
                    style:
                        AppTypography.recordDetailsDeleteDialogueConfirmButton(),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            final bytes = await file.readAsBytes();
            final originalPath = file.path;

            await onDelete();

            Navigator.pop(context, {
              "deleted": true,
              "bytes": bytes,
              "path": originalPath,
            });
          }
        },
      ),
    );
  }
}

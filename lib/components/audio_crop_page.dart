import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'app_top_bar_direction.dart';
import '../screens/Social/social_widgets.dart';

const audioCropChannel = MethodChannel('sornaz/audio_crop');

Future<String> commitAudioCrop(
  String staged,
  String source,
  bool replace,
) async => (await audioCropChannel.invokeMethod<String>('commit', {
  'staged': staged,
  'source': source,
  'replace': replace,
}))!;

class AudioCropPage extends StatefulWidget {
  const AudioCropPage({
    super.key,
    required this.source,
    required this.name,
    required this.onSave,
    this.previewPlayer,
  });
  final String source, name;
  final AudioPlayer? previewPlayer;
  final Future<void> Function(
    String staged,
    bool replace,
    Duration start,
    Duration end,
  )
  onSave;
  @override
  State<AudioCropPage> createState() => _AudioCropPageState();
}

class _AudioCropPageState extends State<AudioCropPage> {
  late final player = widget.previewPlayer ?? AudioPlayer();
  RangeValues range = const RangeValues(0, 1);
  double? length;
  bool busy = false;
  String? error;
  String label(String fa, String en) => socialText(context, fa, en);
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final duration = await player.setAudioSource(
        AudioSource.uri(
          widget.source.startsWith('content:')
              ? Uri.parse(widget.source)
              : Uri.file(widget.source),
        ),
      );
      if (!mounted) return;
      if (duration == null || duration.inMilliseconds <= 0)
        throw StateError('Invalid duration');
      setState(() {
        length = duration.inMilliseconds.toDouble();
        range = RangeValues(0, length!);
      });
    } catch (_) {
      if (mounted)
        setState(
          () => error = label('خواندن فایل ممکن نیست', 'Could not read audio'),
        );
    }
  }

  String time(double ms) =>
      '${(ms ~/ 60000).toString().padLeft(2, '0')}:${((ms ~/ 1000) % 60).toString().padLeft(2, '0')}.${((ms ~/ 10) % 100).toString().padLeft(2, '0')}';
  Future<void> editPoint(bool start) async {
    var input = ((start ? range.start : range.end) / 1000).toStringAsFixed(2);
    final value = await showDialog<double>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(label('زمان بر حسب ثانیه', 'Time in seconds')),
        content: TextFormField(
          initialValue: input,
          onChanged: (value) => input = value,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, double.tryParse(input)),
            child: Text(label('تأیید', 'OK')),
          ),
        ],
      ),
    );
    if (value == null || !mounted || !value.isFinite) return;
    final ms = value * 1000;
    if (ms < 0 || ms > length! || (start ? ms >= range.end : ms <= range.start))
      return;
    setState(
      () => range = start
          ? RangeValues(ms, range.end)
          : RangeValues(range.start, ms),
    );
  }

  Future<void> save(bool replace) async {
    setState(() {
      busy = true;
      error = null;
    });
    String? staged;
    try {
      await player.pause();
      final start = Duration(milliseconds: range.start.round());
      final end = Duration(milliseconds: range.end.round());
      staged = await audioCropChannel.invokeMethod<String>('render', {
        'source': widget.source,
        'start': start.inMilliseconds,
        'end': end.inMilliseconds,
      });
      if (staged == null) throw StateError('Missing output');
      await widget.onSave(staged, replace, start, end);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted)
        setState(
          () => error = label(
            'ذخیره انجام نشد؛ دسترسی به فایل و فضای دستگاه را بررسی کنید.',
            'Could not save. Check file access and available storage.',
          ),
        );
    } finally {
      if (staged != null) {
        try {
          final file = File(staged);
          if (await file.exists()) await file.delete();
        } catch (_) {
          /* Cache cleanup must not hide a successful save. */
        }
      }
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      appBar: AppTopBarDirection(
        child: AppBar(title: Text(label('برش صدا', 'Crop audio'))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 24),
            if (length != null) ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: RangeSlider(
                  values: range,
                  max: length!,
                  onChanged: busy
                      ? null
                      : (v) {
                          if (v.end - v.start >= 100) setState(() => range = v);
                        },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: busy ? null : () => editPoint(true),
                    child: Text(
                      '${label('شروع', 'Start')}: ${time(range.start)}',
                    ),
                  ),
                  TextButton(
                    onPressed: busy ? null : () => editPoint(false),
                    child: Text('${label('پایان', 'End')}: ${time(range.end)}'),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () async {
                        await player.pause();
                        await player.setClip(
                          start: Duration(milliseconds: range.start.round()),
                          end: Duration(milliseconds: range.end.round()),
                        );
                        await player.seek(Duration.zero);
                        player.play().catchError((Object _) {});
                      },
                icon: const Icon(Icons.play_arrow_outlined),
                label: Text(
                  label('پیش‌شنوی بخش انتخاب‌شده', 'Preview selection'),
                ),
              ),
              Text(
                label(
                  'خروجی با فرمت M4A ذخیره می‌شود.',
                  'Audio is saved in M4A format.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: busy ? null : () => save(false),
                child: Text(
                  label('ذخیره به عنوان فایل جدید', 'Save as new file'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => save(true),
                child: Text(
                  label('جایگزینی فایل اصلی', 'Replace original file'),
                ),
              ),
            ] else if (error == null)
              const CircularProgressIndicator(),
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
  );
}

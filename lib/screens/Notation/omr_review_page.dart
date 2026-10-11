import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sornaz/screens/Social/media_picker.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';
import 'package:sornaz/helpers/app_data.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/services/omr/omr_melody.dart';
import 'package:sornaz/services/omr/printed_score_engine.dart';

class OmrReviewPage extends StatefulWidget {
  const OmrReviewPage({super.key, required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<OmrReviewPage> createState() => _OmrReviewPageState();
}

class _OmrReviewPageState extends State<OmrReviewPage> {
  final _title = TextEditingController();
  final _scroll = ScrollController();
  late Uint8List _imageBytes;
  List<OmrDraftNote>? _notes;
  String _clef = 'treble';
  int _numerator = 4;
  int _denominator = 4;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
  }

  Future<void> _cropImage() async {
    if (_busy) return;
    final cropped = await Navigator.push<PlatformFile>(context,
      MaterialPageRoute(builder: (_) => ImageCropPage(bytes: _imageBytes)));
    if (!mounted || cropped?.bytes == null) return;
    setState(() {
      _imageBytes = cropped!.bytes!;
      _notes = null;
      _error = null;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await compute(analyzePrintedScore, _imageBytes);
      final notes = OmrMelody.fromProbe(result);
      final staff = (result['staffs'] as List).single as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _clef = ['bass', 'treble'].contains(staff['clef'])
            ? staff['clef'] as String
            : 'treble';
        if (staff['clef'] == 'unknown') {
          _error = socialText(
            context,
            'کلید موسیقی نامشخص است؛ آن را دستی بررسی کنید.',
            'Clef is unknown. Check it manually.',
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is FormatException
          ? switch (error.message) {
              'Unsupported image' => socialText(context,
                'فرمت تصویر پشتیبانی نمی‌شود. PNG یا JPEG انتخاب کنید.',
                'Unsupported image format. Choose PNG or JPEG.'),
              'Image dimensions are too large' => socialText(context,
                'ابعاد تصویر بسیار بزرگ است. بخش نت را برش دهید.',
                'Image dimensions are too large. Crop to the score.'),
              'Exactly one staff is required.' => socialText(context,
                'یک حامل پنج‌خطیِ مستقل لازم است. تصویر را به یک ردیف نت برش دهید.',
                'One five-line staff is required. Crop to a single score row.'),
              'No noteheads found.' => socialText(context,
                'حامل پیدا شد اما سرنتی شناسایی نشد. تصویر واضح‌تر یا برش نزدیک‌تر را امتحان کنید.',
                'Staff found, but no noteheads detected. Try a clearer, closer crop.'),
              _ => socialText(context,
                'نت تصویر قابل تشخیص نیست. بخش نت را برش دهید و دوباره تلاش کنید.',
                'The score cannot be recognized. Crop to the score and retry.'),
            }
          : socialText(context,
              'پردازش تصویر انجام نشد. تصویر دیگری انتخاب کنید.',
              'Image processing failed. Try another image.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _confirm() {
    try {
      final score = OmrMelody.toImport(
        notes: _notes!,
        clef: _clef,
        numerator: _numerator,
        denominator: _denominator,
        title: _title.text.trim().isEmpty
            ? socialText(context, 'ملودی شناسایی‌شده', 'Scanned melody')
            : _title.text,
      );
      Navigator.pop(context, score);
    } on FormatException catch (error) {
      setState(
        () => _error = switch (error.message) {
          'Confirm every pitch and duration.' => socialText(
            context,
            'ارتفاع و کشش همهٔ نت‌ها را تأیید کنید.',
            'Confirm every pitch and duration.',
          ),
          _ => socialText(
            context,
            'کشش‌ها با ظرفیت میزان سازگار نیستند. کشش یا کسر میزان را اصلاح کنید.',
            'Durations do not fit the measures. Adjust them or the time signature.',
          ),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = _notes;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          socialText(context, 'بررسی نت‌های تصویر', 'Review scanned notes'),
        ),
      ),
      body: SafeArea(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(
                context.watch<AppData>().cornerRadius,
              ),
              child: Image.memory(
                _imageBytes,
                height: 210,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(socialText(context,
              'برای نتیجهٔ بهتر، اسکرین‌شات PNG یا JPEG را به یک حامل پنج‌خطیِ افقی با کلید سل یا فا برش دهید. نوشته‌ها و بخش‌های اضافی صفحه را حذف کنید.',
              'For better results, crop a PNG or JPEG screenshot to one horizontal five-line staff with a treble or bass clef. Remove surrounding screen content.')),
            Align(alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(onPressed: _cropImage,
                icon: const Icon(Icons.crop),
                label: Text(socialText(context, 'برش و بزرگ‌نمایی نت', 'Crop and zoom score')))),
            const SizedBox(height: 4),
            Text(
              socialText(
                context,
                'این تشخیص آزمایشی است. کشش هر نت را تعیین و ارتفاع و ترتیب همهٔ نت‌ها را بررسی کنید. علائم تغییر ارتفاع و سکوت‌ها به‌طور خودکار منتقل نمی‌شوند.',
                'Experimental recognition: set every duration and review all pitches and order. Accidentals and rests are not imported automatically.',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (notes == null && !_busy)
              FilledButton.icon(
                onPressed: _detect,
                icon: const Icon(Icons.auto_fix_high),
                label: Text(socialText(context, 'تشخیص نت‌ها', 'Detect notes')),
              ),
            if (notes != null) ...[
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: socialText(context, 'عنوان قطعه', 'Score title'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                      initialValue: _clef,
                      decoration: InputDecoration(
                        labelText: socialText(context, 'کلید', 'Clef'),
                      ),
                      items: [
                        for (final clef in ['treble', 'bass'])
                          DropdownMenuItem(
                            value: clef,
                            child: Text(
                              clef == 'treble'
                                  ? socialText(context, 'سل', 'Treble')
                                  : socialText(context, 'فا', 'Bass'),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _clef = v!;
                        for (final note in notes) {
                          if (!note.editedPitch && note.pitch != null) {
                            note.pitch = OmrMelody.pitchForStep(
                              _clef,
                              note.staffStep,
                            );
                          }
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: '$_numerator/$_denominator',
                      decoration: InputDecoration(
                        labelText: socialText(
                          context,
                          'کسر میزان',
                          'Time signature',
                        ),
                      ),
                      items: [
                        for (final time in ['2/4', '3/4', '4/4', '6/8'])
                          DropdownMenuItem(value: time, child: Text(time)),
                      ],
                      onChanged: (v) {
                        final parts = v!.split('/');
                        setState(() {
                          _numerator = int.parse(parts[0]);
                          _denominator = int.parse(parts[1]);
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < notes.length; index++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Text('${index + 1}'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            key: ValueKey(
                              'pitch-$index-${notes[index].hashCode}',
                            ),
                            initialValue: notes[index].pitch,
                            hint: Text(
                              socialText(context, 'ارتفاع؟', 'Pitch?'),
                            ),
                            items: [
                              for (var midi = 21; midi <= 108; midi++)
                                DropdownMenuItem(
                                  value: OmrMelody.midiPitch(midi),
                                  child: Text(OmrMelody.midiPitch(midi)!),
                                ),
                            ],
                            onChanged: (value) => setState(() {
                              notes[index].pitch = value;
                              notes[index].editedPitch = true;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
              SizedBox(
                width: 112,
                          child: DropdownButtonFormField<String>(
                  isExpanded: true,
                            key: ValueKey(
                              'duration-$index-${notes[index].hashCode}',
                            ),
                            initialValue: notes[index].duration,
                            hint: Text(socialText(context, 'کشش؟', 'Length?')),
                            items: [
                              for (final entry in const {
                                'w': '1',
                                'h': '1/2',
                                'q': '1/4',
                                '8': '1/8',
                                '16': '1/16',
                              }.entries)
                                DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => notes[index].duration = value),
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: socialText(
                            context,
                            'ویرایش ترتیب یا حذف',
                            'Reorder or delete',
                          ),
                          onSelected: (action) => setState(() {
                            if (action == 'delete') notes.removeAt(index);
                            if (action == 'up' && index > 0) {
                              final item = notes.removeAt(index);
                              notes.insert(index - 1, item);
                            }
                            if (action == 'down' && index < notes.length - 1) {
                              final item = notes.removeAt(index);
                              notes.insert(index + 1, item);
                            }
                          }),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'up',
                              child: Text(
                                socialText(context, 'بالاتر', 'Move up'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'down',
                              child: Text(
                                socialText(context, 'پایین‌تر', 'Move down'),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(socialText(context, 'حذف', 'Delete')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(
                      () => notes.add(OmrDraftNote(x: 0, pitch: null)),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(socialText(context, 'افزودن نت', 'Add note')),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _detect,
                    child: Text(
                      socialText(context, 'تشخیص دوباره', 'Detect again'),
                    ),
                  ),
                ],
              ),
              FilledButton(
                onPressed: notes.isEmpty ? null : _confirm,
                child: Text(
                  socialText(context, 'بررسی در ویرایشگر', 'Review in editor'),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

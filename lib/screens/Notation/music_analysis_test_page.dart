import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

import 'analysis_audio.dart';
import 'music_analysis_calibration.dart';
import 'music_analysis_ffi.dart';
import 'note_alignment.dart';

typedef AnalysisFilePicker = Future<PlatformFile?> Function(bool musicXml);
typedef AnalysisTestRunner =
    Future<CalibrationResult> Function(
      CalibrationCase input,
      AnalysisCancellation cancellation,
    );
typedef AnalysisXmlReader = Future<String> Function(String path);

Future<String> _readMusicXml(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw const FileSystemException('MusicXML file is missing.');
  }
  if (await file.length() > 8 * 1024 * 1024) {
    throw const FormatException('MusicXML exceeds the 8 MiB test limit.');
  }
  return file.readAsString();
}

Future<PlatformFile?> _pickAnalysisFile(bool musicXml) async {
  final result = await FilePicker.platform.pickFiles(
    // Android providers may register .musicxml under the MusicXML MIME type,
    // which the extension-only custom filter does not expose consistently.
    type: musicXml ? FileType.any : FileType.audio,
    withData: false,
  );
  return result?.files.single;
}

Future<CalibrationResult> _runAnalysis(
  CalibrationCase input,
  AnalysisCancellation cancellation,
) => MusicAnalysisCalibrationRunner(
  AnalysisAudioPreparer(PlatformAnalysisAudioDecoder()),
  MusicAnalysisFfi.open(),
).run(input, cancellation: cancellation);

/// Manual, offline diagnostic page; no educational grade is calculated.
class MusicAnalysisTestPage extends StatefulWidget {
  const MusicAnalysisTestPage({
    super.key,
    AnalysisFilePicker? picker,
    AnalysisTestRunner? runner,
    AnalysisXmlReader? xmlReader,
  }) : picker = picker ?? _pickAnalysisFile,
       runner = runner ?? _runAnalysis,
       xmlReader = xmlReader ?? _readMusicXml;

  final AnalysisFilePicker picker;
  final AnalysisTestRunner runner;
  final AnalysisXmlReader xmlReader;

  @override
  State<MusicAnalysisTestPage> createState() => _MusicAnalysisTestPageState();
}

class _MusicAnalysisTestPageState extends State<MusicAnalysisTestPage> {
  PlatformFile? _xml, _audio;
  CalibrationResult? _result;
  String? _error;
  bool _busy = false;
  AnalysisCancellation? _cancellation;

  @override
  void dispose() {
    _cancellation?.cancel();
    super.dispose();
  }

  Future<void> _pick(bool musicXml) async {
    try {
      final file = await widget.picker(musicXml);
      if (file == null || !mounted) return;
      if (musicXml &&
          !file.name.toLowerCase().endsWith('.musicxml') &&
          !file.name.toLowerCase().endsWith('.xml')) {
        setState(
          () => _error = socialText(
            context,
            'فایل با پسوند .musicxml یا .xml انتخاب کنید.',
            'Choose a .musicxml or .xml file.',
          ),
        );
        return;
      }
      setState(() {
        if (musicXml) {
          _xml = file;
        } else {
          _audio = file;
        }
        _result = null;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    }
  }

  Future<void> _analyze() async {
    final xml = _xml;
    final audio = _audio;
    if (xml == null || audio == null) {
      setState(
        () => _error = socialText(
          context,
          'هر دو فایل را انتخاب کنید.',
          'Select both files.',
        ),
      );
      return;
    }
    final token = AnalysisCancellation();
    _cancellation = token;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final xmlPath = xml.path;
      final audioPath = audio.path;
      if (xmlPath == null || audioPath == null) {
        throw const FormatException('Picker did not provide a local file.');
      }
      // MusicXML is text; cap only this read. Audio stays streamed by Phase 3.
      final musicXml = await widget.xmlReader(xmlPath);
      token.throwIfCancelled();
      final result = await widget.runner(
        CalibrationCase(
          id: 'manual_test',
          instrument: 'unspecified',
          source: AnalysisAudioSource.fromLocation(audioPath),
          musicXml: musicXml,
        ),
        token,
      );
      if (mounted && !token.isCancelled) setState(() => _result = result);
    } catch (error) {
      if (mounted && !token.isCancelled) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (identical(_cancellation, token)) _cancellation = null;
      if (mounted) setState(() => _busy = false);
    }
  }

  String _message(Object error) {
    if (error is AnalysisAudioException) {
      return switch (error.code) {
        AnalysisAudioErrorCode.missingFile => socialText(
          context,
          'فایل صوتی پیدا نشد.',
          'Audio file was not found.',
        ),
        AnalysisAudioErrorCode.unsupportedFormat => socialText(
          context,
          'فرمت صوتی پشتیبانی نمی‌شود.',
          'Audio format is unsupported.',
        ),
        AnalysisAudioErrorCode.cancelled => socialText(
          context,
          'تحلیل لغو شد.',
          'Analysis was cancelled.',
        ),
        _ => socialText(
          context,
          'آماده‌سازی صدا ناموفق بود.',
          'Audio preparation failed.',
        ),
      };
    }
    if (error is MusicAnalysisException) {
      return switch (error.code) {
        MusicAnalysisErrorCode.unsupportedPlatform ||
        MusicAnalysisErrorCode.libraryUnavailable ||
        MusicAnalysisErrorCode.missingSymbol ||
        MusicAnalysisErrorCode.abiMismatch => socialText(
          context,
          'موتور تحلیل روی این دستگاه در دسترس نیست.',
          'Analysis engine is unavailable on this device.',
        ),
        MusicAnalysisErrorCode.cancelled => socialText(
          context,
          'تحلیل لغو شد.',
          'Analysis was cancelled.',
        ),
        _ => socialText(
          context,
          'پردازش صوتی ناموفق بود.',
          'Audio analysis failed.',
        ),
      };
    }
    if (error is PlatformException) {
      return socialText(
        context,
        'انتخاب فایل ناموفق بود.',
        'File selection failed.',
      );
    }
    if (error is FileSystemException) {
      return socialText(
        context,
        'فایل انتخاب‌شده در دسترس نیست.',
        'Selected file is unavailable.',
      );
    }
    if (error is FormatException) {
      return socialText(
        context,
        'MusicXML نامعتبر یا پشتیبانی‌نشده است، یا فایل انتخابی بیش از حد بزرگ است.',
        'MusicXML is invalid or unsupported, or the selected file is too large.',
      );
    }
    if (error is UnsupportedError) {
      return socialText(
        context,
        'این نوع اجرای چندصدایی یا ساختار نت فعلاً پشتیبانی نمی‌شود.',
        'This polyphonic performance or score structure is not supported yet.',
      );
    }
    return socialText(context, 'تحلیل ناموفق بود.', 'Analysis failed.');
  }

  String _number(double? value, {int digits = 2}) =>
      value == null ? '—' : value.toStringAsFixed(digits);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = _result?.report;
    return SocialScaffold(
      title: socialText(
        context,
        'آزمایش تحلیل اجرا',
        'Performance analysis test',
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        children: [
          Text(
            socialText(
              context,
              'این صفحه فقط برای آزمایش است؛ نتایج نمره آموزشی نیستند.',
              'Diagnostic only; these results are not an educational grade.',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(true),
            icon: const Icon(Icons.description_outlined),
            label: Text(
              _xml?.name ??
                  socialText(context, 'انتخاب MusicXML', 'Choose MusicXML'),
            ),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(false),
            icon: const Icon(Icons.audio_file_outlined),
            label: Text(
              _audio?.name ??
                  socialText(context, 'انتخاب فایل صوتی', 'Choose audio file'),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _busy ? null : _analyze,
            icon: const Icon(Icons.analytics_outlined),
            label: Text(socialText(context, 'تحلیل', 'Analyze')),
          ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const Center(child: CircularProgressIndicator()),
            TextButton(
              onPressed: _cancellation?.cancel,
              child: Text(socialText(context, 'لغو', 'Cancel')),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (report != null) ...[
            const SizedBox(height: 16),
            Text(
              socialText(context, 'PerformanceReport', 'PerformanceReport'),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '${socialText(context, 'تمپوی تخمینی', 'Estimated tempo')}: ${_number(report.estimatedQuarterBpm)} BPM',
            ),
            Text(
              '${socialText(context, 'میانه اختلاف پیچ', 'Median pitch deviation')}: ${_number(report.medianAbsolutePitchCents)} cents',
            ),
            Text(
              '${socialText(context, 'میانه اختلاف شروع', 'Median onset deviation')}: ${_number(report.medianAbsoluteOnsetBeats)} beats',
            ),
            Text(
              '${socialText(context, 'میانه نسبت طول', 'Median duration ratio')}: ${_number(report.medianDurationRatio)}',
            ),
            Text(
              '${socialText(context, 'میانه RMS', 'Median RMS')}: ${_number(report.medianSoundStrengthRms, digits: 4)}',
            ),
            for (final mark in AlignmentMark.values)
              Text('${mark.name}: ${report.markCounts[mark] ?? 0}'),
            const Divider(),
            for (var i = 0; i < report.notes.length; i++) ...[
              Text(
                '${i + 1}. ${report.notes[i].mark.name}',
                style: theme.textTheme.titleSmall,
              ),
              Text(
                'reference: ${report.notes[i].alignment.reference?.id ?? '—'} '
                '(MIDI ${_number(report.notes[i].alignment.reference?.midiPitch)})  ·  '
                'performed MIDI: ${_number(report.notes[i].alignment.performed?.midiPitch)}',
              ),
              Text(
                'start: ${_number(report.notes[i].alignment.performed?.startSeconds)} s  ·  '
                'end: ${_number(report.notes[i].alignment.performed?.endSeconds)} s  ·  '
                'confidence: ${_number(report.notes[i].alignment.performed?.pitchConfidence)}',
              ),
              Text(
                'pitch: ${_number(report.notes[i].pitchCents)} cents  ·  onset: ${_number(report.notes[i].onsetBeatOffset)} beats  ·  duration: ${_number(report.notes[i].durationRatio)}',
              ),
              Text(
                'RMS: ${_number(report.notes[i].soundStrengthRms, digits: 4)}  ·  relative: ${_number(report.notes[i].relativeSoundStrength)}  ·  persistence: ${_number(report.notes[i].soundingDurationRatio)}',
              ),
              if (i < report.notes.length - 1) const Divider(height: 16),
            ],
          ],
        ],
      ),
    );
  }
}

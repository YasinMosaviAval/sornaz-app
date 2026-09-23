import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/audio_player_provider.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class SongLyricsTab extends StatelessWidget {
  const SongLyricsTab({super.key, this.notes = false});
  final bool notes;
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerProvider>();
    final track = audio.currentAudio;
    if (track == null) {
      return Center(
        child: Text(
          socialText(context, 'آهنگی انتخاب نشده است.', 'No track selected.'),
        ),
      );
    }
    return AudioLyricsEditor(
      key: ValueKey(track.file.path),
      path: track.file.path,
      notes: notes,
      initialTitle: withoutAudioExtension(
        audio.currentMetadata?.title?.trim().isNotEmpty == true
            ? audio.currentMetadata!.title!
            : track.fileName,
      ),
    );
  }
}

class AudioLyricsEditor extends StatefulWidget {
  const AudioLyricsEditor({
    super.key,
    required this.path,
    required this.initialTitle,
    this.notes = false,
  });
  final String path, initialTitle;
  final bool notes;
  @override
  State<AudioLyricsEditor> createState() => AudioLyricsEditorState();
}

class AudioLyricsEditorState extends State<AudioLyricsEditor> {
  final title = TextEditingController(), lyrics = TextEditingController();
  SharedPreferences? prefs;
  Future<void> pending = Future.value();
  bool loaded = false;
  String? error;
  String get storageKey =>
      '${widget.notes ? 'audio_notes' : 'music_lyrics'}_${widget.path}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      prefs = await SharedPreferences.getInstance();
      final raw = prefs!.getString(storageKey);
      final data = raw == null
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      title.text = withoutAudioExtension(
        data['title'] as String? ?? widget.initialTitle,
      );
      lyrics.text = data['lyrics'] as String? ?? '';
      setState(() => loaded = true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  void save(String _) {
    final key = storageKey;
    final data = jsonEncode({'title': title.text, 'lyrics': lyrics.text});
    pending = pending
        .then((_) async {
          final ok = await prefs!.setString(key, data);
          if (!ok) throw StateError('Unable to save lyrics');
          if (mounted && error != null) setState(() => error = null);
        })
        .catchError((Object e) {
          if (mounted) setState(() => error = e.toString());
        });
  }

  @override
  void dispose() {
    title.dispose();
    lyrics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !loaded
      ? Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Text(error!),
        )
      : ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (!widget.notes)
              TextField(
                controller: title,
                onChanged: save,
                decoration: InputDecoration(
                  labelText: socialText(context, 'عنوان ترانه', 'Song title'),
                ),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: lyrics,
              onChanged: save,
              minLines: 12,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: widget.notes
                    ? socialText(context, 'یادداشت ها', 'Notes')
                    : socialText(context, 'متن ترانه', 'Lyrics'),
                alignLabelWithHint: true,
              ),
            ),
            if (error != null)
              Text(
                socialText(
                  context,
                  'ذخیره متن انجام نشد. دوباره تلاش کنید.',
                  'Could not save lyrics. Please try again.',
                ),
              ),
          ],
        );
}

String withoutAudioExtension(String title) {
  const extensions = {
    '.mp3',
    '.wav',
    '.flac',
    '.aac',
    '.m4a',
    '.ogg',
    '.opus',
    '.wma',
    '.aiff',
    '.aif',
    '.amr',
    '.mp4',
    '.oga',
    '.alac',
  };
  return extensions.contains(path.extension(title).toLowerCase())
      ? path.withoutExtension(title)
      : title;
}

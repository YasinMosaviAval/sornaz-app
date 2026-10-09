import 'dart:io';
import 'package:sornaz/components/app_bar.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:provider/provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../metadata/metadata_service.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class EditSongMetadata extends StatefulWidget {
  const EditSongMetadata({super.key, required this.path});
  final String path;
  @override
  State<EditSongMetadata> createState() => _EditSongMetadataState();
}

class _EditSongMetadataState extends State<EditSongMetadata> {
  final fields = <String, TextEditingController>{};
  Metadata? original;
  Uint8List? cover;
  String coverMime = 'image/jpeg';
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      await MetadataService.ensureInitialized();
      final m = await MetadataGod.readMetadata(file: widget.path);
      if (!mounted) return;
      original = m;
      cover = m.picture?.data;
      coverMime = m.picture?.mimeType ?? coverMime;
      final values = <String, Object?>{
        'title': m.title,
        'artist': m.artist,
        'album': m.album,
        'albumArtist': m.albumArtist,
        'genre': m.genre,
        'year': m.year,
        'trackNumber': m.trackNumber,
        'trackTotal': m.trackTotal,
        'discNumber': m.discNumber,
        'discTotal': m.discTotal,
      };
      for (final e in values.entries) {
        fields[e.key] = TextEditingController(text: e.value?.toString() ?? '');
      }
      setState(() {});
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  Future<void> save() async {
    for (final key in [
      'year',
      'trackNumber',
      'trackTotal',
      'discNumber',
      'discTotal',
    ]) {
      final value = fields[key]!.text.trim();
      if (value.isNotEmpty &&
          (int.tryParse(value) == null || int.parse(value) < 0)) {
        setState(
          () => error = socialText(
            context,
            'مقادیر عددی را صحیح وارد کنید.',
            'Enter valid nonnegative numbers.',
          ),
        );
        return;
      }
    }
    setState(() {
      saving = true;
      error = null;
    });
    final player = context.read<AudioPlayerProvider>();
    try {
      if (player.currentAudio?.file.path == widget.path) await player.pause();
      String s(String k) => fields[k]!.text.trim();
      int? n(String k) => int.tryParse(s(k));
      await MetadataGod.writeMetadata(
        file: widget.path,
        metadata: Metadata(
          title: s('title'),
          artist: s('artist'),
          album: s('album'),
          albumArtist: s('albumArtist'),
          genre: s('genre'),
          year: n('year'),
          trackNumber: n('trackNumber'),
          trackTotal: n('trackTotal'),
          discNumber: n('discNumber'),
          discTotal: n('discTotal'),
          picture: cover == null
              ? null
              : Picture(mimeType: coverMime, data: cover!),
          durationMs: original!.durationMs,
          fileSize: original!.fileSize,
        ),
      );
      final updated = await player.extractMetadata(widget.path);
      for (final file in player.allFiles) {
        if (file.file.path == widget.path) file.metadata = updated;
      }
      if (player.currentAudio?.file.path == widget.path)
        await player.loadCurrentMetadata();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: SornazAppBar(
      title: socialText(
        context,
        'ویرایش اطلاعات آهنگ',
        'Edit song information',
      ),
    ),
    body: original == null
        ? Center(
            child: error == null
                ? const CircularProgressIndicator()
                : Text(error!),
          )
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  socialText(
                    context,
                    'مشخصات فنی مانند مدت، بیت‌ریت و کدک از خود فایل خوانده می‌شوند.',
                    'Technical properties such as duration, bitrate and codec are read from the file.',
                  ),
                ),
              ),
              if (cover != null)
                Image.memory(
                  cover!,
                  height: 180,
                  errorBuilder: (_, _, _) => const Icon(Icons.album),
                ),
              TextButton.icon(
                onPressed: saving
                    ? null
                    : () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['jpg', 'jpeg', 'png'],
                        );
                        final path = result?.files.single.path;
                        if (path == null) return;
                        final bytes = await File(path).readAsBytes();
                        if (mounted)
                          setState(() {
                            cover = bytes;
                            coverMime = path.toLowerCase().endsWith('.png')
                                ? 'image/png'
                                : 'image/jpeg';
                          });
                      },
                icon: const Icon(Icons.image),
                label: Text(socialText(context, 'تغییر کاور', 'Change cover')),
              ),
              for (final e in fields.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    enabled: !saving,
                    controller: e.value,
                    decoration: InputDecoration(
                      labelText: socialText(
                        context,
                        const {
                          'title': 'عنوان',
                          'artist': 'هنرمند',
                          'album': 'آلبوم',
                          'albumArtist': 'هنرمند آلبوم',
                          'genre': 'سبک',
                          'year': 'سال',
                          'trackNumber': 'شماره آهنگ',
                          'trackTotal': 'تعداد آهنگ‌ها',
                          'discNumber': 'شماره دیسک',
                          'discTotal': 'تعداد دیسک‌ها',
                        }[e.key]!,
                        const {
                          'title': 'Title',
                          'artist': 'Artist',
                          'album': 'Album',
                          'albumArtist': 'Album artist',
                          'genre': 'Genre',
                          'year': 'Year',
                          'trackNumber': 'Track number',
                          'trackTotal': 'Track total',
                          'discNumber': 'Disc number',
                          'discTotal': 'Disc total',
                        }[e.key]!,
                      ),
                    ),
                  ),
                ),
              if (error != null) Text(error!),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(socialText(context, 'ذخیره', 'Save')),
              ),
            ],
          ),
  );
}

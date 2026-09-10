import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sornaz/components/bottom_nav.dart';
import 'package:sornaz/screens/Social/social_widgets.dart';

class BrowserMusicPlayer extends StatefulWidget {
  const BrowserMusicPlayer({super.key});
  @override
  State<BrowserMusicPlayer> createState() => _BrowserMusicPlayerState();
}
class _BrowserMusicPlayerState extends State<BrowserMusicPlayer> {
  final player = AudioPlayer();
  final files = <PlatformFile>[];
  int selected = -1;
  Future<void> choose() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true, withData: true);
    if (mounted && result != null) setState(() => files.addAll(result.files.where((f) => f.bytes != null)));
  }
  Future<void> play(int index) async {
    try {
      if (selected != index) {
        await player.setAudioSource(AudioSource.uri(Uri.dataFromBytes(files[index].bytes!, mimeType: 'audio/${files[index].extension == 'mp3' ? 'mpeg' : files[index].extension ?? 'mpeg'}')));
        if (!mounted) return;
        setState(() => selected = index);
      }
      if (player.playing) { await player.pause(); }
      else { if (player.processingState == ProcessingState.completed) await player.seek(Duration.zero); unawaited(player.play()); }
    } catch (error) { if (mounted) socialError(context, error); }
  }
  @override
  void dispose() { player.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(socialText(context, 'پخش موسیقی', 'Music player'))),
    bottomNavigationBar: const BottomNavBarWidget(),
    body: Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(socialText(context,
        'مرورگر اجازه جست‌وجوی خودکار حافظه دستگاه را ندارد. فایل‌های صوتی را انتخاب کنید.',
        'Choose audio files to listen here. Browsers cannot scan device storage.'))),
      FilledButton.icon(onPressed: choose, icon: const Icon(Icons.audio_file),
        label: Text(socialText(context, 'انتخاب فایل صوتی', 'Choose audio files'))),
      Expanded(child: StreamBuilder<PlayerState>(stream: player.playerStateStream,
        builder: (context, _) => ListView.builder(itemCount: files.length,
          itemBuilder: (context, i) => ListTile(title: Text(files[i].name),
            leading: Icon(selected == i && player.playing ? Icons.pause : Icons.play_arrow),
            onTap: () => play(i))))),
      if (selected >= 0) StreamBuilder<Duration>(stream: player.positionStream,
        builder: (context, snapshot) => Slider(
          max: (player.duration?.inMilliseconds ?? 1).clamp(1, 1 << 40).toDouble(),
          value: (snapshot.data?.inMilliseconds ?? 0).clamp(0, player.duration?.inMilliseconds ?? 0).toDouble(),
          onChanged: (value) => player.seek(Duration(milliseconds: value.round())))),
    ]),
  );
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sornaz/helpers/app_functions.dart';
import 'package:sornaz/provider/audio_player_provider.dart';

class NowPlayingInfoTab extends StatelessWidget {
  const NowPlayingInfoTab({super.key});
  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioPlayerProvider>();

    if (audio.currentIndex == -1) {
      return const Center(
        child: Text(
          "هیچ آهنگی در حال پخش نیست",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final meta = audio.currentMetadata;
    final title = meta?.title ?? audio.currentAudio?.fileName.substring(0, audio.currentAudio?.fileName.lastIndexOf('.')) ?? 'نامشخص';
    final artist = meta?.artist ?? 'نامشخص';
    final album = meta?.album ?? 'نامشخص';
    final genre = meta?.genre ?? 'نامشخص';
    final year = meta?.year?.toString() ?? 'نامشخص';
    final durationStr = meta?.duration?.toString().split('.').first ?? formatDuration(audio.duration);
    final bitrate = meta?.bitrate != null ? '${meta?.bitrate} kbps' : 'نامشخص';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎵 کاور بزرگ
          Center(
            child: meta?.artwork != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      meta!.artwork!,
                      width: 260,
                      height: 260,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.music_note, size: 200),
          ),
          const SizedBox(height: 24),
          _info('عنوان', title),
          _info('هنرمند', artist),
          _info('آلبوم', album),
          _info('ژانر', genre),
          _info('سال', year),
          _info('مدت', durationStr),
          _info('Bitrate', bitrate),
        ],
      ),
    );
  }
  Widget _info(String label, String? value) {
    if (value == null || value.isEmpty || value == 'نامشخص') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
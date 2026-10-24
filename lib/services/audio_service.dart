import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'media_files.dart';

class AudioService {
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  Future<void> startRecording() async {
    await player.stop();
    if (!await recorder.hasPermission()) {
      throw StateError(
        'Microphone access is needed to record your story. Allow it in device settings.',
      );
    }
    await recorder.start(
      RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        numChannels: 1,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: await recordingPath(),
    );
  }

  Future<String?> stopRecording() async {
    final path = await recorder.stop();
    return path == null ? null : persistRecording(path);
  }

  Future<void> load(String source) => loadAudio(player, source);
  Future<void> dispose() async {
    await recorder.dispose();
    await player.dispose();
  }
}

/// Shared source resolution for recorded files, bundled stories and web recordings.
Future<void> loadAudio(AudioPlayer player, String source) async {
  if (source.startsWith('assets/')) {
    await player.setAsset(source);
  } else if (source.startsWith('data:') || source.startsWith('blob:')) {
    await player.setUrl(source);
  } else {
    await player.setFilePath(source);
  }
}

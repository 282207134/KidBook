import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../services/audio_service.dart';
import '../../services/media_files.dart';
import '../../widgets/common.dart';

enum RecordingStage { ready, recording, review }

class RecordingSheet extends StatefulWidget {
  const RecordingSheet({super.key, required this.pageNumber});
  final int pageNumber;
  @override
  State<RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<RecordingSheet>
    with SingleTickerProviderStateMixin {
  final audio = AudioService();
  late final wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();
  RecordingStage stage = RecordingStage.ready;
  Timer? timer;
  final watch = Stopwatch();
  Duration elapsed = Duration.zero;
  String? source, error;
  bool busy = false, saved = false;
  Future<void> _record() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await audio.player.stop();
      if (source != null) {
        await deleteRecording(source!);
        source = null;
      }
      await audio.startRecording();
      watch
        ..reset()
        ..start();
      elapsed = Duration.zero;
      timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() => elapsed = watch.elapsed);
      });
      if (mounted) setState(() => stage = RecordingStage.recording);
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => busy = true);
    try {
      watch.stop();
      timer?.cancel();
      elapsed = watch.elapsed;
      source = await audio.stopRecording();
      if (source == null || elapsed.inMilliseconds < 500) {
        if (source != null) {
          await deleteRecording(source!);
          source = null;
        }
        throw StateError(
          'That was a little short. Record at least a second of your story.',
        );
      }
      await audio.load(source!);
      if (mounted) setState(() => stage = RecordingStage.review);
    } catch (e) {
      if (mounted) {
        setState(() {
          stage = RecordingStage.ready;
          error = e.toString().replaceFirst('Bad state: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _listen() async {
    try {
      if (audio.player.playing) {
        await audio.player.pause();
      } else {
        if (audio.player.processingState == ProcessingState.completed) {
          await audio.player.seek(Duration.zero);
        }
        unawaited(
          audio.player.play().catchError((Object e) {
            if (mounted) {
              setState(
                () => error = 'Could not play this recording. Please retry.',
              );
            }
          }),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Could not play this recording. Please retry.');
      }
    }
  }

  void _save() {
    if (source == null || busy) return;
    saved = true;
    Navigator.pop(
      context,
      StoryPage(
        id: newId(),
        title: 'Page ${widget.pageNumber}',
        audio: source!,
        seconds: math.max(1, elapsed.inSeconds),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    watch.stop();
    wave.dispose();
    // Cancel any active recording before releasing the platform recorder.
    unawaited(() async {
      if (stage == RecordingStage.recording) await audio.recorder.cancel();
      await audio.dispose();
      if (!saved && source != null) await deleteRecording(source!);
    }());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
    decoration: const BoxDecoration(
      color: Palette.green,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  stage == RecordingStage.recording
                      ? 'Your voice, their adventure'
                      : stage == RecordingStage.review
                      ? 'A little story, ready to keep'
                      : 'Let’s tell a story',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close recording',
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          AnimatedBuilder(
            animation: wave,
            builder: (_, child) => SizedBox(
              height: 100,
              width: double.infinity,
              child: CustomPaint(
                painter: WavePainter(
                  color: Colors.white,
                  phase: stage == RecordingStage.recording
                      ? wave.value * math.pi * 2
                      : 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            clockTime(elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            stage == RecordingStage.recording
                ? 'Recording page ${widget.pageNumber}…'
                : stage == RecordingStage.review
                ? 'Listen before saving your page'
                : 'Each recording becomes a page.',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              SizedBox(
                width: 70,
                child: stage == RecordingStage.review
                    ? StreamBuilder<PlayerState>(
                        stream: audio.player.playerStateStream,
                        builder: (context, snapshot) => IconButton(
                          tooltip: 'Listen to recording',
                          onPressed: _listen,
                          icon: Icon(
                            audio.player.playing &&
                                    audio.player.processingState !=
                                        ProcessingState.completed
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                      )
                    : null,
              ),
              RoundButton(
                icon: stage == RecordingStage.recording
                    ? Icons.stop_rounded
                    : stage == RecordingStage.review
                    ? Icons.replay_rounded
                    : Icons.mic_none_rounded,
                label: stage == RecordingStage.recording
                    ? 'Stop recording'
                    : stage == RecordingStage.review
                    ? 'Record again'
                    : 'Start recording',
                color: Colors.white,
                foreground: Palette.navy,
                onPressed: busy
                    ? null
                    : stage == RecordingStage.recording
                    ? _stop
                    : _record,
              ),
              SizedBox(
                width: 70,
                child: stage == RecordingStage.review
                    ? TextButton(
                        onPressed: _save,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    ),
  );
}

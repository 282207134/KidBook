import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../../services/audio_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.books,
    this.backLabel = 'Library',
    this.title,
    this.initialPage = 0,
  });
  final List<Book> books;
  final String backLabel;
  final String? title;
  final int initialPage;
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final player = AudioPlayer();
  late final tracks = [
    for (final book in widget.books)
      for (final page in book.pages) (book: book, page: page),
  ];
  final subscriptions = <StreamSubscription>[];
  late int index = widget.initialPage.clamp(0, tracks.length - 1);
  Duration position = Duration.zero;
  bool loading = true, playing = false, repeat = false;
  double speed = 1;
  String? error;
  @override
  void initState() {
    super.initState();
    subscriptions.add(
      player.positionStream.listen((value) {
        if (mounted) setState(() => position = value);
      }),
    );
    subscriptions.add(
      player.playerStateStream.listen((state) {
        if (!mounted) return;
        setState(
          () => playing =
              state.playing &&
              state.processingState != ProcessingState.completed,
        );
        if (state.processingState == ProcessingState.completed && !loading) {
          if (index + 1 < tracks.length) {
            _load(index + 1, autoplay: true);
          } else if (repeat) {
            _load(0, autoplay: true);
          }
        }
      }),
    );
    _load(index);
  }

  Future<void> _load(int next, {bool autoplay = false}) async {
    setState(() {
      index = next;
      loading = true;
      error = null;
      position = Duration.zero;
    });
    try {
      await player.pause();
      await loadAudio(player, tracks[index].page.audio);
      if (!mounted) return;
      setState(() => loading = false);
      if (autoplay) unawaited(player.play());
    } catch (_) {
      if (mounted) {
        setState(() {
          loading = false;
          error = 'This recording could not be opened. Tap to retry.';
        });
      }
    }
  }

  Future<void> _toggle() async {
    if (error != null) {
      await _load(index);
      return;
    }
    if (playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      unawaited(
        player.play().catchError((Object e) {
          if (mounted) showError(context, 'Playback failed. Please retry.');
        }),
      );
    }
  }

  @override
  void dispose() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = tracks[index];
    final duration = player.duration ?? track.page.duration;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 135,
                      child: ChunkyButton(
                        label: '‹ ${widget.backLabel}',
                        height: 38,
                        color: Palette.navy,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AspectRatio(
                      aspectRatio: 1,
                      child: BookCover(track.book.cover, radius: 24),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      track.book.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.title ?? 'A story in your voice',
                      style: const TextStyle(color: Palette.muted),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 80,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Palette.mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WavePainter(progress: progress),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.page.title,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${clockTime(position)} / ${clockTime(duration)}',
                                        style: const TextStyle(
                                          color: Palette.muted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${index + 1} / ${tracks.length}',
                                  style: const TextStyle(color: Palette.navy),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      label: 'Playback position',
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                        ),
                        child: Slider(
                          value: progress,
                          onChanged: loading || error != null
                              ? null
                              : (value) => player.seek(
                                  Duration(
                                    milliseconds:
                                        (duration.inMilliseconds * value)
                                            .round(),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Palette.pink)),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ChunkyButton(
                          icon: Icons.skip_previous_rounded,
                          semanticLabel: 'Previous page',
                          height: 72,
                          width: 80,
                          color: Palette.gray,
                          foreground: Palette.navy,
                          onPressed: loading
                              ? null
                              : () {
                                  if (index > 0) {
                                    _load(index - 1, autoplay: playing);
                                  } else {
                                    player.seek(Duration.zero);
                                  }
                                },
                        ),
                        ChunkyButton(
                          icon: loading
                              ? Icons.hourglass_top_rounded
                              : playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          semanticLabel: loading
                              ? 'Loading audio'
                              : playing
                              ? 'Pause story'
                              : 'Play story',
                          height: 110,
                          width: 120,
                          color: Palette.pink,
                          onPressed: loading ? null : _toggle,
                        ),
                        ChunkyButton(
                          icon: Icons.skip_next_rounded,
                          semanticLabel: 'Next page',
                          height: 72,
                          width: 80,
                          color: Palette.gray,
                          foreground: Palette.navy,
                          onPressed: loading || index == tracks.length - 1
                              ? null
                              : () => _load(index + 1, autoplay: playing),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              const speeds = [.75, 1.0, 1.25, 1.5];
                              speed =
                                  speeds[(speeds.indexOf(speed) + 1) %
                                      speeds.length];
                            });
                            player.setSpeed(speed);
                          },
                          child: Text(
                            '$speed×',
                            style: const TextStyle(color: Palette.muted),
                          ),
                        ),
                        IconButton(
                          tooltip: repeat ? 'Repeat on' : 'Repeat off',
                          onPressed: () => setState(() => repeat = !repeat),
                          icon: Icon(
                            Icons.repeat_rounded,
                            color: repeat ? Palette.green : Palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

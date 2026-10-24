import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../data/models.dart';

void showError(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );

Future<bool> confirmDelete(BuildContext context, String label) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text(
          'This will permanently remove it from your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Palette.pink)),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> askName(
  BuildContext context,
  String title,
  String value,
) async {
  final input = TextEditingController(text: value);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: input,
        autofocus: true,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(context, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (input.text.trim().isNotEmpty) {
              Navigator.pop(context, input.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  // Dialog exit animations may still reference the controller during this frame.
  Future.delayed(const Duration(milliseconds: 300), input.dispose);
  return result;
}

class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    this.label,
    this.icon,
    this.color = Palette.green,
    this.foreground = Colors.white,
    this.height = 70,
    this.width,
    this.onPressed,
    this.semanticLabel,
  });
  final String? label, semanticLabel;
  final IconData? icon;
  final Color color, foreground;
  final double height;
  final double? width;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) {
    final shadow = color == Palette.green
        ? Palette.greenShadow
        : color == Palette.pink
        ? Palette.pinkShadow
        : Color.lerp(color, Palette.navy, .18)!;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      onTap: onPressed,
      label: semanticLabel ?? label,
      child: SizedBox(
        width: width,
        height: height + 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: shadow,
            borderRadius: BorderRadius.circular(height > 80 ? 22 : 15),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Material(
              color: onPressed == null ? Palette.gray : color,
              borderRadius: BorderRadius.circular(height > 80 ? 22 : 15),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: icon != null
                        ? Icon(icon, color: foreground, size: height * .48)
                        : Text(
                            label!,
                            style: TextStyle(
                              fontSize: height < 50 ? 18 : 21,
                              fontWeight: FontWeight.w600,
                              color: foreground,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Palette.green,
    this.foreground = Colors.white,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color, foreground;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    excludeSemantics: true,
    onTap: onPressed,
    label: label,
    child: SizedBox(
      width: 76,
      height: 80,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color == Palette.green ? Palette.greenShadow : Palette.gray,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(icon, size: 36, color: foreground),
            ),
          ),
        ),
      ),
    ),
  );
}

class BookCover extends StatelessWidget {
  const BookCover(
    this.source, {
    super.key,
    this.radius = 20,
    this.fit = BoxFit.cover,
  });
  final String source;
  final double radius;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    final Widget image = source.startsWith('data:')
        ? Image.memory(
            base64Decode(source.split(',').last),
            fit: fit,
            gaplessPlayback: true,
          )
        : Image.asset(source, fit: fit, gaplessPlayback: true);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(color: const Color(0xfff3ccc3), child: image),
    );
  }
}

class WavePainter extends CustomPainter {
  const WavePainter({
    this.color = Palette.green,
    this.progress = 0,
    this.phase = 0,
  });
  final Color color;
  final double progress, phase;
  @override
  void paint(Canvas canvas, Size size) {
    for (int layer = 0; layer < 3; layer++) {
      final path = Path()..moveTo(0, size.height / 2);
      double amplitude(double x) {
        final edge = math.sin(x / size.width * math.pi);
        final wave =
            math.sin(x / size.width * 8 * math.pi + phase + layer) * .28 + .6;
        return edge * wave * size.height * (.18 + layer * .09);
      }

      for (double x = 0; x <= size.width; x += 3) {
        path.lineTo(x, size.height / 2 - amplitude(x));
      }
      for (double x = size.width; x >= 0; x -= 3) {
        path.lineTo(x, size.height / 2 + amplitude(x));
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()..color = color.withValues(alpha: .12 + layer * .07),
      );
    }
    if (progress > 0) {
      final x = size.width * progress;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        Paint()
          ..color = color
          ..strokeWidth = 2,
      );
      canvas.drawCircle(
        Offset(x, size.height / 2),
        7,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(x, size.height / 2),
        7,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(WavePainter old) =>
      color != old.color || progress != old.progress || phase != old.phase;
}

class PageTile extends StatelessWidget {
  const PageTile({
    super.key,
    required this.page,
    required this.onPlay,
    this.playing = false,
    this.onMenu,
    this.progress = 0,
  });
  final StoryPage page;
  final VoidCallback onPlay;
  final void Function(String)? onMenu;
  final bool playing;
  final double progress;
  @override
  Widget build(BuildContext context) => Container(
    height: 80,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Palette.mint,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: WavePainter(progress: progress)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      page.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      clockTime(page.duration),
                      style: const TextStyle(
                        color: Palette.muted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: playing ? 'Pause ${page.title}' : 'Play ${page.title}',
                onPressed: onPlay,
                icon: Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Palette.navy,
                  size: 38,
                ),
              ),
              if (onMenu != null)
                PopupMenuButton<String>(
                  tooltip: 'Edit ${page.title}',
                  onSelected: onMenu,
                  icon: const Icon(Icons.more_vert, color: Palette.navy),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename page')),
                    PopupMenuItem(value: 'delete', child: Text('Delete page')),
                  ],
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

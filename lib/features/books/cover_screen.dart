import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

class CoverScreen extends StatefulWidget {
  const CoverScreen({super.key, this.cover});
  final String? cover;
  @override
  State<CoverScreen> createState() => _CoverScreenState();
}

class _CoverScreenState extends State<CoverScreen> {
  late String cover = widget.cover ?? 'assets/images/bedtime.png';
  bool picking = false;
  Future<void> _pick(ImageSource source) async {
    setState(() => picking = true);
    try {
      final photo = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        if (bytes.length > 3 * 1024 * 1024) {
          throw StateError('Choose a photo smaller than 3 MB.');
        }
        final mime =
            photo.mimeType ??
            (photo.name.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg');
        if (mounted) {
          setState(() => cover = 'data:$mime;base64,${base64Encode(bytes)}');
        }
      }
    } catch (_) {
      if (mounted) {
        showError(
          context,
          'Could not open the camera or photo library. You can choose an illustrated cover below.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Palette.navy,
    appBar: AppBar(
      backgroundColor: Palette.navy,
      foregroundColor: Colors.white,
      title: const Text(
        'Book cover',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
      leading: IconButton(
        tooltip: 'Cancel cover',
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      BookCover(cover, radius: 22),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .65),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Make this story their own.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo, choose one, or use an illustration.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xffbac4e2), fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                separatorBuilder: (_, i) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final path =
                      'assets/images/${const ['bedtime', 'adventure', 'friends', 'music', 'playtime', 'welcome'][i]}.png';
                  return Semantics(
                    button: true,
                    label: 'Illustrated cover ${i + 1}',
                    child: GestureDetector(
                      onTap: () => setState(() => cover = path),
                      child: SizedBox(
                        width: 60,
                        child: BookCover(path, radius: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  tooltip: 'Choose photo',
                  onPressed: picking ? null : () => _pick(ImageSource.gallery),
                  icon: const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                RoundButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Take cover photo',
                  onPressed: picking
                      ? null
                      : () => _pick(
                          !kIsWeb &&
                                  (defaultTargetPlatform ==
                                          TargetPlatform.macOS ||
                                      defaultTargetPlatform ==
                                          TargetPlatform.linux ||
                                      defaultTargetPlatform ==
                                          TargetPlatform.windows)
                              ? ImageSource.gallery
                              : ImageSource.camera,
                        ),
                  color: Colors.white,
                  foreground: Palette.navy,
                ),
                IconButton(
                  tooltip: 'Use cover',
                  onPressed: picking
                      ? null
                      : () => Navigator.pop(context, cover),
                  icon: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ChunkyButton(
              label: picking ? 'Opening photos…' : 'Use cover',
              onPressed: picking ? null : () => Navigator.pop(context, cover),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    ),
  );
}

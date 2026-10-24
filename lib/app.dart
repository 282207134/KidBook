import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'data/library_store.dart';
import 'features/library/library_screen.dart';

class KidBookApp extends StatelessWidget {
  const KidBookApp({super.key, required this.store});
  final LibraryStore store;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'KidBook',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    builder: (context, child) => ColoredBox(
      color: const Color(0xffe9edf4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: ClipRect(child: child!),
        ),
      ),
    ),
    home: LibraryScreen(store: store),
  );
}

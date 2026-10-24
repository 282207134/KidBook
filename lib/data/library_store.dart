import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/media_files.dart';
import 'models.dart';

/// One source of truth; immutable models keep editor drafts separate from saved data.
class LibraryStore extends ChangeNotifier {
  LibraryStore(this.preferences);
  static const storageKey = 'kidbook.library.v1';
  final SharedPreferences preferences;
  List<Book> _books = [];
  List<StoryPlaylist> _playlists = [];
  String? loadError;
  List<Book> get books => List.unmodifiable(_books);
  List<StoryPlaylist> get playlists => List.unmodifiable(_playlists);

  void load() {
    final saved = preferences.getString(storageKey);
    if (saved == null) return;
    try {
      final json = jsonDecode(saved) as Map<String, dynamic>;
      if (json['version'] != 1) {
        throw const FormatException('Unsupported library');
      }
      _books = (json['books'] as List).map((b) => Book.fromJson(b)).toList();
      _playlists = (json['playlists'] as List)
          .map((p) => StoryPlaylist.fromJson(p))
          .toList();
    } catch (_) {
      loadError =
          'Your saved library could not be read. The original data has been kept.';
    }
  }

  Future<void> _commit(List<Book> books, List<StoryPlaylist> playlists) async {
    final saved = await preferences.setString(
      storageKey,
      encodeLibrary(books, playlists),
    );
    if (!saved) {
      throw StateError('Could not save your library. Please try again.');
    }
    _books = books;
    _playlists = playlists;
    loadError = null;
    notifyListeners();
  }

  Future<void> saveBook(Book book) async {
    final list = [..._books];
    final index = list.indexWhere((b) => b.id == book.id);
    final old = index < 0 ? null : list[index];
    if (index < 0) {
      list.insert(0, book);
    } else {
      list[index] = book;
    }
    await _commit(list, _playlists);
    for (final p in old?.pages ?? <StoryPage>[]) {
      if (!book.pages.any((n) => n.audio == p.audio)) {
        await deleteRecording(p.audio);
      }
    }
  }

  Future<void> deleteBooks(Set<String> ids) async {
    final removed = _books.where((b) => ids.contains(b.id)).toList();
    await _commit(
      _books.where((b) => !ids.contains(b.id)).toList(),
      _playlists
          .map(
            (p) => StoryPlaylist(
              id: p.id,
              title: p.title,
              bookIds: p.bookIds.where((id) => !ids.contains(id)).toList(),
            ),
          )
          .toList(),
    );
    for (final book in removed) {
      for (final page in book.pages) {
        await deleteRecording(page.audio);
      }
    }
  }

  Future<void> savePlaylist(StoryPlaylist playlist) => _commit(_books, [
    ..._playlists.where((p) => p.id != playlist.id),
    playlist,
  ]);
  Future<void> deletePlaylist(String id) =>
      _commit(_books, _playlists.where((p) => p.id != id).toList());
  List<Book> booksFor(StoryPlaylist p) => [
    for (final id in p.bookIds) ..._books.where((b) => b.id == id),
  ];

  Future<void> addSamples() async {
    const titles = [
      'Bedtime story',
      'A little adventure',
      'The best of friends',
      'A song for you',
      'Let’s play',
      'Up, up and away',
    ];
    const covers = [
      'bedtime',
      'adventure',
      'friends',
      'music',
      'playtime',
      'welcome',
    ];
    final samples = List.generate(
      titles.length,
      (i) => Book(
        id: 'sample-$i',
        title: titles[i],
        cover: 'assets/images/${covers[i]}.png',
        pages: List.generate(
          3,
          (j) => StoryPage(
            id: 'sample-$i-$j',
            title: 'Page ${j + 1}',
            audio: 'assets/audio/page${j + 1}.m4a',
            seconds: const [14, 14, 13][j],
          ),
        ),
      ),
    );
    await _commit([
      ..._books,
      ...samples.where((s) => !_books.any((b) => b.id == s.id)),
    ], _playlists);
  }
}

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidbook/data/library_store.dart';
import 'package:kidbook/data/models.dart';

void main() {
  late LibraryStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LibraryStore(await SharedPreferences.getInstance())..load();
  });
  test('empty install is empty; samples are opt-in and idempotent', () async {
    expect(store.books, isEmpty);
    await store.addSamples();
    await store.addSamples();
    expect(store.books, hasLength(6));
    expect(store.books.first.pages, hasLength(3));
  });
  test('book and playlist survive a fresh store instance', () async {
    await store.addSamples();
    await store.savePlaylist(
      StoryPlaylist(
        id: 'p',
        title: 'Sleep tight',
        bookIds: [store.books.first.id],
      ),
    );
    final restored = LibraryStore(store.preferences)..load();
    expect(restored.books.length, 6);
    expect(restored.playlists.single.title, 'Sleep tight');
    expect(
      restored.booksFor(restored.playlists.single).single.title,
      'Bedtime story',
    );
  });
  test(
    'editing replaces the book and preserves page order and names',
    () async {
      await store.addSamples();
      final book = store.books.first;
      await store.saveBook(
        Book(
          id: book.id,
          title: 'Our story',
          cover: book.cover,
          pages: [book.pages[2].renamed('The end'), book.pages[0]],
        ),
      );
      final restored = LibraryStore(store.preferences)..load();
      expect(restored.books.length, 6);
      expect(restored.books.first.title, 'Our story');
      expect(restored.books.first.pages.first.title, 'The end');
      expect(restored.books.first.pages.last.id, book.pages.first.id);
    },
  );
  test(
    'deleting books removes playlist references, keeping other books',
    () async {
      await store.addSamples();
      final first = store.books.first.id, last = store.books.last.id;
      await store.savePlaylist(
        StoryPlaylist(id: 'p', title: 'Night', bookIds: [first, last]),
      );
      await store.deleteBooks({first});
      expect(store.books, hasLength(5));
      expect(store.playlists.single.bookIds, [last]);
      await store.deletePlaylist('p');
      expect(store.playlists, isEmpty);
    },
  );
  test('corrupt data is retained and reported', () async {
    await store.preferences.setString(LibraryStore.storageKey, '{broken');
    store.load();
    expect(store.loadError, isNotNull);
    expect(store.preferences.getString(LibraryStore.storageKey), '{broken');
  });
  test('schema version and duration formatting are stable', () {
    expect(jsonDecode(encodeLibrary([], []))['version'], 1);
    expect(clockTime(const Duration(seconds: 125)), '2:05');
  });
}

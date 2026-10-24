import 'dart:convert';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
String clockTime(Duration value) =>
    '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';

class StoryPage {
  const StoryPage({
    required this.id,
    required this.title,
    required this.audio,
    required this.seconds,
  });
  final String id, title, audio;
  final int seconds;
  Duration get duration => Duration(seconds: seconds);
  StoryPage renamed(String value) =>
      StoryPage(id: id, title: value, audio: audio, seconds: seconds);
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'audio': audio,
    'seconds': seconds,
  };
  factory StoryPage.fromJson(Map<String, dynamic> json) => StoryPage(
    id: json['id'],
    title: json['title'],
    audio: json['audio'],
    seconds: json['seconds'],
  );
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.cover,
    required this.pages,
  });
  final String id, title, cover;
  final List<StoryPage> pages;
  Duration get duration =>
      pages.fold(Duration.zero, (sum, p) => sum + p.duration);
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'cover': cover,
    'pages': pages.map((p) => p.toJson()).toList(),
  };
  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json['id'],
    title: json['title'],
    cover: json['cover'],
    pages: (json['pages'] as List).map((p) => StoryPage.fromJson(p)).toList(),
  );
}

class StoryPlaylist {
  const StoryPlaylist({
    required this.id,
    required this.title,
    required this.bookIds,
  });
  final String id, title;
  final List<String> bookIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'bookIds': bookIds,
  };
  factory StoryPlaylist.fromJson(Map<String, dynamic> json) => StoryPlaylist(
    id: json['id'],
    title: json['title'],
    bookIds: List<String>.from(json['bookIds']),
  );
}

String encodeLibrary(List<Book> books, List<StoryPlaylist> playlists) =>
    jsonEncode({
      'version': 1,
      'books': books.map((b) => b.toJson()).toList(),
      'playlists': playlists.map((p) => p.toJson()).toList(),
    });

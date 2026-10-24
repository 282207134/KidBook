import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/library_store.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../books/book_editor.dart';
import '../player/player_screen.dart';
import '../playlists/playlist_screens.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.store});
  final LibraryStore store;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool playlists = false, editing = false, listView = false;
  final selected = <String>{};
  LibraryStore get store => widget.store;
  @override
  void initState() {
    super.initState();
    if (store.loadError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showError(context, store.loadError!);
      });
    }
  }

  Future<void> _samples() async {
    try {
      await store.addSamples();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  void _addBook() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => BookEditor(store: store)),
  );
  void _playlist() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PlaylistNameScreen(store: store)),
  );
  void _openBook(Book book) {
    if (editing) {
      setState(() {
        if (!selected.add(book.id)) selected.remove(book.id);
      });
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Palette.gray,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 20),
              Text(book.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '${book.pages.length} pages · ${clockTime(book.duration)}',
                style: const TextStyle(color: Palette.muted),
              ),
              const SizedBox(height: 20),
              ChunkyButton(
                label: 'Play story',
                icon: null,
                onPressed: book.pages.isEmpty
                    ? null
                    : () {
                        Navigator.pop(sheet);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerScreen(
                              books: [book],
                              backLabel: 'Library',
                            ),
                          ),
                        );
                      },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit book'),
                onPressed: () {
                  Navigator.pop(sheet);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookEditor(store: store, book: book),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context, '${selected.length} books')) return;
    try {
      await store.deleteBooks(selected);
      setState(() {
        selected.clear();
        editing = false;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      if (store.books.isEmpty && !playlists) return _welcome();
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                child: Row(
                  children: [
                    _tab(
                      'Library',
                      !playlists,
                      () => setState(() {
                        playlists = false;
                        editing = false;
                        selected.clear();
                      }),
                    ),
                    const SizedBox(width: 12),
                    _tab(
                      'Playlists',
                      playlists,
                      () => setState(() {
                        playlists = true;
                        editing = false;
                        selected.clear();
                      }),
                    ),
                    const Spacer(),
                    ChunkyButton(
                      height: 38,
                      width: 44,
                      color: Palette.gray,
                      foreground: Palette.navy,
                      icon: editing ? Icons.check_rounded : Icons.edit_square,
                      semanticLabel: editing ? 'Done editing' : 'Edit library',
                      onPressed: () => setState(() {
                        editing = !editing;
                        selected.clear();
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(child: playlists ? _playlists() : _books()),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: playlists && store.playlists.isEmpty
            ? null
            : editing && !playlists
            ? (selected.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 35),
                      child: ChunkyButton(
                        label: 'Delete ${selected.length} books',
                        color: Palette.pink,
                        onPressed: _delete,
                      ),
                    ))
            : RoundButton(
                icon: Icons.add_rounded,
                label: playlists ? 'New playlist' : 'New book',
                onPressed: playlists ? _playlist : _addBook,
              ),
      );
    },
  );
  Widget _tab(String label, bool active, VoidCallback action) => ChunkyButton(
    label: label,
    height: 38,
    color: active ? Palette.green : Palette.gray,
    foreground: active ? Colors.white : Palette.navy,
    onPressed: action,
  );
  Widget _welcome() => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Image.asset(
                  'assets/images/welcome.png',
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 45),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 38),
                  child: Text(
                    'Start the adventure\nfor your kids',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 45),
                  child: Text(
                    'To get started, create the first book, and we’ll tell you what to do next.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.3,
                      color: Palette.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 55),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ChunkyButton(
                    label: 'Create first book',
                    onPressed: _addBook,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _samples,
                  child: const Text(
                    'Explore sample library',
                    style: TextStyle(color: Palette.navy),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  Widget _books() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
        child: Row(
          children: [
            Text(
              editing
                  ? '${selected.length} selected'
                  : '${store.books.length} little adventures',
              style: const TextStyle(color: Palette.muted, fontSize: 14),
            ),
            const Spacer(),
            IconButton(
              tooltip: listView ? 'Grid view' : 'List view',
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => listView = !listView),
              icon: Icon(
                listView ? Icons.grid_view_rounded : Icons.view_agenda_outlined,
                color: Palette.navy,
                size: 22,
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: listView
            ? ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                itemCount: store.books.length,
                separatorBuilder: (_, index) => const SizedBox(height: 18),
                itemBuilder: (_, i) => _bookCard(store.books[i], wide: true),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 15,
                  childAspectRatio: 160 / 180,
                ),
                itemCount: store.books.length,
                itemBuilder: (_, i) => _bookCard(store.books[i]),
              ),
      ),
    ],
  );
  Widget _bookCard(Book book, {bool wide = false}) => Semantics(
    label: '${book.title}, ${book.pages.length} pages',
    button: true,
    child: GestureDetector(
      onTap: () => _openBook(book),
      onLongPress: () => setState(() {
        editing = true;
        selected.add(book.id);
      }),
      child: Container(
        height: wide ? 200 : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Palette.navy.withValues(alpha: .12),
              offset: const Offset(0, 7),
              blurRadius: 0,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookCover(book.cover),
            if (wide)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Palette.navy.withValues(alpha: .8),
                      ],
                    ),
                  ),
                  child: Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (editing)
              Positioned(
                right: 12,
                bottom: 12,
                child: SelectionBadge(selected: selected.contains(book.id)),
              ),
          ],
        ),
      ),
    ),
  );
  Widget _playlists() {
    if (store.playlists.isEmpty) {
      return LayoutBuilder(
        builder: (_, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/sleep.png',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 52),
                  Text(
                    'Create a playlist to\nautomatically play\nmultiple books',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Make a little lullaby, so your child can hear your voice and sleep peacefully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      color: Palette.muted,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 55),
                  ChunkyButton(label: 'Create Playlist', onPressed: _playlist),
                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 120),
      itemCount: store.playlists.length,
      separatorBuilder: (_, i) => const SizedBox(height: 18),
      itemBuilder: (_, i) {
        final p = store.playlists[i];
        final books = store.booksFor(p);
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                SizedBox(
                  width: 85,
                  height: 95,
                  child: books.isEmpty
                      ? const Icon(
                          Icons.queue_music_rounded,
                          color: Palette.pink,
                          size: 50,
                        )
                      : BookCover(books.first.cover, radius: 13),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ChooseBooksScreen(store: store, playlist: p),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${books.length} books · ${clockTime(books.fold(Duration.zero, (d, b) => d + b.duration))}',
                          style: const TextStyle(color: Palette.muted),
                        ),
                      ],
                    ),
                  ),
                ),
                if (editing)
                  IconButton(
                    tooltip: 'Delete playlist',
                    icon: const Icon(Icons.delete_outline, color: Palette.pink),
                    onPressed: () async {
                      if (await confirmDelete(context, 'playlist')) {
                        try {
                          await store.deletePlaylist(p.id);
                        } catch (e) {
                          if (mounted) showError(context, e);
                        }
                      }
                    },
                  )
                else
                  IconButton(
                    tooltip: 'Play ${p.title}',
                    icon: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Palette.green,
                      size: 44,
                    ),
                    onPressed: books.every((b) => b.pages.isEmpty)
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                books: books,
                                backLabel: 'Playlists',
                                title: p.title,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SelectionBadge extends StatelessWidget {
  const SelectionBadge({super.key, required this.selected});
  final bool selected;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 160),
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: selected ? Palette.green : Colors.white.withValues(alpha: .25),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: selected ? Palette.green : Colors.white,
        width: 2,
      ),
    ),
    child: selected
        ? const Icon(Icons.check_rounded, color: Colors.white, size: 30)
        : null,
  );
}

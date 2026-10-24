import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/library_store.dart';
import '../../data/models.dart';
import '../../widgets/common.dart';
import '../library/library_screen.dart';

class PlaylistNameScreen extends StatefulWidget {
  const PlaylistNameScreen({super.key, required this.store});
  final LibraryStore store;
  @override
  State<PlaylistNameScreen> createState() => _PlaylistNameScreenState();
}

class _PlaylistNameScreenState extends State<PlaylistNameScreen> {
  final name = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void _create() {
    if (name.text.trim().isEmpty) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChooseBooksScreen(
          store: widget.store,
          playlist: StoryPlaylist(
            id: newId(),
            title: name.text.trim(),
            bookIds: const [],
          ),
          isNew: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Playlist name',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Palette.navy),
                ),
              ],
            ),
            const SizedBox(height: 25),
            TextField(
              key: const ValueKey('playlist-name'),
              controller: name,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              style: Theme.of(context).textTheme.headlineLarge,
              decoration: const InputDecoration(
                hintText: 'Enter a name',
                filled: false,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _create(),
            ),
            const Spacer(),
            ChunkyButton(
              label: 'Create',
              onPressed: name.text.trim().isEmpty ? null : _create,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ),
  );
}

class ChooseBooksScreen extends StatefulWidget {
  const ChooseBooksScreen({
    super.key,
    required this.store,
    required this.playlist,
    this.isNew = false,
  });
  final LibraryStore store;
  final StoryPlaylist playlist;
  final bool isNew;
  @override
  State<ChooseBooksScreen> createState() => _ChooseBooksScreenState();
}

class _ChooseBooksScreenState extends State<ChooseBooksScreen> {
  late final selected = widget.playlist.bookIds.toSet();
  late String title = widget.playlist.title;
  bool saving = false;
  Future<void> _save() async {
    setState(() => saving = true);
    try {
      await widget.store.savePlaylist(
        StoryPlaylist(
          id: widget.playlist.id,
          title: title,
          bookIds: widget.store.books
              .where((b) => selected.contains(b.id))
              .map((b) => b.id)
              .toList(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  label: const Text(
                    'Playlists',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Rename playlist',
                  onPressed: () async {
                    final value = await askName(
                      context,
                      'Playlist name',
                      title,
                    );
                    if (value != null) setState(() => title = value);
                  },
                  icon: const Icon(Icons.more_horiz, color: Palette.navy),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 6),
                Text(
                  selected.isEmpty
                      ? 'Choose books'
                      : '${selected.length} books selected',
                  style: const TextStyle(color: Palette.muted, fontSize: 15),
                ),
              ],
            ),
          ),
          if (widget.store.books.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(35),
                  child: Text(
                    'Create a book in your library first.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                itemCount: widget.store.books.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 18,
                  childAspectRatio: 160 / 180,
                ),
                itemBuilder: (_, i) {
                  final book = widget.store.books[i];
                  final checked = selected.contains(book.id);
                  return Semantics(
                    checked: checked,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (!selected.add(book.id)) selected.remove(book.id);
                      }),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            BookCover(book.cover),
                            ColoredBox(
                              color: Palette.navy.withValues(alpha: .24),
                            ),
                            Positioned(
                              left: 12,
                              right: 10,
                              top: 12,
                              child: Text(
                                book.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: SelectionBadge(selected: checked),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    floatingActionButton: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ChunkyButton(
        label: saving
            ? 'Saving…'
            : widget.isNew
            ? 'Add to playlist'
            : 'Save playlist',
        onPressed: selected.isEmpty || saving ? null : _save,
      ),
    ),
  );
}

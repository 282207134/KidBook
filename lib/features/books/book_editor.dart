import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/library_store.dart';
import '../../data/models.dart';
import '../../services/media_files.dart';
import '../../widgets/common.dart';
import '../player/player_screen.dart';
import 'cover_screen.dart';
import 'recording_sheet.dart';

class BookEditor extends StatefulWidget {
  const BookEditor({super.key, required this.store, this.book});
  final LibraryStore store;
  final Book? book;
  @override
  State<BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<BookEditor> {
  late final name = TextEditingController(text: widget.book?.title ?? '');
  late final id = widget.book?.id ?? newId();
  late final pages = [...?widget.book?.pages];
  late String? cover = widget.book?.cover;
  bool dirty = false, saving = false, committed = false;
  final newRecordings = <String>[];
  @override
  void initState() {
    super.initState();
    name.addListener(_markDirty);
  }

  void _markDirty() {
    dirty = true;
  }

  Book get draft => Book(
    id: id,
    title: name.text.trim(),
    cover: cover ?? 'assets/images/bedtime.png',
    pages: List.of(pages),
  );
  Future<void> _save() async {
    if (name.text.trim().isEmpty) {
      showError(context, 'Give your book a name first.');
      return;
    }
    if (pages.isEmpty) {
      showError(context, 'Record at least one page before saving.');
      return;
    }
    setState(() => saving = true);
    try {
      await widget.store.saveBook(draft);
      committed = true;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => saving = false);
        showError(context, e);
      }
    }
  }

  Future<void> _back() async {
    if (saving) return;
    if (dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Leave this story?'),
          content: const Text('Your unsaved changes will be discarded.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _cover() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => CoverScreen(cover: cover)),
    );
    if (result != null) {
      setState(() {
        cover = result;
        dirty = true;
      });
    }
  }

  Future<void> _record() async {
    FocusScope.of(context).unfocus();
    final page = await showModalBottomSheet<StoryPage>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      barrierColor: Palette.navy.withValues(alpha: .65),
      builder: (_) => RecordingSheet(pageNumber: pages.length + 1),
    );
    if (mounted) FocusScope.of(context).unfocus();
    if (page != null && mounted) {
      setState(() {
        pages.add(page);
        newRecordings.add(page.audio);
        dirty = true;
      });
    }
  }

  Future<void> _pageMenu(StoryPage page, String action) async {
    if (action == 'rename') {
      final value = await askName(context, 'Page name', page.title);
      if (value != null) {
        setState(() {
          pages[pages.indexOf(page)] = page.renamed(value);
          dirty = true;
        });
      }
    } else if (await confirmDelete(context, page.title)) {
      setState(() {
        pages.remove(page);
        dirty = true;
      });
    }
  }

  @override
  void dispose() {
    name.dispose();
    for (final uri in newRecordings) {
      if (!committed || !pages.any((p) => p.audio == uri)) {
        unawaited(deleteRecording(uri));
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !dirty || committed,
    onPopInvokedWithResult: (popped, result) {
      if (!popped) _back();
    },
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 8,
        title: TextButton.icon(
          onPressed: _back,
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: Palette.navy,
          ),
          label: const Text(
            'Library',
            style: TextStyle(color: Palette.navy, fontSize: 21),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : _save,
            child: Text(
              saving ? 'Saving…' : 'Save',
              style: const TextStyle(color: Palette.navy, fontSize: 21),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 25),
            Semantics(
              button: true,
              label: 'Add cover',
              excludeSemantics: true,
              onTap: _cover,
              key: const ValueKey('cover-picker'),
              child: GestureDetector(
                onTap: _cover,
                child: Container(
                  width: MediaQuery.viewInsetsOf(context).bottom > 0
                      ? 110
                      : 195,
                  height: MediaQuery.viewInsetsOf(context).bottom > 0
                      ? 110
                      : 210,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Palette.navy.withValues(alpha: .08),
                    ),
                  ),
                  child: cover != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            BookCover(cover!, radius: 15),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Palette.green,
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_rounded,
                              color: Palette.green,
                              size: 80,
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Add cover',
                              style: TextStyle(
                                color: Palette.muted,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 240,
              child: TextField(
                key: const ValueKey('book-title'),
                controller: name,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  color: Palette.navy,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: const InputDecoration(
                  hintText: 'Book name',
                  counterText: '',
                  suffixIcon: Icon(
                    Icons.edit_outlined,
                    color: Palette.navy,
                    size: 23,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: pages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(50, 0, 50, 50),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Palette.navy,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Text(
                            'Click on the record button.\nEach recording will be made\ninto a page.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Palette.gray,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Text(
                                'Content',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Text(
                                '${pages.length} pages',
                                style: const TextStyle(color: Palette.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              padding: const EdgeInsets.only(bottom: 110),
                              itemCount: pages.length,
                              onReorder: (old, next) => setState(() {
                                if (next > old) next--;
                                pages.insert(next, pages.removeAt(old));
                                dirty = true;
                              }),
                              itemBuilder: (context, i) => Padding(
                                key: ValueKey(pages[i].id),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReorderableDelayedDragStartListener(
                                  index: i,
                                  child: PageTile(
                                    page: pages[i],
                                    onMenu: (action) =>
                                        _pageMenu(pages[i], action),
                                    onPlay: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlayerScreen(
                                          books: [draft],
                                          backLabel: 'Book',
                                          initialPage: i,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: RoundButton(
        icon: Icons.mic_none_rounded,
        label: 'Record a page',
        onPressed: saving ? null : _record,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
  );
}

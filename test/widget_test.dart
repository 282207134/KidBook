import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kidbook/app.dart';
import 'package:kidbook/data/library_store.dart';

void main() {
  late LibraryStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LibraryStore(await SharedPreferences.getInstance())..load();
  });
  testWidgets('onboarding and editor validate an empty book', (tester) async {
    await tester.pumpWidget(KidBookApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Start the adventure\nfor your kids'), findsOneWidget);
    await tester.ensureVisible(find.text('Create first book'));
    await tester.tap(find.text('Create first book'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Give your book a name first.'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('book-title')),
      'Our bedtime story',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Record at least one page before saving.'),
      findsOneWidget,
    );
    expect(store.books, isEmpty);
  });
  testWidgets('grid, list, selection and playlist creation form work', (
    tester,
  ) async {
    await store.addSamples();
    await tester.pumpWidget(KidBookApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('6 little adventures'), findsOneWidget);
    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();
    expect(find.text('Bedtime story'), findsOneWidget);
    await tester.tap(find.text('Playlists'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create Playlist'));
    await tester.tap(find.text('Create Playlist'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('playlist-name')),
      'Sleep, sleep tight',
    );
    await tester.pump();
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bedtime story'));
    await tester.pump();
    await tester.tap(find.text('Add to playlist'));
    await tester.pumpAndSettle();
    expect(store.playlists.single.title, 'Sleep, sleep tight');
    expect(store.playlists.single.bookIds, ['sample-0']);
  });
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets('no overflow at ${size.width} × ${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(KidBookApp(store: store));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Create first book'));
      await tester.tap(find.text('Create first book'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('cover-picker')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Use cover'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}

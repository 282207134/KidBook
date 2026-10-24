import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'data/library_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xfff7f8fb),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final store = LibraryStore(await SharedPreferences.getInstance())..load();
  runApp(KidBookApp(store: store));
}

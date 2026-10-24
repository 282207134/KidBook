import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> recordingPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/kidbook-${DateTime.now().microsecondsSinceEpoch}.m4a';
}

Future<String> persistRecording(String path) async => path;
Future<void> deleteRecording(String path) async {
  if (path.startsWith('assets/') || !path.contains('/kidbook-')) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    /* A missing recording must not undo a saved library. */
  }
}

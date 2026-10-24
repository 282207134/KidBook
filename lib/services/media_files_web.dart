import 'dart:convert';
import 'package:image_picker/image_picker.dart';

Future<String> recordingPath() async => 'recording.webm';
Future<String> persistRecording(String path) async =>
    'data:audio/webm;base64,${base64Encode(await XFile(path).readAsBytes())}';
Future<void> deleteRecording(String path) async {}

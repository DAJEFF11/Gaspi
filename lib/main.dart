import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'library.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    await windowManager.setMinimumSize(const Size(380, 600));
  }
  MediaKit.ensureInitialized();
  final library = MusicLibrary();
  runApp(GaspiApp(library: library));
  await library.initialize();
}

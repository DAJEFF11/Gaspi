import 'dart:io';
import 'package:gaspi/metadata.dart';

void main() {
  final root = Directory.systemTemp.createTempSync('gaspi-check-');
  try {
    final broken = File('${root.path}/Artist - Track.mp3')
      ..writeAsBytesSync([0, 1, 2]);
    File('${root.path}/Artist - Track.lrc').writeAsStringSync('[00:01]Local');
    final result = inspectSong([broken.path, root.path]);
    if (result['title'] != 'Artist - Track' ||
        result['lyrics'] != '[00:01]Local' ||
        result['cover'] != null) {
      throw StateError('Damaged metadata fallback or sidecar failed');
    }
    stdout.writeln(
      'PASS damaged metadata preserves filename and local sidecar',
    );
  } finally {
    root.deleteSync(recursive: true);
  }
}


import 'dart:io';
import 'dart:convert';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'models.dart';

// Metadata parsing runs outside the UI isolate; malformed tags do not prevent playback.
Map<String, dynamic> inspectSong(List<String> args) {
  final path = args[0];
  final song = Song(
    path,
    p.basenameWithoutExtension(path),
    'Artista desconocido',
    'Sin álbum',
    0,
    null,
    '',
  );
  try {
    final m = readMetadata(File(path), getImage: true);
    String? cover;
    if (m.pictures.isNotEmpty) {
      cover = p.join(args[1], '${sha256.convert(utf8.encode(path))}.cover');
      File(cover).writeAsBytesSync(m.pictures.first.bytes);
    }
    final sidecar = File(p.setExtension(path, '.lrc'));
    return Song(
      path,
      m.title?.trim().isNotEmpty == true ? m.title! : song.title,
      m.artist ?? song.artist,
      m.album ?? song.album,
      m.duration?.inMilliseconds ?? 0,
      cover,
      sidecar.existsSync() ? sidecar.readAsStringSync() : m.lyrics ?? '',
    ).toJson();
  } catch (_) {
    final sidecar = File(p.setExtension(path, '.lrc'));
    try {
      if (sidecar.existsSync()) {
        song.lyrics = sidecar.readAsStringSync();
      }
    } catch (_) {
      /* Optional sidecar. */
    }
    return song.toJson();
  }
}

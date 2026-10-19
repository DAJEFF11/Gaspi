import 'dart:async';
import 'models.dart';
export 'models.dart';
import 'dart:convert';
import 'dart:io';
import 'metadata.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const audioExtensions = [
  'mp3',
  'flac',
  'wav',
  'ogg',
  'opus',
  'm4a',
  'aac',
  'aif',
  'aiff',
  'ape',
  'wma',
  'alac',
  'wv',
];

class MusicLibrary extends ChangeNotifier {
  MusicLibrary({Player? audioPlayer})
    : player =
          audioPlayer ??
          Player(configuration: const PlayerConfiguration(title: 'Gaspi')) {
    _subscriptions.add(
      player.stream.playlist.listen((value) {
        currentPath = value.medias.isEmpty
            ? null
            : value.medias[value.index].extras?['path'] as String?;
        notifyListeners();
      }),
    );
    _subscriptions.add(
      player.stream.error.listen((value) {
        message = 'No se pudo reproducir este archivo: $value';
        notifyListeners();
      }),
    );
  }
  final Player player;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<Song> songs = [];
  final Set<String> favorites = {};
  final Map<String, List<String>> playlists = {};
  late Directory root;
  String? currentPath, message;
  bool ready = false, importing = false, shuffled = false;
  bool dark = false;
  PlaylistMode repeat = PlaylistMode.none;
  Future<void> _saveChain = Future.value();
  Song? get current => songs.where((s) => s.path == currentPath).firstOrNull;

  Future<void> initialize() async {
    try {
      root = Directory(
        p.join((await getApplicationSupportDirectory()).path, 'Gaspi'),
      );
      await root.create(recursive: true);
      await Directory(p.join(root.path, 'covers')).create(recursive: true);
      await Directory(p.join(root.path, 'music')).create(recursive: true);
      final file = File(p.join(root.path, 'library.json'));
      final backup = File('${file.path}.bak');
      Map<String, dynamic>? data;
      for (final candidate in [file, backup]) {
        if (!await candidate.exists()) {
          continue;
        }
        try {
          data =
              jsonDecode(await candidate.readAsString())
                  as Map<String, dynamic>;
          break;
        } catch (_) {
          message =
              'La biblioteca no se pudo leer. Se intentará recuperar la copia de seguridad.';
        }
      }
      if (data != null) {
        dark = data['dark'] == true;
        songs.addAll(
          (data['songs'] as List).map(
            (s) => Song.fromJson(Map<String, dynamic>.from(s)),
          ),
        );
        favorites.addAll(List<String>.from(data['favorites'] ?? []));
        (data['playlists'] as Map<String, dynamic>? ?? {}).forEach((
          key,
          value,
        ) {
          playlists[key] = List<String>.from(value);
        });
      }
      ready = true;
    } catch (e) {
      message = 'No se pudo abrir el almacenamiento local: $e';
    }
    notifyListeners();
  }

  Future<void> save() {
    final snapshot = jsonEncode({
      'songs': songs.map((s) => s.toJson()).toList(),
      'favorites': favorites.toList(),
      'playlists': playlists,
      'dark': dark,
    });
    _saveChain = _saveChain
        .then((_) async {
          final file = File(p.join(root.path, 'library.json'));
          final temp = File('${file.path}.tmp');
          final backup = File('${file.path}.bak');
          await temp.writeAsString(snapshot, flush: true);
          if (await backup.exists()) {
            await backup.delete();
          }
          if (await file.exists()) {
            await file.rename(backup.path);
          }
          await temp.rename(file.path);
        })
        .catchError((Object e) {
          message = 'No se pudieron guardar los cambios: $e';
          notifyListeners();
        });
    return _saveChain;
  }

  Future<void> importFiles({bool folder = false}) async {
    if (!ready || importing) {
      return;
    }
    importing = true;
    notifyListeners();
    var count = 0, failed = 0;
    try {
      final paths = <String>[];
      if (folder) {
        final dir = await FilePicker.platform.getDirectoryPath();
        if (dir != null) {
          await for (final entity in Directory(
            dir,
          ).list(recursive: true, followLinks: false)) {
            if (entity is File &&
                audioExtensions.contains(
                  p.extension(entity.path).replaceFirst('.', '').toLowerCase(),
                )) {
              paths.add(entity.path);
            }
          }
        }
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: audioExtensions,
          allowMultiple: true,
        );
        paths.addAll(result?.paths.whereType<String>() ?? []);
      }
      for (var source in paths) {
        try {
          if (Platform.isAndroid) {
            // Android picker paths may be temporary: keep an owned, durable copy.
            final hash = await sha256.bind(File(source).openRead()).first;
            final destination = p.join(
              root.path,
              'music',
              '$hash${p.extension(source).toLowerCase()}',
            );
            if (!await File(destination).exists()) {
              await File(source).copy(destination);
            }
            final originalTitle = p.basenameWithoutExtension(source);
            source = destination;
            if (songs.any((s) => s.path == source)) {
              continue;
            }
            final result = await compute(inspectSong, [
              source,
              p.join(root.path, 'covers'),
            ]);
            if (result['title'] == p.basenameWithoutExtension(source)) {
              result['title'] = originalTitle;
            }
            songs.add(Song.fromJson(result));
          } else {
            if (songs.any((s) => p.equals(s.path, source))) {
              continue;
            }
            songs.add(
              Song.fromJson(
                await compute(inspectSong, [
                  source,
                  p.join(root.path, 'covers'),
                ]),
              ),
            );
          }
          count++;
          notifyListeners();
        } catch (_) {
          failed++;
        }
      }
      await save();
      if (paths.isNotEmpty) {
        message =
            '$count canciones añadidas${failed > 0 ? ' · $failed archivos no se pudieron importar' : ''}';
      }
    } catch (e) {
      message = 'No se pudo importar: $e';
    } finally {
      importing = false;
      notifyListeners();
    }
  }

  Future<void> play(List<Song> tracks, Song start) async {
    if (tracks.isEmpty) {
      return;
    }
    try {
      if (!await File(start.path).exists()) {
        throw const FileSystemException(
          'El archivo se movió o se eliminó. Vuelve a importarlo.',
        );
      }
      await player.open(
        Playlist(
          tracks
              .map(
                (s) => Media(
                  s.path,
                  extras: {
                    'path': s.path,
                    'title': s.title,
                    'artist': s.artist,
                  },
                ),
              )
              .toList(),
          index: tracks.indexOf(start),
        ),
      );
    } catch (e) {
      message = 'No se pudo abrir la canción: $e';
      notifyListeners();
    }
  }

  Future<void> favorite(Song song) async {
    if (!favorites.add(song.path)) {
      favorites.remove(song.path);
    }
    notifyListeners();
    await save();
  }

  Future<void> toggleTheme() async {
    dark = !dark;
    notifyListeners();
    if (ready) {
      await save();
    }
  }

  Future<void> createPlaylist(String name) async {
    final clean = name.trim();
    if (clean.isEmpty || playlists.containsKey(clean)) {
      return;
    }
    playlists[clean] = [];
    notifyListeners();
    await save();
  }

  Future<void> addToPlaylist(String name, Song song) async {
    if (!playlists[name]!.contains(song.path)) {
      playlists[name]!.add(song.path);
    }
    notifyListeners();
    await save();
  }

  Future<void> remove(Song song) async {
    if (currentPath == song.path) {
      await player.stop();
      currentPath = null;
    }
    songs.remove(song);
    favorites.remove(song.path);
    for (final list in playlists.values) {
      list.remove(song.path);
    }
    notifyListeners();
    await save();
  }

  Future<void> loadLyrics() async {
    final song = current;
    if (song == null) {
      return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'txt'],
      );
      final path = result?.files.single.path;
      if (path == null) {
        return;
      }
      song.lyrics = await File(path).readAsString();
      notifyListeners();
      await save();
    } catch (e) {
      message = 'No se pudo leer la letra: $e';
      notifyListeners();
    }
  }

  Future<void> toggleShuffle() async {
    shuffled = !shuffled;
    await player.setShuffle(shuffled);
    notifyListeners();
  }

  Future<void> toggleRepeat() async {
    repeat = switch (repeat) {
      PlaylistMode.none => PlaylistMode.loop,
      PlaylistMode.loop => PlaylistMode.single,
      _ => PlaylistMode.none,
    };
    await player.setPlaylistMode(repeat);
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    player.dispose();
    super.dispose();
  }
}

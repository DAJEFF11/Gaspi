import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:gaspi/app.dart';
import 'package:gaspi/library.dart';

class QuietStreams implements PlayerStream {
  @override
  Stream<Playlist> get playlist => const Stream.empty();
  @override
  Stream<String> get error => const Stream.empty();
  @override
  Stream<bool> get playing => const Stream.empty();
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration> get duration => const Stream.empty();
  @override
  Stream<double> get volume => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class QuietPlayer implements Player {
  @override
  final PlayerStream stream = QuietStreams();
  @override
  final PlayerState state = const PlayerState(
    playing: true,
    position: Duration(seconds: 71),
    duration: Duration(seconds: 230),
  );
  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var errors = 0;
  FlutterError.onError = (details) {
    errors++;
    stderr.writeln(details.toString());
  };
  final font = FontLoader('MaterialIcons')
    ..addFont(
      File(
        'C:/src/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then((b) => ByteData.sublistView(b)),
    );
  await font.load();
  final lib = MusicLibrary(audioPlayer: QuietPlayer())..ready = true;
  final titles = [
    'A little closer',
    'Somewhere, slowly',
    'The quiet side',
    'After the rain',
    'Nothing to rush',
    'Stay for a while',
  ];
  final artists = [
    'Nora Wells',
    'Miles Avery',
    'Sora',
    'Nora Wells',
    'The Others',
    'Miles Avery',
  ];
  for (var i = 0; i < titles.length; i++) {
    lib.songs.add(
      Song(
        'demo-$i.flac',
        titles[i],
        artists[i],
        i % 2 == 0 ? 'Quiet days' : 'Small hours',
        230000,
        null,
        '[00:01]A moment just for you\n[01:10]Nothing to rush, nowhere to go',
      ),
    );
  }
  lib.currentPath = lib.songs[1].path;
  lib.favorites.add(lib.songs[1].path);
  lib.playlists['Quiet mornings'] = [lib.songs[0].path, lib.songs[1].path];
  Future<void> capture(
    String name,
    Size size,
    bool dark, {
    bool player = false,
  }) async {
    lib.dark = dark;
    final key = GlobalKey();
    runApp(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OverflowBox(
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: RepaintBoundary(
              key: key,
              child: MediaQuery(
                data: MediaQueryData(size: size, devicePixelRatio: 1),
                child: GaspiApp(
                  key: ValueKey(name),
                  library: lib,
                  initialPlayerView: player,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('previews/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    stdout.writeln('CAPTURE $name');
  }

  await capture('gaspi-mobile-light', const Size(390, 844), false);
  await capture('gaspi-mobile-dark', const Size(390, 844), true);
  await capture('gaspi-desktop-light', const Size(1440, 900), false);
  await capture('gaspi-desktop-dark', const Size(1440, 900), true);
  await capture(
    'gaspi-desktop-player',
    const Size(1440, 900),
    true,
    player: true,
  );
  await capture(
    'gaspi-mobile-player',
    const Size(390, 844),
    false,
    player: true,
  );
  await capture('gaspi-mobile-small', const Size(320, 640), true);
  await capture('gaspi-desktop-small', const Size(1024, 640), false);
  await capture(
    'gaspi-mobile-player-small',
    const Size(320, 640),
    true,
    player: true,
  );
  stdout.writeln('LAYOUT_ERRORS $errors');
  exit(errors == 0 ? 0 : 1);
}

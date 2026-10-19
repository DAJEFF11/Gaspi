import 'dart:io';
import 'package:gaspi/models.dart';

void check(bool value, String name) {
  if (!value) {
    throw StateError(name);
  }
  stdout.writeln('PASS $name');
}

void main() {
  final lines = parseLrc(
    '[ar:Local]\n[offset:-100]\n[00:01.25][00:03.500]Hola\n[00:02]Mundo',
  );
  check(
    lines.map((l) => l.time.inMilliseconds).join(',') == '1150,1900,3400',
    'LRC repeated timestamps, ordering, fractions and offset',
  );
  check(
    lines.map((l) => l.text).join(',') == 'Hola,Mundo,Hola',
    'LRC text extraction',
  );
  check(parseLrc('Una letra\nsin tiempos').isEmpty, 'Plain lyrics');
  check(
    parseLrc('[offset:-5000]\n[00:01]Hola').single.time == Duration.zero,
    'Negative times clamp to zero',
  );
  final song = Song(
    'C:/music/test.flac',
    'Test',
    'Artist',
    'Album',
    42000,
    null,
    '[00:01]Hola',
  );
  final restored = Song.fromJson(song.toJson());
  check(
    restored.path == song.path &&
        restored.format == 'FLAC' &&
        restored.lyrics == song.lyrics &&
        restored.duration == 42000,
    'Library persistence round trip',
  );
}


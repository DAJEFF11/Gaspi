import 'package:flutter_test/flutter_test.dart';
import 'package:gaspi/library.dart';

void main() {
  test('LRC supports repeated timestamps, fractional seconds and offsets', () {
    final lines = parseLrc(
      '[ar:Local]\n[offset:-100]\n[00:01.25][00:03.500]Hola\n[00:02]Mundo',
    );
    expect(lines.map((l) => l.time.inMilliseconds), [1150, 1900, 3400]);
    expect(lines.map((l) => l.text), ['Hola', 'Mundo', 'Hola']);
  });
  test('Plain lyrics remain unsynchronized', () {
    expect(parseLrc('Una letra\nsin tiempos'), isEmpty);
  });
  test('Library records preserve lyrics and metadata', () {
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
    expect(restored.path, song.path);
    expect(restored.format, 'FLAC');
    expect(restored.lyrics, song.lyrics);
    expect(restored.duration, 42000);
  });
}


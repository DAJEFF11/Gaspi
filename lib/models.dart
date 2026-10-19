import 'package:path/path.dart' as p;

class Song {
  Song(
    this.path,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.cover,
    this.lyrics,
  );
  final String path, title, artist, album;
  final int duration;
  final String? cover;
  String lyrics;
  String get format => p.extension(path).replaceFirst('.', '').toUpperCase();
  Map<String, dynamic> toJson() => {
    'path': path,
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'cover': cover,
    'lyrics': lyrics,
  };
  factory Song.fromJson(Map<String, dynamic> j) => Song(
    j['path'],
    j['title'],
    j['artist'],
    j['album'],
    j['duration'] ?? 0,
    j['cover'],
    j['lyrics'] ?? '',
  );
}

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration time;
  final String text;
}

List<LyricLine> parseLrc(String input) {
  final result = <LyricLine>[];
  final stamp = RegExp(r'\[(\d+):(\d{2})(?:[.:](\d{1,3}))?\]');
  final offsetMatch = RegExp(r'\[offset:([+-]?\d+)\]').firstMatch(input);
  final offset = int.tryParse(offsetMatch?.group(1) ?? '') ?? 0;
  for (final line in input.split('\n')) {
    final matches = stamp.allMatches(line).toList();
    for (final m in matches) {
      final fraction = (m.group(3) ?? '').padRight(3, '0');
      final ms =
          int.parse(m.group(1)!) * 60000 +
          int.parse(m.group(2)!) * 1000 +
          int.parse(fraction) +
          offset;
      result.add(
        LyricLine(
          Duration(milliseconds: ms < 0 ? 0 : ms),
          line.substring(matches.last.end).trim(),
        ),
      );
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}

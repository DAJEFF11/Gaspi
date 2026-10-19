import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'ghost.dart';
import 'library.dart';

String clock(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
ThemeData gaspiTheme(bool dark) {
  final fg = dark ? const Color(0xFFF3F3F3) : const Color(0xFF101010);
  final bg = dark ? const Color(0xFF080808) : const Color(0xFFFAFAFA);
  final scheme = ColorScheme(
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: fg,
    onPrimary: bg,
    secondary: fg,
    onSecondary: bg,
    error: const Color(0xFFCC5050),
    onError: bg,
    surface: dark ? const Color(0xFF111111) : Colors.white,
    onSurface: fg,
    onSurfaceVariant: dark ? const Color(0xFF969696) : const Color(0xFF85858D),
    outline: dark ? const Color(0xFF303030) : const Color(0xFFE5E5E8),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    fontFamily: Platform.isWindows ? 'Segoe UI' : null,
    dividerColor: scheme.outline,
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: bg,
      indicatorColor: fg.withValues(alpha: .07),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: fg, size: 22)),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(color: fg, fontSize: 10),
      ),
      height: 68,
    ),
    sliderTheme: SliderThemeData(
      trackHeight: 3,
      activeTrackColor: fg,
      inactiveTrackColor: fg.withValues(alpha: .14),
      thumbColor: fg,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: fg,
        foregroundColor: bg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      hintStyle: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide(color: scheme.outline),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
  );
}

class GaspiApp extends StatelessWidget {
  const GaspiApp({
    super.key,
    required this.library,
    this.initialPlayerView = false,
  });
  final MusicLibrary library;
  final bool initialPlayerView;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: library,
    builder: (_, _) => MaterialApp(
      title: 'Gaspi',
      debugShowCheckedModeBanner: false,
      theme: gaspiTheme(false),
      darkTheme: gaspiTheme(true),
      themeMode: library.dark ? ThemeMode.dark : ThemeMode.light,
      home: LibraryScreen(
        library: library,
        initialPlayerView: initialPlayerView,
      ),
    ),
  );
}

class Cover extends StatelessWidget {
  const Cover(
    this.song, {
    super.key,
    this.size = 48,
    this.radius = 9,
    this.monochrome = false,
  });
  final Song? song;
  final double size, radius;
  final bool monochrome;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.onSurface.withValues(alpha: .12),
            cs.onSurface.withValues(alpha: .025),
          ],
        ),
      ),
      child: Center(child: GhostMark(size: size * .5, animated: false)),
    );
    Widget content = song?.cover == null
        ? fallback
        : Image.file(
            File(song!.cover!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => fallback,
          );
    if (monochrome && song?.cover != null) {
      content = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          .2126,
          .7152,
          .0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: content,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    required this.library,
    this.initialPlayerView = false,
  });
  final MusicLibrary library;
  final bool initialPlayerView;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  MusicLibrary get lib => widget.library;
  ColorScheme get cs => focusPlayer
      ? gaspiTheme(true).colorScheme
      : Theme.of(context).colorScheme;
  String section = 'Biblioteca',
      category = 'Canciones',
      query = '',
      sort = 'Recientes';
  String? group;
  bool searchOpen = false,
      focusPlayer = false,
      showLyrics = false,
      showQueue = false;
  final search = TextEditingController();
  @override
  void initState() {
    super.initState();
    focusPlayer = widget.initialPlayerView;
    lib.addListener(changed);
  }

  void changed() {
    if (!mounted) {
      return;
    }
    setState(() {});
    if (lib.message != null) {
      final message = lib.message!;
      lib.message = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      });
    }
  }

  @override
  void dispose() {
    lib.removeListener(changed);
    search.dispose();
    super.dispose();
  }

  List<Song> get tracks {
    final result = lib.songs.where((s) {
      final belongs = section == 'Favoritos'
          ? lib.favorites.contains(s.path)
          : section.startsWith('playlist:')
          ? (lib.playlists[section.substring(9)] ?? []).contains(s.path)
          : true;
      return belongs &&
          (group == null ||
              (category == 'Artistas'
                  ? s.artist == group
                  : s.album == group)) &&
          '${s.title} ${s.artist} ${s.album} ${s.format}'
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();
    if (sort == 'Título') {
      result.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    } else if (sort == 'Artista') {
      result.sort(
        (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
      );
    } else {
      return result.reversed.toList();
    }
    return result;
  }

  String get heading =>
      group ??
      (section.startsWith('playlist:')
          ? section.substring(9)
          : section == 'Biblioteca'
          ? 'Explorar'
          : section);
  void navigate(String v) => setState(() {
    section = v;
    group = null;
    showLyrics = false;
    showQueue = false;
    query = '';
    search.clear();
  });
  Future<void> newPlaylist() async {
    var name = '';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva playlist'),
        content: TextField(
          autofocus: true,
          maxLength: 60,
          onChanged: (v) => name = v,
          onSubmitted: (v) => Navigator.pop(ctx, v),
          decoration: const InputDecoration(
            hintText: 'Un nombre para tu colección',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, name),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await lib.createPlaylist(result);
      if (mounted) {
        navigate('playlist:${result.trim()}');
      }
    }
  }

  Future<void> toggleFocus() async {
    final next = !focusPlayer;
    if (Platform.isWindows) {
      try {
        await windowManager.setFullScreen(next);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo cambiar el modo de ventana. La vista de reproducción está disponible.',
              ),
            ),
          );
        }
      }
    }
    if (mounted) {
      setState(() {
        focusPlayer = next;
        showLyrics = false;
        showQueue = false;
      });
    }
  }

  Widget themeButton() => IconButton(
    tooltip: lib.dark ? 'Cambiar a modo claro' : 'Cambiar a negro mate',
    onPressed: lib.toggleTheme,
    icon: Icon(
      lib.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      size: 21,
    ),
  );
  Widget importButton() => PopupMenuButton<String>(
    tooltip: 'Añadir música',
    icon: const Icon(Icons.add_rounded),
    onSelected: (v) => lib.importFiles(folder: v == 'folder'),
    itemBuilder: (_) => [
      const PopupMenuItem(value: 'files', child: Text('Añadir canciones')),
      if (Platform.isWindows)
        const PopupMenuItem(value: 'folder', child: Text('Añadir carpeta')),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 940;
    if (focusPlayer) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): toggleFocus,
        },
        child: Focus(autofocus: true, child: fullPlayer(wide)),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (wide) sidebar(),
                  Expanded(
                    child: Column(
                      children: [
                        header(wide),
                        if (lib.importing)
                          LinearProgressIndicator(
                            minHeight: 2,
                            color: cs.onSurface,
                          ),
                        Expanded(
                          child: !lib.ready
                              ? const Center(child: CircularProgressIndicator())
                              : showLyrics
                              ? lyricsPanel()
                              : showQueue
                              ? queuePanel()
                              : section == 'Playlists'
                              ? playlistPanel()
                              : collection(wide),
                        ),
                      ],
                    ),
                  ),
                  if (wide && lib.current != null)
                    SizedBox(width: 278, child: sidePlayer()),
                ],
              ),
            ),
            miniPlayer(wide),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: section == 'Favoritos'
                  ? 1
                  : section == 'Playlists' || section.startsWith('playlist:')
                  ? 2
                  : 0,
              onDestinationSelected: (i) =>
                  navigate(['Biblioteca', 'Favoritos', 'Playlists'][i]),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_outlined),
                  selectedIcon: Icon(Icons.grid_view_rounded),
                  label: 'Explorar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.favorite_border),
                  selectedIcon: Icon(Icons.favorite),
                  label: 'Favoritos',
                ),
                NavigationDestination(
                  icon: Icon(Icons.queue_music),
                  label: 'Playlists',
                ),
              ],
            ),
    );
  }

  Widget sidebar() => Container(
    width: 220,
    padding: const EdgeInsets.fromLTRB(23, 27, 18, 22),
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border(
        right: BorderSide(color: cs.outline.withValues(alpha: .6)),
      ),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              GhostMark(size: 39),
              SizedBox(width: 8),
              Text(
                'Gaspi',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 41),
          nav(Icons.grid_view_outlined, 'Explorar', 'Biblioteca'),
          nav(Icons.favorite_border, 'Favoritos', 'Favoritos'),
          nav(Icons.queue_music, 'Playlists', 'Playlists'),
          const SizedBox(height: 29),
          Row(
            children: [
              Expanded(
                child: Text(
                  'TU COLECCIÓN',
                  style: TextStyle(
                    fontSize: 9,
                    letterSpacing: 1.5,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Crear playlist',
                onPressed: newPlaylist,
                icon: const Icon(Icons.add, size: 18),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              children: lib.playlists.keys
                  .map((n) => nav(Icons.music_note_outlined, n, 'playlist:$n'))
                  .toList(),
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.offline_pin_outlined,
                size: 15,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 7),
              Text(
                'Solo música local',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  Widget nav(IconData icon, String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      selected: section == value,
      selectedTileColor: cs.onSurface.withValues(alpha: .055),
      selectedColor: cs.onSurface,
      leading: Icon(icon, size: 20),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () => navigate(value),
    ),
  );
  Widget header(bool wide) => Padding(
    padding: EdgeInsets.fromLTRB(wide ? 36 : 18, 17, wide ? 28 : 12, 8),
    child: Row(
      children: [
        if (!wide && !searchOpen) ...[
          const GhostMark(size: 30),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Gaspi',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        if (wide || searchOpen)
          Expanded(
            child: TextField(
              controller: search,
              autofocus: !wide,
              onChanged: (v) => setState(() => query = v),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Busca en tu música',
                isDense: true,
              ),
            ),
          ),
        if (!wide)
          IconButton(
            tooltip: searchOpen ? 'Cerrar búsqueda' : 'Buscar',
            onPressed: () => setState(() {
              searchOpen = !searchOpen;
              if (!searchOpen) {
                query = '';
                search.clear();
              }
            }),
            icon: Icon(searchOpen ? Icons.close : Icons.search, size: 22),
          ),
        themeButton(),
        importButton(),
      ],
    ),
  );
  Widget collection(bool wide) {
    final list = tracks;
    final groups = <String, List<Song>>{};
    for (final s in list) {
      groups
          .putIfAbsent(category == 'Artistas' ? s.artist : s.album, () => [])
          .add(s);
    }
    final grouped =
        section == 'Biblioteca' && category != 'Canciones' && group == null;
    final pad = wide ? 38.0 : 24.0;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 22, pad, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group != null || section.startsWith('playlist:'))
                  IconButton(
                    tooltip: 'Volver',
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => setState(() {
                      if (group != null) {
                        group = null;
                      } else {
                        section = 'Playlists';
                      }
                    }),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                Text(
                  heading,
                  style: TextStyle(
                    fontSize: wide ? 37 : 29,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 12),
                if (section == 'Biblioteca' && group == null)
                  Row(
                    children: ['Canciones', 'Álbumes', 'Artistas']
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(right: 25),
                            child: InkWell(
                              onTap: () => setState(() => category = name),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: category == name
                                            ? cs.onSurface
                                            : cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      width: 28,
                                      height: 2,
                                      color: category == name
                                          ? cs.onSurface
                                          : Colors.transparent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                if (list.isNotEmpty &&
                    !grouped &&
                    query.isEmpty &&
                    section == 'Biblioteca' &&
                    group == null) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    height: wide ? 190 : 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length.clamp(0, 10),
                      separatorBuilder: (_, _) => const SizedBox(width: 15),
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => lib.play(list, list[i]),
                        child: SizedBox(
                          width: wide ? 136 : 116,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Cover(
                                list[i],
                                size: wide ? 136 : 116,
                                monochrome: true,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                list[i].title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                list[i].artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (list.isNotEmpty && !grouped) ...[
                  if (group != null || section != 'Biblioteca') ...[
                    const SizedBox(height: 10),
                    Text(
                      '${list.length} canciones · En tu dispositivo',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 23),
                    SizedBox(
                      width: wide ? 250 : double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          await lib.play(list, list.first);
                          if (!lib.shuffled) {
                            await lib.toggleShuffle();
                          }
                        },
                        icon: const Icon(Icons.shuffle, size: 18),
                        label: const Text(
                          'Reproducción aleatoria',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                  ],
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Canciones',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      DropdownButton<String>(
                        value: sort,
                        underline: const SizedBox.shrink(),
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        items: ['Recientes', 'Título', 'Artista']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => sort = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: emptyState()),
        if (grouped)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 22, pad, 30),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 210,
                mainAxisSpacing: 20,
                crossAxisSpacing: 18,
                childAspectRatio: .76,
              ),
              itemCount: groups.length,
              itemBuilder: (_, i) {
                final name = groups.keys.elementAt(i);
                final songs = groups[name]!;
                return LayoutBuilder(
                  builder: (_, box) => InkWell(
                    onTap: () => setState(() => group = name),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Cover(
                          songs.first,
                          size: box.maxWidth,
                          radius: category == 'Artistas'
                              ? box.maxWidth / 2
                              : 10,
                          monochrome: true,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${songs.length} canciones',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        if (!grouped)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(wide ? 27 : 14, 0, wide ? 27 : 14, 30),
            sliver: SliverList.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => songRow(list[i], i, list, wide),
            ),
          ),
      ],
    );
  }

  Widget emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const GhostMark(size: 88),
          const SizedBox(height: 22),
          Text(
            query.isNotEmpty
                ? 'Ninguna coincidencia'
                : section == 'Biblioteca'
                ? 'Un hogar para tu música'
                : 'Tu colección empieza aquí',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            query.isNotEmpty
                ? 'Busca otro título, artista o álbum.'
                : section == 'Biblioteca'
                ? 'Tus archivos. Tus canciones. Sin ruido.\nMP3, FLAC, WAV y muchos más.'
                : 'Añade canciones desde el corazón\no el menú de tu biblioteca.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.8,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          if (section == 'Biblioteca' && query.isEmpty)
            FilledButton.icon(
              onPressed: lib.importing ? null : () => lib.importFiles(),
              icon: const Icon(Icons.add, size: 19),
              label: const Text('Añadir mi música'),
            ),
        ],
      ),
    ),
  );
  Widget songRow(Song song, int i, List<Song> list, bool wide) {
    final active = song.path == lib.currentPath;
    final fg = active ? cs.onPrimary : cs.onSurface;
    final sub = active
        ? cs.onPrimary.withValues(alpha: .65)
        : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: active ? cs.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => lib.play(list, song),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 3, 9),
            child: Row(
              children: [
                if (wide || group != null) ...[
                  SizedBox(
                    width: 25,
                    child: Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: TextStyle(color: fg, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Cover(song, size: 43, radius: 7, monochrome: true),
                const SizedBox(width: 14),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: fg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: sub),
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  Expanded(
                    flex: 2,
                    child: Text(
                      song.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: sub),
                    ),
                  ),
                  SizedBox(
                    width: 47,
                    child: Text(
                      song.format,
                      style: TextStyle(fontSize: 8, color: sub),
                    ),
                  ),
                  SizedBox(
                    width: 43,
                    child: Text(
                      song.duration > 0
                          ? clock(Duration(milliseconds: song.duration))
                          : '—',
                      style: TextStyle(fontSize: 10, color: sub),
                    ),
                  ),
                ],
                if (active)
                  StreamBuilder<bool>(
                    stream: lib.player.stream.playing,
                    initialData: lib.player.state.playing,
                    builder: (_, snap) => IconButton(
                      tooltip: snap.data == true ? 'Pausar' : 'Reproducir',
                      onPressed: lib.player.playOrPause,
                      icon: Icon(
                        snap.data == true ? Icons.pause : Icons.play_arrow,
                        size: 17,
                        color: fg,
                      ),
                    ),
                  )
                else if (wide)
                  IconButton(
                    tooltip: 'Favorito',
                    onPressed: () => lib.favorite(song),
                    icon: Icon(
                      lib.favorites.contains(song.path)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      size: 17,
                      color: sub,
                    ),
                  ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones',
                  icon: Icon(Icons.more_vert, size: 17, color: sub),
                  onSelected: (v) async {
                    if (v == 'fav') {
                      await lib.favorite(song);
                    } else if (v == 'remove') {
                      await lib.remove(song);
                    } else if (v == 'unlist') {
                      lib.playlists[section.substring(9)]?.remove(song.path);
                      await lib.save();
                      if (mounted) {
                        setState(() {});
                      }
                    } else {
                      await lib.addToPlaylist(v.substring(4), song);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'fav',
                      child: Text(
                        lib.favorites.contains(song.path)
                            ? 'Quitar de favoritos'
                            : 'Añadir a favoritos',
                      ),
                    ),
                    for (final name in lib.playlists.keys)
                      PopupMenuItem(
                        value: 'add:$name',
                        child: Text('Añadir a $name'),
                      ),
                    if (section.startsWith('playlist:'))
                      const PopupMenuItem(
                        value: 'unlist',
                        child: Text('Quitar de esta playlist'),
                      ),
                    const PopupMenuItem(
                      value: 'remove',
                      child: Text('Quitar de la biblioteca'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget playlistPanel() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Playlists',
                style: TextStyle(fontSize: 29, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: 'Crear playlist',
              onPressed: newPlaylist,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: lib.playlists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GhostMark(size: 75),
                      const SizedBox(height: 16),
                      const Text('Cada momento tiene su música.'),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: newPlaylist,
                        child: const Text('Crear playlist'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: lib.playlists.entries.map((entry) {
                    final matching = lib.songs
                        .where((s) => entry.value.contains(s.path))
                        .toList();
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 7),
                      leading: Cover(matching.firstOrNull),
                      title: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${matching.length} canciones',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () => navigate('playlist:${entry.key}'),
                    );
                  }).toList(),
                ),
        ),
      ],
    ),
  );
  Widget sidePlayer() => Container(
    margin: const EdgeInsets.fromLTRB(8, 22, 22, 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: cs.outline.withValues(alpha: .65)),
    ),
    child: Material(
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'AHORA SUENA',
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 9,
                      letterSpacing: 1.7,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Pantalla completa',
                  onPressed: toggleFocus,
                  icon: const Icon(Icons.open_in_full, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Cover(lib.current, size: 208, radius: 12),
            const SizedBox(height: 22),
            Text(
              lib.current!.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                letterSpacing: -.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lib.current!.artist,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 17),
            Text(
              '${lib.current!.format} · LOCAL',
              style: TextStyle(
                fontSize: 9,
                color: cs.onSurfaceVariant,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lyrics_outlined, size: 19),
              title: const Text('Letra', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, size: 17),
              onTap: () => setState(() {
                showLyrics = !showLyrics;
                showQueue = false;
              }),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.queue_music, size: 19),
              title: const Text(
                'A continuación',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right, size: 17),
              onTap: () => setState(() {
                showQueue = !showQueue;
                showLyrics = false;
              }),
            ),
          ],
        ),
      ),
    ),
  );
  Widget playButton({double size = 24, bool plain = false}) =>
      StreamBuilder<bool>(
        stream: lib.player.stream.playing,
        initialData: lib.player.state.playing,
        builder: (_, snap) => plain
            ? IconButton(
                tooltip: snap.data == true ? 'Pausar' : 'Reproducir',
                onPressed: lib.current == null ? null : lib.player.playOrPause,
                iconSize: size,
                icon: Icon(
                  snap.data == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              )
            : IconButton.filled(
                tooltip: snap.data == true ? 'Pausar' : 'Reproducir',
                onPressed: lib.current == null ? null : lib.player.playOrPause,
                iconSize: size,
                icon: Icon(
                  snap.data == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
      );
  Widget progress({bool times = true}) => StreamBuilder<Duration>(
    stream: lib.player.stream.duration,
    initialData: lib.player.state.duration,
    builder: (_, duration) => StreamBuilder<Duration>(
      stream: lib.player.stream.position,
      initialData: lib.player.state.position,
      builder: (_, position) {
        final max = (duration.data?.inMilliseconds ?? 0).toDouble();
        final value = (position.data?.inMilliseconds ?? 0)
            .toDouble()
            .clamp(0, max > 0 ? max : 1)
            .toDouble();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 22,
              child: Slider(
                value: value,
                max: max > 0 ? max : 1,
                onChanged: max > 0
                    ? (v) => lib.player.seek(Duration(milliseconds: v.round()))
                    : null,
              ),
            ),
            if (times)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    clock(position.data ?? Duration.zero),
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    clock(duration.data ?? Duration.zero),
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
          ],
        );
      },
    ),
  );
  Widget volume() => StreamBuilder<double>(
    stream: lib.player.stream.volume,
    initialData: lib.player.state.volume,
    builder: (_, snap) => Row(
      children: [
        const Icon(Icons.volume_down_outlined, size: 18),
        Expanded(
          child: Slider(
            value: (snap.data ?? 100).clamp(0, 100),
            max: 100,
            onChanged: lib.player.setVolume,
          ),
        ),
        const Icon(Icons.volume_up_outlined, size: 18),
      ],
    ),
  );
  Widget miniPlayer(bool wide) => Container(
    decoration: BoxDecoration(
      color: cs.surface,
      border: Border(top: BorderSide(color: cs.outline.withValues(alpha: .7))),
    ),
    padding: EdgeInsets.fromLTRB(
      wide ? 26 : 18,
      wide ? 10 : 4,
      wide ? 26 : 10,
      wide ? 9 : 0,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (wide || lib.current != null) ...[
              Cover(lib.current, size: wide ? 44 : 36, radius: 7),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: lib.current == null ? null : toggleFocus,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lib.current?.title ?? 'Tu música, a tu ritmo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lib.current?.artist ?? 'Añade canciones para empezar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide)
              IconButton(
                tooltip: 'Aleatorio',
                onPressed: lib.toggleShuffle,
                icon: Icon(
                  Icons.shuffle,
                  size: 18,
                  color: lib.shuffled ? cs.onSurface : cs.onSurfaceVariant,
                ),
              ),
            if (wide)
              IconButton(
                tooltip: 'Anterior',
                onPressed: lib.current == null ? null : lib.player.previous,
                icon: const Icon(Icons.skip_previous_rounded),
              ),
            playButton(size: 25, plain: !wide),
            IconButton(
              tooltip: 'Siguiente',
              onPressed: lib.current == null ? null : lib.player.next,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            if (wide) ...[
              IconButton(
                tooltip: 'Repetir',
                onPressed: lib.toggleRepeat,
                icon: Icon(
                  lib.repeat == PlaylistMode.single
                      ? Icons.repeat_one
                      : Icons.repeat,
                  size: 18,
                  color: lib.repeat == PlaylistMode.none
                      ? cs.onSurfaceVariant
                      : cs.onSurface,
                ),
              ),
              const Spacer(flex: 1),
              IconButton(
                tooltip: 'Cola',
                onPressed: () => setState(() {
                  showQueue = !showQueue;
                  showLyrics = false;
                }),
                icon: const Icon(Icons.queue_music, size: 20),
              ),
              SizedBox(width: 125, child: volume()),
              IconButton(
                tooltip: 'Pantalla completa',
                onPressed: lib.current == null ? null : toggleFocus,
                icon: const Icon(Icons.open_in_full, size: 18),
              ),
            ],
          ],
        ),
        if (wide)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 740),
            child: progress(),
          )
        else
          progress(times: false),
      ],
    ),
  );
  Widget lyricsPanel() {
    final song = lib.current;
    final lines = parseLrc(song?.lyrics ?? '');
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 15, 18, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: () => setState(() => showLyrics = false),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              const Expanded(
                child: Text(
                  'Letra',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
              TextButton.icon(
                onPressed: song == null ? null : lib.loadLyrics,
                icon: const Icon(Icons.upload_file, size: 17),
                label: const Text('Cargar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: song == null || song.lyrics.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const GhostMark(size: 70),
                        const SizedBox(height: 20),
                        const Text(
                          'Ponle palabras a tu música.',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Carga un archivo .lrc o .txt.\nLas letras se guardan solo en este dispositivo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : lines.isEmpty
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: Text(
                    song.lyrics,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      height: 1.8,
                    ),
                  ),
                )
              : StreamBuilder<Duration>(
                  stream: lib.player.stream.position,
                  initialData: lib.player.state.position,
                  builder: (_, snapshot) {
                    final active = lines.lastIndexWhere(
                      (l) => l.time <= (snapshot.data ?? Duration.zero),
                    );
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(30, 24, 30, 80),
                      itemCount: lines.length,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => lib.player.seek(lines[i].time),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            lines[i].text,
                            style: TextStyle(
                              fontSize: 27,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                              color: i == active
                                  ? cs.onSurface
                                  : cs.onSurfaceVariant.withValues(alpha: .55),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget queuePanel() => Column(
    children: [
      ListTile(
        leading: IconButton(
          tooltip: 'Volver',
          onPressed: () => setState(() => showQueue = false),
          icon: const Icon(Icons.arrow_back_ios_new, size: 17),
        ),
        title: const Text(
          'A continuación',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
      ),
      Expanded(
        child: StreamBuilder<Playlist>(
          stream: lib.player.stream.playlist,
          initialData: lib.player.state.playlist,
          builder: (_, snap) {
            final list = snap.data ?? const Playlist([]);
            return list.medias.isEmpty
                ? const Center(child: Text('Elige una canción para empezar.'))
                : ListView.builder(
                    itemCount: list.medias.length,
                    itemBuilder: (_, i) => ListTile(
                      selected: i == list.index,
                      selectedTileColor: cs.onSurface.withValues(alpha: .05),
                      leading: Text('${i + 1}'.padLeft(2, '0')),
                      title: Text(
                        list.medias[i].extras?['title'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        list.medias[i].extras?['artist'] ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: i == list.index
                          ? const Icon(Icons.graphic_eq, size: 18)
                          : null,
                      onTap: () => lib.player.jump(i),
                    ),
                  );
          },
        ),
      ),
    ],
  );
  Widget fullPlayer(bool wide) {
    final song = lib.current;
    final isDark = lib.dark;
    return Theme(
      data: gaspiTheme(true),
      child: Builder(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFF0B0B0B),
          body: Stack(
            fit: StackFit.expand,
            children: [
              if (song?.cover != null)
                ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                  child: Opacity(
                    opacity: isDark ? .18 : .42,
                    child: Image.file(
                      File(song!.cover!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: .05),
                      Colors.black.withValues(alpha: isDark ? .72 : .5),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Volver · Esc',
                            onPressed: toggleFocus,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          ),
                          const Spacer(),
                          const GhostMark(size: 25),
                          const SizedBox(width: 6),
                          const Text(
                            'Gaspi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Cambiar tema',
                            onPressed: lib.toggleTheme,
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: showLyrics || showQueue
                          ? Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 850,
                                ),
                                child: showLyrics
                                    ? lyricsPanel()
                                    : queuePanel(),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (_, box) {
                                final width = box.maxWidth;
                                final height = box.maxHeight;
                                if (wide && height > 440) {
                                  final coverSize = math
                                      .min(height - 115, width * .39)
                                      .clamp(230.0, 640.0)
                                      .toDouble();
                                  return Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: width * .075,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Cover(
                                            song,
                                            size: coverSize,
                                            radius: 10,
                                          ),
                                          SizedBox(width: width * .055),
                                          Expanded(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 600,
                                              ),
                                              child: fullControls(song, true),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                final coverSize = math
                                    .min(width - 64, height * .43)
                                    .clamp(100.0, 390.0)
                                    .toDouble();
                                return SingleChildScrollView(
                                  padding: const EdgeInsets.fromLTRB(
                                    30,
                                    15,
                                    30,
                                    24,
                                  ),
                                  child: Column(
                                    children: [
                                      Cover(song, size: coverSize, radius: 12),
                                      const SizedBox(height: 25),
                                      fullControls(song, false),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: () => setState(() {
                              showLyrics = !showLyrics;
                              showQueue = false;
                            }),
                            icon: const Icon(Icons.lyrics_outlined, size: 20),
                            label: const Text('Letra'),
                          ),
                          const SizedBox(width: 18),
                          const Icon(Icons.headphones_outlined, size: 19),
                          const SizedBox(width: 7),
                          const Text(
                            'Este dispositivo',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 18),
                          IconButton(
                            tooltip: 'Cola de reproducción',
                            onPressed: () => setState(() {
                              showQueue = !showQueue;
                              showLyrics = false;
                            }),
                            icon: const Icon(Icons.queue_music_rounded),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget fullControls(Song? song, bool wide) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        section.startsWith('playlist:')
            ? 'DESDE ${section.substring(9).toUpperCase()}'
            : 'DESDE TU BIBLIOTECA',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 17),
      Row(
        children: [
          Expanded(
            child: Text(
              song?.title ?? 'Elige tu próxima canción',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: wide ? 27 : 23,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Favorito',
            onPressed: song == null ? null : () => lib.favorite(song),
            icon: Icon(
              song != null && lib.favorites.contains(song.path)
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 21,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      Text(
        song?.artist ?? 'Gaspi',
        style: const TextStyle(fontSize: 14, color: Colors.white54),
      ),
      const SizedBox(height: 22),
      InkWell(
        onTap: () => setState(() => showLyrics = true),
        child: StreamBuilder<Duration>(
          stream: lib.player.stream.position,
          initialData: lib.player.state.position,
          builder: (_, snap) {
            final lines = parseLrc(song?.lyrics ?? '');
            final line = lines
                .where((l) => l.time <= (snap.data ?? Duration.zero))
                .lastOrNull;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    line?.text ??
                        (song?.lyrics.isNotEmpty == true
                            ? 'Ver la letra'
                            : 'Añade la letra de esta canción'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 17,
                  color: Colors.white54,
                ),
              ],
            );
          },
        ),
      ),
      SliderTheme(
        data: const SliderThemeData(
          activeTrackColor: Colors.white,
          thumbColor: Colors.white,
          inactiveTrackColor: Colors.white24,
          trackHeight: 3,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 3),
        ),
        child: progress(),
      ),
      const SizedBox(height: 17),
      IconTheme(
        data: const IconThemeData(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'Aleatorio',
              onPressed: lib.toggleShuffle,
              icon: Icon(
                Icons.shuffle,
                size: 18,
                color: lib.shuffled ? Colors.white : Colors.white38,
              ),
            ),
            IconButton(
              tooltip: 'Anterior',
              onPressed: song == null ? null : lib.player.previous,
              icon: Icon(Icons.fast_rewind_rounded, size: wide ? 43 : 34),
            ),
            playButton(size: wide ? 48 : 40, plain: true),
            IconButton(
              tooltip: 'Siguiente',
              onPressed: song == null ? null : lib.player.next,
              icon: Icon(Icons.fast_forward_rounded, size: wide ? 43 : 34),
            ),
            IconButton(
              tooltip: 'Repetir',
              onPressed: lib.toggleRepeat,
              icon: Icon(
                lib.repeat == PlaylistMode.single
                    ? Icons.repeat_one
                    : Icons.repeat,
                size: 18,
                color: lib.repeat == PlaylistMode.none
                    ? Colors.white38
                    : Colors.white,
              ),
            ),
          ],
        ),
      ),
      if (wide) ...[
        const SizedBox(height: 24),
        IconTheme(
          data: const IconThemeData(color: Colors.white60),
          child: SliderTheme(
            data: const SliderThemeData(
              activeTrackColor: Colors.white,
              thumbColor: Colors.white,
              inactiveTrackColor: Colors.white24,
            ),
            child: volume(),
          ),
        ),
      ],
    ],
  );
}

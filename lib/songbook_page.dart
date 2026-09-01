import 'dart:async';

import 'package:flutter/material.dart';

import 'design_system.dart';
import 'midi_song.dart';
import 'piano_controller.dart';
import 'sheet_music.dart';
import 'song_metadata_service.dart';

class SongbookPage extends StatefulWidget {
  const SongbookPage({
    super.key,
    required this.controller,
    required this.openPractice,
  });

  final PianoController controller;
  final VoidCallback openPractice;

  @override
  State<SongbookPage> createState() => _SongbookPageState();
}

class _SongbookPageState extends State<SongbookPage> {
  MidiSong? selected;
  int scorePage = 0;

  Future<void> _import() async {
    final song = await widget.controller.importMidi();
    if (!mounted || song == null) return;
    setState(() {
      selected = song;
      scorePage = 0;
    });
    await showSongMetadataEditor(
      context,
      widget.controller,
      song,
      searchOnline: true,
    );
    if (mounted) {
      setState(() {
        selected = widget.controller.songs.firstWhere(
          (item) => item.id == song.id,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final songs = widget.controller.songs;
    selected ??=
        widget.controller.selectedSong ?? (songs.isEmpty ? null : songs.first);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= 1120;
          return Padding(
            padding: EdgeInsets.all(constraints.maxWidth < 600 ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SONGBOOK',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.primary,
                                letterSpacing: 2.4,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          'Scores from your MIDI library',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: _import,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add MIDI'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: split
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 330,
                              child: _SongGallery(
                                songs: songs,
                                selected: selected,
                                onSelect: _select,
                              ),
                            ),
                            const SizedBox(width: 22),
                            Expanded(
                              child: _ScoreDetail(
                                song: selected,
                                controller: widget.controller,
                                page: scorePage,
                                onPage: (value) =>
                                    setState(() => scorePage = value),
                                openPractice: widget.openPractice,
                                onEdited: _refreshSelected,
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          children: [
                            SizedBox(
                              height: 250,
                              child: _SongGallery(
                                songs: songs,
                                selected: selected,
                                onSelect: _select,
                                horizontal: true,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: constraints.maxHeight * .78,
                              child: _ScoreDetail(
                                song: selected,
                                controller: widget.controller,
                                page: scorePage,
                                onPage: (value) =>
                                    setState(() => scorePage = value),
                                openPractice: widget.openPractice,
                                onEdited: _refreshSelected,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _select(MidiSong song) {
    widget.controller.selectSong(song);
    setState(() {
      selected = song;
      scorePage = 0;
    });
  }

  void _refreshSelected() {
    final id = selected?.id;
    if (id == null) return;
    setState(
      () => selected = widget.controller.songs.firstWhere(
        (song) => song.id == id,
      ),
    );
  }
}

class _SongGallery extends StatelessWidget {
  const _SongGallery({
    required this.songs,
    required this.selected,
    required this.onSelect,
    this.horizontal = false,
  });
  final List<MidiSong> songs;
  final MidiSong? selected;
  final ValueChanged<MidiSong> onSelect;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text('Add a MIDI file to begin your Songbook.'),
      );
    }
    final list = ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      itemCount: songs.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12, height: 12),
      itemBuilder: (context, index) {
        final song = songs[index];
        return SizedBox(
          width: horizontal ? 220 : null,
          child: _SongbookCard(
            song: song,
            selected: selected?.id == song.id,
            onTap: () => onSelect(song),
          ),
        );
      },
    );
    return list;
  }
}

class _SongbookCard extends StatelessWidget {
  const _SongbookCard({
    required this.song,
    required this.selected,
    required this.onTap,
  });
  final MidiSong song;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final cover = song.coverArtUrl;
    return Material(
      color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 82,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.tertiary],
                  ),
                ),
                child: cover != null && cover.isNotEmpty
                    ? Image.network(
                        cover,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.music_note_rounded,
                          color: colors.onPrimary,
                          size: 32,
                        ),
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        color: readableForeground(colors.primary),
                        size: 32,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.composer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${song.keySignature}  ·  ${song.durationLabel}',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 11,
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
}

class _ScoreDetail extends StatefulWidget {
  const _ScoreDetail({
    required this.song,
    required this.controller,
    required this.page,
    required this.onPage,
    required this.openPractice,
    required this.onEdited,
  });
  final MidiSong? song;
  final PianoController controller;
  final int page;
  final ValueChanged<int> onPage;
  final VoidCallback openPractice;
  final VoidCallback onEdited;

  @override
  State<_ScoreDetail> createState() => _ScoreDetailState();
}

class _ScoreDetailState extends State<_ScoreDetail> {
  bool exporting = false;

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    if (song == null) return const Center(child: Text('Select a score.'));
    late final SheetMusicLayout scoreLayout;
    try {
      scoreLayout = SheetMusicLayout(song);
    } on FormatException catch (error) {
      return Center(
        child: Text(
          'This MIDI file cannot be transcribed.\n${error.message}',
          textAlign: TextAlign.center,
        ),
      );
    }
    final count = scoreLayout.pageCount;
    final page = widget.page.clamp(0, count - 1);
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              song.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await showSongMetadataEditor(context, widget.controller, song);
                widget.onEdited();
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit metadata'),
            ),
            FilledButton.tonalIcon(
              onPressed: exporting ? null : () => _export(song),
              icon: exporting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Export PDF'),
            ),
            FilledButton.icon(
              onPressed: widget.openPractice,
              icon: const Icon(Icons.piano_rounded),
              label: const Text('Practice'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Transcribed from MIDI · rhythm quantized to 1/16 · hand assignment inferred',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: InteractiveViewer(
              minScale: .7,
              maxScale: 4,
              child: Center(
                child: SheetMusicPage(song: song, pageIndex: page),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: page > 0 ? () => widget.onPage(page - 1) : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Text(
              'Page ${page + 1} of $count',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            IconButton(
              onPressed: page + 1 < count
                  ? () => widget.onPage(page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _export(MidiSong song) async {
    setState(() => exporting = true);
    try {
      final uri = await exportSheetMusicPdf(song);
      if (mounted && uri != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF exported to ${uri.toString()}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF export failed: $error')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }
}

Future<void> showSongMetadataEditor(
  BuildContext context,
  PianoController controller,
  MidiSong song, {
  bool searchOnline = false,
}) => showDialog<void>(
  context: context,
  builder: (_) => _SongMetadataDialog(
    controller: controller,
    song: song,
    autoSearch: searchOnline,
  ),
);

class _SongMetadataDialog extends StatefulWidget {
  const _SongMetadataDialog({
    required this.controller,
    required this.song,
    required this.autoSearch,
  });
  final PianoController controller;
  final MidiSong song;
  final bool autoSearch;

  @override
  State<_SongMetadataDialog> createState() => _SongMetadataDialogState();
}

class _SongMetadataDialogState extends State<_SongMetadataDialog> {
  late final TextEditingController title = TextEditingController(
    text: widget.song.title,
  );
  late final TextEditingController composer = TextEditingController(
    text: widget.song.composer,
  );
  late final TextEditingController collection = TextEditingController(
    text: widget.song.collection,
  );
  late final TextEditingController date = TextEditingController(
    text: widget.song.releaseDate,
  );
  late final TextEditingController genre = TextEditingController(
    text: widget.song.genre,
  );
  late final TextEditingController cover = TextEditingController(
    text: widget.song.coverArtUrl,
  );
  final service = SongMetadataService();
  List<OnlineSongMetadata> results = const [];
  bool searching = false;
  String? error;
  String? musicBrainzId;

  @override
  void initState() {
    super.initState();
    musicBrainzId = widget.song.musicBrainzId;
    if (widget.autoSearch) unawaited(_search());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Song metadata'),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 330,
                  child: TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                ),
                SizedBox(
                  width: 330,
                  child: TextField(
                    controller: composer,
                    decoration: const InputDecoration(
                      labelText: 'Composer or artist',
                    ),
                  ),
                ),
                SizedBox(
                  width: 330,
                  child: TextField(
                    controller: collection,
                    decoration: const InputDecoration(
                      labelText: 'Album or collection',
                    ),
                  ),
                ),
                SizedBox(
                  width: 155,
                  child: TextField(
                    controller: date,
                    decoration: const InputDecoration(
                      labelText: 'Release date',
                    ),
                  ),
                ),
                SizedBox(
                  width: 163,
                  child: TextField(
                    controller: genre,
                    decoration: const InputDecoration(labelText: 'Genre'),
                  ),
                ),
                SizedBox(
                  width: 672,
                  child: TextField(
                    controller: cover,
                    decoration: const InputDecoration(
                      labelText: 'Cover-art URL',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: searching ? null : _search,
                icon: searching
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.travel_explore_rounded),
                label: const Text('Find metadata and cover online'),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (results.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MusicBrainz matches',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              ...results.map(
                (result) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: SizedBox.square(
                    dimension: 48,
                    child: result.coverArtUrl == null
                        ? const Icon(Icons.album_rounded)
                        : Image.network(
                            result.coverArtUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const Icon(Icons.album_rounded),
                          ),
                  ),
                  title: Text(result.title),
                  subtitle: Text(
                    '${result.artist} · ${result.release}${result.releaseDate.isEmpty ? '' : ' · ${result.releaseDate}'}',
                  ),
                  trailing: Text('${result.score}%'),
                  onTap: () => _apply(result),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () async {
          await widget.controller.updateSongMetadata(
            widget.song,
            title: title.text,
            composer: composer.text,
            collection: collection.text,
            releaseDate: date.text,
            genre: genre.text,
            coverArtUrl: cover.text,
            musicBrainzId: musicBrainzId,
          );
          if (context.mounted) Navigator.pop(context);
        },
        child: const Text('Save'),
      ),
    ],
  );

  Future<void> _search() async {
    setState(() {
      searching = true;
      error = null;
    });
    try {
      final found = await service.search(
        title: title.text,
        artist: composer.text,
      );
      if (!mounted) return;
      setState(() {
        results = found;
        if (found.isEmpty) {
          error =
              'No close matches found. Try simplifying the title or artist.';
        }
      });
    } catch (value) {
      if (mounted) setState(() => error = 'Online lookup failed: $value');
    } finally {
      if (mounted) setState(() => searching = false);
    }
  }

  void _apply(OnlineSongMetadata result) {
    setState(() {
      title.text = result.title;
      composer.text = result.artist;
      collection.text = result.release;
      date.text = result.releaseDate;
      genre.text = result.genre;
      cover.text = result.coverArtUrl ?? '';
      musicBrainzId = result.musicBrainzId;
    });
  }

  @override
  void dispose() {
    title.dispose();
    composer.dispose();
    collection.dispose();
    date.dispose();
    genre.dispose();
    cover.dispose();
    super.dispose();
  }
}

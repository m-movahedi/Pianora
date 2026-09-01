import 'dart:typed_data';

class MidiEvent {
  const MidiEvent({
    required this.tick,
    required this.seconds,
    required this.data,
  });
  final int tick;
  final double seconds;
  final Uint8List data;
}

class MidiNote {
  const MidiNote({
    required this.note,
    required this.start,
    required this.end,
    required this.velocity,
    required this.channel,
  });
  final int note;
  final double start;
  final double end;
  final int velocity;
  final int channel;
}

class MidiSong {
  const MidiSong({
    required this.id,
    required this.title,
    required this.composer,
    required this.collection,
    required this.duration,
    required this.bpm,
    required this.timeSignature,
    required this.keySignature,
    required this.events,
    required this.notes,
    required this.bytes,
    this.assetPath,
    this.coverArtUrl,
    this.releaseDate,
    this.genre,
    this.musicBrainzId,
    this.isImported = false,
  });

  final String id;
  final String title;
  final String composer;
  final String collection;
  final double duration;
  final int bpm;
  final String timeSignature;
  final String keySignature;
  final List<MidiEvent> events;
  final List<MidiNote> notes;
  final Uint8List bytes;
  final String? assetPath;
  final String? coverArtUrl;
  final String? releaseDate;
  final String? genre;
  final String? musicBrainzId;
  final bool isImported;

  MidiSong copyWith({
    String? id,
    String? title,
    String? composer,
    String? collection,
    String? coverArtUrl,
    String? releaseDate,
    String? genre,
    String? musicBrainzId,
    bool? isImported,
  }) => MidiSong(
    id: id ?? this.id,
    title: title ?? this.title,
    composer: composer ?? this.composer,
    collection: collection ?? this.collection,
    duration: duration,
    bpm: bpm,
    timeSignature: timeSignature,
    keySignature: keySignature,
    events: events,
    notes: notes,
    bytes: bytes,
    assetPath: assetPath,
    coverArtUrl: coverArtUrl ?? this.coverArtUrl,
    releaseDate: releaseDate ?? this.releaseDate,
    genre: genre ?? this.genre,
    musicBrainzId: musicBrainzId ?? this.musicBrainzId,
    isImported: isImported ?? this.isImported,
  );

  String get difficulty => notes.length > 1800
      ? 'Advanced'
      : notes.length > 700
      ? 'Intermediate'
      : 'Beginner';
  String get durationLabel =>
      '${(duration ~/ 60)}:${(duration % 60).floor().toString().padLeft(2, '0')}';

  MidiSongAnalysis get analysis => MidiSongAnalysis.fromSong(this);
}

class SongSection {
  const SongSection({
    required this.name,
    required this.start,
    required this.end,
  });
  final String name;
  final double start;
  final double end;
}

class MidiSongAnalysis {
  const MidiSongAnalysis({
    required this.level,
    required this.score,
    required this.recommendedStartSpeed,
    required this.noteRange,
    required this.maximumPolyphony,
    required this.notesPerSecond,
    required this.skills,
    required this.prerequisites,
    required this.sections,
  });

  final String level;
  final int score;
  final double recommendedStartSpeed;
  final String noteRange;
  final int maximumPolyphony;
  final double notesPerSecond;
  final List<String> skills;
  final List<String> prerequisites;
  final List<SongSection> sections;

  factory MidiSongAnalysis.fromSong(MidiSong song) {
    if (song.notes.isEmpty) {
      return const MidiSongAnalysis(
        level: 'Unknown',
        score: 0,
        recommendedStartSpeed: .5,
        noteRange: '—',
        maximumPolyphony: 0,
        notesPerSecond: 0,
        skills: [],
        prerequisites: ['Basic keyboard orientation'],
        sections: [],
      );
    }
    final pitches = song.notes.map((note) => note.note).toList()..sort();
    final starts = <int, int>{};
    for (final note in song.notes) {
      final key = (note.start * 20).round();
      starts[key] = (starts[key] ?? 0) + 1;
    }
    final polyphony = starts.values.fold<int>(
      1,
      (best, value) => value > best ? value : best,
    );
    final density =
        song.notes.length / (song.duration <= 0 ? 1 : song.duration);
    final range = pitches.last - pitches.first;
    final handCrossing =
        song.notes.any((note) => note.note < 60) &&
        song.notes.any((note) => note.note >= 60);
    var difficulty = 8 + (density * 11).round() + range ~/ 2 + polyphony * 5;
    if (song.bpm > 120) difficulty += (song.bpm - 120) ~/ 4;
    difficulty = difficulty.clamp(1, 100);
    final level = difficulty < 28
        ? 'Beginner'
        : difficulty < 52
        ? 'Elementary'
        : difficulty < 74
        ? 'Intermediate'
        : 'Advanced';
    final skills = <String>[
      if (handCrossing) 'Hands together',
      if (polyphony >= 3) 'Chord coordination',
      if (density >= 4) 'Fast note reading',
      if (range >= 24) 'Keyboard movement',
      if (song.keySignature != 'C major') 'Key signatures',
      if (song.bpm >= 110) 'Tempo control',
    ];
    if (skills.isEmpty) skills.add('Single-note reading');
    final prerequisites = <String>[
      'Keyboard orientation',
      if (handCrossing) 'Basic left and right-hand independence',
      if (polyphony >= 3) 'Major and minor chord shapes',
      if (density >= 4) 'Eighth-note rhythm',
      if (range >= 24) 'Comfort moving between hand positions',
    ];
    final beatSeconds = 60 / (song.bpm <= 0 ? 100 : song.bpm);
    final numerator = int.tryParse(song.timeSignature.split('/').first) ?? 4;
    final phraseLength = (beatSeconds * numerator * 4)
        .clamp(6.0, 30.0)
        .toDouble();
    final sections = <SongSection>[];
    var start = 0.0;
    var index = 0;
    while (start < song.duration) {
      final end = (start + phraseLength).clamp(0, song.duration).toDouble();
      sections.add(
        SongSection(
          name: 'Section ${String.fromCharCode(65 + (index % 26))}',
          start: start,
          end: end,
        ),
      );
      start = end;
      index++;
    }
    return MidiSongAnalysis(
      level: level,
      score: difficulty,
      recommendedStartSpeed: difficulty < 28
          ? .75
          : difficulty < 52
          ? .65
          : .5,
      noteRange: '${_noteLabel(pitches.first)}–${_noteLabel(pitches.last)}',
      maximumPolyphony: polyphony,
      notesPerSecond: density,
      skills: skills,
      prerequisites: prerequisites,
      sections: sections,
    );
  }
}

String _noteLabel(int note) {
  const names = [
    'C',
    'C♯',
    'D',
    'D♯',
    'E',
    'F',
    'F♯',
    'G',
    'G♯',
    'A',
    'A♯',
    'B',
  ];
  return '${names[note % 12]}${note ~/ 12 - 1}';
}

class MidiSongParser {
  MidiSong parse(
    Uint8List data, {
    required String fallbackTitle,
    String? assetPath,
  }) {
    final reader = _Reader(data);
    if (reader.ascii(4) != 'MThd') {
      throw const FormatException('Not a Standard MIDI file');
    }
    final headerLength = reader.u32();
    reader.u16();
    final trackCount = reader.u16();
    final division = reader.u16();
    if (division & 0x8000 != 0) {
      throw const FormatException('SMPTE MIDI timing is not supported yet');
    }
    if (headerLength > 6) reader.skip(headerLength - 6);

    final raw = <_RawEvent>[];
    final tempos = <_Tempo>[const _Tempo(0, 500000)];
    String? embeddedTitle;
    String? copyright;
    String timeSignature = '4/4';
    String keySignature = 'C major';

    for (var track = 0; track < trackCount && !reader.done; track++) {
      if (reader.ascii(4) != 'MTrk') {
        throw const FormatException('Invalid MIDI track');
      }
      final length = reader.u32();
      final end = reader.offset + length;
      var tick = 0;
      var runningStatus = 0;
      while (reader.offset < end) {
        tick += reader.variable();
        var status = reader.u8();
        if (status < 0x80) {
          if (runningStatus == 0) {
            throw const FormatException('Invalid running status');
          }
          reader.back();
          status = runningStatus;
        } else if (status < 0xF0) {
          runningStatus = status;
        }
        if (status == 0xFF) {
          final type = reader.u8();
          final size = reader.variable();
          final payload = reader.take(size);
          if ((type == 0x03 || type == 0x01) && embeddedTitle == null) {
            embeddedTitle = _text(payload);
          }
          if (type == 0x02) copyright = _text(payload);
          if (type == 0x51 && payload.length == 3) {
            tempos.add(
              _Tempo(tick, (payload[0] << 16) | (payload[1] << 8) | payload[2]),
            );
          }
          if (type == 0x58 && payload.length >= 2) {
            timeSignature = '${payload[0]}/${1 << payload[1]}';
          }
          if (type == 0x59 && payload.length >= 2) {
            keySignature = _key(
              payload[0] > 127 ? payload[0] - 256 : payload[0],
              payload[1] == 0,
            );
          }
          continue;
        }
        if (status == 0xF0 || status == 0xF7) {
          reader.skip(reader.variable());
          continue;
        }
        final command = status & 0xF0;
        final dataLength = command == 0xC0 || command == 0xD0 ? 1 : 2;
        final message = Uint8List(dataLength + 1)..[0] = status;
        for (var i = 0; i < dataLength; i++) {
          message[i + 1] = reader.u8();
        }
        raw.add(_RawEvent(tick, message));
      }
      reader.offset = end;
    }

    tempos.sort((a, b) => a.tick.compareTo(b.tick));
    final uniqueTempos = <_Tempo>[];
    for (final tempo in tempos) {
      if (uniqueTempos.isNotEmpty && uniqueTempos.last.tick == tempo.tick) {
        uniqueTempos.removeLast();
      }
      uniqueTempos.add(tempo);
    }
    double secondsAt(int tick) {
      var seconds = 0.0;
      var previousTick = 0;
      var micros = uniqueTempos.first.micros;
      for (final tempo in uniqueTempos.skip(1)) {
        if (tempo.tick > tick) break;
        seconds += (tempo.tick - previousTick) * micros / division / 1000000;
        previousTick = tempo.tick;
        micros = tempo.micros;
      }
      return seconds + (tick - previousTick) * micros / division / 1000000;
    }

    raw.sort((a, b) => a.tick.compareTo(b.tick));
    final events = raw
        .map(
          (event) => MidiEvent(
            tick: event.tick,
            seconds: secondsAt(event.tick),
            data: event.data,
          ),
        )
        .toList();
    final active = <int, List<_ActiveNote>>{};
    final notes = <MidiNote>[];
    for (final event in events) {
      final command = event.data[0] & 0xF0;
      if (command != 0x80 && command != 0x90) continue;
      final channel = event.data[0] & 0x0F;
      final note = event.data[1];
      final key = channel * 128 + note;
      final isOn = command == 0x90 && event.data[2] > 0;
      if (isOn) {
        active
            .putIfAbsent(key, () => [])
            .add(_ActiveNote(event.seconds, event.data[2]));
      } else if (active[key]?.isNotEmpty == true) {
        final start = active[key]!.removeAt(0);
        notes.add(
          MidiNote(
            note: note,
            start: start.seconds,
            end: event.seconds,
            velocity: start.velocity,
            channel: channel,
          ),
        );
      }
    }
    notes.sort((a, b) => a.start.compareTo(b.start));
    final duration = events.isEmpty ? 0.0 : events.last.seconds;
    final title = _cleanTitle(embeddedTitle, fallbackTitle);
    return MidiSong(
      id: '${fallbackTitle}_${data.length}_${events.length}',
      title: title,
      composer: _composer('$title $fallbackTitle', copyright),
      collection:
          title.toLowerCase().contains('bach') ||
              fallbackTitle.toLowerCase().contains('bach')
          ? 'Baroque Essentials'
          : 'My MIDI files',
      duration: duration,
      bpm: (60000000 / uniqueTempos.first.micros).round(),
      timeSignature: timeSignature,
      keySignature: keySignature,
      events: events,
      notes: notes,
      bytes: data,
      assetPath: assetPath,
    );
  }

  static String _text(Uint8List bytes) =>
      String.fromCharCodes(bytes).replaceAll(RegExp(r'[\x00-\x1F]'), '').trim();
  static String _cleanTitle(String? embedded, String fallback) {
    final value = (embedded == null || embedded.trim().isEmpty)
        ? fallback
        : embedded;
    return value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\.midi?$', caseSensitive: false), '')
        .trim();
  }

  static String _composer(String title, String? copyright) {
    final source = '$title ${copyright ?? ''}'.toLowerCase();
    if (source.contains('bach') || source.contains('846')) {
      return 'Johann Sebastian Bach';
    }
    return 'Unknown composer';
  }

  static String _key(int sharps, bool major) {
    const majorKeys = [
      'C♭',
      'G♭',
      'D♭',
      'A♭',
      'E♭',
      'B♭',
      'F',
      'C',
      'G',
      'D',
      'A',
      'E',
      'B',
      'F♯',
      'C♯',
    ];
    const minorKeys = [
      'A♭',
      'E♭',
      'B♭',
      'F',
      'C',
      'G',
      'D',
      'A',
      'E',
      'B',
      'F♯',
      'C♯',
      'G♯',
      'D♯',
      'A♯',
    ];
    final index = (sharps + 7).clamp(0, 14);
    return '${major ? majorKeys[index] : minorKeys[index]} ${major ? 'major' : 'minor'}';
  }
}

class _Reader {
  _Reader(this.data);
  final Uint8List data;
  int offset = 0;
  bool get done => offset >= data.length;
  int u8() => data[offset++];
  int u16() => (u8() << 8) | u8();
  int u32() => (u8() << 24) | (u8() << 16) | (u8() << 8) | u8();
  String ascii(int size) => String.fromCharCodes(take(size));
  Uint8List take(int size) {
    final value = Uint8List.sublistView(data, offset, offset + size);
    offset += size;
    return value;
  }

  void skip(int size) => offset += size;
  void back() => offset--;
  int variable() {
    var value = 0;
    int byte;
    do {
      byte = u8();
      value = (value << 7) | (byte & 0x7F);
    } while (byte & 0x80 != 0);
    return value;
  }
}

class _RawEvent {
  const _RawEvent(this.tick, this.data);
  final int tick;
  final Uint8List data;
}

class _Tempo {
  const _Tempo(this.tick, this.micros);
  final int tick;
  final int micros;
}

class _ActiveNote {
  const _ActiveNote(this.seconds, this.velocity);
  final double seconds;
  final int velocity;
}

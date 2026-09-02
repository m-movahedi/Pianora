import 'dart:convert';
import 'dart:typed_data';

import 'package:crisp_notation/crisp_notation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_ish/midi_song.dart';
import 'package:piano_ish/sheet_music.dart';
import 'package:piano_ish/song_metadata_service.dart';

import 'synthetic_midi_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('song metadata can enrich a parsed MIDI song', () {
    final song = _song.copyWith(
      title: 'Goldberg Variations',
      composer: 'Johann Sebastian Bach',
      collection: 'Keyboard Works',
      releaseDate: '1741',
      genre: 'Classical',
      coverArtUrl: 'https://example.com/cover.jpg',
      musicBrainzId: 'recording-id',
      isImported: true,
    );
    expect(song.title, 'Goldberg Variations');
    expect(song.releaseDate, '1741');
    expect(song.coverArtUrl, endsWith('cover.jpg'));
    expect(song.isImported, isTrue);
    expect(song.notes, same(_song.notes));
  });

  test('sheet layout engraves MIDI as a paginated piano grand staff', () async {
    final bytes = createSyntheticPianoMidi();
    final layout = SheetMusicLayout(_songWithBytes(bytes));

    expect(layout.measureCount, greaterThan(12));
    expect(layout.pageCount, greaterThan(1));
    expect(layout.grandStaff.upper.clef, Clef.treble);
    expect(layout.grandStaff.lower.clef, Clef.bass);
    expect(
      _pitches(layout.grandStaff.upper).every((midi) => midi >= 60),
      isTrue,
    );
    expect(
      _pitches(layout.grandStaff.lower).every((midi) => midi < 60),
      isTrue,
    );
    expect(
      layout.grandStaff.upper.measures.length,
      layout.grandStaff.lower.measures.length,
    );
  });

  test('engraved score exports as a valid PDF document', () async {
    final bytes = createSyntheticPianoMidi();
    final pdf = await buildSheetMusicPdf(_songWithBytes(bytes));

    expect(pdf, isNotEmpty);
    expect(String.fromCharCodes(pdf.take(4)), '%PDF');
  });

  test('MusicBrainz results include release metadata and cover art', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'musicbrainz.org');
      expect(request.url.queryParameters['fmt'], 'json');
      expect(request.headers['user-agent'], contains('Piano-ish/1.1.0'));
      return http.Response(
        jsonEncode({
          'recordings': [
            {
              'id': 'recording-id',
              'title': 'Prelude in C Major',
              'score': 98,
              'first-release-date': '1722',
              'artist-credit': [
                {'name': 'Johann Sebastian Bach'},
              ],
              'tags': [
                {'name': 'classical'},
              ],
              'releases': [
                {
                  'id': 'release-id',
                  'title': 'Well-Tempered Clavier',
                  'date': '2000',
                },
              ],
            },
          ],
        }),
        200,
      );
    });
    final results = await SongMetadataService(
      client: client,
    ).search(title: 'Prelude in C Major', artist: 'Johann Sebastian Bach');
    expect(results, hasLength(1));
    expect(results.single.release, 'Well-Tempered Clavier');
    expect(results.single.genre, 'classical');
    expect(
      results.single.coverArtUrl,
      contains('/release/release-id/front-500'),
    );
  });
}

final _song = MidiSong(
  id: 'songbook-test',
  title: 'Prelude',
  composer: 'J. S. Bach',
  collection: 'Tests',
  duration: 100,
  bpm: 80,
  timeSignature: '4/4',
  keySignature: 'C major',
  events: const [],
  notes: const [MidiNote(note: 60, start: 0, end: 1, velocity: 90, channel: 0)],
  bytes: Uint8List(0),
);

MidiSong _songWithBytes(Uint8List bytes) => MidiSong(
  id: _song.id,
  title: _song.title,
  composer: _song.composer,
  collection: _song.collection,
  duration: _song.duration,
  bpm: _song.bpm,
  timeSignature: _song.timeSignature,
  keySignature: _song.keySignature,
  events: _song.events,
  notes: _song.notes,
  bytes: bytes,
);

Iterable<int> _pitches(Score score) sync* {
  for (final measure in score.measures) {
    for (final element in measure.elements) {
      if (element is NoteElement) {
        yield* element.pitches.map((pitch) => pitch.midiNumber);
      }
    }
  }
}

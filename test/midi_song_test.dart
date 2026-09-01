import 'package:flutter_test/flutter_test.dart';
import 'package:pianora/midi_song.dart';
import 'package:pianora/piano_controller.dart';

import 'synthetic_midi_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('parses the synthetic MIDI test fixture', () {
    final bytes = createSyntheticPianoMidi();
    final song = MidiSongParser().parse(
      bytes,
      fallbackTitle: 'Synthetic piano study',
    );

    expect(song.events, isNotEmpty);
    expect(song.notes, isNotEmpty);
    expect(song.duration, greaterThan(1));
    expect(song.bpm, greaterThan(0));
    expect(song.analysis.score, inInclusiveRange(1, 100));
    expect(song.analysis.sections, isNotEmpty);
    expect(song.analysis.prerequisites, isNotEmpty);
    expect(song.analysis.recommendedStartSpeed, inInclusiveRange(.5, .75));
  });

  test('practice tools configure hand, loop, timing, and notation modes', () {
    final bytes = createSyntheticPianoMidi();
    final song = MidiSongParser().parse(bytes, fallbackTitle: 'Piano study');
    final controller = PianoController()..selectSong(song);

    controller.setPracticeHand(PracticeHand.left);
    controller.setScoreView(ScoreView.sheetMusic);
    controller.setTimingTolerance(.12);
    controller.setLoopRange(1, 5);
    controller.setAutoTempoRamp(true);

    expect(controller.practiceHand, PracticeHand.left);
    expect(controller.scoreView, ScoreView.sheetMusic);
    expect(controller.timingTolerance, .12);
    expect(controller.loopEnabled, isTrue);
    expect(controller.loopStart, 1);
    expect(controller.loopEnd, 5);
    expect(controller.autoTempoRamp, isTrue);
  });

  test('pause and play advances only after the expected group is matched', () {
    final bytes = createSyntheticPianoMidi();
    final song = MidiSongParser().parse(
      bytes,
      fallbackTitle: 'Synthetic piano study',
    );
    final controller = PianoController()..selectedSong = song;
    controller.setPracticeMode(PracticeMode.pauseAndPlay);
    controller.play();

    final start = controller.position;
    final chord = controller.expectedNotes.toList();
    expect(chord, isNotEmpty);

    for (final note in chord.take(chord.length - 1)) {
      controller.audition(note, true);
      controller.audition(note, false);
      expect(controller.position, start);
    }
    controller.audition(chord.last, true);

    expect(controller.position > start || !controller.isPlaying, isTrue);
    controller.pause(sendPanic: false);
  });
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crisp_notation/crisp_notation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'midi_song.dart';

/// Creates a conventional piano transcription from performance MIDI.
///
/// Timing is quantized by crisp_notation to a sixteenth-note grid. MIDI does
/// not encode the composer's original hand or staff assignment, so middle C
/// is used as the deterministic split point for the grand staff.
GrandStaff engraveMidiSong(MidiSong song, {int splitMidiNote = 60}) {
  final source = scoreFromMidi(song.bytes);
  final upperMeasures = <Measure>[];
  final lowerMeasures = <Measure>[];

  for (
    var measureIndex = 0;
    measureIndex < source.measures.length;
    measureIndex++
  ) {
    final sourceMeasure = source.measures[measureIndex];
    final upper = <MusicElement>[];
    final lower = <MusicElement>[];

    for (
      var elementIndex = 0;
      elementIndex < sourceMeasure.elements.length;
      elementIndex++
    ) {
      final element = sourceMeasure.elements[elementIndex];
      final upperId = 'upper-$measureIndex-$elementIndex';
      final lowerId = 'lower-$measureIndex-$elementIndex';
      if (element is NoteElement) {
        final upperPitches = element.pitches
            .where((pitch) => pitch.midiNumber >= splitMidiNote)
            .toList(growable: false);
        final lowerPitches = element.pitches
            .where((pitch) => pitch.midiNumber < splitMidiNote)
            .toList(growable: false);
        upper.add(
          upperPitches.isEmpty
              ? RestElement(element.duration, id: upperId)
              : _copyNote(element, upperPitches, upperId),
        );
        lower.add(
          lowerPitches.isEmpty
              ? RestElement(element.duration, id: lowerId)
              : _copyNote(element, lowerPitches, lowerId),
        );
      } else {
        upper.add(RestElement(element.duration, id: upperId));
        lower.add(RestElement(element.duration, id: lowerId));
      }
    }

    upperMeasures.add(sourceMeasure.copyWith(elements: upper));
    lowerMeasures.add(sourceMeasure.copyWith(elements: lower));
  }

  return GrandStaff(
    upper: _scoreWith(source, Clef.treble, upperMeasures),
    lower: _scoreWith(source, Clef.bass, lowerMeasures),
  );
}

NoteElement _copyNote(NoteElement source, List<Pitch> pitches, String id) =>
    NoteElement(
      pitches: pitches,
      duration: source.duration,
      showAccidental: source.showAccidental,
      tieToNext: source.tieToNext,
      articulations: source.articulations,
      graceNotes: source.graceNotes,
      graceStyle: source.graceStyle,
      ornament: source.ornament,
      fingerings: source.fingerings,
      arpeggio: source.arpeggio,
      tremolo: source.tremolo,
      notehead: source.notehead,
      id: id,
    );

Score _scoreWith(Score source, Clef clef, List<Measure> measures) => Score(
  clef: clef,
  keySignature: source.keySignature,
  timeSignature: source.timeSignature,
  measures: measures,
  metadata: source.metadata,
  tempo: source.tempo,
);

GrandStaff _sliceGrandStaff(GrandStaff source, int start, int end) {
  final safeEnd = math.min(end, source.upper.measures.length);
  final upper = source.upper.measures.sublist(start, safeEnd);
  final lower = source.lower.measures.sublist(start, safeEnd);
  return GrandStaff(
    upper: _scoreWith(source.upper, source.upper.clef, upper),
    lower: _scoreWith(source.lower, source.lower.clef, lower),
  );
}

class SheetMusicLayout {
  SheetMusicLayout(this.song) : grandStaff = engraveMidiSong(song);

  final MidiSong song;
  final GrandStaff grandStaff;

  /// Twelve measures gives a readable three-to-five-system A4 page for most
  /// piano MIDI while still allowing the engraver to wrap dense measures.
  static const measuresPerPage = 12;
  static const measuresPerPdfSystem = 4;

  int get measureCount => grandStaff.upper.measures.length;
  int get pageCount => math.max(1, (measureCount / measuresPerPage).ceil());

  GrandStaff page(int pageIndex) {
    final start = (pageIndex * measuresPerPage).clamp(0, measureCount);
    return _sliceGrandStaff(grandStaff, start, start + measuresPerPage);
  }
}

class SheetMusicPage extends StatelessWidget {
  const SheetMusicPage({
    super.key,
    required this.song,
    required this.pageIndex,
  });

  final MidiSong song;
  final int pageIndex;

  @override
  Widget build(BuildContext context) {
    final layout = SheetMusicLayout(song);
    final page = layout.page(pageIndex.clamp(0, layout.pageCount - 1));
    const notationTheme = CrispNotationTheme(
      staffColor: Color(0xFF171717),
      noteColor: Color(0xFF111111),
    );
    return AspectRatio(
      aspectRatio: 1 / 1.414,
      child: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(30, 24, 30, 18),
          child: Column(
            children: [
              Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF171717),
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  song.composer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontFamily: 'serif',
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRect(
                  child: SingleChildScrollView(
                    child: InteractiveGrandStaffView(
                      grandStaff: page,
                      theme: notationTheme,
                      staffSpace: 6.5,
                      staffGap: 5,
                      systemGap: 7,
                      justify: true,
                      gridAlign: true,
                      showMeasureNumbers: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${pageIndex + 1}',
                style: const TextStyle(
                  color: Color(0xFF333333),
                  fontFamily: 'serif',
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Uint8List> buildSheetMusicPdf(MidiSong song) async {
  final layout = SheetMusicLayout(song);
  final document = pw.Document(
    title: song.title,
    author: song.composer,
    creator: 'Piano-ish',
  );

  for (var pageIndex = 0; pageIndex < layout.pageCount; pageIndex++) {
    final pageScore = layout.page(pageIndex);
    final systems = <Uint8List>[];
    for (
      var start = 0;
      start < pageScore.upper.measures.length;
      start += SheetMusicLayout.measuresPerPdfSystem
    ) {
      final system = _sliceGrandStaff(
        pageScore,
        start,
        start + SheetMusicLayout.measuresPerPdfSystem,
      );
      systems.add(
        await exportGrandStaffToPng(
          system,
          theme: CrispNotationTheme.standard,
          staffSpace: 18,
          staffGap: 5,
        ),
      );
    }
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 26),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              song.title,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(font: pw.Font.timesBold(), fontSize: 20),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              song.composer,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(font: pw.Font.times(), fontSize: 10),
            ),
            pw.SizedBox(height: 15),
            ...systems.map(
              (png) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Image(
                  pw.MemoryImage(png),
                  height: 145,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
            pw.Spacer(),
            pw.Text(
              '${pageIndex + 1}',
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  return document.save();
}

Future<Uri?> exportSheetMusicPdf(MidiSong song) async {
  final safeTitle = song.title
      .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), '')
      .trim();
  return FilePicker.saveFile(
    fileName: '${safeTitle.isEmpty ? 'Piano-ish score' : safeTitle}.pdf',
    bytes: await buildSheetMusicPdf(song),
    mimeType: 'application/pdf',
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    dialogTitle: 'Export sheet music',
  );
}

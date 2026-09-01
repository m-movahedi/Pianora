import 'dart:typed_data';

/// A copyright-free Standard MIDI File generated specifically for Pianora's
/// tests. It contains 16 measures of quarter notes spanning both piano staves.
Uint8List createSyntheticPianoMidi() {
  const ticksPerQuarter = 480;
  const measures = 16;
  const notesPerMeasure = 4;
  const pitches = <int>[48, 60, 52, 64, 55, 67, 57, 69];
  final track = <int>[
    // 4/4 time signature and 120 BPM.
    0x00, 0xff, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08,
    0x00, 0xff, 0x51, 0x03, 0x07, 0xa1, 0x20,
  ];

  for (var index = 0; index < measures * notesPerMeasure; index++) {
    final pitch = pitches[index % pitches.length];
    track.addAll(<int>[0x00, 0x90, pitch, 88]);
    track.addAll(<int>[..._variableLength(ticksPerQuarter), 0x80, pitch, 0x00]);
  }
  track.addAll(const <int>[0x00, 0xff, 0x2f, 0x00]);

  return Uint8List.fromList(<int>[
    0x4d, 0x54, 0x68, 0x64, // MThd
    0x00, 0x00, 0x00, 0x06,
    0x00, 0x00, // Format 0
    0x00, 0x01, // One track
    (ticksPerQuarter >> 8) & 0xff,
    ticksPerQuarter & 0xff,
    0x4d, 0x54, 0x72, 0x6b, // MTrk
    (track.length >> 24) & 0xff,
    (track.length >> 16) & 0xff,
    (track.length >> 8) & 0xff,
    track.length & 0xff,
    ...track,
  ]);
}

List<int> _variableLength(int value) {
  final bytes = <int>[value & 0x7f];
  var remaining = value >> 7;
  while (remaining > 0) {
    bytes.insert(0, (remaining & 0x7f) | 0x80);
    remaining >>= 7;
  }
  return bytes;
}

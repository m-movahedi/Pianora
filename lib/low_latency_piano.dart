import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

/// Small in-process piano voice for immediate MIDI monitoring.
///
/// It avoids the high-latency Microsoft GS Wavetable MIDI path. One prepared
/// C4 piano-like sample is transposed per voice inside SoLoud's native mixer.
class LowLatencyPiano {
  final Map<int, SoundHandle> _voices = {};
  final Set<int> _releasedUnderPedal = {};
  AudioSource? _source;
  Future<void>? _initializing;
  bool sustainDown = false;

  bool get isReady => _source != null && SoLoud.instance.isInitialized;

  Future<void> initialize() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (!SoLoud.instance.isInitialized) {
      await SoLoud.instance.init(
        sampleRate: 44100,
        bufferSize: 256,
        channels: Channels.stereo,
        lowLatency: true,
      );
    }
    _source ??= await SoLoud.instance.loadMem(
      'piano-ish-c4.wav',
      _buildPianoWave(),
      mode: LoadMode.memory,
    );
  }

  void noteOn(int note, int velocity) {
    final source = _source;
    if (source == null) return;
    final previous = _voices.remove(note);
    if (previous != null) unawaited(SoLoud.instance.stop(previous));
    _releasedUnderPedal.remove(note);

    final volume = .12 + .78 * math.pow(velocity / 127, 1.45);
    final handle = SoLoud.instance.play(source, volume: volume, paused: true);
    SoLoud.instance.setRelativePlaySpeed(
      handle,
      math.pow(2, (note - 60) / 12).toDouble(),
    );
    SoLoud.instance.setPause(handle, false);
    _voices[note] = handle;
  }

  void noteOff(int note) {
    if (sustainDown) {
      _releasedUnderPedal.add(note);
      return;
    }
    _release(note);
  }

  void setSustain(bool down) {
    sustainDown = down;
    if (down) return;
    for (final note in _releasedUnderPedal.toList()) {
      _release(note);
    }
    _releasedUnderPedal.clear();
  }

  void _release(int note) {
    final handle = _voices.remove(note);
    if (handle == null || !SoLoud.instance.isInitialized) return;
    SoLoud.instance.fadeVolume(handle, 0, const Duration(milliseconds: 70));
    Future<void>.delayed(const Duration(milliseconds: 80), () async {
      if (SoLoud.instance.isInitialized) await SoLoud.instance.stop(handle);
    });
  }

  void allNotesOff() {
    for (final note in _voices.keys.toList()) {
      _release(note);
    }
    _releasedUnderPedal.clear();
    sustainDown = false;
  }

  void dispose() {
    allNotesOff();
    if (SoLoud.instance.isInitialized) SoLoud.instance.deinit();
  }

  Uint8List _buildPianoWave() {
    const sampleRate = 44100;
    const seconds = 4.5;
    final samples = (sampleRate * seconds).round();
    final dataLength = samples * 2;
    final bytes = Uint8List(44 + dataLength);
    final data = ByteData.sublistView(bytes);

    void text(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        bytes[offset + i] = value.codeUnitAt(i);
      }
    }

    text(0, 'RIFF');
    data.setUint32(4, 36 + dataLength, Endian.little);
    text(8, 'WAVE');
    text(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    text(36, 'data');
    data.setUint32(40, dataLength, Endian.little);

    const frequency = 261.625565; // Middle C (C4 / MIDI 60)
    const harmonics = [1.0, .52, .29, .17, .10, .065, .038, .022];
    for (var i = 0; i < samples; i++) {
      final t = i / sampleRate;
      final attack = math.min(1.0, t / .006);
      final decay = .78 * math.exp(-1.25 * t) + .22 * math.exp(-.28 * t);
      final hammer = t < .025
          ? math.sin(2 * math.pi * 3200 * t) * (.025 - t) * 3.2
          : 0.0;
      var wave = hammer;
      for (var harmonic = 0; harmonic < harmonics.length; harmonic++) {
        final partial = harmonic + 1;
        final detune = partial == 1 ? 1.0 : 1.0 + partial * .00018;
        wave +=
            harmonics[harmonic] *
            math.sin(2 * math.pi * frequency * partial * detune * t);
      }
      final value = (wave * attack * decay * .28).clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (value * 32767).round(), Endian.little);
    }
    return bytes;
  }
}

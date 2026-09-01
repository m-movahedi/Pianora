import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_midi_command/flutter_midi_command_messages.dart';
import 'package:flutter_midi_command_ble/flutter_midi_command_ble.dart';
import 'package:universal_ble/universal_ble.dart';

import 'low_latency_piano.dart';
import 'app_storage.dart';
import 'midi_song.dart';

enum PracticeMode { playAlong, pauseAndPlay }

enum PracticeHand { both, right, left }

enum ScoreView { fallingNotes, hybrid, sheetMusic }

class PianoController extends ChangeNotifier {
  PianoController()
    : _midi = MidiCommand(bleTransport: UniversalBleMidiTransport());

  final MidiCommand _midi;
  final MidiSongParser _parser = MidiSongParser();
  final MidiMessageParser _liveMidiParser = MidiMessageParser();
  final LowLatencyPiano _pianoSound = LowLatencyPiano();
  StreamSubscription<MidiPacket>? _inputSubscription;
  StreamSubscription<Uint8List>? _bleInputSubscription;
  StreamSubscription<MidiSetupChange>? _setupSubscription;
  StreamSubscription<BluetoothState>? _bluetoothSubscription;
  Timer? _ticker;
  Timer? _scanTimer;
  Timer? _inputHealthTimer;
  Timer? _progressTimer;
  Timer? _countInTimer;
  DateTime? _playStarted;
  double _positionAtStart = 0;
  int _eventIndex = 0;
  int _lastMetronomeBeat = -1;
  bool _startingAfterCountIn = false;
  String? _rememberedDeviceId;
  bool _autoReconnectStarted = false;
  final List<MidiDevice> _windowsBluetoothDevices = [];

  final List<MidiSong> songs = [];
  List<MidiDevice> devices = [];
  MidiSong? selectedSong;
  MidiDevice? connectedDevice;
  final Set<int> playedNotes = {};
  final Set<int> fileNotes = {};
  bool isLoading = true;
  bool isConnecting = false;
  bool isForgetting = false;
  bool isBluetoothScanning = false;
  bool isAwaitingBluetoothInput = false;
  bool bluetoothInputTimedOut = false;
  BluetoothState bluetoothState = BluetoothState.unknown;
  bool isPlaying = false;
  double position = 0;
  double speed = 1;
  int correctNotes = 0;
  int attemptedNotes = 0;
  int? lastInputNote;
  int lastInputVelocity = 0;
  int inputNoteCount = 0;
  int inputPacketCount = 0;
  bool hearNotesEnabled = false;
  bool sustainPedalDown = false;
  int sustainPedalValue = 0;
  PracticeMode practiceMode = PracticeMode.playAlong;
  PracticeHand practiceHand = PracticeHand.both;
  ScoreView scoreView = ScoreView.fallingNotes;
  bool showNoteNames = true;
  bool metronomeEnabled = false;
  int countInBeats = 0;
  int countInRemaining = 0;
  bool loopEnabled = false;
  double loopStart = 0;
  double loopEnd = 0;
  bool autoTempoRamp = false;
  double timingTolerance = .18;
  final List<double> bookmarks = [];
  final Map<double, String> annotations = {};
  int earlyNotes = 0;
  int onTimeNotes = 0;
  int lateNotes = 0;
  final Set<int> _waitMatchedNotes = {};
  String? message;
  void Function(
    String songId,
    double position,
    int correct,
    int attempted,
    bool completed,
  )?
  onProgress;
  bool _completionReported = false;

  Future<void> initialize() async {
    await _loadRememberedDevice();
    await _loadImportedSongs();
    if (songs.isNotEmpty) {
      selectedSong = songs.first;
      loopEnd = selectedSong!.duration;
    }
    // BLE must be configured before these merged streams are read. The
    // constructor above guarantees both USB/WinMM and BLE events are included.
    // Listen below the typed-message layer. A few Windows BLE devices deliver
    // valid packets that the convenience stream can silently omit.
    _inputSubscription = _midi.onMidiPacketReceived?.listen(_handlePacket);
    _setupSubscription = _midi.onMidiSetupChanged?.listen(
      (_) => refreshDevices(),
    );
    _bluetoothSubscription = _midi.onBluetoothStateChanged.listen((state) {
      bluetoothState = state;
      if (state != BluetoothState.poweredOn) isBluetoothScanning = false;
      notifyListeners();
    });
    await _initializeBluetooth();
    await refreshDevices();
    if (_rememberedDeviceId != null &&
        connectedDevice == null &&
        !_autoReconnectStarted &&
        bluetoothState == BluetoothState.poweredOn) {
      await startBluetoothScan();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _midi.startBluetooth();
      bluetoothState = _midi.bluetoothState;
    } catch (error) {
      bluetoothState = BluetoothState.unsupported;
      message = 'Bluetooth MIDI is unavailable: $error';
    }
  }

  Future<void> startBluetoothScan() async {
    if (isBluetoothScanning) return;
    message = null;
    try {
      await _midi.startBluetooth();
      bluetoothState = _midi.bluetoothState;
      if (bluetoothState != BluetoothState.poweredOn) {
        message = bluetoothState == BluetoothState.poweredOff
            ? 'Turn on Bluetooth in Windows, then scan again.'
            : 'Bluetooth is not ready (${bluetoothState.name}).';
        notifyListeners();
        return;
      }
      // A device already paired or connected in Windows is deliberately not
      // emitted as a fresh scan result by universal_ble. Query that system
      // collection first, then merge it with live advertisements below.
      await _loadWindowsBluetoothDevices();
      isBluetoothScanning = true;
      // Some Roland pianos do not include the 128-bit MIDI service in every
      // advertising packet. The name prefixes are OR-ed with the service
      // filter, so generic BLE devices remain hidden while FP-series devices
      // can still reach the MIDI service-discovery step on connection.
      await UniversalBle.startScan(
        scanFilter: ScanFilter(
          withServices: const [midiServiceId],
          withNamePrefix: const ['FP-10', 'Roland', 'ROLAND'],
        ),
      );
      await refreshDevices();
      _scanTimer?.cancel();
      _scanTimer = Timer(const Duration(seconds: 20), stopBluetoothScan);
    } catch (error) {
      isBluetoothScanning = false;
      message = 'Bluetooth scan could not start: $error';
    }
    notifyListeners();
  }

  Future<void> _loadWindowsBluetoothDevices() async {
    try {
      final systemDevices = await UniversalBle.getSystemDevices(
        withServices: const [midiServiceId],
        timeout: const Duration(seconds: 10),
      );
      _windowsBluetoothDevices
        ..clear()
        ..addAll(
          systemDevices
              .where((device) => device.name?.trim().isNotEmpty == true)
              .map(
                (device) => MidiDevice(
                  device.deviceId,
                  device.name!.trim(),
                  MidiDeviceType.ble,
                  false,
                ),
              ),
        );
    } catch (_) {
      // Live discovery can still succeed when Windows' system-device query
      // is unavailable or a stale pairing cannot be interrogated.
    }
  }

  void stopBluetoothScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (isBluetoothScanning) {
      try {
        unawaited(UniversalBle.stopScan());
      } catch (_) {
        // The transport can already be stopping after an adapter state change.
      }
    }
    isBluetoothScanning = false;
    notifyListeners();
  }

  Future<void> refreshDevices() async {
    try {
      final discovered = await _midi.devices ?? [];
      final merged = <String, MidiDevice>{
        for (final device in _windowsBluetoothDevices) device.id: device,
        for (final device in discovered) device.id: device,
      };
      devices = merged.values.toList();
      if (connectedDevice != null) {
        final matches = devices.where(
          (device) => device.id == connectedDevice!.id,
        );
        if (matches.isEmpty) {
          connectedDevice = null;
          _autoReconnectStarted = false;
        } else {
          connectedDevice = matches.first;
        }
      }
      final remembered = devices.where(
        (device) => device.id == _rememberedDeviceId,
      );
      if (connectedDevice == null &&
          !isConnecting &&
          !_autoReconnectStarted &&
          remembered.isNotEmpty) {
        _autoReconnectStarted = true;
        unawaited(connect(remembered.first, automatic: true));
      }
    } catch (error) {
      message = 'MIDI devices could not be read: $error';
    }
    notifyListeners();
  }

  Future<void> setHearNotes(bool enabled) async {
    if (!enabled) {
      hearNotesEnabled = false;
      _pianoSound.allNotesOff();
      notifyListeners();
      return;
    }
    try {
      await _pianoSound.initialize();
      hearNotesEnabled = true;
      message = 'Low-latency piano sound is ready';
    } catch (error) {
      hearNotesEnabled = false;
      message = 'Could not start low-latency audio: $error';
    }
    notifyListeners();
  }

  Future<void> connect(MidiDevice device, {bool automatic = false}) async {
    if (isConnecting) return;
    isConnecting = true;
    message = null;
    notifyListeners();
    try {
      await _bleInputSubscription?.cancel();
      _bleInputSubscription = null;
      if (device.type == MidiDeviceType.ble) stopBluetoothScan();
      if (connectedDevice != null && connectedDevice!.id != device.id) {
        _midi.disconnectDevice(connectedDevice!);
      }
      await _midi.connectToDevice(
        device,
        awaitConnectionTimeout: const Duration(seconds: 12),
      );
      if (device.type == MidiDeviceType.ble) {
        await _armBluetoothMidiInput(device);
      }
      connectedDevice = device;
      _beginInputHealthCheck(device);
      _rememberedDeviceId = device.id;
      await _saveRememberedDevice(device.id);
      message = '${device.name} is ready';
    } catch (error) {
      await _bleInputSubscription?.cancel();
      _bleInputSubscription = null;
      if (!automatic) message = _connectionError(device, error);
      _autoReconnectStarted = false;
    }
    isConnecting = false;
    notifyListeners();
  }

  Future<void> _armBluetoothMidiInput(MidiDevice device) async {
    // Listen directly to the characteristic before re-writing the Windows
    // Client Characteristic Configuration Descriptor. Re-subscribing is
    // important for a paired FP-10 because Windows can retain the GATT link
    // while discarding the previous process's ValueChanged event handler.
    await _bleInputSubscription?.cancel();
    _bleInputSubscription = UniversalBle.characteristicValueStream(
      device.id,
      midiCharacteristicId,
    ).listen(_handleBlePacket);
    await UniversalBle.subscribeNotifications(
      device.id,
      midiServiceId,
      midiCharacteristicId,
      timeout: const Duration(seconds: 8),
    );
  }

  void _beginInputHealthCheck(MidiDevice device) {
    _inputHealthTimer?.cancel();
    isAwaitingBluetoothInput = device.type == MidiDeviceType.ble;
    bluetoothInputTimedOut = false;
    if (!isAwaitingBluetoothInput) return;
    final packetsAtConnect = inputPacketCount;
    _inputHealthTimer = Timer(const Duration(seconds: 12), () {
      if (connectedDevice?.id != device.id ||
          inputPacketCount != packetsAtConnect) {
        return;
      }
      bluetoothInputTimedOut = true;
      message =
          'No MIDI input was received. Press Repair connection to reset the stale Windows pairing.';
      notifyListeners();
    });
  }

  void _confirmBluetoothInput() {
    if (!isAwaitingBluetoothInput) return;
    _inputHealthTimer?.cancel();
    isAwaitingBluetoothInput = false;
    bluetoothInputTimedOut = false;
  }

  String _connectionError(MidiDevice device, Object error) {
    if (error is MidiPairingRejectedException) {
      return 'Pairing with ${device.name} was canceled. Start the scan and try again.';
    }
    if (error is MidiConnectionTimeoutException) {
      return '${device.name} did not become ready. Make sure it is nearby and not connected to another app.';
    }
    if (error is MidiServiceDiscoveryException) {
      return '${device.name} does not expose the Bluetooth MIDI service.';
    }
    if (error is MidiNotificationSubscriptionException) {
      return 'Windows connected to ${device.name}, but MIDI notifications could not be enabled.';
    }
    return 'Could not connect to ${device.name}: $error';
  }

  void disconnect() {
    _inputHealthTimer?.cancel();
    isAwaitingBluetoothInput = false;
    bluetoothInputTimedOut = false;
    unawaited(_bleInputSubscription?.cancel());
    _bleInputSubscription = null;
    if (connectedDevice != null) _midi.disconnectDevice(connectedDevice!);
    connectedDevice = null;
    _rememberedDeviceId = null;
    _autoReconnectStarted = false;
    unawaited(_saveRememberedDevice(null));
    playedNotes.clear();
    lastInputNote = null;
    lastInputVelocity = 0;
    inputNoteCount = 0;
    inputPacketCount = 0;
    sustainPedalDown = false;
    sustainPedalValue = 0;
    notifyListeners();
  }

  Future<void> forgetDevice(MidiDevice device) async {
    if (isForgetting) return;
    isForgetting = true;
    message = 'Removing ${device.name} from Windows…';
    notifyListeners();
    try {
      if (connectedDevice?.id == device.id) {
        await _bleInputSubscription?.cancel();
        _bleInputSubscription = null;
        _midi.disconnectDevice(device);
        connectedDevice = null;
        playedNotes.clear();
      }
      if (device.type == MidiDeviceType.ble) {
        await UniversalBle.disconnect(
          device.id,
          timeout: const Duration(seconds: 6),
        );
        await UniversalBle.unpair(
          device.id,
          timeout: const Duration(seconds: 10),
        );
      }
      _windowsBluetoothDevices.removeWhere((item) => item.id == device.id);
      devices.removeWhere((item) => item.id == device.id);
      if (_rememberedDeviceId == device.id) {
        _rememberedDeviceId = null;
        await _saveRememberedDevice(null);
      }
      _autoReconnectStarted = false;
      lastInputNote = null;
      lastInputVelocity = 0;
      inputNoteCount = 0;
      inputPacketCount = 0;
      message = '${device.name} was removed. Scan Bluetooth to pair it again.';
    } catch (error) {
      message = 'Windows could not forget ${device.name}: $error';
    } finally {
      isForgetting = false;
      notifyListeners();
    }
  }

  Future<void> repairBluetoothConnection(MidiDevice device) async {
    final targetId = device.id;
    await forgetDevice(device);
    if (message?.startsWith('Windows could not forget') == true) return;
    // Keep the id only for this repair attempt. When the FP-10 advertises
    // again, refreshDevices will reconnect and Windows will show its pairing
    // prompt without requiring the user to find the device a second time.
    _rememberedDeviceId = targetId;
    _autoReconnectStarted = false;
    await _saveRememberedDevice(targetId);
    message = 'Turn the FP-10 on and approve the Windows pairing prompt…';
    notifyListeners();
    await startBluetoothScan();
  }

  Future<File?> _rememberedDeviceFile() async {
    final directory = await pianoraSupportDirectory();
    if (directory == null) return null;
    return File('${directory.path}${Platform.pathSeparator}midi_device.txt');
  }

  Future<void> _loadRememberedDevice() async {
    try {
      final file = await _rememberedDeviceFile();
      if (file != null && await file.exists()) {
        final id = await file.readAsString();
        if (id.trim().isNotEmpty) _rememberedDeviceId = id.trim();
      }
    } catch (_) {
      // Remembering a device is a convenience and must never block startup.
    }
  }

  Future<void> _saveRememberedDevice(String? id) async {
    try {
      final file = await _rememberedDeviceFile();
      if (file == null) return;
      if (id == null) {
        if (await file.exists()) await file.delete();
        return;
      }
      await file.parent.create(recursive: true);
      await file.writeAsString(id, flush: true);
    } catch (_) {
      // MIDI remains usable if Windows app-data storage is unavailable.
    }
  }

  Future<MidiSong?> importMidi() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['mid', 'midi'],
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    try {
      final parsed = _parser.parse(bytes, fallbackTitle: file.name);
      final song = parsed.copyWith(isImported: true);
      songs.add(song);
      selectSong(song);
      await _saveSongLibrary();
      message = 'Added ${song.title}';
      notifyListeners();
      return song;
    } catch (error) {
      message = 'That MIDI file is not supported: $error';
    }
    notifyListeners();
    return null;
  }

  Future<void> updateSongMetadata(
    MidiSong original, {
    required String title,
    required String composer,
    required String collection,
    String? releaseDate,
    String? genre,
    String? coverArtUrl,
    String? musicBrainzId,
  }) async {
    final index = songs.indexWhere((song) => song.id == original.id);
    if (index < 0) return;
    final updated = original.copyWith(
      title: title.trim().isEmpty ? original.title : title.trim(),
      composer: composer.trim().isEmpty ? 'Unknown composer' : composer.trim(),
      collection: collection.trim().isEmpty
          ? 'My MIDI files'
          : collection.trim(),
      releaseDate: releaseDate?.trim() ?? '',
      genre: genre?.trim() ?? '',
      coverArtUrl: coverArtUrl?.trim() ?? '',
      musicBrainzId: musicBrainzId?.trim() ?? '',
    );
    songs[index] = updated;
    if (selectedSong?.id == original.id) selectedSong = updated;
    await _saveSongLibrary();
    message = 'Updated ${updated.title}';
    notifyListeners();
  }

  Future<File?> _songLibraryFile() async {
    final directory = await pianoraSupportDirectory();
    if (directory == null) return null;
    return File(
      '${directory.path}${Platform.pathSeparator}songs${Platform.pathSeparator}library.json',
    );
  }

  String _safeSongFileName(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  Future<void> _loadImportedSongs() async {
    try {
      final libraryFile = await _songLibraryFile();
      if (libraryFile == null || !await libraryFile.exists()) return;
      final decoded = jsonDecode(await libraryFile.readAsString());
      if (decoded is! List) return;
      for (final raw in decoded.whereType<Map>()) {
        final item = raw.cast<String, Object?>();
        final fileName = item['fileName'] as String?;
        if (fileName == null || fileName.isEmpty) continue;
        final midiFile = File(
          '${libraryFile.parent.path}${Platform.pathSeparator}$fileName',
        );
        if (!await midiFile.exists()) continue;
        final parsed = _parser.parse(
          await midiFile.readAsBytes(),
          fallbackTitle: item['title'] as String? ?? fileName,
        );
        final song = parsed.copyWith(
          id: item['id'] as String? ?? parsed.id,
          title: item['title'] as String? ?? parsed.title,
          composer: item['composer'] as String? ?? parsed.composer,
          collection: item['collection'] as String? ?? parsed.collection,
          coverArtUrl: item['coverArtUrl'] as String? ?? '',
          releaseDate: item['releaseDate'] as String? ?? '',
          genre: item['genre'] as String? ?? '',
          musicBrainzId: item['musicBrainzId'] as String? ?? '',
          isImported: true,
        );
        if (!songs.any((existing) => existing.id == song.id)) songs.add(song);
      }
    } catch (error) {
      message = 'Some saved songs could not be loaded: $error';
    }
  }

  Future<void> _saveSongLibrary() async {
    try {
      final libraryFile = await _songLibraryFile();
      if (libraryFile == null) return;
      await libraryFile.parent.create(recursive: true);
      final entries = <Map<String, Object?>>[];
      for (final song in songs.where((song) => song.isImported)) {
        final fileName = '${_safeSongFileName(song.id)}.mid';
        await File(
          '${libraryFile.parent.path}${Platform.pathSeparator}$fileName',
        ).writeAsBytes(song.bytes, flush: true);
        entries.add({
          'id': song.id,
          'fileName': fileName,
          'title': song.title,
          'composer': song.composer,
          'collection': song.collection,
          'coverArtUrl': song.coverArtUrl,
          'releaseDate': song.releaseDate,
          'genre': song.genre,
          'musicBrainzId': song.musicBrainzId,
        });
      }
      await libraryFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(entries),
        flush: true,
      );
    } catch (error) {
      message = 'Songbook could not be saved: $error';
    }
  }

  void selectSong(MidiSong song) {
    stop(reset: true);
    selectedSong = song;
    loopStart = 0;
    loopEnd = song.duration;
    loopEnabled = false;
    bookmarks.clear();
    annotations.clear();
    correctNotes = 0;
    attemptedNotes = 0;
    _waitMatchedNotes.clear();
    _completionReported = false;
    notifyListeners();
  }

  void setPracticeMode(PracticeMode mode) {
    if (practiceMode == mode) return;
    stop(reset: true);
    practiceMode = mode;
    correctNotes = 0;
    attemptedNotes = 0;
    _waitMatchedNotes.clear();
    notifyListeners();
  }

  void setPracticeHand(PracticeHand hand) {
    practiceHand = hand;
    _waitMatchedNotes.clear();
    notifyListeners();
  }

  void setScoreView(ScoreView view) {
    scoreView = view;
    notifyListeners();
  }

  void setShowNoteNames(bool enabled) {
    showNoteNames = enabled;
    notifyListeners();
  }

  Future<void> setMetronome(bool enabled) async {
    metronomeEnabled = enabled;
    if (enabled) await _pianoSound.initialize();
    notifyListeners();
  }

  Future<void> playTrainingClick({bool accent = false}) async {
    await _pianoSound.initialize();
    _click(accent: accent);
  }

  void setCountInBeats(int beats) {
    countInBeats = beats.clamp(0, 8);
    notifyListeners();
  }

  void setTimingTolerance(double seconds) {
    timingTolerance = seconds.clamp(.06, .4);
    notifyListeners();
  }

  void setAutoTempoRamp(bool enabled) {
    autoTempoRamp = enabled;
    notifyListeners();
  }

  void setLoopEnabled(bool enabled) {
    final song = selectedSong;
    loopEnabled = enabled;
    if (enabled && song != null && loopEnd <= loopStart) {
      loopStart = position.clamp(0, song.duration);
      loopEnd = (loopStart + 10).clamp(0, song.duration);
    }
    notifyListeners();
  }

  void setLoopRange(double start, double end) {
    final duration = selectedSong?.duration ?? 0;
    loopStart = start.clamp(0, duration);
    loopEnd = end.clamp(loopStart + .1, duration);
    loopEnabled = true;
    notifyListeners();
  }

  void addBookmark() {
    if (bookmarks.any((value) => (value - position).abs() < .5)) return;
    bookmarks.add(position);
    bookmarks.sort();
    final seconds = position.floor();
    message =
        'Bookmark added at ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
    notifyListeners();
  }

  void removeBookmark(double value) {
    bookmarks.remove(value);
    annotations.remove(value);
    notifyListeners();
  }

  void setAnnotation(double value, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      annotations.remove(value);
    } else {
      if (!bookmarks.contains(value)) bookmarks.add(value);
      annotations[value] = trimmed;
    }
    notifyListeners();
  }

  void togglePlayback() {
    if (countInRemaining > 0) {
      _cancelCountIn();
      return;
    }
    isPlaying ? pause() : play();
  }

  void play() {
    final song = selectedSong;
    if (song == null || song.duration <= 0) return;
    if (practiceMode == PracticeMode.playAlong &&
        position <= .01 &&
        countInBeats > 0 &&
        !_startingAfterCountIn) {
      _startCountIn(song);
      return;
    }
    if (position >= song.duration) {
      _completionReported = false;
      correctNotes = 0;
      attemptedNotes = 0;
      seek(0);
    }
    if (practiceMode == PracticeMode.pauseAndPlay) {
      final nextStart = _nextNoteStart(position);
      if (nextStart == null) {
        position = song.duration;
        return;
      }
      position = nextStart;
      _waitMatchedNotes.clear();
      isPlaying = true;
      notifyListeners();
      return;
    }
    _eventIndex = song.events.indexWhere((event) => event.seconds >= position);
    if (_eventIndex < 0) _eventIndex = song.events.length;
    _positionAtStart = position;
    _playStarted = DateTime.now();
    _lastMetronomeBeat = -1;
    isPlaying = true;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) => _tick());
    notifyListeners();
  }

  void _tick() {
    final song = selectedSong;
    if (!isPlaying || song == null || _playStarted == null) return;
    position =
        _positionAtStart +
        DateTime.now().difference(_playStarted!).inMicroseconds /
            1000000 *
            speed;
    if (metronomeEnabled) {
      final beatSeconds = 60 / song.bpm;
      final beat = (position / beatSeconds).floor();
      if (beat != _lastMetronomeBeat) {
        _lastMetronomeBeat = beat;
        _click(accent: beat % _beatsPerMeasure(song) == 0);
      }
    }
    while (_eventIndex < song.events.length &&
        song.events[_eventIndex].seconds <= position) {
      final event = song.events[_eventIndex++];
      final command = event.data[0] & 0xF0;
      if ((command == 0x80 || command == 0x90) &&
          !_noteAllowed(event.data[1])) {
        continue;
      }
      _trackFileNote(event.data);
      if (connectedDevice != null) {
        _midi.sendData(event.data, deviceId: connectedDevice!.id);
      }
    }
    if (loopEnabled && loopEnd > loopStart && position >= loopEnd) {
      _restartPlaybackAt(loopStart);
    } else if (position >= song.duration) {
      position = song.duration;
      _reportProgress(completed: true);
      _applyTempoRamp();
      pause(sendPanic: true);
    }
    notifyListeners();
  }

  void pause({bool sendPanic = true}) {
    _cancelCountIn(notify: false);
    isPlaying = false;
    _ticker?.cancel();
    _ticker = null;
    if (sendPanic) _panic();
    if (selectedSong == null || position < selectedSong!.duration) {
      _reportProgress(completed: false);
    }
    notifyListeners();
  }

  void stop({bool reset = false}) {
    pause();
    if (reset) {
      position = 0;
      _completionReported = false;
      correctNotes = 0;
      attemptedNotes = 0;
      earlyNotes = 0;
      onTimeNotes = 0;
      lateNotes = 0;
    }
  }

  void seek(double value) {
    final song = selectedSong;
    if (song == null) return;
    final wasPlaying = isPlaying;
    pause();
    position = value.clamp(0, song.duration);
    _waitMatchedNotes.clear();
    _eventIndex = song.events.indexWhere((event) => event.seconds >= position);
    if (_eventIndex < 0) _eventIndex = song.events.length;
    if (wasPlaying) play();
    notifyListeners();
  }

  void setSpeed(double value) {
    final wasPlaying = isPlaying;
    if (wasPlaying) pause();
    speed = value;
    if (wasPlaying) play();
    notifyListeners();
  }

  void audition(int note, bool on) {
    final data = Uint8List.fromList([on ? 0x90 : 0x80, note, on ? 90 : 0]);
    if (connectedDevice != null) {
      _midi.sendData(data, deviceId: connectedDevice!.id);
    }
    if (on) {
      playedNotes.add(note);
      _registerPracticeNote(note);
      if (hearNotesEnabled) _pianoSound.noteOn(note, 90);
    } else {
      playedNotes.remove(note);
      if (hearNotesEnabled) _pianoSound.noteOff(note);
    }
    notifyListeners();
  }

  void _trackFileNote(Uint8List data) {
    final command = data[0] & 0xF0;
    if (command == 0x90 && data[2] > 0) fileNotes.add(data[1]);
    if (command == 0x80 || (command == 0x90 && data[2] == 0)) {
      fileNotes.remove(data[1]);
    }
  }

  void _handlePacket(MidiPacket packet) {
    inputPacketCount++;
    _confirmBluetoothInput();
    final messages = _liveMidiParser.parse(
      packet.data,
      flushPendingNrpn: false,
    );
    for (final message in messages) {
      _handleMidiMessage(message);
    }
    notifyListeners();
  }

  void _handleMidiMessage(MidiMessage midiMessage) {
    if (midiMessage is NoteOnMessage && midiMessage.velocity > 0) {
      _handleLiveNote(midiMessage.note, midiMessage.velocity, true);
    } else if (midiMessage is NoteOffMessage ||
        (midiMessage is NoteOnMessage && midiMessage.velocity == 0)) {
      final note = midiMessage is NoteOffMessage
          ? midiMessage.note
          : (midiMessage as NoteOnMessage).note;
      _handleLiveNote(note, 0, false);
    } else if (midiMessage is CCMessage && midiMessage.controller == 64) {
      sustainPedalValue = midiMessage.value;
      sustainPedalDown = midiMessage.value >= 64;
      if (hearNotesEnabled) _pianoSound.setSustain(sustainPedalDown);
    }
  }

  String? _lastLiveEvent;
  DateTime? _lastLiveEventAt;

  void _handleLiveNote(int note, int velocity, bool on) {
    // The direct BLE fallback and the package stream can both see the same
    // notification. Ignore only the immediate duplicate, not a repeated key.
    final signature = '${on ? 1 : 0}:$note:$velocity';
    final now = DateTime.now();
    if (_lastLiveEvent == signature &&
        _lastLiveEventAt != null &&
        now.difference(_lastLiveEventAt!) < const Duration(milliseconds: 20)) {
      return;
    }
    _lastLiveEvent = signature;
    _lastLiveEventAt = now;
    if (on) {
      playedNotes.add(note);
      lastInputNote = note;
      lastInputVelocity = velocity;
      inputNoteCount++;
      _registerPracticeNote(note);
    } else {
      playedNotes.remove(note);
    }
    if (hearNotesEnabled) {
      if (on) {
        _pianoSound.noteOn(note, velocity);
      } else {
        _pianoSound.noteOff(note);
      }
    }
  }

  void _handleBlePacket(Uint8List packet) {
    inputPacketCount++;
    _confirmBluetoothInput();
    for (final bytes in _decodeBleMidiPacket(packet)) {
      final messages = _liveMidiParser.parse(bytes, flushPendingNrpn: false);
      for (final message in messages) {
        _handleMidiMessage(message);
      }
    }
    notifyListeners();
  }

  List<Uint8List> _decodeBleMidiPacket(Uint8List packet) {
    if (packet.length <= 2) return const [];
    final output = <Uint8List>[];
    var index = 1; // byte 0 is the BLE-MIDI header
    int? runningStatus;
    while (index < packet.length) {
      // Every BLE-MIDI message begins with a timestamp byte. With running
      // status the byte after it is data; otherwise it is a MIDI status byte.
      if ((packet[index] & 0x80) != 0) index++;
      if (index >= packet.length) break;
      if ((packet[index] & 0x80) != 0) {
        runningStatus = packet[index++];
      }
      final status = runningStatus;
      if (status == null) break;
      final high = status & 0xF0;
      final dataLength = (high == 0xC0 || high == 0xD0) ? 1 : 2;
      if (status >= 0xF0 || index + dataLength > packet.length) break;
      final message = <int>[status];
      for (var count = 0; count < dataLength; count++) {
        if (index >= packet.length || (packet[index] & 0x80) != 0) break;
        message.add(packet[index++]);
      }
      if (message.length == dataLength + 1) {
        output.add(Uint8List.fromList(message));
      } else {
        break;
      }
    }
    return output;
  }

  void _registerPracticeNote(int note) {
    if (!isPlaying) return;
    attemptedNotes++;
    _scheduleProgressSave();
    final expected = expectedNotes;
    if (!expected.contains(note)) return;
    correctNotes++;
    final matching = selectedSong?.notes
        .where(
          (candidate) =>
              candidate.note == note &&
              candidate.start >= position - .5 &&
              candidate.start <= position + .5,
        )
        .toList();
    if (matching != null && matching.isNotEmpty) {
      matching.sort(
        (a, b) =>
            (a.start - position).abs().compareTo((b.start - position).abs()),
      );
      final delta = position - matching.first.start;
      if (delta < -timingTolerance) {
        earlyNotes++;
      } else if (delta > timingTolerance) {
        lateNotes++;
      } else {
        onTimeNotes++;
      }
    }
    if (practiceMode != PracticeMode.pauseAndPlay) return;
    _waitMatchedNotes.add(note);
    if (_waitMatchedNotes.containsAll(expected)) _advanceWaitStep();
  }

  void _advanceWaitStep() {
    final song = selectedSong;
    if (song == null) return;
    final currentStart = _currentWaitGroup.isEmpty
        ? position
        : _currentWaitGroup.first.start;
    double? next;
    for (final note in song.notes) {
      if (_noteAllowed(note.note) && note.start > currentStart + .06) {
        next = note.start;
        break;
      }
    }
    _waitMatchedNotes.clear();
    if (loopEnabled && loopEnd > loopStart && next != null && next >= loopEnd) {
      position = loopStart;
      return;
    }
    if (next == null) {
      position = song.duration;
      isPlaying = false;
      message = 'Piece complete — well played!';
      _reportProgress(completed: true);
      _applyTempoRamp();
      return;
    }
    position = next;
  }

  double? _nextNoteStart(double from) {
    final song = selectedSong;
    if (song == null) return null;
    for (final note in song.notes) {
      if (_noteAllowed(note.note) && note.start >= from - .01) {
        return note.start;
      }
    }
    return null;
  }

  void _scheduleProgressSave() {
    _progressTimer?.cancel();
    _progressTimer = Timer(
      const Duration(milliseconds: 500),
      () => _reportProgress(completed: false),
    );
  }

  void _reportProgress({required bool completed}) {
    final song = selectedSong;
    if (song == null || onProgress == null) return;
    if (completed && _completionReported) return;
    if (completed) _completionReported = true;
    onProgress!(song.id, position, correctNotes, attemptedNotes, completed);
  }

  List<MidiNote> get _currentWaitGroup {
    final song = selectedSong;
    if (song == null) return const [];
    final start = _nextNoteStart(position);
    if (start == null) return const [];
    return song.notes
        .where((note) => (note.start - start).abs() <= .06)
        .where((note) => _noteAllowed(note.note))
        .toList();
  }

  Set<int> get expectedNotes {
    final song = selectedSong;
    if (song == null) return {};
    if (practiceMode == PracticeMode.pauseAndPlay) {
      return _currentWaitGroup.map((note) => note.note).toSet();
    }
    return song.notes
        .where(
          (note) =>
              _noteAllowed(note.note) &&
              note.start >= position - .18 &&
              note.start <= position + .35,
        )
        .map((note) => note.note)
        .toSet();
  }

  Set<int> get matchedWaitNotes => Set.unmodifiable(_waitMatchedNotes);

  bool _noteAllowed(int note) => switch (practiceHand) {
    PracticeHand.both => true,
    PracticeHand.left => note < 60,
    PracticeHand.right => note >= 60,
  };

  int _beatsPerMeasure(MidiSong song) =>
      int.tryParse(song.timeSignature.split('/').first) ?? 4;

  Future<void> _startCountIn(MidiSong song) async {
    _cancelCountIn(notify: false);
    await _pianoSound.initialize();
    countInRemaining = countInBeats;
    notifyListeners();
    void beat() {
      if (countInRemaining <= 0) return;
      _click(accent: countInRemaining == countInBeats);
      countInRemaining--;
      notifyListeners();
      if (countInRemaining == 0) {
        _countInTimer?.cancel();
        _startingAfterCountIn = true;
        play();
        _startingAfterCountIn = false;
      }
    }

    beat();
    if (countInRemaining > 0) {
      _countInTimer = Timer.periodic(
        Duration(milliseconds: (60000 / song.bpm / speed).round()),
        (_) => beat(),
      );
    }
  }

  void _cancelCountIn({bool notify = true}) {
    _countInTimer?.cancel();
    _countInTimer = null;
    countInRemaining = 0;
    if (notify) notifyListeners();
  }

  void _click({required bool accent}) {
    final note = accent ? 96 : 91;
    _pianoSound.noteOn(note, accent ? 105 : 72);
    Timer(const Duration(milliseconds: 65), () => _pianoSound.noteOff(note));
  }

  void _restartPlaybackAt(double value) {
    _panic();
    fileNotes.clear();
    position = value;
    _positionAtStart = value;
    _playStarted = DateTime.now();
    _eventIndex = selectedSong!.events.indexWhere(
      (event) => event.seconds >= value,
    );
    if (_eventIndex < 0) _eventIndex = selectedSong!.events.length;
  }

  void _applyTempoRamp() {
    if (!autoTempoRamp || attemptedNotes == 0 || accuracy < 80) return;
    final previous = speed;
    speed = (speed + .05).clamp(.5, 1.5);
    if (speed > previous) {
      message =
          'Great accuracy — next round increased to ${speed.toStringAsFixed(2)}×';
    }
  }

  String get lastInputNoteLabel {
    final note = lastInputNote;
    if (note == null) return 'Waiting for a key…';
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

  int get accuracy => attemptedNotes == 0
      ? 0
      : (correctNotes / attemptedNotes * 100).round().clamp(0, 100);
  bool get fp10Visible => devices.any(
    (device) =>
        device.name.toLowerCase().contains('fp-10') ||
        device.name.toLowerCase().contains('roland'),
  );

  bool get bluetoothAvailable =>
      bluetoothState != BluetoothState.unsupported &&
      bluetoothState != BluetoothState.unauthorized;

  int get bluetoothDeviceCount =>
      devices.where((device) => device.type == MidiDeviceType.ble).length;

  void clearMessage() {
    message = null;
    notifyListeners();
  }

  void _panic() {
    fileNotes.clear();
    if (connectedDevice == null) return;
    for (var channel = 0; channel < 16; channel++) {
      _midi.sendData(
        Uint8List.fromList([0xB0 | channel, 123, 0]),
        deviceId: connectedDevice!.id,
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _countInTimer?.cancel();
    _scanTimer?.cancel();
    if (isBluetoothScanning) {
      try {
        unawaited(UniversalBle.stopScan());
      } catch (_) {}
    }
    _inputSubscription?.cancel();
    _bleInputSubscription?.cancel();
    _inputHealthTimer?.cancel();
    _progressTimer?.cancel();
    _setupSubscription?.cancel();
    _bluetoothSubscription?.cancel();
    _panic();
    _pianoSound.dispose();
    _midi.dispose();
    super.dispose();
  }
}

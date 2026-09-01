import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pianora/app_state.dart';
import 'package:pianora/design_system.dart';
import 'package:pianora/main.dart';
import 'package:pianora/midi_song.dart';
import 'package:pianora/piano_controller.dart';

void main() {
  testWidgets('primary pages do not overflow at phone and tablet sizes', (
    tester,
  ) async {
    final appState = PianoraAppState()..isLoaded = true;
    final controller = PianoController()
      ..isLoading = false
      ..selectedSong = _song;
    controller.songs.add(_song);
    const visuals = PianoraVisuals(
      language: DesignLanguage.minimalSwiss,
      brightness: Brightness.light,
    );
    for (final size in const [
      Size(390, 844),
      Size(768, 1024),
      Size(1100, 650),
      Size(1440, 900),
    ]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: appState.accentColor,
              dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
            ),
            extensions: const [visuals],
          ),
          home: PianoHome(appState: appState, initialController: controller),
        ),
      );
      await tester.pump();
      _expectNoLayoutException(tester, 'Library at $size');

      final compactNavigation = size.width < 900 || size.height < 620;
      for (final entry in const [
        (1, 'Songbook'),
        (2, 'Practice'),
        (3, 'Planner'),
        (4, 'Awards'),
        (5, 'Settings'),
      ]) {
        final target = find.byKey(
          ValueKey(
            compactNavigation
                ? 'navigation-${entry.$1}'
                : 'side-navigation-${entry.$2}',
          ),
        );
        expect(target, findsOneWidget, reason: '${entry.$2} at $size');
        await tester.tap(target);
        await tester.pump(const Duration(milliseconds: 500));
        _expectNoLayoutException(tester, '${entry.$2} at $size');
        if (entry.$2 == 'Settings') {
          expect(find.text('Open-source licenses'), findsOneWidget);
        }
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 11));
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

void _expectNoLayoutException(WidgetTester tester, String location) {
  final exception = tester.takeException();
  if (exception is FlutterError) {
    final overflowing = <String>[];
    for (final flex in tester.allRenderObjects.whereType<RenderFlex>()) {
      RenderBox? child = flex.firstChild;
      var extent = 0.0;
      while (child != null) {
        final parentData = child.parentData! as FlexParentData;
        extent = flex.direction == Axis.horizontal
            ? math.max(extent, parentData.offset.dx + child.size.width)
            : math.max(extent, parentData.offset.dy + child.size.height);
        child = flex.childAfter(child);
      }
      final available = flex.direction == Axis.horizontal
          ? flex.size.width
          : flex.size.height;
      if (extent > available + .5) {
        overflowing.add(
          '${flex.debugCreator} ${flex.direction} $extent > $available',
        );
      }
    }
    fail('$location\n${exception.toStringDeep()}\n${overflowing.join('\n')}');
  }
  expect(exception, isNull, reason: location);
}

final _song = MidiSong(
  id: 'responsive-test',
  title: 'Responsive Prelude',
  composer: 'Test Composer',
  collection: 'Tests',
  duration: 120,
  bpm: 90,
  timeSignature: '4/4',
  keySignature: 'C major',
  events: const [],
  notes: const [MidiNote(note: 60, start: 0, end: 1, velocity: 90, channel: 0)],
  bytes: Uint8List(0),
);

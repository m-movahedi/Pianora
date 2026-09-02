import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piano_ish/app_state.dart';
import 'package:piano_ish/design_system.dart';

void main() {
  test('learning paths round-trip songs and rich lesson documents', () {
    final original = LearningPath(
      id: 'path-1',
      title: 'Starter route',
      description: 'A mixed learning path',
      updatedAt: DateTime.utc(2026, 8, 22),
      steps: const [
        PlannerStep(
          id: 'song-1',
          title: 'Prelude',
          type: PlannerStepType.song,
          songId: 'bach-846',
          minimumAccuracy: 85,
        ),
        PlannerStep(
          id: 'lesson-1',
          title: 'Technique notes',
          type: PlannerStepType.document,
          content: '# Relax\n<div>Keep the wrist loose.</div>',
          completed: true,
        ),
      ],
    );

    final restored = LearningPath.fromJson(original.toJson());

    expect(restored.title, original.title);
    expect(restored.steps, hasLength(2));
    expect(restored.steps.first.minimumAccuracy, 85);
    expect(restored.steps.last.type, PlannerStepType.document);
    expect(restored.steps.last.content, contains('<div>'));
  });

  test('where you left off chooses the newest unfinished path', () {
    final state = PianoIshAppState();
    state.learningPaths.addAll([
      LearningPath(
        id: 'older',
        title: 'Older path',
        description: '',
        updatedAt: DateTime.utc(2026, 1, 1),
        steps: const [
          PlannerStep(
            id: 'one',
            title: 'Done',
            type: PlannerStepType.document,
            completed: true,
          ),
        ],
      ),
      LearningPath(
        id: 'newer',
        title: 'Current path',
        description: '',
        updatedAt: DateTime.utc(2026, 2, 1),
        steps: const [
          PlannerStep(
            id: 'two',
            title: 'Next song',
            type: PlannerStepType.song,
            songId: 'song',
          ),
        ],
      ),
    ]);

    expect(state.mostRecentIncompletePath?.id, 'newer');
    expect(state.pathProgress(state.learningPaths.first), 1);
  });

  test('achievement statistics are derived from saved practice data', () {
    final state = PianoIshAppState();
    state.dailyPracticeSeconds.addAll({
      '2026-08-18': 600,
      '2026-08-19': 900,
      '2026-08-20': 300,
      '2026-08-22': 120,
    });
    state.scoreHistory.addAll([
      ScoreRecord(
        songId: 'bach',
        accuracy: 82,
        correct: 82,
        attempted: 100,
        playedAt: DateTime.utc(2026, 8, 20),
      ),
      ScoreRecord(
        songId: 'mozart',
        accuracy: 96.5,
        correct: 193,
        attempted: 200,
        playedAt: DateTime.utc(2026, 8, 22),
      ),
    ]);

    expect(state.longestPracticeStreak, 3);
    expect(state.totalPracticeMinutes, 32);
    expect(state.completedSessions, 2);
    expect(state.bestAccuracy, 96.5);
    expect(state.totalCorrectNotes, 275);
    expect(state.practicedSongCount, 2);
  });

  test('accent foregrounds meet WCAG AA contrast in both themes', () {
    for (final brightness in Brightness.values) {
      for (final accent in PianoIshAppState.accentPresets) {
        final scheme = ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
          dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
        );
        final heroColors = [
          scheme.primary,
          Color.lerp(scheme.primary, scheme.tertiary, .58)!,
        ];
        final foreground = readableForegroundFor(heroColors);
        for (final background in heroColors) {
          expect(
            _contrastRatio(foreground, background),
            greaterThanOrEqualTo(4.5),
            reason:
                'Insufficient contrast for ${accent.toARGB32()} in $brightness',
          );
        }
      }
    }
  });
}

double _contrastRatio(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() < second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  return (lighter + .05) / (darker + .05);
}

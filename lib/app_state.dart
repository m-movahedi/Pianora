import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_storage.dart';
import 'design_system.dart';

enum PlannerStepType { song, document }

class PlannerStep {
  const PlannerStep({
    required this.id,
    required this.title,
    required this.type,
    this.songId,
    this.minimumAccuracy = 80,
    this.content,
    this.completed = false,
  });

  final String id;
  final String title;
  final PlannerStepType type;
  final String? songId;
  final int minimumAccuracy;
  final String? content;
  final bool completed;

  PlannerStep copyWith({bool? completed}) => PlannerStep(
    id: id,
    title: title,
    type: type,
    songId: songId,
    minimumAccuracy: minimumAccuracy,
    content: content,
    completed: completed ?? this.completed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'type': type.name,
    'songId': songId,
    'minimumAccuracy': minimumAccuracy,
    'content': content,
    'completed': completed,
  };

  factory PlannerStep.fromJson(Map<String, Object?> json) => PlannerStep(
    id: json['id'] as String? ?? _newId('step'),
    title: json['title'] as String? ?? 'Untitled step',
    type: PlannerStepType.values.firstWhere(
      (value) => value.name == json['type'],
      orElse: () => PlannerStepType.document,
    ),
    songId: json['songId'] as String?,
    minimumAccuracy: (json['minimumAccuracy'] as num?)?.round() ?? 80,
    content: json['content'] as String?,
    completed: json['completed'] as bool? ?? false,
  );
}

class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final List<PlannerStep> steps;
  final DateTime updatedAt;

  LearningPath copyWith({
    String? title,
    String? description,
    List<PlannerStep>? steps,
    DateTime? updatedAt,
  }) => LearningPath(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    steps: steps ?? this.steps,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'steps': steps.map((step) => step.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory LearningPath.fromJson(Map<String, Object?> json) => LearningPath(
    id: json['id'] as String? ?? _newId('path'),
    title: json['title'] as String? ?? 'Imported learning path',
    description: json['description'] as String? ?? '',
    steps: (json['steps'] as List<Object?>? ?? const [])
        .whereType<Map>()
        .map((step) => PlannerStep.fromJson(step.cast<String, Object?>()))
        .toList(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class SongProgress {
  const SongProgress({
    required this.songId,
    required this.position,
    required this.bestAccuracy,
    required this.attempts,
    required this.lastPlayed,
  });

  final String songId;
  final double position;
  final double bestAccuracy;
  final int attempts;
  final DateTime lastPlayed;

  Map<String, Object?> toJson() => {
    'songId': songId,
    'position': position,
    'bestAccuracy': bestAccuracy,
    'attempts': attempts,
    'lastPlayed': lastPlayed.toIso8601String(),
  };

  factory SongProgress.fromJson(Map<String, Object?> json) => SongProgress(
    songId: json['songId'] as String? ?? '',
    position: (json['position'] as num?)?.toDouble() ?? 0,
    bestAccuracy: (json['bestAccuracy'] as num?)?.toDouble() ?? 0,
    attempts: (json['attempts'] as num?)?.round() ?? 0,
    lastPlayed:
        DateTime.tryParse(json['lastPlayed'] as String? ?? '') ??
        DateTime.now(),
  );
}

class ScoreRecord {
  const ScoreRecord({
    required this.songId,
    required this.accuracy,
    required this.correct,
    required this.attempted,
    required this.playedAt,
  });

  final String songId;
  final double accuracy;
  final int correct;
  final int attempted;
  final DateTime playedAt;

  Map<String, Object?> toJson() => {
    'songId': songId,
    'accuracy': accuracy,
    'correct': correct,
    'attempted': attempted,
    'playedAt': playedAt.toIso8601String(),
  };

  factory ScoreRecord.fromJson(Map<String, Object?> json) => ScoreRecord(
    songId: json['songId'] as String? ?? '',
    accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
    correct: (json['correct'] as num?)?.round() ?? 0,
    attempted: (json['attempted'] as num?)?.round() ?? 0,
    playedAt:
        DateTime.tryParse(json['playedAt'] as String? ?? '') ?? DateTime.now(),
  );
}

class PianoIshAppState extends ChangeNotifier {
  static const accentPresets = <Color>[
    Color(0xFF705CF6),
    Color(0xFF4C7CF3),
    Color(0xFF00A7A0),
    Color(0xFF25A86F),
    Color(0xFFF0A52B),
    Color(0xFFF06B5F),
    Color(0xFFE84A8A),
    Color(0xFF9B59D0),
    Color(0xFF596275),
    Color(0xFF252A34),
  ];

  ThemeMode themeMode = ThemeMode.system;
  DesignLanguage designLanguage = DesignLanguage.minimalSwiss;
  Color accentColor = accentPresets.first;
  String profileName = '';
  String? profileImagePath;
  bool saveProgress = true;
  int dailyGoalMinutes = 20;
  String appVersion = '1.0.0';
  final Map<String, SongProgress> progress = {};
  final List<ScoreRecord> scoreHistory = [];
  final List<LearningPath> learningPaths = [];
  final Map<String, double> dailyPracticeSeconds = {};
  final Map<String, double> _lastSongPositions = {};
  bool isLoaded = false;

  Future<File?> _stateFile() async {
    final directory = await pianoIshSupportDirectory();
    if (directory == null) return null;
    return File('${directory.path}${Platform.pathSeparator}app_state.json');
  }

  Future<void> load() async {
    try {
      appVersion = (await PackageInfo.fromPlatform()).version;
      final file = await _stateFile();
      if (file != null && await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, Object?>;
        themeMode = ThemeMode.values.firstWhere(
          (value) => value.name == json['themeMode'],
          orElse: () => ThemeMode.system,
        );
        final designRevision =
            (json['designExperimentRevision'] as num?)?.round() ?? 0;
        designLanguage = designRevision < 3
            ? DesignLanguage.minimalSwiss
            : DesignLanguage.values.firstWhere(
                (value) => value.name == json['designLanguage'],
                orElse: () => DesignLanguage.minimalSwiss,
              );
        accentColor = Color(
          (json['accentColor'] as num?)?.round() ?? accentColor.toARGB32(),
        );
        profileName = json['profileName'] as String? ?? '';
        profileImagePath = json['profileImagePath'] as String?;
        saveProgress = json['saveProgress'] as bool? ?? true;
        dailyGoalMinutes = (json['dailyGoalMinutes'] as num?)?.round() ?? 20;
        final daily = json['dailyPracticeSeconds'];
        if (daily is Map) {
          for (final entry in daily.entries) {
            dailyPracticeSeconds[entry.key.toString()] =
                (entry.value as num?)?.toDouble() ?? 0;
          }
        }
        for (final item in (json['progress'] as List<Object?>? ?? const [])) {
          if (item is Map) {
            final value = SongProgress.fromJson(item.cast<String, Object?>());
            if (value.songId.isNotEmpty) progress[value.songId] = value;
          }
        }
        scoreHistory.addAll(
          (json['scoreHistory'] as List<Object?>? ?? const [])
              .whereType<Map>()
              .map(
                (item) => ScoreRecord.fromJson(item.cast<String, Object?>()),
              ),
        );
        learningPaths.addAll(
          (json['learningPaths'] as List<Object?>? ?? const [])
              .whereType<Map>()
              .map(
                (item) => LearningPath.fromJson(item.cast<String, Object?>()),
              ),
        );
      }
    } catch (_) {
      // A damaged settings file must not prevent the trainer from opening.
    }
    isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    notifyListeners();
    await _save();
  }

  Future<void> setDesignLanguage(DesignLanguage value) async {
    designLanguage = value;
    notifyListeners();
    await _save();
  }

  Future<void> setAccent(Color value) async {
    accentColor = value;
    notifyListeners();
    await _save();
  }

  Future<void> setProfile(String name, String? imagePath) async {
    profileName = name.trim();
    profileImagePath = imagePath;
    notifyListeners();
    await _save();
  }

  Future<void> setSaveProgress(bool value) async {
    saveProgress = value;
    notifyListeners();
    await _save();
  }

  Future<void> setDailyGoalMinutes(int value) async {
    dailyGoalMinutes = value.clamp(5, 120);
    notifyListeners();
    await _save();
  }

  Future<void> recordPractice({
    required String songId,
    required double position,
    required int correct,
    required int attempted,
    required bool completed,
  }) async {
    if (!saveProgress || songId.isEmpty) return;
    final accuracy = attempted == 0 ? 0.0 : correct / attempted * 100;
    final previousPosition = _lastSongPositions[songId] ?? 0;
    if (position >= previousPosition) {
      final day = _dayKey(DateTime.now());
      dailyPracticeSeconds[day] =
          (dailyPracticeSeconds[day] ?? 0) + (position - previousPosition);
    }
    _lastSongPositions[songId] = completed ? 0 : position;
    final previous = progress[songId];
    progress[songId] = SongProgress(
      songId: songId,
      position: completed ? 0 : position,
      bestAccuracy: mathMax(previous?.bestAccuracy ?? 0, accuracy),
      attempts: (previous?.attempts ?? 0) + (completed ? 1 : 0),
      lastPlayed: DateTime.now(),
    );
    if (completed) {
      scoreHistory.insert(
        0,
        ScoreRecord(
          songId: songId,
          accuracy: accuracy,
          correct: correct,
          attempted: attempted,
          playedAt: DateTime.now(),
        ),
      );
      if (scoreHistory.length > 100) {
        scoreHistory.removeRange(100, scoreHistory.length);
      }
    }
    _syncSongSteps(songId);
    notifyListeners();
    await _save();
  }

  void _syncSongSteps(String songId) {
    final accuracy = progress[songId]?.bestAccuracy ?? 0;
    for (var pathIndex = 0; pathIndex < learningPaths.length; pathIndex++) {
      final path = learningPaths[pathIndex];
      final steps = path.steps
          .map(
            (step) => step.type == PlannerStepType.song && step.songId == songId
                ? step.copyWith(completed: accuracy >= step.minimumAccuracy)
                : step,
          )
          .toList();
      learningPaths[pathIndex] = path.copyWith(steps: steps);
    }
  }

  Future<void> upsertPath(LearningPath path) async {
    final index = learningPaths.indexWhere((item) => item.id == path.id);
    final updated = path.copyWith(updatedAt: DateTime.now());
    if (index < 0) {
      learningPaths.insert(0, updated);
    } else {
      learningPaths[index] = updated;
    }
    notifyListeners();
    await _save();
  }

  Future<void> removePath(String id) async {
    learningPaths.removeWhere((path) => path.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> setDocumentComplete(
    String pathId,
    String stepId,
    bool completed,
  ) async {
    final index = learningPaths.indexWhere((path) => path.id == pathId);
    if (index < 0) return;
    final path = learningPaths[index];
    learningPaths[index] = path.copyWith(
      steps: path.steps
          .map(
            (step) =>
                step.id == stepId ? step.copyWith(completed: completed) : step,
          )
          .toList(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _save();
  }

  double pathProgress(LearningPath path) {
    if (path.steps.isEmpty) return 0;
    return path.steps.where((step) => step.completed).length /
        path.steps.length;
  }

  LearningPath? get mostRecentIncompletePath {
    final paths = learningPaths.where((path) => pathProgress(path) < 1).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return paths.isEmpty ? null : paths.first;
  }

  double get todayPracticeMinutes =>
      (dailyPracticeSeconds[_dayKey(DateTime.now())] ?? 0) / 60;

  int get practiceStreak {
    var streak = 0;
    var day = DateTime.now();
    while ((dailyPracticeSeconds[_dayKey(day)] ?? 0) > 0) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  double get weeklyPracticeMinutes {
    var total = 0.0;
    final now = DateTime.now();
    for (var offset = 0; offset < 7; offset++) {
      total +=
          dailyPracticeSeconds[_dayKey(now.subtract(Duration(days: offset)))] ??
          0;
    }
    return total / 60;
  }

  double get totalPracticeMinutes =>
      dailyPracticeSeconds.values.fold<double>(0, (sum, value) => sum + value) /
      60;

  int get completedSessions => scoreHistory.length;

  double get bestAccuracy => scoreHistory.fold<double>(
    0,
    (best, score) => mathMax(best, score.accuracy),
  );

  int get totalCorrectNotes =>
      scoreHistory.fold<int>(0, (total, score) => total + score.correct);

  int get practicedSongCount => <String>{
    ...progress.keys.where((id) => id.isNotEmpty),
    ...scoreHistory.map((score) => score.songId).where((id) => id.isNotEmpty),
  }.length;

  int get completedLearningPaths => learningPaths
      .where((path) => path.steps.isNotEmpty && pathProgress(path) >= 1)
      .length;

  int get longestPracticeStreak {
    final days =
        dailyPracticeSeconds.entries
            .where((entry) => entry.value > 0)
            .map((entry) => DateTime.tryParse(entry.key))
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (days.isEmpty) return 0;
    var longest = 1;
    var current = 1;
    for (var index = 1; index < days.length; index++) {
      final gap = days[index].difference(days[index - 1]).inDays;
      if (gap == 1) {
        current++;
        if (current > longest) longest = current;
      } else if (gap > 1) {
        current = 1;
      }
    }
    return longest;
  }

  List<String> get achievements {
    final values = <String>[];
    if (scoreHistory.isNotEmpty) values.add('First performance');
    if (scoreHistory.any((score) => score.accuracy >= 90)) {
      values.add('90% note accuracy');
    }
    if (practiceStreak >= 3) values.add('3-day streak');
    if (practiceStreak >= 7) values.add('7-day streak');
    if (weeklyPracticeMinutes >= 60) values.add('One-hour week');
    return values;
  }

  Future<void> _save() async {
    try {
      final file = await _stateFile();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'themeMode': themeMode.name,
          'designLanguage': designLanguage.name,
          'designExperimentRevision': 3,
          'accentColor': accentColor.toARGB32(),
          'profileName': profileName,
          'profileImagePath': profileImagePath,
          'saveProgress': saveProgress,
          'dailyGoalMinutes': dailyGoalMinutes,
          'dailyPracticeSeconds': dailyPracticeSeconds,
          'progress': progress.values.map((item) => item.toJson()).toList(),
          'scoreHistory': scoreHistory.map((item) => item.toJson()).toList(),
          'learningPaths': learningPaths.map((item) => item.toJson()).toList(),
        }),
        flush: true,
      );
    } catch (_) {
      // Persistence is optional; the in-memory experience remains usable.
    }
  }
}

double mathMax(double a, double b) => a > b ? a : b;

String newLearningId(String prefix) => _newId(prefix);

String _newId(String prefix) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';

String _dayKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

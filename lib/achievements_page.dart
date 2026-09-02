import 'package:flutter/material.dart';

import 'app_state.dart';
import 'design_system.dart';

enum _AchievementTier { bronze, silver, gold, platinum }

class _TierGoal {
  const _TierGoal(this.tier, this.target);

  final _AchievementTier tier;
  final double target;
}

class _AchievementTrack {
  const _AchievementTrack({
    required this.title,
    required this.description,
    required this.icon,
    required this.value,
    required this.unit,
    required this.goals,
    this.decimals = 0,
  });

  final String title;
  final String description;
  final IconData icon;
  final double value;
  final String unit;
  final List<_TierGoal> goals;
  final int decimals;

  int get earned => goals.where((goal) => value >= goal.target).length;
  _TierGoal? get next => earned == goals.length ? null : goals[earned];
}

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.appState});

  final PianoIshAppState appState;

  List<_AchievementTrack> get _tracks => [
    _AchievementTrack(
      title: 'The Regular',
      description: 'Build a lasting daily practice habit.',
      icon: Icons.local_fire_department_rounded,
      value: appState.longestPracticeStreak.toDouble(),
      unit: 'days',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 3),
        _TierGoal(_AchievementTier.silver, 7),
        _TierGoal(_AchievementTier.gold, 30),
        _TierGoal(_AchievementTier.platinum, 100),
      ],
    ),
    _AchievementTrack(
      title: 'Stage Ready',
      description: 'Complete performances from beginning to end.',
      icon: Icons.stadium_rounded,
      value: appState.completedSessions.toDouble(),
      unit: 'performances',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 1),
        _TierGoal(_AchievementTier.silver, 10),
        _TierGoal(_AchievementTier.gold, 50),
        _TierGoal(_AchievementTier.platinum, 100),
      ],
    ),
    _AchievementTrack(
      title: 'Precision',
      description: 'Raise your best note-accuracy score.',
      icon: Icons.center_focus_strong_rounded,
      value: appState.bestAccuracy,
      unit: '% accuracy',
      decimals: 1,
      goals: const [
        _TierGoal(_AchievementTier.bronze, 70),
        _TierGoal(_AchievementTier.silver, 85),
        _TierGoal(_AchievementTier.gold, 95),
        _TierGoal(_AchievementTier.platinum, 100),
      ],
    ),
    _AchievementTrack(
      title: 'Note Collector',
      description: 'Play correct notes during scored performances.',
      icon: Icons.music_note_rounded,
      value: appState.totalCorrectNotes.toDouble(),
      unit: 'notes',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 100),
        _TierGoal(_AchievementTier.silver, 500),
        _TierGoal(_AchievementTier.gold, 2500),
        _TierGoal(_AchievementTier.platinum, 10000),
      ],
    ),
    _AchievementTrack(
      title: 'Repertoire',
      description: 'Practice a wider collection of different pieces.',
      icon: Icons.library_music_rounded,
      value: appState.practicedSongCount.toDouble(),
      unit: 'pieces',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 1),
        _TierGoal(_AchievementTier.silver, 3),
        _TierGoal(_AchievementTier.gold, 10),
        _TierGoal(_AchievementTier.platinum, 25),
      ],
    ),
    _AchievementTrack(
      title: 'Time at the Keys',
      description: 'Accumulate focused practice time.',
      icon: Icons.timer_rounded,
      value: appState.totalPracticeMinutes,
      unit: 'minutes',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 30),
        _TierGoal(_AchievementTier.silver, 180),
        _TierGoal(_AchievementTier.gold, 600),
        _TierGoal(_AchievementTier.platinum, 3000),
      ],
    ),
    _AchievementTrack(
      title: 'Pathfinder',
      description: 'Complete every step in your learning paths.',
      icon: Icons.route_rounded,
      value: appState.completedLearningPaths.toDouble(),
      unit: 'paths',
      goals: const [
        _TierGoal(_AchievementTier.bronze, 1),
        _TierGoal(_AchievementTier.silver, 3),
        _TierGoal(_AchievementTier.gold, 7),
        _TierGoal(_AchievementTier.platinum, 15),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tracks = _tracks;
    final earned = tracks.fold<int>(0, (sum, track) => sum + track.earned);
    final total = tracks.fold<int>(0, (sum, track) => sum + track.goals.length);
    final compact = MediaQuery.sizeOf(context).width < 700;
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 22, 20, 36)
          : const EdgeInsets.fromLTRB(42, 38, 48, 54),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1250),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AchievementHeader(earned: earned, total: total),
              const SizedBox(height: 34),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980 ? 2 : 1;
                  const gap = 18.0;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: tracks
                        .map(
                          (track) => SizedBox(
                            width: width,
                            child: _AchievementCard(track: track),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({required this.earned, required this.total});

  final int earned;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR MILESTONES',
          style: TextStyle(
            color: colors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 9),
        Text('Achievements', style: Theme.of(context).textTheme.displaySmall),
        const SizedBox(height: 8),
        Text(
          'Every achievement has Bronze, Silver, Gold, and Platinum tiers.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: visuals.isSwiss ? visuals.swissInk : colors.primary,
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$earned / $total',
            style: TextStyle(
              color: visuals.isSwiss ? visuals.swissPaper : colors.onPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text(
            'TIERS EARNED',
            style: TextStyle(
              color: (visuals.isSwiss ? visuals.swissPaper : colors.onPrimary)
                  .withValues(alpha: .7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 580) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [copy, const SizedBox(height: 18), summary],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: copy),
            const SizedBox(width: 24),
            summary,
          ],
        );
      },
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.track});

  final _AchievementTrack track;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final next = track.next;
    final previousTarget = track.earned == 0
        ? 0.0
        : track.goals[track.earned - 1].target;
    final progress = next == null
        ? 1.0
        : ((track.value - previousTarget) / (next.target - previousTarget))
              .clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: visuals.isSwiss
            ? visuals.swissSurface
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 26),
        border: Border.all(
          color: visuals.isSwiss
              ? visuals.swissInk.withValues(alpha: .62)
              : colors.outlineVariant.withValues(alpha: .42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 16),
                ),
                child: Icon(track.icon, color: colors.onPrimary, size: 27),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: track.goals
                .map(
                  (goal) => Expanded(
                    child: _TierMarker(
                      goal: goal,
                      unlocked: track.value >= goal.target,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 21),
          ClipRRect(
            borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                '${track.value.toStringAsFixed(track.decimals)} ${track.unit}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                next == null
                    ? 'All tiers unlocked'
                    : '${_tierName(next.tier)} at ${next.target.toStringAsFixed(0)}',
                style: TextStyle(
                  color: next == null
                      ? colors.primary
                      : colors.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierMarker extends StatelessWidget {
  const _TierMarker({required this.goal, required this.unlocked});

  final _TierGoal goal;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final color = _tierColor(goal.tier);
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 360),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: unlocked ? color : color.withValues(alpha: .11),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked
                  ? color
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Icon(
            unlocked ? Icons.workspace_premium_rounded : Icons.lock_outline,
            color: unlocked
                ? readableForeground(color)
                : color.withValues(alpha: .55),
            size: 20,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          _tierName(goal.tier).toUpperCase(),
          style: TextStyle(
            color: unlocked
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: .7,
          ),
        ),
        Text(
          goal.target.toStringAsFixed(0),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

String _tierName(_AchievementTier tier) => switch (tier) {
  _AchievementTier.bronze => 'Bronze',
  _AchievementTier.silver => 'Silver',
  _AchievementTier.gold => 'Gold',
  _AchievementTier.platinum => 'Platinum',
};

Color _tierColor(_AchievementTier tier) => switch (tier) {
  _AchievementTier.bronze => const Color(0xFFAD6B3C),
  _AchievementTier.silver => const Color(0xFF84909E),
  _AchievementTier.gold => const Color(0xFFD6A514),
  _AchievementTier.platinum => const Color(0xFF6977C9),
};

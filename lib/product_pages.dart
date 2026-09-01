import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:url_launcher/url_launcher.dart';

import 'app_state.dart';
import 'design_system.dart';
import 'midi_song.dart';
import 'piano_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.appState,
    required this.controller,
    required this.devicesSection,
  });

  final PianoraAppState appState;
  final PianoController controller;
  final Widget devicesSection;

  Future<void> _editProfile(BuildContext context) async {
    final name = TextEditingController(text: appState.profileName);
    var imagePath = appState.profileImagePath;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit profile'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(
                  appState: appState,
                  radius: 42,
                  overridePath: imagePath,
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () async {
                    final file = await FilePicker.pickFile(
                      type: FileType.image,
                    );
                    if (file?.path != null) {
                      setDialogState(() => imagePath = file!.path);
                    }
                  },
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Choose profile picture'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
    if (result == true) await appState.setProfile(name.text, imagePath);
    name.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 22, 20, 36)
          : const EdgeInsets.fromLTRB(44, 40, 52, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SETTINGS', style: _eyebrow(context)),
              const SizedBox(height: 8),
              Text(
                'Make Pianora yours',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Personalize the studio, manage your learning identity, and keep your practice history safe.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              _SettingsCard(
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle:
                    'Your identity across practice sessions and learning paths',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.profileName.isEmpty
                              ? 'Set up your profile'
                              : appState.profileName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          appState.profileImagePath == null
                              ? 'Add your name and a picture'
                              : 'Profile picture and name are saved locally',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                    final edit = FilledButton.tonalIcon(
                      onPressed: () => _editProfile(context),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    );
                    if (constraints.maxWidth < 500) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ProfileAvatar(appState: appState, radius: 34),
                          const SizedBox(height: 14),
                          details,
                          const SizedBox(height: 16),
                          edit,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        ProfileAvatar(appState: appState, radius: 34),
                        const SizedBox(width: 16),
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        edit,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                icon: Icons.cable_rounded,
                title: 'MIDI devices',
                subtitle:
                    'Connect and manage USB or Bluetooth MIDI instruments',
                child: devicesSection,
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                icon: Icons.palette_outlined,
                title: 'Appearance',
                subtitle:
                    'Choose a mode and an accent that feels like your studio',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Design language',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<DesignLanguage>(
                        segments: const [
                          ButtonSegment(
                            value: DesignLanguage.appleSoft,
                            icon: Icon(Icons.blur_on_rounded),
                            label: Text('Soft Minimal'),
                            tooltip:
                                'Experiment 01: Apple-like soft minimalism',
                          ),
                          ButtonSegment(
                            value: DesignLanguage.skeuomorphicInstrument,
                            icon: Icon(Icons.piano_rounded),
                            label: Text('Instrument'),
                            tooltip:
                                'Experiment 02: tactile skeuomorphic instrument',
                          ),
                          ButtonSegment(
                            value: DesignLanguage.minimalSwiss,
                            icon: Icon(Icons.grid_4x4_rounded),
                            label: Text('Swiss'),
                            tooltip: 'Experiment 03: Minimal / Swiss',
                          ),
                        ],
                        selected: {appState.designLanguage},
                        onSelectionChanged: (value) =>
                            appState.setDesignLanguage(value.first),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(switch (appState.designLanguage) {
                      DesignLanguage.appleSoft =>
                        'Experiment 01 • Frosted surfaces, restrained depth, and quiet typography.',
                      DesignLanguage.skeuomorphicInstrument =>
                        'Experiment 02 • Piano lacquer, warm ivory, walnut, brass, and tactile controls.',
                      DesignLanguage.minimalSwiss =>
                        'Experiment 03 • Strict grid, paper and ink contrast, bold type, and flat geometry.',
                    }, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded),
                            label: Text('System'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                            label: Text('Light'),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                            label: Text('Dark'),
                          ),
                        ],
                        selected: {appState.themeMode},
                        onSelectionChanged: (value) =>
                            appState.setThemeMode(value.first),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Accent color',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: PianoraAppState.accentPresets
                          .map(
                            (color) => _AccentSwatch(
                              color: color,
                              selected:
                                  color.toARGB32() ==
                                  appState.accentColor.toARGB32(),
                              onTap: () => appState.setAccent(color),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SettingsCard(
                icon: Icons.insights_rounded,
                title: 'Progress & score history',
                subtitle: 'Stored privately on this Windows computer',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: appState.saveProgress,
                      onChanged: appState.setSaveProgress,
                      title: const Text('Save practice progress'),
                      subtitle: const Text(
                        'Remember song position, best accuracy, attempts, and completed-session scores.',
                      ),
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Daily practice goal'),
                              Text(
                                'Used for your home dashboard and streak motivation.',
                              ),
                            ],
                          ),
                        ),
                        DropdownButton<int>(
                          value: appState.dailyGoalMinutes,
                          items: const [10, 15, 20, 30, 45, 60]
                              .map(
                                (minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text('$minutes min'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              appState.setDailyGoalMinutes(value);
                            }
                          },
                        ),
                      ],
                    ),
                    if (appState.scoreHistory.isNotEmpty) ...[
                      const Divider(height: 28),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent scores',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...appState.scoreHistory.take(5).map((score) {
                        final matches = controller.songs.where(
                          (item) => item.id == score.songId,
                        );
                        final song = matches.isEmpty ? null : matches.first;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                            child: Text('${score.accuracy.round()}%'),
                          ),
                          title: Text(song?.title ?? 'Practice session'),
                          subtitle: Text(
                            '${score.correct}/${score.attempted} correct • ${_friendlyDate(score.playedAt)}',
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _SettingsCard(
                icon: Icons.policy_outlined,
                title: 'Legal & licenses',
                subtitle:
                    'Copyright notices for the open-source software used by Pianora',
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.description_outlined),
                      title: const Text('Open-source licenses'),
                      subtitle: const Text(
                        'View package, font, audio engine, and framework licenses.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: 'Pianora Piano tranier',
                        applicationVersion: appState.appVersion,
                        applicationIcon: const Icon(
                          Icons.piano_rounded,
                          size: 44,
                        ),
                        applicationLegalese:
                            'Copyright (c) 2026 Mohammad Movahedi',
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.library_music_outlined),
                      title: const Text('Music metadata attribution'),
                      subtitle: const Text(
                        'Metadata provided by MusicBrainz. Genre tags are available under CC BY-NC-SA 3.0. Cover artwork remains the property of its respective copyright holder.',
                      ),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () => launchUrl(
                        Uri.parse('https://musicbrainz.org'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Pianora Piano tranier ${appState.appVersion}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Built with ❤️ by '),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => launchUrl(
                            Uri.parse('https://www.m-movahedi.com'),
                          ),
                          child: const Text('Mohammad Movahedi'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.appState,
    required this.radius,
    this.overridePath,
  });

  final PianoraAppState appState;
  final double radius;
  final String? overridePath;

  @override
  Widget build(BuildContext context) {
    final path = overridePath ?? appState.profileImagePath;
    final file = path == null ? null : File(path);
    final hasImage = file?.existsSync() == true;
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: hasImage ? FileImage(file!) : null,
      child: hasImage
          ? null
          : Text(
              appState.profileName.trim().isEmpty
                  ? 'P'
                  : appState.profileName.trim()[0].toUpperCase(),
              style: TextStyle(
                fontSize: radius * .75,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
    );
  }
}

class PlannerPage extends StatefulWidget {
  const PlannerPage({
    super.key,
    required this.appState,
    required this.controller,
    required this.openPractice,
  });

  final PianoraAppState appState;
  final PianoController controller;
  final VoidCallback openPractice;

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  Future<void> _importPath() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json', 'md', 'markdown', 'html', 'htm'],
    );
    final path = result?.path;
    if (path == null) return;
    final file = File(path);
    final content = await file.readAsString();
    LearningPath learningPath;
    if (path.toLowerCase().endsWith('.json')) {
      final decoded = jsonDecode(content);
      final map = decoded is Map<String, Object?>
          ? decoded
          : (decoded as Map).cast<String, Object?>();
      learningPath = LearningPath.fromJson(
        map,
      ).copyWith(updatedAt: DateTime.now());
    } else {
      final title = result!.name.replaceFirst(RegExp(r'\.[^.]+$'), '');
      learningPath = LearningPath(
        id: newLearningId('path'),
        title: title,
        description: 'Imported learning document',
        updatedAt: DateTime.now(),
        steps: [
          PlannerStep(
            id: newLearningId('step'),
            title: title,
            type: PlannerStepType.document,
            content: content,
          ),
        ],
      );
    }
    await widget.appState.upsertPath(learningPath);
  }

  Future<void> _exportPath(LearningPath path) async {
    await FilePicker.saveFile(
      dialogTitle: 'Export learning path',
      fileName: '${_safeName(path.title)}.pianora.json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
      mimeType: 'application/json',
      bytes: Uint8List.fromList(
        utf8.encode(const JsonEncoder.withIndent('  ').convert(path.toJson())),
      ),
    );
  }

  Future<void> _editPath([LearningPath? existing]) async {
    final updated = await showDialog<LearningPath>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _PathEditor(existing: existing, songs: widget.controller.songs),
    );
    if (updated != null) await widget.appState.upsertPath(updated);
  }

  Future<void> _openPath(LearningPath path) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 700),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            path.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(path.description),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: path.steps.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final step = path.steps[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: step.completed
                              ? const Icon(Icons.check_rounded)
                              : Text('${index + 1}'),
                        ),
                        title: Text(step.title),
                        subtitle: Text(
                          step.type == PlannerStepType.song
                              ? 'Pass with ${step.minimumAccuracy}% note accuracy'
                              : 'Learning document • Markdown / HTML',
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () {
                          if (step.type == PlannerStepType.song) {
                            final matches = widget.controller.songs.where(
                              (song) => song.id == step.songId,
                            );
                            if (matches.isNotEmpty) {
                              widget.controller.selectSong(matches.first);
                              Navigator.pop(context);
                              widget.openPractice();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Import “${step.title}” into the music gallery first.',
                                  ),
                                ),
                              );
                            }
                          } else {
                            _showDocument(path, step);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDocument(LearningPath path, PlannerStep step) async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(step.title),
            actions: [
              TextButton.icon(
                onPressed: () => widget.appState.setDocumentComplete(
                  path.id,
                  step.id,
                  !step.completed,
                ),
                icon: Icon(
                  step.completed ? Icons.undo_rounded : Icons.check_rounded,
                ),
                label: Text(
                  step.completed ? 'Mark incomplete' : 'Mark complete',
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(36),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: HtmlWidget(
                  markdown.markdownToHtml(
                    step.content ?? '',
                    extensionSet: markdown.ExtensionSet.gitHubWeb,
                  ),
                  textStyle: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paths = widget.appState.learningPaths;
    final compact = MediaQuery.sizeOf(context).width < 700;
    final headerCopy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PLANNER', style: _eyebrow(context)),
        const SizedBox(height: 8),
        Text(
          'Your learning paths',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Turn songs and lesson documents into measurable, repeatable journeys.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: _importPath,
          icon: const Icon(Icons.file_download_outlined),
          label: const Text('Import'),
        ),
        FilledButton.icon(
          onPressed: _editPath,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New path'),
        ),
      ],
    );
    return SingleChildScrollView(
      padding: compact
          ? const EdgeInsets.fromLTRB(20, 22, 20, 36)
          : const EdgeInsets.fromLTRB(44, 40, 52, 56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 680) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerCopy,
                        const SizedBox(height: 18),
                        actions,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(child: headerCopy),
                      const SizedBox(width: 24),
                      actions,
                    ],
                  );
                },
              ),
              const SizedBox(height: 30),
              if (paths.isEmpty)
                _PlannerEmpty(onCreate: _editPath, onImport: _importPath)
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth > 820
                        ? (constraints.maxWidth - 18) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: paths
                          .map(
                            (path) => SizedBox(
                              width: width,
                              child: _PathCard(
                                path: path,
                                progress: widget.appState.pathProgress(path),
                                onOpen: () => _openPath(path),
                                onEdit: () => _editPath(path),
                                onExport: () => _exportPath(path),
                                onDelete: () =>
                                    widget.appState.removePath(path.id),
                              ),
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

class _PathEditor extends StatefulWidget {
  const _PathEditor({required this.existing, required this.songs});
  final LearningPath? existing;
  final List<MidiSong> songs;

  @override
  State<_PathEditor> createState() => _PathEditorState();
}

class _PathEditorState extends State<_PathEditor> {
  late final TextEditingController title;
  late final TextEditingController description;
  late List<PlannerStep> steps;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.existing?.title ?? '');
    description = TextEditingController(
      text: widget.existing?.description ?? '',
    );
    steps = [...?widget.existing?.steps];
  }

  Future<void> _addSong() async {
    MidiSong? selected;
    var accuracy = 80.0;
    final step = await showDialog<PlannerStep>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add song goal'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MidiSong>(
                  initialValue: selected,
                  decoration: const InputDecoration(labelText: 'Song'),
                  items: widget.songs
                      .map(
                        (song) => DropdownMenuItem(
                          value: song,
                          child: Text(song.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => selected = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text('Minimum accuracy'),
                    const Spacer(),
                    Text('${accuracy.round()}%'),
                  ],
                ),
                Slider(
                  value: accuracy,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  onChanged: (value) => setDialogState(() => accuracy = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () => Navigator.pop(
                      context,
                      PlannerStep(
                        id: newLearningId('step'),
                        title: selected!.title,
                        type: PlannerStepType.song,
                        songId: selected!.id,
                        minimumAccuracy: accuracy.round(),
                      ),
                    ),
              child: const Text('Add goal'),
            ),
          ],
        ),
      ),
    );
    if (step != null) setState(() => steps.add(step));
  }

  Future<void> _addDocument() async {
    final documentTitle = TextEditingController();
    final content = TextEditingController();
    final step = await showDialog<PlannerStep>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add learning document'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: documentTitle,
                decoration: const InputDecoration(labelText: 'Step title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: content,
                minLines: 8,
                maxLines: 14,
                decoration: const InputDecoration(
                  labelText: 'Markdown or HTML content',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              PlannerStep(
                id: newLearningId('step'),
                title: documentTitle.text.trim().isEmpty
                    ? 'Learning note'
                    : documentTitle.text.trim(),
                type: PlannerStepType.document,
                content: content.text,
              ),
            ),
            child: const Text('Add document'),
          ),
        ],
      ),
    );
    documentTitle.dispose();
    content.dispose();
    if (step != null) setState(() => steps.add(step));
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'Create learning path'
                        : 'Edit learning path',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Path title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Short description'),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Steps', style: Theme.of(context).textTheme.titleMedium),
                  OutlinedButton.icon(
                    onPressed: _addDocument,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Document'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _addSong,
                    icon: const Icon(Icons.music_note_rounded),
                    label: const Text('Song goal'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: steps.isEmpty
                  ? const Center(
                      child: Text('Add a song goal or a learning document.'),
                    )
                  : ReorderableListView.builder(
                      itemCount: steps.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          steps.insert(newIndex, steps.removeAt(oldIndex));
                        });
                      },
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        return Card(
                          key: ValueKey(step.id),
                          child: ListTile(
                            leading: Icon(
                              step.type == PlannerStepType.song
                                  ? Icons.piano_rounded
                                  : Icons.article_outlined,
                            ),
                            title: Text(step.title),
                            subtitle: Text(
                              step.type == PlannerStepType.song
                                  ? 'Minimum ${step.minimumAccuracy}% accuracy'
                                  : 'Markdown / HTML document',
                            ),
                            trailing: IconButton(
                              onPressed: () =>
                                  setState(() => steps.removeAt(index)),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: title.text.trim().isEmpty || steps.isEmpty
                      ? null
                      : () => Navigator.pop(
                          context,
                          LearningPath(
                            id: widget.existing?.id ?? newLearningId('path'),
                            title: title.text.trim(),
                            description: description.text.trim(),
                            steps: steps,
                            updatedAt: DateTime.now(),
                          ),
                        ),
                  child: const Text('Save path'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.path,
    required this.progress,
    required this.onOpen,
    required this.onEdit,
    required this.onExport,
    required this.onDelete,
  });
  final LearningPath path;
  final double progress;
  final VoidCallback onOpen, onEdit, onExport, onDelete;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onOpen,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: const Icon(Icons.route_rounded),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => switch (value) {
                    'edit' => onEdit(),
                    'export' => onExport(),
                    'delete' => onDelete(),
                    _ => null,
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'export', child: Text('Export')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(path.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(
              path.description.isEmpty
                  ? 'A custom learning journey'
                  : path.description,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 10),
            Text('${path.steps.length} steps'),
          ],
        ),
      ),
    ),
  );
}

class _PlannerEmpty extends StatelessWidget {
  const _PlannerEmpty({required this.onCreate, required this.onImport});
  final VoidCallback onCreate, onImport;
  @override
  Widget build(BuildContext context) {
    final visuals = Theme.of(context).extension<PianoraVisuals>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(54),
      decoration: BoxDecoration(
        color: visuals.isSwiss
            ? visuals.swissSurface
            : Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 28),
        border: Border.all(
          color: visuals.isSwiss
              ? visuals.swissInk
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.route_outlined, size: 50),
          const SizedBox(height: 14),
          Text(
            'Design your first learning path',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Combine songs, passing grades, Markdown notes, and HTML lessons.',
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            children: [
              OutlinedButton(
                onPressed: onImport,
                child: const Text('Import file'),
              ),
              FilledButton(
                onPressed: onCreate,
                child: const Text('Create path'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final IconData icon;
  final String title, subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final visuals = Theme.of(context).extension<PianoraVisuals>()!;
    final compact = MediaQuery.sizeOf(context).width < 700;
    return Container(
      padding: EdgeInsets.all(compact ? 18 : 26),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(
          visuals.isSwiss ? 0 : (visuals.isSkeuomorphic ? 18 : 28),
        ),
        border: Border.all(
          color: visuals.isSwiss
              ? visuals.swissInk.withValues(alpha: .65)
              : visuals.isSkeuomorphic
              ? visuals.brass.withValues(alpha: .35)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .35),
        ),
        boxShadow: visuals.isSwiss
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: visuals.isSkeuomorphic ? .18 : .035,
                  ),
                  blurRadius: visuals.isSkeuomorphic ? 16 : 28,
                  offset: Offset(0, visuals.isSkeuomorphic ? 7 : 10),
                ),
                if (visuals.isSkeuomorphic)
                  BoxShadow(
                    color: Colors.white.withValues(alpha: .3),
                    blurRadius: 1,
                    offset: const Offset(0, -1),
                  ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: visuals.isSwiss
                      ? Theme.of(context).colorScheme.primary
                      : visuals.isSkeuomorphic
                      ? visuals.lacquer
                      : Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    visuals.isSwiss ? 0 : (visuals.isSkeuomorphic ? 8 : 12),
                  ),
                  border: visuals.isSkeuomorphic
                      ? Border.all(color: visuals.brass.withValues(alpha: .55))
                      : null,
                ),
                child: Icon(
                  icon,
                  color: visuals.isSwiss
                      ? Theme.of(context).colorScheme.onPrimary
                      : visuals.isSkeuomorphic
                      ? visuals.brass
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 21,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }
}

class _AccentSwatch extends StatelessWidget {
  const _AccentSwatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.onSurface
              : Colors.transparent,
          width: 3,
        ),
        boxShadow: selected
            ? [BoxShadow(color: color.withValues(alpha: .38), blurRadius: 14)]
            : null,
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: readableForeground(color))
          : null,
    ),
  );
}

TextStyle _eyebrow(BuildContext context) => TextStyle(
  color: Theme.of(context).colorScheme.primary,
  fontWeight: FontWeight.w600,
  fontSize: 12,
  letterSpacing: .1,
);

String _safeName(String input) => input
    .replaceAll(RegExp(r'[^a-zA-Z0-9 _-]'), '')
    .trim()
    .replaceAll(' ', '-');

String _friendlyDate(DateTime value) =>
    '${value.month}/${value.day}/${value.year}';

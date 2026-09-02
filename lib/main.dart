import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:crisp_notation/crisp_notation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import 'app_state.dart';
import 'achievements_page.dart';
import 'design_system.dart';
import 'midi_song.dart';
import 'piano_controller.dart';
import 'product_pages.dart';
import 'songbook_page.dart';
import 'third_party_licenses.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerBundledFontLicenses();
  registerPianoIshThirdPartyLicenses();
  runApp(const PianoIshApp());
}

class PianoIshApp extends StatefulWidget {
  const PianoIshApp({super.key});

  @override
  State<PianoIshApp> createState() => _PianoIshAppState();
}

class _PianoIshAppState extends State<PianoIshApp> {
  late final PianoIshAppState appState;

  @override
  void initState() {
    super.initState();
    appState = PianoIshAppState()..load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appState,
    builder: (context, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Piano-ish',
      themeMode: appState.themeMode,
      theme: _buildTheme(
        appState.accentColor,
        Brightness.light,
        appState.designLanguage,
      ),
      darkTheme: _buildTheme(
        appState.accentColor,
        Brightness.dark,
        appState.designLanguage,
      ),
      home: appState.isLoaded
          ? PianoHome(appState: appState)
          : const _LoadingScreen(),
    ),
  );
}

ThemeData _buildTheme(
  Color accent,
  Brightness brightness,
  DesignLanguage language,
) {
  final scheme = ColorScheme.fromSeed(
    seedColor: accent,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  final dark = brightness == Brightness.dark;
  final skeuo = language == DesignLanguage.skeuomorphicInstrument;
  final swiss = language == DesignLanguage.minimalSwiss;
  final visuals = PianoIshVisuals(language: language, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: swiss
        ? visuals.swissPaper
        : skeuo
        ? (dark ? const Color(0xFF15110E) : const Color(0xFFE6DAC4))
        : (dark ? const Color(0xFF09090B) : const Color(0xFFF5F5F7)),
    fontFamily: 'Segoe UI Variable',
    splashFactory: InkSparkle.splashFactory,
    cardTheme: CardThemeData(
      color: swiss
          ? visuals.swissSurface
          : skeuo
          ? visuals.ivory
          : (dark ? const Color(0xFF18181B) : const Color(0xFFFFFFFF)),
      elevation: skeuo ? 3 : 0,
      shadowColor: Colors.black.withValues(alpha: skeuo ? .24 : .08),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(swiss ? 0 : (skeuo ? 18 : 28)),
        side: BorderSide(
          color: swiss
              ? visuals.swissInk.withValues(alpha: .58)
              : skeuo
              ? visuals.brass.withValues(alpha: .35)
              : dark
              ? Colors.white.withValues(alpha: .07)
              : Colors.black.withValues(alpha: .045),
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: swiss
          ? visuals.swissSurface
          : skeuo
          ? visuals.ivory
          : dark
          ? const Color(0xF2151518)
          : const Color(0xF7FFFFFF),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: swiss
          ? visuals.swissSurface
          : skeuo
          ? visuals.ivory
          : dark
          ? const Color(0xFF1C1C1E)
          : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(swiss ? 0 : (skeuo ? 18 : 30)),
        side: swiss
            ? BorderSide(color: visuals.swissInk, width: 1.2)
            : skeuo
            ? BorderSide(color: visuals.brass.withValues(alpha: .4))
            : BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: skeuo ? 4 : 0,
        shadowColor: Colors.black.withValues(alpha: .35),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(swiss ? 0 : (skeuo ? 10 : 14)),
          side: skeuo
              ? BorderSide(color: visuals.brass.withValues(alpha: .38))
              : BorderSide.none,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(
          color: swiss
              ? visuals.swissInk
              : scheme.outlineVariant.withValues(alpha: .75),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(swiss ? 0 : 14),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(swiss ? 0 : 12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: .62),
      selectedColor: scheme.primaryContainer,
      side: swiss
          ? BorderSide(color: visuals.swissInk.withValues(alpha: .52))
          : BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(swiss ? 0 : 12),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.surface
              : scheme.surfaceContainerHigh.withValues(alpha: .55),
        ),
        side: WidgetStatePropertyAll(
          BorderSide(color: scheme.outlineVariant.withValues(alpha: .5)),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(swiss ? 0 : 13),
          ),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: swiss
          ? visuals.swissSurface
          : skeuo
          ? visuals.ivory
          : scheme.surfaceContainerHighest.withValues(alpha: .48),
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(swiss ? 0 : 14),
        borderSide: swiss
            ? BorderSide(color: visuals.swissInk)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(swiss ? 0 : 14),
        borderSide: BorderSide(
          color: swiss
              ? visuals.swissInk
              : scheme.outlineVariant.withValues(alpha: .55),
        ),
      ),
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(
        fontSize: swiss ? 44 : (skeuo ? 38 : 40),
        fontWeight: swiss ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: swiss ? -2 : -1.35,
        color: scheme.onSurface,
        fontFamily: skeuo ? 'Georgia' : null,
      ),
      headlineMedium: TextStyle(
        fontWeight: swiss ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: swiss ? -1.1 : -.8,
        color: scheme.onSurface,
        fontFamily: skeuo ? 'Georgia' : null,
      ),
      titleLarge: TextStyle(
        fontWeight: swiss ? FontWeight.w700 : FontWeight.w600,
        letterSpacing: -.3,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
      bodyMedium: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.windows: FadeForwardsPageTransitionsBuilder()},
    ),
    extensions: [visuals],
  );
}

class PianoHome extends StatefulWidget {
  const PianoHome({super.key, required this.appState, this.initialController});
  final PianoIshAppState appState;
  final PianoController? initialController;
  @override
  State<PianoHome> createState() => _PianoHomeState();
}

class _PianoHomeState extends State<PianoHome> {
  late final PianoController controller;
  late final bool _ownsController;
  int page = 0;
  @override
  void initState() {
    super.initState();
    _ownsController = widget.initialController == null;
    controller = widget.initialController ?? PianoController();
    controller.onProgress = (songId, position, correct, attempted, completed) {
      unawaited(
        widget.appState.recordPractice(
          songId: songId,
          position: position,
          correct: correct,
          attempted: attempted,
          completed: completed,
        ),
      );
    };
    if (_ownsController) controller.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.isLoading) return const _LoadingScreen();
      final colors = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
      final viewport = MediaQuery.sizeOf(context);
      final compactNavigation = viewport.width < 900 || viewport.height < 620;
      return Scaffold(
        bottomNavigationBar: compactNavigation
            ? _CompactNavigationBar(
                page: page,
                connected: controller.connectedDevice != null,
                appState: widget.appState,
                onChange: (value) => setState(() => page = value),
              )
            : null,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: visuals.isSwiss
                  ? [visuals.swissPaper, visuals.swissPaper]
                  : visuals.isSkeuomorphic
                  ? [
                      Theme.of(context).scaffoldBackgroundColor,
                      Color.lerp(
                        Theme.of(context).scaffoldBackgroundColor,
                        visuals.wood,
                        dark ? .22 : .14,
                      )!,
                    ]
                  : [
                      Theme.of(context).scaffoldBackgroundColor,
                      Color.alphaBlend(
                        colors.primary.withValues(alpha: dark ? .035 : .022),
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              if (visuals.isSwiss)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _SwissGridPainter(
                        color: visuals.swissInk.withValues(alpha: .035),
                      ),
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final content = Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          reverseDuration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutQuint,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(.012, .004),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(page),
                            child: switch (page) {
                              0 => _LibraryPage(
                                controller: controller,
                                appState: widget.appState,
                                openPlayer: () => setState(() => page = 2),
                                openPlanner: () => setState(() => page = 3),
                              ),
                              1 => SongbookPage(
                                controller: controller,
                                openPractice: () => setState(() => page = 2),
                              ),
                              2 => _PracticePage(controller: controller),
                              3 => PlannerPage(
                                appState: widget.appState,
                                controller: controller,
                                openPractice: () => setState(() => page = 2),
                              ),
                              4 => AchievementsPage(appState: widget.appState),
                              _ => SettingsPage(
                                appState: widget.appState,
                                controller: controller,
                                devicesSection: _DevicesSettingsSection(
                                  controller: controller,
                                ),
                              ),
                            },
                          ),
                        ),
                      ),
                      if (controller.message != null)
                        Positioned(
                          right: compactNavigation ? 12 : 28,
                          bottom: compactNavigation ? 12 : 26,
                          child: _Toast(
                            message: controller.message!,
                            onClose: controller.clearMessage,
                          ),
                        ),
                    ],
                  );
                  if (compactNavigation) {
                    return SafeArea(bottom: false, child: content);
                  }
                  return Row(
                    children: [
                      _SideBar(
                        page: page,
                        connected: controller.connectedDevice != null,
                        appState: widget.appState,
                        onChange: (value) => setState(() => page = value),
                      ),
                      Expanded(child: content),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SwissGridPainter extends CustomPainter {
  const _SwissGridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const spacing = 96.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SwissGridPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CompactNavigationBar extends StatelessWidget {
  const _CompactNavigationBar({
    required this.page,
    required this.connected,
    required this.appState,
    required this.onChange,
  });

  final int page;
  final bool connected;
  final PianoIshAppState appState;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final colors = Theme.of(context).colorScheme;
    final destinations = <(IconData, String)>[
      (Icons.grid_view_rounded, 'Library'),
      (Icons.menu_book_rounded, 'Songbook'),
      (Icons.piano_rounded, 'Practice'),
      (Icons.route_rounded, 'Planner'),
      (Icons.workspace_premium_rounded, 'Awards'),
      (Icons.settings_rounded, 'Settings'),
    ];
    return Material(
      color: visuals.isSwiss ? visuals.swissSurface : colors.surface,
      elevation: visuals.isSwiss ? 0 : 12,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: visuals.isSwiss
                    ? visuals.swissInk
                    : colors.outlineVariant.withValues(alpha: .55),
              ),
            ),
          ),
          child: Row(
            children: List.generate(destinations.length, (index) {
              final selected = page == index;
              final destination = destinations[index];
              final foreground = selected
                  ? colors.onPrimary
                  : colors.onSurfaceVariant;
              return Expanded(
                child: Semantics(
                  key: ValueKey('navigation-$index'),
                  selected: selected,
                  label: destination.$2,
                  button: true,
                  child: InkWell(
                    onTap: () => onChange(index),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: selected
                                ? colors.primary
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child:
                              index == 5 &&
                                  (appState.profileImagePath != null ||
                                      appState.profileName.isNotEmpty)
                              ? Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: ProfileAvatar(
                                    appState: appState,
                                    radius: 17,
                                  ),
                                )
                              : Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      destination.$1,
                                      color: foreground,
                                      size: 21,
                                    ),
                                    if (index == 5 && connected)
                                      Positioned(
                                        right: 5,
                                        bottom: 5,
                                        child: Container(
                                          width: 7,
                                          height: 7,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF20A66A),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          destination.$2,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            color: selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                            fontSize: 9,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _SideBar extends StatelessWidget {
  const _SideBar({
    required this.page,
    required this.connected,
    required this.appState,
    required this.onChange,
  });
  final int page;
  final bool connected;
  final PianoIshAppState appState;
  final ValueChanged<int> onChange;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 0, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          visuals.isSwiss ? 0 : (visuals.isSkeuomorphic ? 20 : 30),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(
            width: 92,
            decoration: BoxDecoration(
              color: visuals.isSwiss
                  ? visuals.swissSurface
                  : visuals.isSkeuomorphic
                  ? null
                  : (dark ? const Color(0xFF202024) : Colors.white).withValues(
                      alpha: dark ? .72 : .76,
                    ),
              gradient: visuals.isSkeuomorphic
                  ? LinearGradient(
                      colors: [visuals.woodLight, visuals.wood],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(
                visuals.isSwiss ? 0 : (visuals.isSkeuomorphic ? 20 : 30),
              ),
              border: Border.all(
                color: visuals.isSwiss
                    ? visuals.swissInk
                    : visuals.isSkeuomorphic
                    ? visuals.brass.withValues(alpha: .62)
                    : dark
                    ? Colors.white.withValues(alpha: .09)
                    : Colors.white.withValues(alpha: .88),
                width: visuals.isSkeuomorphic ? 1.5 : 1,
              ),
              boxShadow: visuals.isSwiss
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? .24 : .07),
                        blurRadius: visuals.isSkeuomorphic ? 22 : 38,
                        offset: Offset(0, visuals.isSkeuomorphic ? 9 : 16),
                      ),
                    ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: visuals.isSkeuomorphic
                        ? LinearGradient(
                            colors: [const Color(0xFF303030), visuals.lacquer],
                          )
                        : null,
                    color: visuals.isSkeuomorphic ? null : colors.primary,
                    borderRadius: BorderRadius.circular(
                      visuals.isSwiss ? 0 : (visuals.isSkeuomorphic ? 10 : 14),
                    ),
                    border: visuals.isSkeuomorphic
                        ? Border.all(color: visuals.brass.withValues(alpha: .7))
                        : null,
                    boxShadow: visuals.isSwiss
                        ? []
                        : [
                            BoxShadow(
                              color:
                                  (visuals.isSkeuomorphic
                                          ? Colors.black
                                          : colors.primary)
                                      .withValues(alpha: .24),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                  ),
                  child: Icon(
                    Icons.graphic_eq_rounded,
                    color: visuals.isSkeuomorphic
                        ? visuals.brass
                        : readableForeground(colors.primary),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 34),
                _NavIcon(
                  icon: Icons.grid_view_rounded,
                  label: 'Library',
                  selected: page == 0,
                  onTap: () => onChange(0),
                ),
                _NavIcon(
                  icon: Icons.menu_book_rounded,
                  label: 'Songbook',
                  selected: page == 1,
                  onTap: () => onChange(1),
                ),
                _NavIcon(
                  icon: Icons.piano_rounded,
                  label: 'Practice',
                  selected: page == 2,
                  onTap: () => onChange(2),
                ),
                _NavIcon(
                  icon: Icons.route_rounded,
                  label: 'Planner',
                  selected: page == 3,
                  onTap: () => onChange(3),
                ),
                _NavIcon(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Awards',
                  selected: page == 4,
                  onTap: () => onChange(4),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                  child: Tooltip(
                    message: 'Settings & profile',
                    child: InkWell(
                      key: const ValueKey('side-navigation-Settings'),
                      onTap: () => onChange(5),
                      customBorder: const CircleBorder(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: page == 5
                                ? colors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            appState.profileImagePath != null ||
                                    appState.profileName.isNotEmpty
                                ? ProfileAvatar(appState: appState, radius: 22)
                                : const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFFE8E8ED),
                                    child: Icon(
                                      Icons.settings_rounded,
                                      color: Color(0xFF6E6E73),
                                    ),
                                  ),
                            if (connected)
                              Positioned(
                                right: -1,
                                bottom: -1,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF68E0AE),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: dark
                                          ? const Color(0xFF202024)
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final foreground = visuals.isSwiss
        ? (selected ? colors.onPrimary : visuals.swissInk)
        : visuals.isSkeuomorphic
        ? (selected ? visuals.brass : const Color(0xFFE8D8BF))
        : (selected ? colors.primary : colors.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 9),
      child: Tooltip(
        message: label,
        child: InkWell(
          key: ValueKey('side-navigation-$label'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 74,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: selected
                        ? (visuals.isSwiss
                              ? colors.primary
                              : visuals.isSkeuomorphic
                              ? visuals.lacquer
                              : colors.primaryContainer.withValues(alpha: .78))
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: visuals.isSkeuomorphic && selected
                        ? Border.all(
                            color: visuals.brass.withValues(alpha: .65),
                          )
                        : null,
                    boxShadow: selected && !visuals.isSwiss
                        ? [
                            BoxShadow(
                              color:
                                  (visuals.isSkeuomorphic
                                          ? Colors.black
                                          : colors.primary)
                                      .withValues(alpha: .24),
                              blurRadius: visuals.isSkeuomorphic ? 8 : 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(icon, color: foreground, size: 23),
                ),
                const SizedBox(height: 4),
                Text(
                  visuals.isSwiss ? label.toUpperCase() : label,
                  style: TextStyle(
                    fontSize: visuals.isSwiss ? 9 : 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: visuals.isSwiss ? .65 : 0,
                    color: foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.action,
  });
  final String eyebrow, title, subtitle;
  final Widget action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final copy = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: .1,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 9),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        ],
      );
      if (constraints.maxWidth < 620) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [copy, const SizedBox(height: 18), action],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: copy),
          const SizedBox(width: 20),
          action,
        ],
      );
    },
  );
}

class _LibraryPage extends StatelessWidget {
  const _LibraryPage({
    required this.controller,
    required this.appState,
    required this.openPlayer,
    required this.openPlanner,
  });
  final PianoController controller;
  final PianoIshAppState appState;
  final VoidCallback openPlayer;
  final VoidCallback openPlanner;
  @override
  Widget build(BuildContext context) {
    final song = controller.selectedSong;
    final path = appState.mostRecentIncompletePath;
    final trimmedName = appState.profileName.trim();
    final firstName = trimmedName.isEmpty
        ? ''
        : trimmedName.split(RegExp(r'\s+')).first;
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
              _TopHeader(
                eyebrow: 'YOUR MUSIC',
                title: firstName.isEmpty
                    ? 'Welcome back'
                    : 'Welcome back, $firstName',
                subtitle: 'Pick a piece and make a little progress today.',
                action: FilledButton.icon(
                  onPressed: controller.importMidi,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Import MIDI'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Where you left off',
                      maxLines: 2,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.5,
                          ),
                    ),
                  ),
                  if (compact)
                    IconButton(
                      onPressed: openPlanner,
                      tooltip: 'Open Planner',
                      icon: const Icon(Icons.arrow_forward_rounded),
                    )
                  else
                    TextButton.icon(
                      onPressed: openPlanner,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Open Planner'),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _ContinuePathCard(
                path: path,
                progress: path == null ? 0 : appState.pathProgress(path),
                onTap: openPlanner,
              ),
              const SizedBox(height: 18),
              _HabitDashboard(appState: appState),
              const SizedBox(height: 32),
              if (song != null)
                _FeaturedSong(
                  song: song,
                  controller: controller,
                  openPlayer: openPlayer,
                ),
              const SizedBox(height: 36),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Music gallery',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${controller.songs.length} ${controller.songs.length == 1 ? 'piece' : 'pieces'}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1050
                      ? 3
                      : constraints.maxWidth > 650
                      ? 2
                      : 1;
                  final width =
                      (constraints.maxWidth - 18 * (columns - 1)) / columns;
                  return Wrap(
                    spacing: 18,
                    runSpacing: 18,
                    children: controller.songs
                        .map(
                          (item) => SizedBox(
                            width: width,
                            child: _SongCard(
                              song: item,
                              selected: item.id == song?.id,
                              onTap: () {
                                controller.selectSong(item);
                                openPlayer();
                              },
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

class _HabitDashboard extends StatelessWidget {
  const _HabitDashboard({required this.appState});
  final PianoIshAppState appState;

  @override
  Widget build(BuildContext context) {
    final today = appState.todayPracticeMinutes;
    final goal = appState.dailyGoalMinutes.toDouble();
    final achievement = appState.achievements.isEmpty
        ? 'First session waiting'
        : appState.achievements.last;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 30) / 4;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _HabitTile(
              width: width,
              icon: Icons.today_rounded,
              label: 'Today',
              value: '${today.round()} / ${goal.round()} min',
              progress: (today / goal).clamp(0, 1),
            ),
            _HabitTile(
              width: width,
              icon: Icons.local_fire_department_rounded,
              label: 'Practice streak',
              value: '${appState.practiceStreak} days',
            ),
            _HabitTile(
              width: width,
              icon: Icons.calendar_view_week_rounded,
              label: 'This week',
              value: '${appState.weeklyPracticeMinutes.round()} min',
            ),
            _HabitTile(
              width: width,
              icon: Icons.emoji_events_outlined,
              label: 'Latest achievement',
              value: achievement,
            ),
          ],
        );
      },
    );
  }
}

class _HabitTile extends StatelessWidget {
  const _HabitTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.progress,
  });
  final double width;
  final IconData icon;
  final String label;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    return Container(
      width: math.max(190, width),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: visuals.isSwiss
            ? visuals.swissSurface
            : Theme.of(context).colorScheme.surface.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 22),
        border: Border.all(
          color: visuals.isSwiss
              ? visuals.swissInk.withValues(alpha: .42)
              : Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .35),
        ),
        boxShadow: visuals.isSwiss
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .035),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 11),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (progress != null) ...[
            const SizedBox(height: 9),
            LinearProgressIndicator(value: progress, minHeight: 5),
          ],
        ],
      ),
    );
  }
}

class _ContinuePathCard extends StatelessWidget {
  const _ContinuePathCard({
    required this.path,
    required this.progress,
    required this.onTap,
  });

  final LearningPath? path;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final current = path;
    final unfinished = current?.steps.where((step) => !step.completed).toList();
    final nextStep = unfinished == null || unfinished.isEmpty
        ? null
        : unfinished.first;
    final leading = Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 18),
      ),
      child: Icon(
        current == null ? Icons.add_road_rounded : Icons.route_rounded,
        color: colors.onPrimaryContainer,
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          current?.title ?? 'Create your first learning path',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 5),
        Text(
          current == null
              ? 'Build a guided journey from songs, accuracy goals, and lesson notes.'
              : nextStep == null
              ? 'All steps completed'
              : 'Next: ${nextStep.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (current != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: colors.surface.withValues(alpha: .6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ],
    );
    final button = FilledButton.tonalIcon(
      onPressed: onTap,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(current == null ? 'Plan' : 'Continue'),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 26),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: visuals.isSwiss
                ? visuals.swissSurface
                : colors.surface.withValues(alpha: .86),
            borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 28),
            border: Border.all(
              color: visuals.isSwiss
                  ? visuals.swissInk.withValues(alpha: .6)
                  : colors.outlineVariant.withValues(alpha: .38),
            ),
            boxShadow: visuals.isSwiss
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .045),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leading,
                    const SizedBox(height: 16),
                    details,
                    const SizedBox(height: 18),
                    button,
                  ],
                );
              }
              return Row(
                children: [
                  leading,
                  const SizedBox(width: 18),
                  Expanded(child: details),
                  const SizedBox(width: 18),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FeaturedSong extends StatelessWidget {
  const _FeaturedSong({
    required this.song,
    required this.controller,
    required this.openPlayer,
  });
  final MidiSong song;
  final PianoController controller;
  final VoidCallback openPlayer;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    final compact = MediaQuery.sizeOf(context).width < 900;
    final heroColors = visuals.isSwiss
        ? [visuals.swissInk, visuals.swissInk]
        : visuals.isSkeuomorphic
        ? [const Color(0xFF32302D), const Color(0xFF090909)]
        : [colors.primary, Color.lerp(colors.primary, colors.tertiary, .58)!];
    final foreground = readableForegroundFor(heroColors);
    final badgeBackground = visuals.isSwiss
        ? colors.primary
        : visuals.isSkeuomorphic
        ? visuals.felt.withValues(alpha: .72)
        : foreground.withValues(alpha: .14);
    final badgeForeground = visuals.isSwiss
        ? readableForeground(colors.primary)
        : visuals.isSkeuomorphic
        ? visuals.brass
        : foreground;
    return Container(
      height: compact ? 320 : 310,
      padding: EdgeInsets.all(compact ? 24 : 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: heroColors,
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 34),
        boxShadow: visuals.isSwiss
            ? []
            : [
                BoxShadow(
                  color:
                      (visuals.isSkeuomorphic ? Colors.black : colors.primary)
                          .withValues(alpha: .2),
                  blurRadius: 42,
                  offset: const Offset(0, 18),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: -35,
            child: Transform.rotate(
              angle: -.12,
              child: Icon(
                Icons.music_note_rounded,
                color: visuals.isSkeuomorphic
                    ? visuals.brass.withValues(alpha: .17)
                    : foreground.withValues(alpha: .11),
                size: 230,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 20),
                  border: visuals.isSkeuomorphic
                      ? Border.all(color: visuals.brass.withValues(alpha: .48))
                      : null,
                ),
                child: Text(
                  'FEATURED PIECE',
                  style: TextStyle(
                    color: badgeForeground,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                song.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 28 : 33,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                song.composer,
                style: TextStyle(
                  color: foreground.withValues(alpha: .82),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      controller.play();
                      openPlayer();
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Practice'),
                    style: FilledButton.styleFrom(
                      backgroundColor: foreground,
                      foregroundColor: readableForeground(foreground),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                  ),
                  _MiniMeta(
                    icon: Icons.schedule_rounded,
                    label: song.durationLabel,
                    color: foreground,
                  ),
                  _MiniMeta(
                    icon: Icons.speed_rounded,
                    label: '${song.bpm} BPM',
                    color: foreground,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  const _MiniMeta({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: color.withValues(alpha: .74)),
      const SizedBox(width: 5),
      Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class _SongCard extends StatefulWidget {
  const _SongCard({
    required this.song,
    required this.selected,
    required this.onTap,
  });
  final MidiSong song;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<_SongCard> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visuals = Theme.of(context).extension<PianoIshVisuals>()!;
    return MouseRegion(
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: AnimatedScale(
        scale: hovering && !visuals.isSwiss ? 1.008 : 1,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutQuint,
        child: Material(
          color: Theme.of(context).cardTheme.color,
          elevation: hovering && !visuals.isSwiss ? 3 : 0,
          shadowColor: Colors.black.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 24),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 24),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.selected
                      ? colors.primary
                      : visuals.isSwiss
                      ? visuals.swissInk.withValues(alpha: .45)
                      : colors.outlineVariant.withValues(alpha: .28),
                  width: widget.selected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(visuals.isSwiss ? 0 : 24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: _coverGradient(widget.song.title),
                      borderRadius: BorderRadius.circular(
                        visuals.isSwiss ? 0 : 17,
                      ),
                    ),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: _coverForeground(widget.song.title),
                      size: 34,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.song.composer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 5,
                          runSpacing: 3,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              widget.song.difficulty,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            Text('•', style: TextStyle(color: colors.outline)),
                            Text(
                              widget.song.durationLabel,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.outline),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

LinearGradient _coverGradient(String value) {
  final colors = _coverColors(value);
  return LinearGradient(
    colors: colors,
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );
}

List<Color> _coverColors(String value) {
  final options = <List<Color>>[
    const [Color(0xFF5D50DE), Color(0xFFB69AF8)],
    const [Color(0xFFEF7F95), Color(0xFFF5C36C)],
    const [Color(0xFF25A8A0), Color(0xFF8DDFC6)],
  ];
  return options[value.hashCode.abs() % options.length];
}

Color _coverForeground(String value) {
  final colors = _coverColors(value);
  return readableForeground(Color.lerp(colors.first, colors.last, .5)!);
}

class _PracticePage extends StatelessWidget {
  const _PracticePage({required this.controller});
  final PianoController controller;
  @override
  Widget build(BuildContext context) {
    final song = controller.selectedSong;
    if (song == null) {
      return const Center(child: Text('Import a MIDI file to begin'));
    }
    final viewport = MediaQuery.sizeOf(context);
    final compact = viewport.width < 1000 || viewport.height < 720;
    final content = Column(
      mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _PracticeHeader(controller: controller, song: song),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _HearNotesToggle(controller: controller),
              _PedalIndicator(controller: controller),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _PracticeToolsBar(controller: controller, song: song),
        const SizedBox(height: 12),
        if (compact)
          _PracticeMain(controller: controller, song: song, compact: true)
        else
          Expanded(
            child: _PracticeMain(
              controller: controller,
              song: song,
              compact: false,
            ),
          ),
        const SizedBox(height: 16),
        _Transport(controller: controller, song: song),
      ],
    );
    if (compact) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: content,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 32, 44, 34),
      child: content,
    );
  }
}

class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({required this.controller, required this.song});

  final PianoController controller;
  final MidiSong song;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final identity = Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primary,
                Color.lerp(colors.primary, colors.tertiary, .62)!,
              ],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(Icons.music_note_rounded, color: colors.onPrimary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(song.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(
                '${song.composer}  •  ${song.keySignature}  •  ${song.timeSignature}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ModeSelector(controller: controller),
                    const SizedBox(width: 10),
                    _DevicePill(controller: controller),
                  ],
                ),
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: identity),
            const SizedBox(width: 16),
            _ModeSelector(controller: controller),
            const SizedBox(width: 12),
            _DevicePill(controller: controller),
          ],
        );
      },
    );
  }
}

class _PracticeMain extends StatelessWidget {
  const _PracticeMain({
    required this.controller,
    required this.song,
    required this.compact,
  });

  final PianoController controller;
  final MidiSong song;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = Container(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.primary.withValues(alpha: .16),
          const Color(0xFF18171D),
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: _ScoreSurface(controller: controller, song: song),
    );
    final session = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatPanel(controller: controller, song: song),
        const SizedBox(height: 14),
        _PracticeTip(controller: controller),
      ],
    );
    if (compact) {
      return Column(
        children: [
          SizedBox(height: 390, child: score),
          const SizedBox(height: 14),
          _Keyboard(controller: controller),
          const SizedBox(height: 18),
          session,
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Expanded(child: score),
              const SizedBox(height: 14),
              _Keyboard(controller: controller),
            ],
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(width: 235, child: session),
      ],
    );
  }
}

class _PracticeToolsBar extends StatelessWidget {
  const _PracticeToolsBar({required this.controller, required this.song});
  final PianoController controller;
  final MidiSong song;

  Future<void> _annotate(BuildContext context, double position) async {
    final text = TextEditingController(
      text: controller.annotations[position] ?? '',
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note at ${_clock(position)}'),
        content: TextField(
          controller: text,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What should you remember here?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save note'),
          ),
        ],
      ),
    );
    if (saved == true) controller.setAnnotation(position, text.text);
    text.dispose();
  }

  Future<void> _showTools(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final analysis = song.analysis;
            final safeEnd = math.max(.1, song.duration);
            final start = controller.loopStart
                .clamp(0, safeEnd - .1)
                .toDouble();
            final end = controller.loopEnd
                .clamp(start + .1, safeEnd)
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Practice tools',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: controller.loopEnabled,
                    onChanged: controller.setLoopEnabled,
                    title: const Text('Loop a difficult section'),
                    subtitle: Text('${_clock(start)} – ${_clock(end)}'),
                  ),
                  RangeSlider(
                    values: RangeValues(start, end),
                    min: 0,
                    max: safeEnd,
                    divisions: math.max(1, safeEnd.floor()),
                    labels: RangeLabels(_clock(start), _clock(end)),
                    onChanged: (range) =>
                        controller.setLoopRange(range.start, range.end),
                  ),
                  if (analysis.sections.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: analysis.sections
                          .map(
                            (section) => ActionChip(
                              label: Text(section.name),
                              onPressed: () => controller.setLoopRange(
                                section.start,
                                section.end,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (controller.bookmarks.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Bookmarks',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...controller.bookmarks.map(
                      (bookmark) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark_rounded),
                        title: Text(
                          controller.annotations[bookmark] ?? _clock(bookmark),
                        ),
                        subtitle: controller.annotations[bookmark] == null
                            ? const Text('Click the note icon to annotate')
                            : Text(_clock(bookmark)),
                        onTap: () => controller.seek(bookmark),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              onPressed: () => _annotate(context, bookmark),
                              icon: const Icon(Icons.edit_note_rounded),
                            ),
                            IconButton(
                              onPressed: () =>
                                  controller.removeBookmark(bookmark),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const Divider(height: 34),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: controller.autoTempoRamp,
                    onChanged: controller.setAutoTempoRamp,
                    title: const Text('Automatic tempo ramp'),
                    subtitle: const Text(
                      'Increase speed by 5% after a session with at least 80% accuracy.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Timing tolerance: ±${(controller.timingTolerance * 1000).round()} ms',
                  ),
                  Slider(
                    value: controller.timingTolerance,
                    min: .06,
                    max: .4,
                    divisions: 17,
                    onChanged: controller.setTimingTolerance,
                  ),
                  const Divider(height: 34),
                  Text(
                    'Automatic MIDI analysis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        label: Text(
                          '${analysis.level} • ${analysis.score}/100',
                        ),
                      ),
                      Chip(
                        label: Text(
                          'Start at ${(analysis.recommendedStartSpeed * 100).round()}%',
                        ),
                      ),
                      Chip(label: Text('Range ${analysis.noteRange}')),
                      Chip(
                        label: Text(
                          'Up to ${analysis.maximumPolyphony} notes together',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Skills used',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 7),
                  Text(analysis.skills.join(' • ')),
                  const SizedBox(height: 14),
                  Text(
                    'Recommended prerequisites',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 7),
                  ...analysis.prerequisites.map((item) => Text('• $item')),
                  const SizedBox(height: 18),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        controller.setSpeed(analysis.recommendedStartSpeed),
                    icon: const Icon(Icons.speed_rounded),
                    label: const Text('Use suggested starting tempo'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SegmentedButton<ScoreView>(
          segments: const [
            ButtonSegment(
              value: ScoreView.fallingNotes,
              icon: Icon(Icons.waterfall_chart_rounded),
              label: Text('Falling'),
            ),
            ButtonSegment(
              value: ScoreView.hybrid,
              icon: Icon(Icons.vertical_split_rounded),
              label: Text('Hybrid'),
            ),
            ButtonSegment(
              value: ScoreView.sheetMusic,
              icon: Icon(Icons.music_note_rounded),
              label: Text('Staff'),
            ),
          ],
          selected: {controller.scoreView},
          showSelectedIcon: false,
          onSelectionChanged: (value) => controller.setScoreView(value.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        SegmentedButton<PracticeHand>(
          segments: const [
            ButtonSegment(value: PracticeHand.both, label: Text('Both')),
            ButtonSegment(value: PracticeHand.right, label: Text('Right')),
            ButtonSegment(value: PracticeHand.left, label: Text('Left')),
          ],
          selected: {controller.practiceHand},
          showSelectedIcon: false,
          onSelectionChanged: (value) =>
              controller.setPracticeHand(value.first),
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
        FilterChip(
          selected: controller.showNoteNames,
          onSelected: controller.setShowNoteNames,
          avatar: const Icon(Icons.abc_rounded, size: 18),
          label: const Text('Note names'),
        ),
        FilterChip(
          selected: controller.metronomeEnabled,
          onSelected: controller.setMetronome,
          avatar: const Icon(Icons.timer_outlined, size: 18),
          label: const Text('Metronome'),
        ),
        PopupMenuButton<int>(
          initialValue: controller.countInBeats,
          onSelected: controller.setCountInBeats,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 0, child: Text('No count-in')),
            PopupMenuItem(value: 2, child: Text('2-beat count-in')),
            PopupMenuItem(value: 4, child: Text('4-beat count-in')),
          ],
          child: Chip(
            avatar: const Icon(Icons.numbers_rounded, size: 18),
            label: Text(
              controller.countInBeats == 0
                  ? 'Count-in'
                  : '${controller.countInBeats} beats',
            ),
          ),
        ),
        IconButton(
          onPressed: controller.addBookmark,
          tooltip: 'Bookmark this position',
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
        IconButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => _ExerciseLab(controller: controller),
          ),
          tooltip: 'Interactive note and rhythm drills',
          icon: const Icon(Icons.school_outlined),
        ),
        IconButton(
          onPressed: () => _showTools(context),
          tooltip: 'Loop, timing, tempo, and song analysis',
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

enum _DrillMode { noteFinding, rhythm }

class _ExerciseLab extends StatefulWidget {
  const _ExerciseLab({required this.controller});
  final PianoController controller;

  @override
  State<_ExerciseLab> createState() => _ExerciseLabState();
}

class _ExerciseLabState extends State<_ExerciseLab> {
  final random = math.Random();
  _DrillMode mode = _DrillMode.noteFinding;
  int target = 60;
  int correct = 0;
  int attempts = 0;
  int lastInputCount = 0;
  double drillBpm = 80;
  Timer? beatTimer;
  DateTime? lastBeat;
  int rhythmHits = 0;
  int rhythmAttempts = 0;

  @override
  void initState() {
    super.initState();
    lastInputCount = widget.controller.inputNoteCount;
    _nextTarget();
    widget.controller.addListener(_inputChanged);
  }

  void _nextTarget() {
    target = 60 + random.nextInt(13);
  }

  void _inputChanged() {
    if (!mounted || widget.controller.inputNoteCount == lastInputCount) return;
    lastInputCount = widget.controller.inputNoteCount;
    setState(() {
      if (mode == _DrillMode.noteFinding) {
        attempts++;
        if (widget.controller.lastInputNote == target) {
          correct++;
          _nextTarget();
        }
      } else if (lastBeat != null) {
        rhythmAttempts++;
        final beatMs = 60000 / drillBpm;
        final elapsed = DateTime.now().difference(lastBeat!).inMilliseconds;
        final distance = math.min(elapsed.abs(), (beatMs - elapsed).abs());
        if (distance <= 140) rhythmHits++;
      }
    });
  }

  void _toggleRhythm() {
    if (beatTimer != null) {
      beatTimer?.cancel();
      beatTimer = null;
      setState(() {});
      return;
    }
    void beat() {
      lastBeat = DateTime.now();
      widget.controller.playTrainingClick(accent: rhythmAttempts % 4 == 0);
      if (mounted) setState(() {});
    }

    beat();
    beatTimer = Timer.periodic(
      Duration(milliseconds: (60000 / drillBpm).round()),
      (_) => beat(),
    );
    setState(() {});
  }

  @override
  void dispose() {
    beatTimer?.cancel();
    widget.controller.removeListener(_inputChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 620,
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Interactive exercise lab',
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
            SegmentedButton<_DrillMode>(
              segments: const [
                ButtonSegment(
                  value: _DrillMode.noteFinding,
                  icon: Icon(Icons.piano_rounded),
                  label: Text('Find the note'),
                ),
                ButtonSegment(
                  value: _DrillMode.rhythm,
                  icon: Icon(Icons.timer_outlined),
                  label: Text('Rhythm tapping'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (value) {
                beatTimer?.cancel();
                beatTimer = null;
                setState(() => mode = value.first);
              },
            ),
            const SizedBox(height: 28),
            if (mode == _DrillMode.noteFinding) ...[
              const Text('Play this note on your piano'),
              const SizedBox(height: 10),
              Text(
                _midiNoteName(target),
                style: TextStyle(
                  fontSize: 70,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text('Score: $correct / $attempts'),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => setState(_nextTarget),
                child: const Text('Skip note'),
              ),
            ] else ...[
              Text(
                beatTimer == null
                    ? 'Press Start, then tap any piano key on every click.'
                    : 'Keep tapping with the pulse',
              ),
              const SizedBox(height: 16),
              Text(
                '${drillBpm.round()} BPM',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Slider(
                value: drillBpm,
                min: 50,
                max: 140,
                divisions: 18,
                onChanged: beatTimer == null
                    ? (value) => setState(() => drillBpm = value)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'On-beat taps: $rhythmHits / $rhythmAttempts  •  tolerance ±140 ms',
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _toggleRhythm,
                icon: Icon(
                  beatTimer == null
                      ? Icons.play_arrow_rounded
                      : Icons.stop_rounded,
                ),
                label: Text(beatTimer == null ? 'Start rhythm drill' : 'Stop'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ScoreSurface extends StatelessWidget {
  const _ScoreSurface({required this.controller, required this.song});
  final PianoController controller;
  final MidiSong song;

  Widget _roll(BuildContext context) => CustomPaint(
    painter: _PianoRollPainter(
      song: song,
      position: controller.position,
      accent: Theme.of(context).colorScheme.primary,
      accentAlt: Theme.of(context).colorScheme.tertiary,
      onAccent: Theme.of(context).colorScheme.onPrimary,
    ),
    child: const SizedBox.expand(),
  );

  Widget _staff(BuildContext context) => ColoredBox(
    color: Theme.of(context).colorScheme.surface,
    child: CustomPaint(
      painter: _StaffPainter(
        song: song,
        position: controller.position,
        showNames: controller.showNoteNames,
        ink: Theme.of(context).colorScheme.onSurface,
        accent: Theme.of(context).colorScheme.primary,
      ),
      child: const SizedBox.expand(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final view = switch (controller.scoreView) {
      ScoreView.fallingNotes => _roll(context),
      ScoreView.sheetMusic => _staff(context),
      ScoreView.hybrid => Column(
        children: [
          Expanded(child: _staff(context)),
          const Divider(height: 1),
          Expanded(child: _roll(context)),
        ],
      ),
    };
    return Stack(
      fit: StackFit.expand,
      children: [
        view,
        if (controller.countInRemaining > 0)
          ColoredBox(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .82),
            child: Center(
              child: Text(
                '${controller.countInRemaining + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 82,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StaffPainter extends CustomPainter {
  _StaffPainter({
    required this.song,
    required this.position,
    required this.showNames,
    required this.ink,
    required this.accent,
  });
  final MidiSong song;
  final double position;
  final bool showNames;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ink.withValues(alpha: .42)
      ..strokeWidth = 1;
    final left = 42.0;
    final right = size.width - 20;
    const spacing = 11.0;
    final centers = [size.height * .31, size.height * .69];
    for (final center in centers) {
      for (var i = -2; i <= 2; i++) {
        final y = center + i * spacing;
        canvas.drawLine(Offset(left, y), Offset(right, y), line);
      }
    }
    _text(canvas, '𝄞', Offset(9, centers.first - 29), ink, 38);
    _text(canvas, '𝄢', Offset(10, centers.last - 27), ink, 35);
    const window = 8.0;
    for (final note in song.notes) {
      if (note.start < position - .15 || note.start > position + window) {
        continue;
      }
      final x = left + (note.start - position) / window * (right - left);
      final treble = note.note >= 60;
      final center = treble ? centers.first : centers.last;
      final reference = treble ? 71 : 50;
      final y = center - (note.note - reference) * spacing / 2;
      final active = note.start <= position + .08;
      final paint = Paint()..color = active ? accent : ink;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-.22);
      canvas.drawOval(const Rect.fromLTWH(-7, -4.5, 14, 9), paint);
      canvas.restore();
      canvas.drawLine(
        Offset(x + 6, y),
        Offset(x + 6, y - 28),
        paint..strokeWidth = 1.5,
      );
      if (showNames) {
        _text(
          canvas,
          _midiNoteName(note.note),
          Offset(x - 10, y + 9),
          active ? accent : ink,
          9,
        );
      }
    }
    _text(
      canvas,
      'Upcoming 8 seconds',
      Offset(left, 10),
      ink.withValues(alpha: .6),
      10,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset offset,
    Color color,
    double size,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StaffPainter old) =>
      old.position != position ||
      old.showNames != showNames ||
      old.song.id != song.id ||
      old.ink != ink ||
      old.accent != accent;
}

class _DevicePill extends StatelessWidget {
  const _DevicePill({required this.controller});
  final PianoController controller;
  @override
  Widget build(BuildContext context) {
    final device = controller.connectedDevice;
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: device == null
            ? const Color(0xFFFFF1E8)
            : colors.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(
            device == null ? Icons.usb_off_rounded : Icons.usb_rounded,
            size: 16,
            color: device == null ? const Color(0xFFD97B3F) : colors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            device?.name ?? 'Demo mode',
            style: TextStyle(
              color: device == null
                  ? const Color(0xFFB05F2D)
                  : colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HearNotesToggle extends StatelessWidget {
  const _HearNotesToggle({required this.controller});
  final PianoController controller;

  @override
  Widget build(BuildContext context) => FilterChip(
    selected: controller.hearNotesEnabled,
    onSelected: controller.setHearNotes,
    avatar: Icon(
      controller.hearNotesEnabled
          ? Icons.volume_up_rounded
          : Icons.volume_off_rounded,
      size: 18,
    ),
    label: Text(controller.hearNotesEnabled ? 'Note sound on' : 'Hear notes'),
    tooltip: 'Play pressed notes through the Windows speaker synthesizer',
  );
}

class _PedalIndicator extends StatelessWidget {
  const _PedalIndicator({required this.controller});
  final PianoController controller;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: controller.sustainPedalDown
            ? colors.primaryContainer
            : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.sustainPedalDown
              ? colors.primary
              : colors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.keyboard_double_arrow_down_rounded,
            size: 17,
            color: controller.sustainPedalDown
                ? colors.primary
                : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            controller.sustainPedalDown
                ? 'Sustain pedal down (${controller.sustainPedalValue})'
                : 'Sustain pedal up',
            style: TextStyle(
              color: controller.sustainPedalDown
                  ? colors.onPrimaryContainer
                  : colors.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.controller});
  final PianoController controller;

  @override
  Widget build(BuildContext context) => SegmentedButton<PracticeMode>(
    segments: const [
      ButtonSegment(
        value: PracticeMode.playAlong,
        icon: Icon(Icons.play_circle_outline_rounded, size: 18),
        label: Text('Play along'),
        tooltip: 'The song follows its tempo while you play along',
      ),
      ButtonSegment(
        value: PracticeMode.pauseAndPlay,
        icon: Icon(Icons.front_hand_outlined, size: 18),
        label: Text('Pause & play'),
        tooltip: 'The song waits for each note or chord',
      ),
    ],
    selected: {controller.practiceMode},
    onSelectionChanged: (selection) =>
        controller.setPracticeMode(selection.first),
    showSelectedIcon: false,
    style: ButtonStyle(
      visualDensity: VisualDensity.compact,
      textStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _StatPanel extends StatelessWidget {
  const _StatPanel({required this.controller, required this.song});
  final PianoController controller;
  final MidiSong song;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .35),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live session',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _Stat(
          label: 'Accuracy',
          value: controller.attemptedNotes == 0
              ? '—'
              : '${controller.accuracy}%',
          color: Theme.of(context).colorScheme.primary,
        ),
        _Stat(
          label: 'Notes played',
          value: '${controller.attemptedNotes}',
          color: Theme.of(context).colorScheme.secondary,
        ),
        _Stat(
          label: 'Score notes',
          value: '${song.notes.length}',
          color: Theme.of(context).colorScheme.tertiary,
        ),
        _Stat(
          label: 'Tempo',
          value: '${(song.bpm * controller.speed).round()} BPM',
          color: Theme.of(context).colorScheme.primary.withValues(alpha: .58),
        ),
        if (controller.correctNotes > 0)
          Text(
            'Timing  ${controller.earlyNotes} early  •  ${controller.onTimeNotes} on time  •  ${controller.lateNotes} late',
            style: Theme.of(context).textTheme.labelSmall,
          ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

class _PracticeTip extends StatelessWidget {
  const _PracticeTip({required this.controller});
  final PianoController controller;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: .48),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.lightbulb_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          controller.connectedDevice == null
              ? 'Connect your piano'
              : controller.practiceMode == PracticeMode.playAlong
              ? 'Follow the performance'
              : 'You control the tempo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          controller.connectedDevice == null
              ? 'The score still runs in demo mode. Open Settings to connect the FP-10.'
              : controller.practiceMode == PracticeMode.playAlong
              ? 'The app plays at the selected tempo. Match the highlighted notes as they reach the line.'
              : 'Play every highlighted note. The score advances only when the full note or chord matches.',
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _Transport extends StatelessWidget {
  const _Transport({required this.controller, required this.song});
  final PianoController controller;
  final MidiSong song;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final playback = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () =>
              controller.seek(math.max(0, controller.position - 10)),
          icon: const Icon(Icons.replay_10_rounded),
        ),
        FilledButton(
          onPressed: controller.togglePlayback,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
            backgroundColor: colors.primary,
          ),
          child: Icon(
            controller.isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 28,
          ),
        ),
        IconButton(
          onPressed: () => controller.seek(
            math.min(song.duration, controller.position + 10),
          ),
          icon: const Icon(Icons.forward_10_rounded),
        ),
        const SizedBox(width: 12),
        Text(
          _clock(controller.position),
          style: const TextStyle(
            fontFeatures: [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
    final modeControl = controller.practiceMode == PracticeMode.playAlong
        ? PopupMenuButton<double>(
            initialValue: controller.speed,
            onSelected: controller.setSpeed,
            itemBuilder: (_) => [.5, .75, 1.0, 1.25, 1.5]
                .map(
                  (value) =>
                      PopupMenuItem(value: value, child: Text('$value×')),
                )
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${controller.speed}×',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.front_hand_outlined,
                  size: 15,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 6),
                Text(
                  'Waits for you',
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          );
    final slider = Slider(
      value: controller.position.clamp(0, math.max(.001, song.duration)),
      max: math.max(.001, song.duration),
      onChanged: controller.seek,
    );
    final duration = Text(
      song.durationLabel,
      style: TextStyle(
        color: colors.onSurfaceVariant,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 680) {
            return Column(
              children: [
                Row(children: [playback, const Spacer(), modeControl]),
                Row(
                  children: [
                    Expanded(child: slider),
                    duration,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              playback,
              Expanded(child: slider),
              duration,
              const SizedBox(width: 22),
              modeControl,
            ],
          );
        },
      ),
    );
  }
}

String _clock(double seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).floor().toString().padLeft(2, '0')}';

class _Keyboard extends StatelessWidget {
  const _Keyboard({required this.controller});
  final PianoController controller;
  static const blackNotes = {1, 3, 6, 8, 10};
  @override
  Widget build(BuildContext context) {
    // A0 (MIDI 21) through C8 (MIDI 108): the complete 88-key piano.
    const start = 21;
    const end = 108;
    final whites = [
      for (var note = start; note <= end; note++)
        if (!blackNotes.contains(note % 12)) note,
    ];
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      height: 136,
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    '88 KEYS  •  A0–C8',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: controller.lastInputNote == null
                          ? colors.surfaceContainerHigh
                          : colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sensors_rounded,
                          size: 14,
                          color: controller.lastInputNote == null
                              ? colors.onSurfaceVariant
                              : colors.onPrimary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          controller.lastInputNoteLabel,
                          style: TextStyle(
                            color: controller.lastInputNote == null
                                ? colors.onSurfaceVariant
                                : colors.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        if (controller.lastInputNote == null &&
                            controller.inputPacketCount > 0) ...[
                          const SizedBox(width: 7),
                          Text(
                            'packets ${controller.inputPacketCount}',
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 9,
                            ),
                          ),
                        ],
                        if (controller.lastInputNote != null) ...[
                          const SizedBox(width: 7),
                          Text(
                            'v${controller.lastInputVelocity}  •  #${controller.inputNoteCount}',
                            style: TextStyle(
                              color: colors.onPrimary.withValues(alpha: .86),
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final keyboardWidth = math.max(constraints.maxWidth, 1056.0);
                final whiteWidth = keyboardWidth / whites.length;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: keyboardWidth,
                    child: Stack(
                      children: [
                        Row(
                          children: whites
                              .map(
                                (note) => Expanded(
                                  child: _PianoKey(
                                    note: note,
                                    active:
                                        controller.playedNotes.contains(note) ||
                                        controller.fileNotes.contains(note),
                                    expected: controller.expectedNotes.contains(
                                      note,
                                    ),
                                    matched: controller.matchedWaitNotes
                                        .contains(note),
                                    isBlack: false,
                                    controller: controller,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        for (var i = 0; i < whites.length - 1; i++)
                          if (blackNotes.contains((whites[i] + 1) % 12))
                            Positioned(
                              left: (i + 1) * whiteWidth - whiteWidth * .31,
                              width: whiteWidth * .62,
                              height: 68,
                              child: _PianoKey(
                                note: whites[i] + 1,
                                active:
                                    controller.playedNotes.contains(
                                      whites[i] + 1,
                                    ) ||
                                    controller.fileNotes.contains(
                                      whites[i] + 1,
                                    ),
                                expected: controller.expectedNotes.contains(
                                  whites[i] + 1,
                                ),
                                matched: controller.matchedWaitNotes.contains(
                                  whites[i] + 1,
                                ),
                                isBlack: true,
                                controller: controller,
                              ),
                            ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PianoKey extends StatelessWidget {
  const _PianoKey({
    required this.note,
    required this.active,
    required this.expected,
    required this.matched,
    required this.isBlack,
    required this.controller,
  });
  final int note;
  final bool active, expected, isBlack;
  final bool matched;
  final PianoController controller;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTapDown: (_) => controller.audition(note, true),
      onTapUp: (_) => controller.audition(note, false),
      onTapCancel: () => controller.audition(note, false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        margin: EdgeInsets.only(right: isBlack ? 0 : 1),
        decoration: BoxDecoration(
          color: active
              ? colors.primary
              : matched
              ? colors.tertiary
              : expected
              ? colors.primaryContainer
              : isBlack
              ? Color.alphaBlend(
                  colors.primary.withValues(alpha: .12),
                  const Color(0xFF1D1D20),
                )
              : colors.surface,
          border: Border.all(
            color: isBlack
                ? Color.alphaBlend(
                    colors.primary.withValues(alpha: .22),
                    const Color(0xFF101012),
                  )
                : colors.outlineVariant,
          ),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(isBlack ? 5 : 7),
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .72),
                    blurRadius: 11,
                    spreadRadius: 2,
                  ),
                ]
              : isBlack
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _PianoRollPainter extends CustomPainter {
  _PianoRollPainter({
    required this.song,
    required this.position,
    required this.accent,
    required this.accentAlt,
    required this.onAccent,
  });
  final MidiSong song;
  final double position;
  final Color accent;
  final Color accentAlt;
  final Color onAccent;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Color.lerp(const Color(0xFF29282E), accent, .18)!
      ..strokeWidth = 1;
    for (var i = 1; i < 12; i++) {
      canvas.drawLine(
        Offset(size.width * i / 12, 0),
        Offset(size.width * i / 12, size.height),
        grid,
      );
    }
    for (var i = 1; i < 8; i++) {
      canvas.drawLine(
        Offset(0, size.height * i / 8),
        Offset(size.width, size.height * i / 8),
        grid,
      );
    }
    final playY = size.height * .78;
    canvas.drawLine(
      Offset(0, playY),
      Offset(size.width, playY),
      Paint()
        ..color = Color.lerp(accent, Colors.white, .42)!
        ..strokeWidth = 2,
    );
    const windowBefore = 1.3;
    const windowAfter = 5.0;
    final playNowNotes = <int, Color>{};
    for (final note in song.notes) {
      if (note.end < position - windowBefore ||
          note.start > position + windowAfter) {
        continue;
      }
      final x = (note.note - 21) / 87 * size.width;
      final width = math.max(5.0, size.width / 90 * .78);
      final yBottom = playY - (note.start - position) / windowAfter * playY;
      final height = math.max(
        7.0,
        (note.end - note.start) / windowAfter * playY,
      );
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, yBottom - height, width, height),
        const Radius.circular(4),
      );
      final active = note.start <= position && note.end >= position;
      final noteColor = active
          ? Color.lerp(accent, Colors.white, .32)!
          : note.channel % 2 == 0
          ? accent
          : accentAlt;
      if (note.start <= position + .08 && note.end >= position - .08) {
        playNowNotes[note.note] = noteColor;
      }
      canvas.drawRRect(rect, Paint()..color = noteColor);
      if (active) {
        canvas.drawCircle(
          Offset(x + width / 2, playY),
          5,
          Paint()..color = onAccent,
        );
      }
    }
    final label = TextPainter(
      text: TextSpan(
        text: 'PLAY NOW',
        style: TextStyle(
          color: Color.lerp(accent, Colors.white, .52),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(12, playY + 8));

    // Musically/Synthesia-style labels: each note gets a badge exactly where
    // its falling bar meets the strike line, rather than a detached summary.
    final sortedNotes = playNowNotes.keys.toList()..sort();
    final rowRightEdges = <double>[
      -double.infinity,
      -double.infinity,
      -double.infinity,
    ];
    for (final note in sortedNotes) {
      final noteText = _midiNoteName(note);
      final painter = TextPainter(
        text: TextSpan(
          text: noteText,
          style: TextStyle(
            color: onAccent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final badgeWidth = math.max(30.0, painter.width + 12);
      final centerX = (note - 21) / 87 * size.width + size.width / 180;
      var row = 0;
      for (var candidate = 0; candidate < rowRightEdges.length; candidate++) {
        if (centerX - badgeWidth / 2 > rowRightEdges[candidate] + 3) {
          row = candidate;
          break;
        }
      }
      final left = (centerX - badgeWidth / 2).clamp(
        2.0,
        size.width - badgeWidth - 2,
      );
      final top = playY - 27 - row * 25;
      final badge = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, badgeWidth, 21),
        const Radius.circular(10.5),
      );
      canvas.drawRRect(badge, Paint()..color = playNowNotes[note]!);
      painter.paint(
        canvas,
        Offset(left + (badgeWidth - painter.width) / 2, top + 4),
      );
      rowRightEdges[row] = left + badgeWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _PianoRollPainter old) =>
      old.position != position ||
      old.song.id != song.id ||
      old.accent != accent ||
      old.accentAlt != accentAlt ||
      old.onAccent != onAccent;
}

String _midiNoteName(int note) {
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

class _DevicesSettingsSection extends StatelessWidget {
  const _DevicesSettingsSection({required this.controller});
  final PianoController controller;

  Future<void> _confirmForget(BuildContext context, MidiDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Forget ${device.name}?'),
        content: const Text(
          'This disconnects the piano and removes its Bluetooth pairing from Windows. You can pair it again with Scan Bluetooth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forget device'),
          ),
        ],
      ),
    );
    if (confirmed == true) await controller.forgetDevice(device);
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: controller.refreshDevices,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh USB'),
          ),
          FilledButton.icon(
            onPressed: controller.bluetoothAvailable
                ? (controller.isBluetoothScanning
                      ? controller.stopBluetoothScan
                      : controller.startBluetoothScan)
                : null,
            icon: Icon(
              controller.isBluetoothScanning
                  ? Icons.stop_rounded
                  : Icons.bluetooth_searching_rounded,
            ),
            label: Text(
              controller.isBluetoothScanning ? 'Stop scan' : 'Scan Bluetooth',
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF242135), Color(0xFF3A3550)],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.piano_rounded,
                color: Color(0xFFB6A8FF),
                size: 38,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.connectedDevice?.name ??
                        (controller.fp10Visible
                            ? 'Roland keyboard found'
                            : 'Roland FP-10'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    controller.connectedDevice != null
                        ? controller.bluetoothInputTimedOut
                              ? 'Connected, but no MIDI input — repair the Windows pairing'
                              : controller.isAwaitingBluetoothInput
                              ? 'Connected — press any piano key to verify MIDI input'
                              : 'Connected — MIDI input and output are active'
                        : controller.fp10Visible
                        ? 'Available — select it below to connect'
                        : 'Connect the USB-B port to this Windows PC',
                    style: const TextStyle(color: Color(0xFFB4AFC2)),
                  ),
                ],
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: controller.connectedDevice != null
                    ? const Color(0xFF68E0AE)
                    : const Color(0xFF746E82),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      _BluetoothPanel(controller: controller),
      const SizedBox(height: 24),
      Text(
        'Available MIDI devices',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 13),
      if (controller.devices.isEmpty)
        _EmptyDevices(onRefresh: controller.refreshDevices)
      else
        ...controller.devices.map(
          (device) => _DeviceTile(
            device: device,
            selected: controller.connectedDevice?.id == device.id,
            busy: controller.isConnecting || controller.isForgetting,
            onConnect: () => controller.connect(device),
            onDisconnect: controller.disconnect,
            onForget: device.type == MidiDeviceType.ble
                ? () => _confirmForget(context, device)
                : null,
            onRepair:
                device.type == MidiDeviceType.ble &&
                    controller.connectedDevice?.id == device.id
                ? () => controller.repairBluetoothConnection(device)
                : null,
            repairRecommended: controller.bluetoothInputTimedOut,
          ),
        ),
      const SizedBox(height: 26),
      Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FP-10 connection checklist',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'USB: connect the FP-10 directly by USB-B, press Refresh USB, then Connect.\nBluetooth: enable Bluetooth on the FP-10, press Scan Bluetooth, then connect when it appears.\n\nDo not pair it as an audio device. Close other piano or MIDI apps that may already be using the connection.',
                    style: TextStyle(
                      height: 1.65,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _BluetoothPanel extends StatelessWidget {
  const _BluetoothPanel({required this.controller});

  final PianoController controller;

  String get _status {
    if (controller.isBluetoothScanning) {
      return 'Looking for nearby Bluetooth MIDI instruments…';
    }
    return switch (controller.bluetoothState) {
      BluetoothState.poweredOn =>
        controller.bluetoothDeviceCount == 0
            ? 'Bluetooth is ready. Start a scan to find your FP-10.'
            : '${controller.bluetoothDeviceCount} Bluetooth MIDI device${controller.bluetoothDeviceCount == 1 ? '' : 's'} found.',
      BluetoothState.poweredOff =>
        'Bluetooth is turned off in Windows settings.',
      BluetoothState.unauthorized =>
        'Windows has not allowed Bluetooth access for this app.',
      BluetoothState.unsupported =>
        'This computer does not expose a compatible Bluetooth adapter.',
      BluetoothState.resetting => 'The Bluetooth adapter is restarting…',
      _ => 'Checking the Windows Bluetooth adapter…',
    };
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: controller.isBluetoothScanning
              ? Padding(
                  padding: const EdgeInsets.all(13),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  Icons.bluetooth_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bluetooth MIDI',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _status,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (controller.isBluetoothScanning)
          TextButton(
            onPressed: controller.stopBluetoothScan,
            child: const Text('Stop'),
          ),
      ],
    ),
  );
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.selected,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
    required this.onForget,
    required this.onRepair,
    required this.repairRecommended,
  });
  final MidiDevice device;
  final bool selected, busy;
  final VoidCallback onConnect, onDisconnect;
  final VoidCallback? onForget;
  final VoidCallback? onRepair;
  final bool repairRecommended;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final identity = Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            device.type == MidiDeviceType.ble
                ? Icons.bluetooth_rounded
                : Icons.usb_rounded,
            color: colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${device.type == MidiDeviceType.ble ? 'BLUETOOTH' : device.type.name.toUpperCase()} MIDI • ${device.inputPorts.length} in / ${device.outputPorts.length} out',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: 6,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (onForget != null)
          IconButton(
            onPressed: busy ? null : onForget,
            tooltip: 'Forget Bluetooth device',
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        if (onRepair != null)
          OutlinedButton.icon(
            onPressed: busy ? null : onRepair,
            icon: Icon(
              Icons.build_circle_outlined,
              color: repairRecommended ? const Color(0xFFE45D75) : null,
            ),
            label: Text(repairRecommended ? 'Repair connection' : 'Repair'),
          ),
        if (selected)
          OutlinedButton(
            onPressed: onDisconnect,
            child: const Text('Disconnect'),
          )
        else
          FilledButton(
            onPressed: busy ? null : onConnect,
            child: Text(busy ? 'Connecting…' : 'Connect'),
          ),
      ],
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 620) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [identity, const SizedBox(height: 14), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 14),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices({required this.onRefresh});
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(30),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        const Icon(Icons.usb_off_rounded, size: 36, color: Color(0xFFAAA5B4)),
        const SizedBox(height: 10),
        const Text(
          'No MIDI devices found',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          'Connect and power on your keyboard, then try again.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 13),
        TextButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Scan again'),
        ),
      ],
    ),
  );
}

class _Toast extends StatelessWidget {
  const _Toast({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Material(
    elevation: 8,
    borderRadius: BorderRadius.circular(15),
    color: const Color(0xFF292638),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white70, size: 18),
          ),
        ],
      ),
    ),
  );
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.graphic_eq_rounded, color: Color(0xFF705CF6), size: 52),
          SizedBox(height: 18),
          CircularProgressIndicator(),
          SizedBox(height: 15),
          Text(
            'Preparing your music…',
            style: TextStyle(color: Color(0xFF777284)),
          ),
        ],
      ),
    ),
  );
}

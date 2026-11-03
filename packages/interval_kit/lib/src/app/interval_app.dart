import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interval_core/interval_core.dart';

import '../audio/cue_player.dart';
import '../haptics/haptic_player.dart';
import '../l10n/generated/kit_localizations.dart';
import '../settings/app_language.dart';
import '../settings/vibration_strength.dart';
import '../theme/interval_colors.dart';
import '../theme/interval_theme.dart';
import '../workout/keep_screen_on.dart';
import '../workout/workout_controller.dart';
import '../workout/workout_screen.dart';

/// Adds behaviour that follows the workout, such as background music.
///
/// Called once, when the app starts; returns a callback that undoes it.
typedef WorkoutAttachment = VoidCallback Function(WorkoutController workout);

/// The application shell shared by every app.
///
/// It owns the [WorkoutController], follows the [settings] — switching the
/// language and the theme, and restarting the workout when its plan
/// changes — and opens the settings screen. Apps describe only what makes
/// them different.
class IntervalApp<S> extends StatefulWidget {
  const IntervalApp({
    required this.settings,
    required this.planOf,
    required this.languageOf,
    required this.themeModeOf,
    required this.withThemeMode,
    required this.cues,
    required this.onGenerateTitle,
    required this.localizationsDelegates,
    required this.supportedLocales,
    required this.phaseLabel,
    required this.formatTime,
    required this.settingsBuilder,
    required this.vibrationOf,
    this.keepScreenOn = keepScreenOnWithWakelock,
    this.attach,
    super.key,
  });

  final ValueNotifier<S> settings;
  final WorkoutPlan Function(S settings) planOf;
  final AppLanguage Function(S settings) languageOf;
  final ThemeMode Function(S settings) themeModeOf;

  /// Returns [settings] with the theme changed, when the user switches it.
  final S Function(S settings, ThemeMode themeMode) withThemeMode;
  final CuePlayer cues;
  final GenerateAppTitle onGenerateTitle;

  /// The app's own delegates; [KitLocalizations] are added automatically.
  final List<LocalizationsDelegate<Object?>> localizationsDelegates;
  final List<Locale> supportedLocales;
  final String Function(BuildContext context, Phase phase) phaseLabel;
  final String Function(TimerSnapshot snapshot) formatTime;
  final WidgetBuilder settingsBuilder;

  /// The vibration strength of the transition cues, from the [settings].
  final VibrationStrength Function(S settings) vibrationOf;
  final KeepScreenOn keepScreenOn;
  final WorkoutAttachment? attach;

  @override
  State<IntervalApp<S>> createState() => _IntervalAppState<S>();
}

class _IntervalAppState<S> extends State<IntervalApp<S>>
    with TickerProviderStateMixin {
  /// Plays the transition vibrations; its strength follows the settings.
  late final SystemHapticPlayer _haptics = SystemHapticPlayer(
    strength: widget.vibrationOf(widget.settings.value),
  );

  late final WorkoutController _workout = WorkoutController(
    plan: widget.planOf(widget.settings.value),
    cues: widget.cues,
    keepScreenOn: widget.keepScreenOn,
    haptics: _haptics,
  );
  VoidCallback? _detach;

  /// Finds the theme toggle for the flood transition.
  final GlobalKey _themeButtonKey = GlobalKey();

  // The theme floods in from the toggle button: a disk of the incoming
  // background grows over the old screen, the theme swaps underneath at
  // full cover, and the disk dissolves to reveal the new one. Two
  // controllers — the swap starts from the growth's own completion, which
  // a single controller would not survive.
  late final AnimationController _flood = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );
  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  Offset _floodOrigin = Offset.zero;
  Color _floodColor = Colors.black;
  double _floodRadius = 0;
  ThemeMode? _pendingTheme;
  var _switchingTheme = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
    _detach = widget.attach?.call(_workout);
    _flood
      ..addListener(_refresh)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _swapThemeUnderCover();
      });
    _dissolve.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _switchingTheme = false);
      }
    });
  }

  void _refresh() => setState(() {});

  void _onSettingsChanged() {
    _haptics.strength = widget.vibrationOf(widget.settings.value);
    final plan = widget.planOf(widget.settings.value);
    if (plan != _workout.plan) {
      _workout.replacePlan(plan);
    }
  }

  @override
  void dispose() {
    _flood.dispose();
    _dissolve.dispose();
    widget.settings.removeListener(_onSettingsChanged);
    _detach?.call();
    unawaited(_haptics.dispose());
    _workout.dispose();
    super.dispose();
  }

  /// The theme floods in from the toggle button: a disk of the incoming
  /// background grows over the current screen; at full cover the theme
  /// swaps underneath and the disk dissolves away.
  void _toggleTheme(BuildContext context) {
    if (_switchingTheme) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final button = _themeButtonKey.currentContext?.findRenderObject();
    final center = button is RenderBox
        ? button.localToGlobal(button.size.center(Offset.zero))
        : size.center(Offset.zero);
    _pendingTheme = isDark ? ThemeMode.light : ThemeMode.dark;
    setState(() {
      _switchingTheme = true;
      _floodOrigin = center;
      _floodColor = isDark
          ? IntervalColors.light.background
          : IntervalColors.dark.background;
      _floodRadius = _coverRadius(center, size);
    });
    // A finished dissolve leaves the controller at 1, which would make the
    // next cover transparent from the start.
    _dissolve.value = 0;
    _flood.forward(from: 0);
  }

  static double _coverRadius(Offset origin, Size size) {
    double farthest = 0;
    for (final corner in [
      Offset.zero,
      size.topRight(Offset.zero),
      size.bottomLeft(Offset.zero),
      size.bottomRight(Offset.zero),
    ]) {
      farthest = math.max(farthest, (corner - origin).distance);
    }
    return farthest;
  }

  /// The disk covers the screen: swap the theme underneath and dissolve
  /// the cover away.
  void _swapThemeUnderCover() {
    final next = _pendingTheme;
    if (next == null) return;
    widget.settings.value = widget.withThemeMode(widget.settings.value, next);
    _pendingTheme = null;
    _dissolve.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: widget.settings,
    builder: (context, settings, _) => MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: widget.onGenerateTitle,
      theme: buildIntervalTheme(),
      darkTheme: buildIntervalTheme(brightness: Brightness.dark),
      themeMode: widget.themeModeOf(settings),
      // The flood transition replaces the theme animation.
      themeAnimationDuration: Duration.zero,
      // Without an app bar on the main screen, the status bar icons have
      // to be told to match the theme.
      builder: (context, child) {
        final app = AnnotatedRegion(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: child!,
        );
        if (!_switchingTheme) return app;
        return Stack(
          children: [
            app,
            Positioned.fill(
              child: FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(_dissolve),
                child: ClipPath(
                  clipper: _DiskClipper(
                    _floodOrigin,
                    _floodRadius * _flood.value,
                  ),
                  child: ColoredBox(color: _floodColor),
                ),
              ),
            ),
          ],
        );
      },
      locale: widget.languageOf(settings).locale,
      supportedLocales: widget.supportedLocales,
      localizationsDelegates: [
        ...widget.localizationsDelegates,
        KitLocalizations.delegate,
      ],
      home: Builder(
        builder: (context) => WorkoutScreen(
          controller: _workout,
          phaseLabel: widget.phaseLabel,
          formatTime: widget.formatTime,
          onOpenSettings: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: widget.settingsBuilder)),
          onToggleTheme: () => _toggleTheme(context),
          themeButtonKey: _themeButtonKey,
        ),
      ),
    ),
  );
}

/// The growing disk of the theme flood transition.
class _DiskClipper extends CustomClipper<Path> {
  const _DiskClipper(this.origin, this.radius);

  final Offset origin;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: origin, radius: radius));

  @override
  bool shouldReclip(_DiskClipper oldClipper) =>
      oldClipper.origin != origin || oldClipper.radius != radius;
}

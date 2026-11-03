import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:interval_core/interval_core.dart';

import '../audio/cue_player.dart';
import '../l10n/generated/kit_localizations.dart';
import '../settings/app_language.dart';
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

  /// Whether the workout button vibrates, from the [settings].
  final bool Function(S settings) vibrationOf;
  final KeepScreenOn keepScreenOn;
  final WorkoutAttachment? attach;

  @override
  State<IntervalApp<S>> createState() => _IntervalAppState<S>();
}

class _IntervalAppState<S> extends State<IntervalApp<S>> {
  late final WorkoutController _workout = WorkoutController(
    plan: widget.planOf(widget.settings.value),
    cues: widget.cues,
    keepScreenOn: widget.keepScreenOn,
  );
  VoidCallback? _detach;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
    _detach = widget.attach?.call(_workout);
  }

  void _onSettingsChanged() {
    final plan = widget.planOf(widget.settings.value);
    if (plan != _workout.plan) {
      _workout.replacePlan(plan);
    }
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _detach?.call();
    _workout.dispose();
    super.dispose();
  }

  /// Switches to the opposite of the theme on screen. From then on the
  /// choice is kept instead of following the device.
  void _toggleTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.settings.value = widget.withThemeMode(
      widget.settings.value,
      isDark ? ThemeMode.light : ThemeMode.dark,
    );
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
      // Without an app bar on the main screen, the status bar icons have
      // to be told to match the theme.
      builder: (context, child) => AnnotatedRegion(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child!,
      ),
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
          vibrationEnabled: widget.vibrationOf(settings),
        ),
      ),
    ),
  );
}

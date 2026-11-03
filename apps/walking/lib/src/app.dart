import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:interval_kit/interval_kit.dart';
import 'package:interval_media/interval_media.dart';

import '../l10n/generated/app_localizations.dart';
import 'settings/settings_screen.dart';
import 'settings/walking_settings.dart';

class WalkingApp extends StatelessWidget {
  const WalkingApp({
    required this.settings,
    required this.cues,
    required this.version,
    this.keepScreenOn = keepScreenOnWithWakelock,
    this.music,
    this.createPlayer = JustAudioTrackPlayer.new,
    this.session,
    super.key,
  });

  final ValueNotifier<WalkingSettings> settings;
  final CuePlayer cues;
  final String version;
  final KeepScreenOn keepScreenOn;

  /// The user's playlists, or `null` where music is not supported.
  final MusicLibrary? music;
  final TrackPlayer Function() createPlayer;

  /// Keeps the walk going with the screen off; `null` on the web.
  final WorkoutMediaSession? session;

  @override
  Widget build(BuildContext context) => IntervalApp(
    settings: settings,
    planOf: (settings) => settings.toPlan(),
    languageOf: (settings) => settings.language,
    themeModeOf: (settings) => settings.themeMode,
    withThemeMode: (settings, themeMode) =>
        settings.copyWith(themeMode: themeMode),
    vibrationOf: (settings) => settings.vibration,
    cues: cues,
    keepScreenOn: keepScreenOn,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    phaseLabel: _phaseLabel,
    formatTime: _formatTime,
    settingsBuilder: (_) =>
        SettingsScreen(settings: settings, version: version, music: music),
    attach: _attach,
  );

  VoidCallback _attach(WorkoutController workout) {
    final music = this.music;
    final phaseMusic = music == null
        ? null
        : PhaseMusic(
            workout: workout,
            playlists: music,
            createPlayer: createPlayer,
          );
    final unfollow = session?.follow(workout, describe: _describe);

    return () {
      phaseMusic?.dispose();
      unfollow?.call();
    };
  }

  /// The notification text, in the language the user chose.
  ({String title, String subtitle}) _describe(TimerSnapshot snapshot) {
    final l10n = lookupAppLocalizations(settings.value.language.locale);
    return (
      title: _phaseName(l10n, snapshot.phase),
      // The countdown belongs to the first round.
      subtitle: l10n.notificationRound(
        math.max(1, snapshot.phase.round),
        snapshot.plan.rounds,
      ),
    );
  }

  /// `m:ss`, e.g. `2:59`.
  static String _formatTime(TimerSnapshot snapshot) {
    final seconds = snapshot.remainingSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  static String _phaseLabel(BuildContext context, Phase phase) =>
      _phaseName(AppLocalizations.of(context), phase);

  static String _phaseName(AppLocalizations l10n, Phase phase) =>
      switch (phase.intensity) {
        Intensity.prepare => l10n.phasePrepare,
        Intensity.high => l10n.phaseFast,
        Intensity.low => l10n.phaseSlow,
      };
}

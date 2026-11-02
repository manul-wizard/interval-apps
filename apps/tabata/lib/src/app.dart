import 'package:flutter/widgets.dart';
import 'package:interval_kit/interval_kit.dart';

import '../l10n/generated/app_localizations.dart';
import 'settings/settings_screen.dart';
import 'settings/tabata_settings.dart';

class TabataApp extends StatelessWidget {
  const TabataApp({
    required this.settings,
    required this.cues,
    required this.version,
    this.keepScreenOn = keepScreenOnWithWakelock,
    super.key,
  });

  final ValueNotifier<TabataSettings> settings;
  final CuePlayer cues;
  final String version;
  final KeepScreenOn keepScreenOn;

  @override
  Widget build(BuildContext context) => IntervalApp(
    settings: settings,
    planOf: (settings) => settings.toPlan(),
    languageOf: (settings) => settings.language,
    themeModeOf: (settings) => settings.themeMode,
    withThemeMode: (settings, themeMode) =>
        settings.copyWith(themeMode: themeMode),
    cues: cues,
    keepScreenOn: keepScreenOn,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    phaseLabel: _phaseLabel,
    formatTime: (snapshot) =>
        snapshot.remainingSeconds.toString().padLeft(2, '0'),
    settingsBuilder: (_) =>
        SettingsScreen(settings: settings, version: version),
  );

  static String _phaseLabel(BuildContext context, Phase phase) {
    final l10n = AppLocalizations.of(context);
    return switch (phase.intensity) {
      Intensity.prepare => l10n.phasePrepare,
      Intensity.high => l10n.phaseWork,
      Intensity.low => l10n.phaseRest,
    };
  }
}

import 'package:flutter/material.dart';
import 'package:interval_kit/interval_kit.dart';

import '../../l10n/generated/app_localizations.dart';
import 'tabata_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.version,
    super.key,
  });

  final ValueNotifier<TabataSettings> settings;
  final String version;

  void _update(TabataSettings Function(TabataSettings) change) =>
      settings.value = change(settings.value);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ValueListenableBuilder(
      valueListenable: settings,
      builder: (context, current, _) => SettingsPage(
        title: KitLocalizations.of(context).settings,
        footer: Text(version, style: Theme.of(context).textTheme.labelSmall),
        children: [
          LanguageStepper(
            value: current.language,
            onChanged: (value) => _update((s) => s.copyWith(language: value)),
          ),
          SettingSwitch(
            label: KitLocalizations.of(context).vibration,
            value: current.vibration,
            onChanged: (value) => _update((s) => s.copyWith(vibration: value)),
          ),
          IntSettingStepper(
            label: l10n.settingRounds,
            value: current.rounds,
            range: TabataSettings.roundsRange,
            onChanged: (value) => _update((s) => s.copyWith(rounds: value)),
          ),
          IntSettingStepper(
            label: l10n.settingWork,
            value: current.workSeconds,
            range: TabataSettings.workRange,
            onChanged: (value) =>
                _update((s) => s.copyWith(workSeconds: value)),
          ),
          IntSettingStepper(
            label: l10n.settingRest,
            value: current.restSeconds,
            range: TabataSettings.restRange,
            onChanged: (value) =>
                _update((s) => s.copyWith(restSeconds: value)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:interval_kit/interval_kit.dart';
import 'package:interval_media/interval_media.dart';

import '../../l10n/generated/app_localizations.dart';
import '../music/playlist_screen.dart';
import 'walking_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.settings,
    required this.version,
    this.music,
    super.key,
  });

  final ValueNotifier<WalkingSettings> settings;
  final String version;

  /// The user's playlists; `null` where music cannot be chosen, e.g. on
  /// the web.
  final MusicLibrary? music;

  void _update(WalkingSettings Function(WalkingSettings) change) =>
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
          VibrationStepper(
            value: current.vibration,
            onChanged: (value) => _update((s) => s.copyWith(vibration: value)),
          ),
          IntSettingStepper(
            label: l10n.settingRounds,
            value: current.rounds,
            range: WalkingSettings.roundsRange,
            onChanged: (value) => _update((s) => s.copyWith(rounds: value)),
          ),
          IntSettingStepper(
            label: l10n.settingFast,
            value: current.fastMinutes,
            range: WalkingSettings.fastRange,
            onChanged: (value) =>
                _update((s) => s.copyWith(fastMinutes: value)),
          ),
          IntSettingStepper(
            label: l10n.settingSlow,
            value: current.slowMinutes,
            range: WalkingSettings.slowRange,
            onChanged: (value) =>
                _update((s) => s.copyWith(slowMinutes: value)),
          ),
          if (music case final music?) ...[
            _PlaylistLink(
              music: music,
              intensity: Intensity.high,
              label: l10n.settingMusicFast,
              title: l10n.phaseFast,
            ),
            _PlaylistLink(
              music: music,
              intensity: Intensity.low,
              label: l10n.settingMusicSlow,
              title: l10n.phaseSlow,
            ),
          ],
        ],
      ),
    );
  }
}

class _PlaylistLink extends StatelessWidget {
  const _PlaylistLink({
    required this.music,
    required this.intensity,
    required this.label,
    required this.title,
  });

  final MusicLibrary music;
  final Intensity intensity;
  final String label;
  final String title;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: music,
    builder: (context, _) => SettingLink(
      label: label,
      value: AppLocalizations.of(context)
          .musicTrackCount(music.value[intensity].length),
      icon: Icons.library_music_outlined,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PlaylistScreen(
            library: music,
            intensity: intensity,
            title: title,
          ),
        ),
      ),
    ),
  );
}

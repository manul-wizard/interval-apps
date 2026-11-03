import 'dart:ui';

import 'package:interval_kit/interval_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tabata_settings.dart';

/// Persists [TabataSettings] on the device.
final class SettingsStore {
  SettingsStore._(this._preferences);

  static const _language = 'language';
  static const _theme = 'theme';
  static const _vibration = 'vibration';
  static const _rounds = 'rounds';
  static const _work = 'workSeconds';
  static const _rest = 'restSeconds';

  static Future<SettingsStore> open() async => SettingsStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_language, _rounds, _work, _rest, _theme, _vibration},
      ),
    ),
  );

  final SharedPreferencesWithCache _preferences;

  /// Reads the saved settings; on first launch, picks the device language
  /// and follows the device theme.
  TabataSettings load({required List<Locale> deviceLocales}) {
    const defaults = TabataSettings(language: AppLanguage.english);
    final language = _preferences.getString(_language);

    return TabataSettings(
      themeMode: ThemePreference.fromCode(_preferences.getString(_theme)),
      language: language == null
          ? AppLanguage.fromLocales(deviceLocales)
          : AppLanguage.fromCode(language),
      vibration: _preferences.getBool(_vibration) ?? defaults.vibration,
      rounds: TabataSettings.roundsRange.clamp(
        _preferences.getInt(_rounds) ?? defaults.rounds,
      ),
      workSeconds: TabataSettings.workRange.clamp(
        _preferences.getInt(_work) ?? defaults.workSeconds,
      ),
      restSeconds: TabataSettings.restRange.clamp(
        _preferences.getInt(_rest) ?? defaults.restSeconds,
      ),
    );
  }

  Future<void> save(TabataSettings settings) async {
    await Future.wait([
      _preferences.setString(_language, settings.language.code),
      if (settings.themeMode.code case final theme?)
        _preferences.setString(_theme, theme)
      else
        _preferences.remove(_theme),
      _preferences.setBool(_vibration, settings.vibration),
      _preferences.setInt(_rounds, settings.rounds),
      _preferences.setInt(_work, settings.workSeconds),
      _preferences.setInt(_rest, settings.restSeconds),
    ]);
  }
}

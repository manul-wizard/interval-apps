import 'dart:ui';

import 'package:interval_kit/interval_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'walking_settings.dart';

/// Persists [WalkingSettings] on the device.
final class SettingsStore {
  SettingsStore._(this._preferences);

  static const _language = 'language';
  static const _theme = 'theme';
  static const _vibration = 'vibration';
  static const _rounds = 'rounds';
  static const _fast = 'fastMinutes';
  static const _slow = 'slowMinutes';

  static Future<SettingsStore> open() async => SettingsStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_language, _rounds, _fast, _slow, _theme, _vibration},
      ),
    ),
  );

  final SharedPreferencesWithCache _preferences;

  /// Reads the saved settings; on first launch, picks the device language
  /// and follows the device theme.
  WalkingSettings load({required List<Locale> deviceLocales}) {
    const defaults = WalkingSettings(language: AppLanguage.english);
    final language = _preferences.getString(_language);

    return WalkingSettings(
      themeMode: ThemePreference.fromCode(_preferences.getString(_theme)),
      language: language == null
          ? AppLanguage.fromLocales(deviceLocales)
          : AppLanguage.fromCode(language),
      vibration: VibrationStrength.fromCode(_preferences.getString(_vibration)),
      rounds: WalkingSettings.roundsRange.clamp(
        _preferences.getInt(_rounds) ?? defaults.rounds,
      ),
      fastMinutes: WalkingSettings.fastRange.clamp(
        _preferences.getInt(_fast) ?? defaults.fastMinutes,
      ),
      slowMinutes: WalkingSettings.slowRange.clamp(
        _preferences.getInt(_slow) ?? defaults.slowMinutes,
      ),
    );
  }

  Future<void> save(WalkingSettings settings) async {
    await Future.wait([
      _preferences.setString(_language, settings.language.code),
      if (settings.themeMode.code case final theme?)
        _preferences.setString(_theme, theme)
      else
        _preferences.remove(_theme),
      _preferences.setString(_vibration, settings.vibration.code),
      _preferences.setInt(_rounds, settings.rounds),
      _preferences.setInt(_fast, settings.fastMinutes),
      _preferences.setInt(_slow, settings.slowMinutes),
    ]);
  }
}

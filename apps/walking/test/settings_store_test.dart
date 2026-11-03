import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:walking/src/settings/settings_store.dart';
import 'package:walking/src/settings/walking_settings.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  Future<WalkingSettings> reopen() async =>
      (await SettingsStore.open()).load(deviceLocales: const [Locale('ru')]);

  test('starts in the device language and theme', () async {
    final settings = await reopen();
    expect(settings.language, AppLanguage.russian);
    expect(settings.themeMode, ThemeMode.system);
  });

  test('keeps a picked theme', () async {
    final store = await SettingsStore.open();
    final settings = store.load(deviceLocales: const [Locale('en')]);

    await store.save(settings.copyWith(themeMode: ThemeMode.dark));
    expect((await reopen()).themeMode, ThemeMode.dark);

    await store.save(settings.copyWith(themeMode: ThemeMode.system));
    expect((await reopen()).themeMode, ThemeMode.system);
  });

  test('vibrates by default and keeps the choice to turn it off', () async {
    final store = await SettingsStore.open();
    final settings = store.load(deviceLocales: const [Locale('en')]);
    expect(settings.vibration, isTrue);

    await store.save(settings.copyWith(vibration: false));
    expect((await reopen()).vibration, isFalse);
  });
}

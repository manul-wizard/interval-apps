import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';
import 'package:interval_media/interval_media.dart';
import 'package:walking/src/app.dart';
import 'package:walking/src/settings/walking_settings.dart';

void main() {
  Future<ValueNotifier<WalkingSettings>> pumpApp(
    WidgetTester tester,
    AppLanguage language,
  ) async {
    final settings = ValueNotifier(WalkingSettings(language: language));
    await tester.pumpWidget(
      WalkingApp(
        settings: settings,
        cues: const SilentCuePlayer(),
        version: '1.2.3',
        keepScreenOn: ({required enabled}) async {},
      ),
    );
    await tester.pumpAndSettle();
    return settings;
  }

  testWidgets('starts with a short countdown', (tester) async {
    await pumpApp(tester, AppLanguage.english);

    expect(find.text('0:10'), findsOneWidget);
    expect(find.text('0/5'), findsOneWidget);
    expect(find.text('GET READY'), findsOneWidget);
  });

  testWidgets('turns vibration off from the settings', (tester) async {
    final settings = await pumpApp(tester, AppLanguage.english);
    expect(settings.value.vibration, isTrue);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(settings.value.vibration, isFalse);
  });

  testWidgets('settings with playlists fit a small screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final root = Directory.systemTemp.createTempSync('walking_layout_');
    addTearDown(() => root.deleteSync(recursive: true));
    final music = (await tester.runAsync(
      () async => MusicLibrary.open(root: root),
    ))!;

    await tester.pumpWidget(
      WalkingApp(
        settings: ValueNotifier(
          const WalkingSettings(language: AppLanguage.english),
        ),
        cues: const SilentCuePlayer(),
        version: '1.2.3',
        keepScreenOn: ({required enabled}) async {},
        music: music,
        createPlayer: RecordingTrackPlayer.new,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // Fling through the whole list; any layout overflow would throw.
    await tester.fling(find.byType(ListView), const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('moves on to the fast pace', (tester) async {
    await pumpApp(tester, AppLanguage.russian);

    await tester.tap(find.text('СТАРТ'));
    await tester.pump(WalkingSettings.prepare);

    expect(find.text('БЫСТРЫЙ ТЕМП'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    await tester.tap(find.text('СТОП'));
    await tester.pumpAndSettle();
  });

  testWidgets('plays the fast playlist while walking fast', (tester) async {
    final root = Directory.systemTemp.createTempSync('walking_app_');
    addTearDown(() => root.deleteSync(recursive: true));
    final music = (await tester.runAsync(() async {
      final music = await MusicLibrary.open(root: root);
      await music.add(Intensity.high, [
        (name: 'fast.mp3', read: () => Stream.value(const [0])),
      ]);
      return music;
    }))!;
    final players = <RecordingTrackPlayer>[];

    await tester.pumpWidget(
      WalkingApp(
        settings: ValueNotifier(
          const WalkingSettings(language: AppLanguage.english),
        ),
        cues: const SilentCuePlayer(),
        version: '1.2.3',
        keepScreenOn: ({required enabled}) async {},
        music: music,
        createPlayer: () {
          final player = RecordingTrackPlayer();
          players.add(player);
          return player;
        },
      ),
    );
    await tester.tap(find.text('START'));
    await tester.pump(WalkingSettings.prepare + const Duration(seconds: 5));

    final [fast, slow] = players;
    expect(fast.tracks.single.title, 'fast');
    expect(fast.playing, isTrue);
    expect(fast.volume, 1);
    expect(slow.playing, isFalse);

    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
  });

  testWidgets('describes the walk in the notification', (tester) async {
    final session = WorkoutMediaSession();
    await tester.pumpWidget(
      WalkingApp(
        settings: ValueNotifier(
          const WalkingSettings(language: AppLanguage.russian),
        ),
        cues: const SilentCuePlayer(),
        version: '1.2.3',
        keepScreenOn: ({required enabled}) async {},
        session: session,
      ),
    );

    await tester.tap(find.text('СТАРТ'));
    await tester.pump();
    expect(session.mediaItem.value?.title, 'Приготовьтесь');
    expect(session.mediaItem.value?.artist, 'Раунд 1 из 5');

    await tester.pump(WalkingSettings.prepare + const Duration(minutes: 3));
    expect(session.mediaItem.value?.title, 'Медленный темп');
    expect(session.playbackState.value.playing, isTrue);

    await tester.tap(find.text('СТОП'));
    await tester.pumpAndSettle();
    expect(session.playbackState.value.playing, isFalse);
  });
}

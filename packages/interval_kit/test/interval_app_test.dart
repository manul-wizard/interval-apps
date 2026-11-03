import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  final plan = WorkoutPlan.intervals(
    rounds: 1,
    prepare: const Duration(seconds: 3),
    high: const Duration(seconds: 5),
    low: const Duration(seconds: 5),
  );

  // The theme is the only setting these tests need.
  Widget app({
    ValueNotifier<ThemeMode>? settings,
    WorkoutAttachment? attach,
    VibrationStrength vibration = VibrationStrength.medium,
  }) => IntervalApp(
    settings: settings ?? ValueNotifier(ThemeMode.system),
    planOf: (_) => plan,
    languageOf: (_) => AppLanguage.english,
    themeModeOf: (themeMode) => themeMode,
    withThemeMode: (_, themeMode) => themeMode,
    vibrationOf: (_) => vibration,
    cues: const SilentCuePlayer(),
    keepScreenOn: ({required enabled}) async {},
    onGenerateTitle: (_) => 'Test',
    localizationsDelegates: const [],
    supportedLocales: const [Locale('en')],
    phaseLabel: (_, phase) => phase.intensity.name,
    formatTime: (snapshot) => '${snapshot.remainingSeconds}',
    settingsBuilder: (_) => const SizedBox(),
    attach: attach,
  );

  testWidgets('attaches to the workout once and detaches on dispose', (
    tester,
  ) async {
    final attached = <WorkoutController>[];
    var detached = 0;

    await tester.pumpWidget(
      app(
        attach: (workout) {
          attached.add(workout);
          return () => detached++;
        },
      ),
    );
    await tester.pump();

    expect(attached, hasLength(1));
    expect(attached.single.plan, plan);
    expect(detached, 0);

    await tester.pumpWidget(const SizedBox());

    expect(detached, 1);
  });

  Brightness brightnessOnScreen(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(WorkoutScreen))).brightness;

  testWidgets('taps back on the workout button', (tester) async {
    final haptics = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.method);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();

    expect(haptics, ['HapticFeedback.vibrate']);
  });

  testWidgets('stays silent when vibration is off', (tester) async {
    final haptics = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add(call.method);
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(app(vibration: VibrationStrength.off));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();

    expect(haptics, isEmpty);
  });

  testWidgets('disables reset while the workout is at its beginning', (
    tester,
  ) async {
    Future<FlatTextButton> resetButton() async =>
        tester.widget(find.widgetWithText(FlatTextButton, 'RESET'));

    await tester.pumpWidget(app());
    await tester.pump();
    expect((await resetButton()).onPressed, isNull);

    await tester.tap(find.text('START'));
    await tester.pump();
    expect((await resetButton()).onPressed, isNotNull);

    await tester.tap(find.text('RESET'));
    await tester.pump();
    expect((await resetButton()).onPressed, isNull);
  });

  testWidgets('rests the ring until the workout runs', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    // Transform.scale keeps the Z diagonal at 1, so the 2D scale has to be
    // read off the X entry; getMaxScaleOnAxis would always report 1.
    double ringScale() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(TimerFace),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .entry(0, 0);

    // A fresh app shows the ring in the resting look, like a pause.
    expect(ringScale(), moreOrLessEquals(0.96, epsilon: 0.01));

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(ringScale(), moreOrLessEquals(1, epsilon: 0.02));

    // Pausing rebuilds the screen and starts the press-in; the animation
    // itself ticks from the following frame.
    await tester.tap(find.text('STOP'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(ringScale(), moreOrLessEquals(0.96, epsilon: 0.01));

    await tester.tap(find.text('RESUME'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(ringScale(), moreOrLessEquals(1, epsilon: 0.02));
  });

  testWidgets('labels the paused workout Resume', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.tap(find.text('STOP'));
    await tester.pump();
    expect(find.text('RESUME'), findsOneWidget);

    await tester.tap(find.text('RESUME'));
    await tester.pump();
    expect(find.text('STOP'), findsOneWidget);
  });

  testWidgets('floods the theme in from the toggle button', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = ValueNotifier(ThemeMode.system);

    await tester.pumpWidget(app(settings: settings));
    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-flood the theme has not swapped yet.
    expect(settings.value, ThemeMode.system);

    await tester.pumpAndSettle();
    expect(settings.value, ThemeMode.dark);
  });

  testWidgets('follows the device theme until the user picks one', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final settings = ValueNotifier(ThemeMode.system);

    await tester.pumpWidget(app(settings: settings));
    expect(brightnessOnScreen(tester), Brightness.dark);

    await tester.tap(find.byTooltip('Light theme'));
    await tester.pumpAndSettle();
    expect(settings.value, ThemeMode.light);
    expect(brightnessOnScreen(tester), Brightness.light);

    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    expect(settings.value, ThemeMode.dark);
    expect(brightnessOnScreen(tester), Brightness.dark);
  });
}

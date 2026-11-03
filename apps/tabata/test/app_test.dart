import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';
import 'package:tabata/src/app.dart';
import 'package:tabata/src/settings/tabata_settings.dart';

void main() {
  late ValueNotifier<TabataSettings> settings;

  setUp(() {
    settings = ValueNotifier(
      const TabataSettings(language: AppLanguage.english),
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      TabataApp(
        settings: settings,
        cues: const SilentCuePlayer(),
        version: '1.2.3',
        keepScreenOn: ({required enabled}) async {},
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the countdown before the first round', (tester) async {
    await pumpApp(tester);

    expect(find.text('10'), findsOneWidget);
    expect(find.text('0/8'), findsOneWidget);
    expect(find.text('GET READY'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);
  });

  testWidgets('start and stop toggle the timer', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('START'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('STOP'), findsOneWidget);
    expect(find.text('09'), findsOneWidget);

    await tester.tap(find.text('STOP'));
    await tester.pumpAndSettle();
    expect(find.text('PAUSE'), findsOneWidget);
  });

  testWidgets('settings change the workout', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('SETTINGS'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_circle_outline).first);
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(settings.value.rounds, 9);
    expect(find.text('0/9'), findsOneWidget);
  });

  testWidgets('turns vibration off from the settings', (tester) async {
    await pumpApp(tester);
    expect(settings.value.vibration, isTrue);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(settings.value.vibration, isFalse);
  });

  testWidgets('settings fit a small screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpApp(tester);

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    // Fling through the whole list; any layout overflow would throw.
    await tester.fling(find.byType(ListView), const Offset(0, -300), 1000);
    await tester.pumpAndSettle();

    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('switches the language', (tester) async {
    await pumpApp(tester);

    settings.value = settings.value.copyWith(language: AppLanguage.russian);
    await tester.pumpAndSettle();

    expect(find.text('СТАРТ'), findsOneWidget);
    expect(find.text('ПОДГОТОВКА'), findsOneWidget);
  });
}

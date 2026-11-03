import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  Future<void> pumpStepper(
    WidgetTester tester, {
    required int value,
    required ValueChanged<int> onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: KitLocalizations.localizationsDelegates,
      home: Scaffold(
        body: IntSettingStepper(
          label: 'Rounds',
          value: value,
          range: const IntRange(1, 3),
          onChanged: onChanged,
        ),
      ),
    ),
  );

  testWidgets('changes the value by one per tap', (tester) async {
    int? changed;
    await pumpStepper(tester, value: 2, onChanged: (value) => changed = value);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    expect(changed, 3);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    expect(changed, 1);
  });

  testWidgets('disables the button at the limit', (tester) async {
    int? changed;
    await pumpStepper(tester, value: 3, onChanged: (value) => changed = value);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    expect(changed, isNull);
  });

  testWidgets('repeats faster the longer the button is held', (tester) async {
    final changes = <int>[];
    await pumpStepper(tester, value: 1, onChanged: changes.add);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byIcon(Icons.add_circle_outline)),
    );
    await tester.pump(kLongPressTimeout);
    // The first repeat waits a beat, so a plain long press barely moves.
    await tester.pump(const Duration(milliseconds: 250));
    expect(changes, isEmpty);

    await tester.pump(const Duration(seconds: 2));
    await gesture.up();

    expect(changes.length, greaterThan(4));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  Future<void> pumpSwitch(
    WidgetTester tester, {
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SettingSwitch(
          label: 'Vibration',
          value: value,
          onChanged: onChanged,
        ),
      ),
    ),
  );

  testWidgets('toggles when the plate is tapped', (tester) async {
    final changes = <bool>[];
    await pumpSwitch(tester, value: false, onChanged: changes.add);

    await tester.tap(find.byType(InkWell));
    expect(changes, [true]);
  });

  testWidgets('a tap on the switch itself fires once', (tester) async {
    final changes = <bool>[];
    await pumpSwitch(tester, value: false, onChanged: changes.add);

    await tester.tap(find.byType(Switch));
    expect(changes, [true]);
  });
}

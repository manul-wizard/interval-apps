import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  /// Expects the ring track and its arc at [sweepAngle].
  void expectSweep(WidgetTester tester, double sweepAngle) {
    expect(
      tester.renderObject(
        find.descendant(
          of: find.byType(ProgressRing),
          matching: find.byType(CustomPaint),
        ),
      ),
      paints
        ..arc(sweepAngle: math.pi * 2)
        ..arc(sweepAngle: sweepAngle),
    );
  }

  /// Expects the ring drawn half full: the track, then the half arc.
  void expectHalfFull(WidgetTester tester) => expectSweep(tester, -math.pi);

  Future<void> pumpRing(
    WidgetTester tester, {
    double fraction = 1,
    Duration? drainOver = const Duration(seconds: 20),
    Color color = const Color(0xFF00FF00),
  }) => tester.pumpWidget(
    Center(
      child: SizedBox.square(
        dimension: 200,
        child: ProgressRing(
          remainingFraction: fraction,
          drainOver: drainOver,
          color: color,
        ),
      ),
    ),
  );

  testWidgets('drains in step with the clock', (tester) async {
    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 10));
    expectHalfFull(tester);
    // Without a size the painter is invisible however correct the arcs are.
    expect(tester.getSize(find.byType(ProgressRing)), const Size(200, 200));
  });

  testWidgets('snaps to a fresher measurement instead of refilling', (
    tester,
  ) async {
    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 5));

    // The engine measured slightly more than the drain has reached (clock
    // skew on phones). The ring takes the measurement as is instead of
    // treating it as a new phase and sweeping back through the track color.
    await pumpRing(
      tester,
      fraction: 0.87,
      drainOver: const Duration(seconds: 16),
    );
    expectSweep(tester, -0.87 * 2 * math.pi);
  });

  testWidgets('fades a finished phase out through the track color', (
    tester,
  ) async {
    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 20)); // drained to empty

    // The next phase arrives: no sweep back to full. The empty ring hides
    // in the track color while the new phase takes over underneath.
    await pumpRing(
      tester,
      drainOver: const Duration(seconds: 10),
      color: const Color(0xFF0000FF),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expectSweep(tester, 0);

    // The new phase drains all the way down: the swap lands mid-pump, the
    // fresh drain starts ticking on the next one, and then it runs out.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    expectSweep(tester, 0);
  });

  testWidgets('a reset sweeps back in the resting color', (tester) async {
    await pumpRing(tester, color: const Color(0xFF0000FF));
    await tester.pump(const Duration(seconds: 5));

    // A reset: the sweep back runs together with the change to the
    // resting color.
    await tester.pumpWidget(
      const Center(
        child: SizedBox.square(
          dimension: 200,
          child: ProgressRing(remainingFraction: 1, color: Color(0xFF00FF00)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.renderObject(
        find.descendant(
          of: find.byType(ProgressRing),
          matching: find.byType(CustomPaint),
        ),
      ),
      paints
        // The track falls back to the light palette without a theme.
        ..arc(sweepAngle: math.pi * 2, color: const Color(0xFFE7DFDA))
        ..arc(sweepAngle: -2 * math.pi, color: const Color(0xFF00FF00)),
    );
  });

  testWidgets('refills on reset without draining while paused', (tester) async {
    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 10));
    expectHalfFull(tester);

    // A reset: full again, with nothing to drain yet.
    await tester.pumpWidget(
      const Center(
        child: SizedBox.square(
          dimension: 200,
          child: ProgressRing(remainingFraction: 1, color: Color(0xFF00FF00)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 125));
    expectSweep(tester, -1.5 * math.pi);
    await tester.pump(const Duration(milliseconds: 300));
    expectSweep(tester, -2 * math.pi);
  });

  testWidgets('keeps real time when the system turns animations off', (
    tester,
  ) async {
    // Android does this in battery saver mode or with "Remove animations".
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await pumpRing(tester);
    await tester.pump(const Duration(seconds: 10));
    expectHalfFull(tester);
  });
}

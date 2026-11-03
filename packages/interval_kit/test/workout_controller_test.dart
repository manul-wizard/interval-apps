import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  final plan = WorkoutPlan.intervals(
    rounds: 2,
    prepare: const Duration(seconds: 2),
    high: const Duration(seconds: 3),
    low: const Duration(seconds: 1),
    lowAfterLastRound: false,
  );

  void withController(
    void Function(
      FakeAsync async,
      WorkoutController controller,
      RecordingCuePlayer cues,
      RecordingHapticPlayer haptics,
      List<bool> screenOn,
    )
    body,
  ) {
    fakeAsync((async) {
      final cues = RecordingCuePlayer();
      final haptics = RecordingHapticPlayer();
      final screenOn = <bool>[];
      final controller = WorkoutController(
        plan: plan,
        cues: cues,
        keepScreenOn: ({required enabled}) async => screenOn.add(enabled),
        haptics: haptics,
      );
      body(async, controller, cues, haptics, screenOn);
      controller.dispose();
      async.flushMicrotasks();
    });
  }

  test('plays a cue for every phase except the countdown', () {
    withController((async, controller, cues, _, _) {
      controller.toggle();
      async.elapse(plan.totalDuration);

      expect(cues.played, [Cue.tap, Cue.high, Cue.low, Cue.high, Cue.finish]);
    });
  });

  test('taps on phase changes, doubles on the main phase, ends heavy', () {
    withController((async, controller, _, haptics, _) {
      controller.toggle();
      async.elapse(plan.totalDuration);

      expect(haptics.played, [
        HapticCue.phaseChange, // the countdown
        HapticCue.mainPhase, // work
        HapticCue.phaseChange, // rest
        HapticCue.mainPhase, // work
        HapticCue.finished,
      ]);
    });
  });

  test('returns to the beginning after the workout', () {
    withController((async, controller, _, _, _) {
      controller.toggle();
      async.elapse(plan.totalDuration);

      expect(controller.status, TimerStatus.ready);
      expect(controller.snapshot, TimerSnapshot.initial(plan));
    });
  });

  test('keeps the screen on only while running', () {
    withController((async, controller, _, _, screenOn) {
      controller
        ..toggle()
        ..toggle()
        ..toggle()
        ..reset();

      expect(screenOn, [true, false, true, false]);
    });
  });

  test('notifies listeners as the countdown ticks', () {
    withController((async, controller, _, _, _) {
      final seconds = <int>[];
      controller
        ..addListener(() => seconds.add(controller.snapshot.remainingSeconds))
        ..toggle();
      async.elapse(const Duration(seconds: 2));

      expect(seconds, [2, 1, 3]);
    });
  });
}

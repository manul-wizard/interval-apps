import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:interval_kit/interval_kit.dart';

void main() {
  /// Records the haptic types sent to the platform.
  final vibrated = <String>[];

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrated.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(vibrated.clear);

  test('a single light tap on a phase change', () async {
    await SystemHapticPlayer().play(HapticCue.phaseChange);

    expect(vibrated, ['HapticFeedbackType.lightImpact']);
  });

  test('a heavier tap on the main phase', () async {
    final player = SystemHapticPlayer(strength: VibrationStrength.strong);
    await player.play(HapticCue.mainPhase);

    expect(vibrated, ['HapticFeedbackType.heavyImpact']);
    await player.dispose();
  });

  test('the main phase double-taps a beat apart', () {
    fakeAsync((async) {
      final player = SystemHapticPlayer();
      unawaited(player.play(HapticCue.mainPhase));
      async.flushMicrotasks();
      expect(vibrated, ['HapticFeedbackType.mediumImpact']);

      async.elapse(const Duration(milliseconds: 140));
      async.flushMicrotasks();
      expect(vibrated, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.lightImpact',
      ]);

      // No third tap.
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();
      expect(vibrated, hasLength(2));

      unawaited(player.dispose());
    });
  });

  test('dispose cancels the second tap of a double', () {
    fakeAsync((async) {
      final player = SystemHapticPlayer();
      unawaited(player.play(HapticCue.mainPhase));
      async.flushMicrotasks();

      unawaited(player.dispose());
      async.elapse(const Duration(seconds: 1));
      async.flushMicrotasks();

      expect(vibrated, ['HapticFeedbackType.mediumImpact']);
    });
  });

  test('nothing vibrates when the vibration is off', () async {
    final player = SystemHapticPlayer(strength: VibrationStrength.off);
    await player.play(HapticCue.mainPhase);
    await player.play(HapticCue.finished);

    expect(vibrated, isEmpty);
  });

  test('the strength follows the setting', () async {
    final player = SystemHapticPlayer();
    player.strength = VibrationStrength.strong;
    await player.play(HapticCue.phaseChange);

    expect(vibrated, ['HapticFeedbackType.mediumImpact']);
  });
}

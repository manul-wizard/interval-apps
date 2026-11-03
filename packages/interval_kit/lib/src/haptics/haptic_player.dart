import 'dart:async';

import 'package:flutter/services.dart';
import 'package:interval_core/interval_core.dart';

import '../settings/vibration_strength.dart';

/// The haptic feedback tied to a timer event.
enum HapticCue {
  /// A single tap: a secondary phase began — the countdown or a rest.
  phaseChange,

  /// A double tap: the main phase began — work or a fast pace.
  mainPhase,

  /// The workout is done.
  finished;

  /// The feedback for a phase, by its intensity.
  static HapticCue forPhase(Phase phase) => switch (phase.intensity) {
    Intensity.high => HapticCue.mainPhase,
    Intensity.prepare || Intensity.low => HapticCue.phaseChange,
  };
}

/// Plays haptic feedback for timer events, so the user can follow the
/// workout with the sound off.
abstract interface class HapticPlayer {
  Future<void> play(HapticCue cue);

  Future<void> dispose();
}

/// A [HapticPlayer] that does nothing.
final class SilentHapticPlayer implements HapticPlayer {
  const SilentHapticPlayer();

  @override
  Future<void> play(HapticCue cue) async {}

  @override
  Future<void> dispose() async {}
}

/// Haptics through [HapticFeedback], scaled by a [VibrationStrength] that
/// follows the user's setting.
final class SystemHapticPlayer implements HapticPlayer {
  SystemHapticPlayer({this.strength = VibrationStrength.medium});

  /// The strength the next feedback plays at; follows the user's setting.
  VibrationStrength strength;

  Timer? _secondPulse;

  @override
  Future<void> play(HapticCue cue) async {
    if (strength == VibrationStrength.off) return;
    final strong = strength == VibrationStrength.strong;
    switch (cue) {
      case HapticCue.phaseChange:
        await (strong
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact());
      case HapticCue.mainPhase:
        // A double tap marks the main phase.
        await (strong
            ? HapticFeedback.heavyImpact()
            : HapticFeedback.mediumImpact());
        _secondPulse?.cancel();
        _secondPulse = Timer(const Duration(milliseconds: 140), () {
          unawaited(
            strong
                ? HapticFeedback.mediumImpact()
                : HapticFeedback.lightImpact(),
          );
        });
      case HapticCue.finished:
        await (strong
            ? HapticFeedback.heavyImpact()
            : HapticFeedback.mediumImpact());
    }
  }

  @override
  Future<void> dispose() async {
    _secondPulse?.cancel();
  }
}

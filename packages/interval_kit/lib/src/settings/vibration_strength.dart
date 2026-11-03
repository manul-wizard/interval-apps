import 'package:flutter/services.dart';

import '../l10n/generated/kit_localizations.dart';

/// How strongly the workout button vibrates under the finger.
///
/// Flutter exposes no vibration amplitude, only three semantic impact
/// levels; how distinct they feel is up to the device. [medium] is the
/// default for a new install.
enum VibrationStrength {
  off,
  medium,
  strong;

  /// The stored value.
  String get code => name;

  /// Reads the stored value, defaulting to [VibrationStrength.medium].
  static VibrationStrength fromCode(String? code) => switch (code) {
    'off' => VibrationStrength.off,
    'strong' => VibrationStrength.strong,
    _ => VibrationStrength.medium,
  };

  /// The label on the settings stepper.
  String label(KitLocalizations l10n) => switch (this) {
    VibrationStrength.off => l10n.vibrationOff,
    VibrationStrength.medium => l10n.vibrationMedium,
    VibrationStrength.strong => l10n.vibrationStrong,
  };

  /// The haptic feedback for a button tap, or null when vibration is off.
  Future<void>? tap() => switch (this) {
    VibrationStrength.off => null,
    VibrationStrength.medium => HapticFeedback.mediumImpact(),
    VibrationStrength.strong => HapticFeedback.heavyImpact(),
  };
}

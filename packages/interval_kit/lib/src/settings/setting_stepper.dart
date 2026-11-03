import 'package:flutter/material.dart';

import '../l10n/generated/kit_localizations.dart';
import '../widgets/value_stepper.dart';
import 'app_language.dart';
import 'int_range.dart';
import 'vibration_strength.dart';

/// A [ValueStepper] for an integer setting limited to [range].
class IntSettingStepper extends StatelessWidget {
  const IntSettingStepper({
    required this.label,
    required this.value,
    required this.range,
    required this.onChanged,
    super.key,
  });

  final String label;
  final int value;
  final IntRange range;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = KitLocalizations.of(context);
    final previous = range.step(value, -1);
    final next = range.step(value, 1);

    return ValueStepper(
      label: label,
      value: '$value',
      decrementLabel: l10n.decrease,
      incrementLabel: l10n.increase,
      onDecrement: previous == null ? null : () => onChanged(previous),
      onIncrement: next == null ? null : () => onChanged(next),
    );
  }
}

/// The language switch every app has at the top of its settings.
class LanguageStepper extends StatelessWidget {
  const LanguageStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    const languages = AppLanguage.values;
    final index = value.index;

    return ValueStepper(
      label: KitLocalizations.of(context).language,
      value: value.label,
      decrementIcon: Icons.arrow_circle_left_outlined,
      incrementIcon: Icons.arrow_circle_right_outlined,
      decrementLabel: index > 0 ? languages[index - 1].label : null,
      incrementLabel: index < languages.length - 1
          ? languages[index + 1].label
          : null,
      onDecrement: index > 0 ? () => onChanged(languages[index - 1]) : null,
      onIncrement: index < languages.length - 1
          ? () => onChanged(languages[index + 1])
          : null,
    );
  }
}

/// The vibration strength switch every app has in its settings.
class VibrationStepper extends StatelessWidget {
  const VibrationStepper({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final VibrationStrength value;
  final ValueChanged<VibrationStrength> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = KitLocalizations.of(context);
    const strengths = VibrationStrength.values;
    final index = value.index;

    return ValueStepper(
      label: l10n.vibration,
      value: value.label(l10n),
      decrementIcon: Icons.arrow_circle_left_outlined,
      incrementIcon: Icons.arrow_circle_right_outlined,
      decrementLabel: index > 0 ? strengths[index - 1].label(l10n) : null,
      incrementLabel: index < strengths.length - 1
          ? strengths[index + 1].label(l10n)
          : null,
      onDecrement: index > 0 ? () => onChanged(strengths[index - 1]) : null,
      onIncrement: index < strengths.length - 1
          ? () => onChanged(strengths[index + 1])
          : null,
    );
  }
}

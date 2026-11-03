import 'package:flutter/material.dart';

import '../theme/interval_colors.dart';
import 'press_scale.dart';

/// A labelled on/off plate, sized like a [ValueStepper] so the two line up
/// in a settings list. Tapping anywhere on the plate toggles the switch.
class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = IntervalColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.titleMedium),
        const SizedBox(height: 10),
        PressScale(
          child: Material(
            color: colors.surface,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => onChanged(!value),
              // The switch only shows the state; taps anywhere on the
              // plate, including on the switch itself, go to the InkWell.
              child: SizedBox(
                width: 252,
                height: 96,
                child: Center(
                  child: IgnorePointer(
                    child: Switch(value: value, onChanged: (_) {}),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

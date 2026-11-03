import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/interval_colors.dart';

/// A labelled "− value +" control on a rounded plate.
///
/// Holding a button repeats it, which makes large ranges quick to cross.
/// The buttons deliberately have no tooltips: a tooltip would claim the
/// long press.
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.decrementIcon = Icons.remove_circle_outline,
    this.incrementIcon = Icons.add_circle_outline,
    this.decrementLabel,
    this.incrementLabel,
    super.key,
  });

  final String label;
  final String value;

  /// `null` disables the button, e.g. at the lower limit.
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  final IconData decrementIcon;
  final IconData incrementIcon;

  /// Screen-reader labels for the buttons.
  final String? decrementLabel;
  final String? incrementLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = IntervalColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: textTheme.titleMedium),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.surface,
            shape: const StadiumBorder(),
          ),
          child: SizedBox(
            width: 252,
            height: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _RepeatingIconButton(
                  icon: decrementIcon,
                  semanticLabel: decrementLabel,
                  onPressed: onDecrement,
                ),
                SizedBox(
                  width: 96,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ),
                _RepeatingIconButton(
                  icon: incrementIcon,
                  semanticLabel: incrementLabel,
                  onPressed: onIncrement,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RepeatingIconButton extends StatefulWidget {
  const _RepeatingIconButton({
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  State<_RepeatingIconButton> createState() => _RepeatingIconButtonState();
}

class _RepeatingIconButtonState extends State<_RepeatingIconButton> {
  static const _slowestRepeat = Duration(milliseconds: 450);
  static const _fastestRepeat = Duration(milliseconds: 60);
  static const _acceleration = Duration(milliseconds: 30);

  Timer? _repeat;

  void _startRepeating() {
    _stopRepeating();
    _repeatAfter(_slowestRepeat);
  }

  /// Fires [onPressed] after [interval], then keeps firing sooner and
  /// sooner, down to [_fastestRepeat], until the hold ends. A slow start
  /// keeps a short press from jumping far; the floor keeps a long press
  /// quick.
  void _repeatAfter(Duration interval) {
    _repeat = Timer(interval, () {
      final onPressed = widget.onPressed;
      if (onPressed == null) {
        _stopRepeating();
        return;
      }
      onPressed();
      final faster = interval - _acceleration;
      _repeatAfter(faster > _fastestRepeat ? faster : _fastestRepeat);
    });
  }

  void _stopRepeating() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final colors = IntervalColors.of(context);

    return GestureDetector(
      onLongPressStart: enabled ? (_) => _startRepeating() : null,
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: IconButton(
        icon: Icon(widget.icon, semanticLabel: widget.semanticLabel),
        iconSize: 36,
        color: colors.primary,
        disabledColor: colors.muted,
        onPressed: widget.onPressed,
      ),
    );
  }
}

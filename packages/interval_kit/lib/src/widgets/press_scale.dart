import 'package:flutter/widgets.dart';

/// Shrinks [child] slightly while a pointer is down, as tactile feedback.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  static const _pressedScale = 0.9;
  static const _duration = Duration(milliseconds: 200);

  var _pressed = false;

  void _setPressed(bool pressed) {
    if (widget.enabled && pressed != _pressed) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _setPressed(true),
    onPointerUp: (_) => _setPressed(false),
    onPointerCancel: (_) => _setPressed(false),
    child: AnimatedScale(
      scale: _pressed ? _pressedScale : 1,
      duration: _duration,
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

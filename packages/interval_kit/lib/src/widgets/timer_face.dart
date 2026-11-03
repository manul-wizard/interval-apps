import 'package:flutter/material.dart';

import 'progress_ring.dart';

/// The big countdown: a [ProgressRing] with the time and a caption on top.
///
/// While [pressed] — the workout is paused — the ring alone scales down,
/// echoing the button under the finger; the time and the caption stay put.
class TimerFace extends StatefulWidget {
  const TimerFace({
    required this.time,
    required this.caption,
    required this.remainingFraction,
    required this.color,
    this.drainOver,
    this.pressed = false,
    super.key,
  });

  final String time;
  final String caption;
  final double remainingFraction;
  final Color color;
  final Duration? drainOver;
  final bool pressed;

  @override
  State<TimerFace> createState() => _TimerFaceState();
}

class _TimerFaceState extends State<TimerFace>
    with SingleTickerProviderStateMixin {
  static const _pressedScale = 0.96;
  static const _pressInDuration = Duration(milliseconds: 150);
  static const _releaseDuration = Duration(milliseconds: 350);

  late final AnimationController _ringScale = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(TimerFace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressed != widget.pressed) {
      // animateTo starts from the current value, so rapid toggles just
      // reverse course instead of jumping.
      if (widget.pressed) {
        _ringScale.animateTo(
          _pressedScale,
          duration: _pressInDuration,
          curve: Curves.easeOut,
        );
      } else {
        _ringScale.animateTo(
          1,
          duration: _releaseDuration,
          curve: Curves.easeOutBack,
        );
      }
    }
  }

  @override
  void dispose() {
    _ringScale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _ringScale,
          builder: (context, child) =>
              Transform.scale(scale: _ringScale.value, child: child),
          child: ProgressRing(
            remainingFraction: widget.remainingFraction,
            color: widget.color,
            drainOver: widget.drainOver,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                child: Text(widget.time, style: textTheme.displayLarge),
              ),
              const SizedBox(height: 8),
              Text(widget.caption, style: textTheme.headlineMedium),
            ],
          ),
        ),
      ],
    );
  }
}

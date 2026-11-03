import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/interval_colors.dart';

/// A circular countdown that empties clockwise from the top.
///
/// The ring shows [remainingFraction]. While [drainOver] is non-null it keeps
/// draining smoothly towards empty over that duration, so the caller only
/// needs to update it when the remaining time is re-measured (once a second
/// is plenty) instead of every frame. When the fraction jumps back up — a
/// new phase or a reset — the ring sweeps back to full first; a fraction
/// that only moves down (a fresh measurement) snaps straight to it.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    required this.remainingFraction,
    required this.color,
    this.drainOver,
    this.child,
    super.key,
  });

  final double remainingFraction;
  final Color color;
  final Duration? drainOver;
  final Widget? child;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with TickerProviderStateMixin {
  static const _colorDuration = Duration(milliseconds: 500);
  static const _fillDuration = Duration(milliseconds: 250);

  // The ring shows real time, so neither controller may speed up when the
  // system turns animations off, as Android does in battery saver mode.
  // Otherwise the ring empties in a moment and jumps back every second.
  late final AnimationController _drain = AnimationController(
    vsync: this,
    value: widget.remainingFraction,
    animationBehavior: AnimationBehavior.preserve,
  );

  // Sweeps the ring back towards full on a new phase or a reset, on top of
  // the paused drain; when it arrives the drain restarts from full.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  void initState() {
    super.initState();
    _fill.addStatusListener(_drainWhenFilled);
    _sync();
  }

  /// The fraction the ring currently shows.
  double get _shown => (_drain.value + _fill.value).clamp(0.0, 1.0);

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingFraction != oldWidget.remainingFraction ||
        widget.drainOver != oldWidget.drainOver) {
      _sync();
    }
  }

  void _sync() {
    final drainOver = widget.drainOver;
    if (widget.remainingFraction - _shown > 0.001) {
      // A refill — a new phase or a reset — reads better as a sweep than a
      // snap; the drain holds still until the sweep arrives.
      _drain.stop();
      _fill.animateTo(1 - _drain.value, duration: _fillDuration);
    } else {
      _fill
        ..stop()
        ..value = 0;
      _drain.value = widget.remainingFraction;
      if (drainOver != null && drainOver > Duration.zero) {
        _drain.animateTo(0, duration: drainOver);
      }
    }
  }

  /// The sweep reached the top; run the phase down from full. With nothing
  /// to drain (a reset while paused) the filled ring simply stays.
  void _drainWhenFilled(AnimationStatus status) {
    final drainOver = widget.drainOver;
    if (status != AnimationStatus.completed ||
        !mounted ||
        drainOver == null ||
        drainOver <= Duration.zero) {
      return;
    }
    _fill.value = 0;
    _drain.value = 1;
    _drain.animateTo(0, duration: drainOver);
  }

  @override
  void dispose() {
    _drain.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<Color?>(
    tween: ColorTween(end: widget.color),
    duration: _colorDuration,
    builder: (context, color, child) => CustomPaint(
      painter: _RingPainter(
        drain: _drain,
        fill: _fill,
        color: color ?? widget.color,
        trackColor: IntervalColors.of(context).surface,
      ),
      child: child,
    ),
    child: AspectRatio(aspectRatio: 1, child: Center(child: widget.child)),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.drain,
    required this.fill,
    required this.color,
    required this.trackColor,
  }) : super(repaint: Listenable.merge([drain, fill]));

  final Animation<double> drain;
  final Animation<double> fill;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.shortestSide * 0.06;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final fraction = (drain.value + fill.value).clamp(0.0, 1.0);

    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = trackColor);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      -math.pi * 2 * fraction,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.trackColor != trackColor;
}

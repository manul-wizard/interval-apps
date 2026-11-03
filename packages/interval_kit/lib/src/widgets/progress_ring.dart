import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/interval_colors.dart';

/// A circular countdown that empties clockwise from the top.
///
/// The ring shows [remainingFraction]. While [drainOver] is non-null it keeps
/// draining smoothly towards empty over that duration, so the caller only
/// needs to update it when the remaining time is re-measured (once a second
/// is plenty) instead of every frame.
///
/// How it reacts when the fraction jumps back up depends on why:
///
/// * A new phase ([drainOver] non-null) does not sweep back — the drained
///   ring is invisible anyway. It fades out through the track color, the
///   new phase is swapped in underneath at full, and the color flows into
///   the phase's own.
/// * A reset ([drainOver] null) sweeps the ring back to full, where it
///   stays until the workout runs again.
class ProgressRing extends StatefulWidget {
  const ProgressRing({
    required this.remainingFraction,
    required this.color,
    this.drainOver,
    super.key,
  });

  final double remainingFraction;
  final Color color;
  final Duration? drainOver;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with TickerProviderStateMixin {
  static const _colorDuration = Duration(milliseconds: 500);
  static const _toTrackDuration = Duration(milliseconds: 200);
  static const _fromTrackDuration = Duration(milliseconds: 300);
  static const _fillDuration = Duration(milliseconds: 250);

  // The ring shows real time, so none of the controllers may speed up when
  // the system turns animations off, as Android does in battery saver mode.
  late final AnimationController _drain = AnimationController(
    vsync: this,
    value: widget.remainingFraction,
    animationBehavior: AnimationBehavior.preserve,
  );

  // Sweeps the ring back to full on a reset, on top of the paused drain.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );

  // Two color controllers take turns: either can hand the next fade to the
  // other from its own completion callback, which a single controller could
  // not survive — its teardown would kill the hand-off mid-flight.
  late final AnimationController _colorA = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final AnimationController _colorB = AnimationController(
    vsync: this,
    animationBehavior: AnimationBehavior.preserve,
  );
  late final ColorTween _tweenA = ColorTween(
    begin: widget.color,
    end: widget.color,
  );
  late final ColorTween _tweenB = ColorTween(
    begin: widget.color,
    end: widget.color,
  );
  late final Listenable _ticks = Listenable.merge([
    _drain,
    _fill,
    _colorA,
    _colorB,
  ]);

  /// Whether [ColorTween] pair B is the active one.
  var _onB = false;

  /// The phase waiting for its fade to the track color to finish before
  /// being swapped in; `null` when no swap is pending.
  Duration? _pendingDrainOver;

  /// The track color of the last build; read by [didUpdateWidget].
  late Color _trackColor = widget.color;

  AnimationController get _activeColor => _onB ? _colorB : _colorA;
  ColorTween get _activeTween => _onB ? _tweenB : _tweenA;
  Color get _paintedColor =>
      _activeTween.evaluate(_activeColor) ?? widget.color;

  @override
  void initState() {
    super.initState();
    _fill.addStatusListener(_drainWhenFilled);
    _colorA.addStatusListener((s) => _swapPhaseIn(s, _colorA));
    _colorB.addStatusListener((s) => _swapPhaseIn(s, _colorB));
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
    } else if (widget.color != oldWidget.color) {
      _pendingDrainOver = null;
      _fadeColor(widget.color, _colorDuration);
    }
  }

  void _sync() {
    final drainOver = widget.drainOver;
    if (widget.remainingFraction - _shown > 0.001) {
      _fill.stop();
      _drain.stop();
      if (drainOver != null && drainOver > Duration.zero) {
        // A new phase: the drained ring is invisible, so instead of
        // sweeping back to full it fades out through the track color and
        // the new phase takes over underneath (_swapPhaseIn).
        _pendingDrainOver = drainOver;
        _fadeColor(_trackColor, _toTrackDuration);
      } else {
        // A reset: sweep back to full, where the ring stays until the
        // workout runs again.
        _fill.animateTo(1 - _drain.value, duration: _fillDuration);
      }
    } else {
      _pendingDrainOver = null;
      _fill
        ..stop()
        ..value = 0;
      _drain.value = widget.remainingFraction;
      if (drainOver != null && drainOver > Duration.zero) {
        _drain.animateTo(0, duration: drainOver);
      }
      if (widget.color != _paintedColor) {
        _fadeColor(widget.color, _colorDuration);
      }
    }
  }

  /// Runs the active color controller from the current color to [to].
  void _fadeColor(Color to, Duration duration) {
    final from = _paintedColor;
    final previous = _activeColor;
    _onB = !_onB;
    previous.stop();
    _activeTween
      ..begin = from
      ..end = to;
    _activeColor
      ..duration = duration
      ..forward(from: 0);
  }

  /// The fade to the track color finished; swap the new phase in at full
  /// and let it take the color.
  void _swapPhaseIn(AnimationStatus status, AnimationController controller) {
    final drainOver = _pendingDrainOver;
    if (status != AnimationStatus.completed ||
        !identical(controller, _activeColor) ||
        drainOver == null) {
      return;
    }
    _pendingDrainOver = null;
    _fill.value = 0;
    _drain.value = 1;
    _drain.animateTo(0, duration: drainOver);
    _fadeColor(widget.color, _fromTrackDuration);
  }

  /// A reset sweep reached the top; drain the phase if the workout has
  /// already started again. With nothing to drain (a reset while paused)
  /// the filled ring simply stays.
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
    _colorA.dispose();
    _colorB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _trackColor = IntervalColors.of(context).surface;
    return AnimatedBuilder(
      animation: _ticks,
      builder: (context, _) => AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _RingPainter(
            fraction: _shown,
            color: _paintedColor,
            trackColor: _trackColor,
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
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
      oldDelegate.fraction != fraction ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}

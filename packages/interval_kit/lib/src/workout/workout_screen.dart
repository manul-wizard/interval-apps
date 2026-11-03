import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:interval_core/interval_core.dart';

import '../l10n/generated/kit_localizations.dart';
import '../settings/vibration_strength.dart';
import '../theme/interval_colors.dart';
import '../widgets/pill_button.dart';
import '../widgets/timer_face.dart';
import 'workout_controller.dart';

/// The main screen of every app: countdown ring, phase, start and reset.
///
/// Apps only decide how phases are named and how time is written.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({
    required this.controller,
    required this.phaseLabel,
    required this.formatTime,
    required this.onOpenSettings,
    this.onToggleTheme,
    this.vibration = VibrationStrength.medium,
    super.key,
  });

  final WorkoutController controller;
  final String Function(BuildContext context, Phase phase) phaseLabel;
  final String Function(TimerSnapshot snapshot) formatTime;
  final VoidCallback onOpenSettings;

  /// Switches between the light and the dark theme; the button is hidden
  /// when it is null.
  final VoidCallback? onToggleTheme;

  /// How strongly the start/stop button vibrates.
  final VibrationStrength vibration;

  @override
  Widget build(BuildContext context) {
    final l10n = KitLocalizations.of(context);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = IntervalColors.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final snapshot = controller.snapshot;
              final running = controller.isRunning;
              final paused = controller.status == TimerStatus.paused;
              final status = controller.status == TimerStatus.paused
                  ? l10n.paused
                  : phaseLabel(context, snapshot.phase);

              return Column(
                children: [
                  Row(
                    children: [
                      if (onToggleTheme case final onToggleTheme?)
                        IconButton(
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                          tooltip: isDark ? l10n.lightTheme : l10n.darkTheme,
                          padding: const EdgeInsets.all(16),
                          onPressed: onToggleTheme,
                        ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        tooltip: l10n.settings,
                        padding: const EdgeInsets.all(16),
                        onPressed: onOpenSettings,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Pausing presses the face in, like the button under the
                  // finger; resuming pops it back with a small bounce.
                  _FacePress(
                    pressed: paused,
                    child: SizedBox.square(
                      dimension: _ringDiameter(constraints),
                      child: TimerFace(
                        time: formatTime(snapshot),
                        caption:
                            '${snapshot.phase.round}/${snapshot.plan.rounds}',
                        remainingFraction: snapshot.remainingFraction,
                        color: running
                            ? colors.forIntensity(snapshot.phase.intensity)
                            : colors.idle,
                        drainOver: running ? snapshot.remainingInPhase : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      status.toUpperCase(),
                      style: textTheme.titleLarge,
                    ),
                  ),
                  const Spacer(flex: 2),
                  PillButton(
                    label: running
                        ? l10n.stop
                        : controller.status == TimerStatus.paused
                        ? l10n.resume
                        : l10n.start,
                    onPressed: () {
                      vibration.tap();
                      controller.toggle();
                    },
                  ),
                  const Spacer(),
                  FlatTextButton(
                    label: l10n.reset,
                    onPressed: controller.status == TimerStatus.ready
                        ? null
                        : controller.reset,
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Large on a phone held upright, but never crowding out the buttons.
  static double _ringDiameter(BoxConstraints constraints) => math.min(
    400,
    math.min(constraints.maxWidth * 0.7, constraints.maxHeight * 0.45),
  );
}

/// Scales [child] down while [pressed] — the timer face pressing in on
/// pause — and springs it back with a small bounce when released.
class _FacePress extends StatefulWidget {
  const _FacePress({required this.pressed, required this.child});

  final bool pressed;
  final Widget child;

  @override
  State<_FacePress> createState() => _FacePressState();
}

class _FacePressState extends State<_FacePress>
    with SingleTickerProviderStateMixin {
  static const _pressedScale = 0.96;
  static const _pressInDuration = Duration(milliseconds: 150);
  static const _releaseDuration = Duration(milliseconds: 350);

  late final AnimationController _scale = AnimationController(
    vsync: this,
    value: 1,
  );

  @override
  void didUpdateWidget(_FacePress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pressed != widget.pressed) {
      // animateTo starts from the current value, so rapid toggles just
      // reverse course instead of jumping.
      if (widget.pressed) {
        _scale.animateTo(
          _pressedScale,
          duration: _pressInDuration,
          curve: Curves.easeOut,
        );
      } else {
        _scale.animateTo(
          1,
          duration: _releaseDuration,
          curve: Curves.easeOutBack,
        );
      }
    }
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _scale,
    builder: (context, child) =>
        Transform.scale(scale: _scale.value, child: child),
    child: widget.child,
  );
}

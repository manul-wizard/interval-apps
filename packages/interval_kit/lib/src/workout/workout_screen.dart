import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:interval_core/interval_core.dart';

import '../l10n/generated/kit_localizations.dart';
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
    super.key,
  });

  final WorkoutController controller;
  final String Function(BuildContext context, Phase phase) phaseLabel;
  final String Function(TimerSnapshot snapshot) formatTime;
  final VoidCallback onOpenSettings;

  /// Switches between the light and the dark theme; the button is hidden
  /// when it is null.
  final VoidCallback? onToggleTheme;

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
                  SizedBox.square(
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
                    onPressed: controller.toggle,
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

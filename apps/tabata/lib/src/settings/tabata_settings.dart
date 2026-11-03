import 'package:flutter/foundation.dart';
import 'package:interval_kit/interval_kit.dart';

/// Everything the user can configure in the Tabata app.
@immutable
final class TabataSettings {
  const TabataSettings({
    required this.language,
    this.rounds = 8,
    this.workSeconds = 20,
    this.restSeconds = 10,
    this.themeMode = ThemeMode.system,
    this.vibration = true,
  });

  static const roundsRange = IntRange(2, 99);
  static const workRange = IntRange(10, 999);
  static const restRange = IntRange(5, 999);

  final AppLanguage language;
  final int rounds;
  final int workSeconds;
  final int restSeconds;

  /// Light, dark, or [ThemeMode.system] to follow the device.
  final ThemeMode themeMode;

  /// Whether the start/stop button vibrates under the finger.
  final bool vibration;

  /// The classic protocol: a countdown as long as a rest, then rounds of
  /// work and rest, finishing on the last work interval.
  WorkoutPlan toPlan() => WorkoutPlan.intervals(
    rounds: rounds,
    prepare: Duration(seconds: restSeconds),
    high: Duration(seconds: workSeconds),
    low: Duration(seconds: restSeconds),
    lowAfterLastRound: false,
  );

  TabataSettings copyWith({
    AppLanguage? language,
    int? rounds,
    int? workSeconds,
    int? restSeconds,
    ThemeMode? themeMode,
    bool? vibration,
  }) => TabataSettings(
    language: language ?? this.language,
    rounds: rounds ?? this.rounds,
    workSeconds: workSeconds ?? this.workSeconds,
    restSeconds: restSeconds ?? this.restSeconds,
    themeMode: themeMode ?? this.themeMode,
    vibration: vibration ?? this.vibration,
  );

  @override
  bool operator ==(Object other) =>
      other is TabataSettings &&
      other.language == language &&
      other.rounds == rounds &&
      other.workSeconds == workSeconds &&
      other.restSeconds == restSeconds &&
      other.themeMode == themeMode &&
      other.vibration == vibration;

  @override
  int get hashCode => Object.hash(
    language,
    rounds,
    workSeconds,
    restSeconds,
    themeMode,
    vibration,
  );
}

import 'package:flutter/foundation.dart';

import '../haptics/haptic_player.dart';
import 'cue.dart';

/// Plays [Cue]s.
abstract interface class CuePlayer {
  Future<void> play(Cue cue);

  Future<void> dispose();
}

/// A [CuePlayer] that stays silent, for tests and muted sessions.
final class SilentCuePlayer implements CuePlayer {
  const SilentCuePlayer();

  @override
  Future<void> play(Cue cue) async {}

  @override
  Future<void> dispose() async {}
}

/// Records played cues, for tests.
@visibleForTesting
final class RecordingCuePlayer implements CuePlayer {
  final played = <Cue>[];

  @override
  Future<void> play(Cue cue) async => played.add(cue);

  @override
  Future<void> dispose() async {}
}

/// Records played haptic cues, for tests.
@visibleForTesting
final class RecordingHapticPlayer implements HapticPlayer {
  final played = <HapticCue>[];

  @override
  Future<void> play(HapticCue cue) async => played.add(cue);

  @override
  Future<void> dispose() async {}
}

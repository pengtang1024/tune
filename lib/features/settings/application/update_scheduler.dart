import 'dart:async';
import 'dart:math';

import 'package:tune/utils/logger.dart';

/// Asks for a new release on a schedule (docs/update-cdn.md §4.3).
///
/// The first check waits a minute: a start-up that races the first frame only
/// makes the window slower. After that the check runs twice a day with a
/// little jitter in the wait, so a fleet of machines does not reach the CDN at
/// the same second. A failure backs off instead of repeating; a machine that
/// is offline stays quiet until the next attempt.
class UpdateScheduler {
  UpdateScheduler({
    required Future<bool> Function() check,
    DateTime Function()? clock,
    Random? random,
  }) : _check = check,
       _clock = clock ?? DateTime.now,
       _random = random ?? Random();

  /// Runs one automatic check and says whether it worked.
  final Future<bool> Function() _check;
  final DateTime Function() _clock;
  final Random _random;

  Timer? _timer;
  int _failures = 0;
  DateTime? _lastRun;

  /// How long after the start the first check runs.
  static const firstDelay = Duration(seconds: 60);

  /// How often a machine that checks successfully asks again.
  static const interval = Duration(hours: 6);

  /// No two automatic checks are closer than this.
  static const minimumGap = Duration(minutes: 30);

  /// The wait after the first, second and later failures in a row. It grows
  /// until the normal interval is reached and stays there.
  static const backoff = [
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 4),
    Duration(hours: 6),
  ];

  /// The wait after [failures] failed checks in a row.
  static Duration delayAfterFailure(int failures) {
    if (failures <= 0) return interval;
    final index = failures < backoff.length ? failures - 1 : backoff.length - 1;
    return backoff[index];
  }

  /// The wait after a successful check: six hours, ten percent either way.
  Duration nextDelay() {
    final span = interval.inMilliseconds;
    final jitter = (span * 0.1).round();
    return Duration(
      milliseconds: span - jitter + _random.nextInt(jitter * 2 + 1),
    );
  }

  void start() {
    _timer?.cancel();
    _schedule(firstDelay);
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _tick);
  }

  Future<void> _tick() async {
    final last = _lastRun;
    if (last != null) {
      final since = _clock().difference(last);
      if (since < minimumGap) {
        _schedule(minimumGap - since);
        return;
      }
    }
    _lastRun = _clock();

    bool worked;
    try {
      worked = await _check();
    } catch (error) {
      Log.debug('自动检查更新失败: $error');
      worked = false;
    }

    if (worked) {
      _failures = 0;
      _schedule(nextDelay());
      return;
    }
    _failures++;
    _schedule(delayAfterFailure(_failures));
  }
}

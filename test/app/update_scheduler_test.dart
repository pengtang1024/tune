import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/settings/application/update_scheduler.dart';

/// The wall clock the scheduler sees: the fake time of the test.
DateTime _clock(FakeAsync async) =>
    DateTime.utc(2026).add(async.elapsed);

void _advance(FakeAsync async, Duration duration) {
  async.elapse(duration);
  async.flushMicrotasks();
}

void main() {
  test('the first check waits a minute and then runs', () {
    fakeAsync((async) {
      var calls = 0;
      final scheduler = UpdateScheduler(
        check: () async {
          calls++;
          return true;
        },
        clock: () => _clock(async),
      )..start();

      _advance(async, const Duration(seconds: 59));
      expect(calls, 0);

      _advance(async, const Duration(seconds: 2));
      expect(calls, 1);

      scheduler.stop();
    });
  });

  test('a successful check waits about six hours', () {
    fakeAsync((async) {
      var calls = 0;
      final scheduler = UpdateScheduler(
        check: () async {
          calls++;
          return true;
        },
        clock: () => _clock(async),
        random: Random(7),
      )..start();

      _advance(async, UpdateScheduler.firstDelay + const Duration(seconds: 1));
      expect(calls, 1);

      _advance(async, const Duration(hours: 5, minutes: 20));
      expect(calls, 1);

      _advance(async, const Duration(hours: 1, minutes: 30));
      expect(calls, 2);

      scheduler.stop();
    });
  });

  test('a failure backs off instead of repeating', () {
    fakeAsync((async) {
      var calls = 0;
      final scheduler = UpdateScheduler(
        check: () async {
          calls++;
          return false;
        },
        clock: () => _clock(async),
      )..start();

      _advance(async, UpdateScheduler.firstDelay + const Duration(seconds: 1));
      expect(calls, 1);

      // The wait of the first failure is half an hour.
      _advance(async, const Duration(minutes: 29));
      expect(calls, 1);

      _advance(async, const Duration(minutes: 2));
      expect(calls, 2);

      // The second failure waits an hour: one minute is still a wait, so it
      // is not reached one minute short of it.
      _advance(async, const Duration(minutes: 58));
      expect(calls, 2);

      _advance(async, const Duration(minutes: 2));
      expect(calls, 3);

      scheduler.stop();
    });
  });

  test('a check that throws counts as a failure, not as an answer', () {
    fakeAsync((async) {
      var calls = 0;
      final scheduler = UpdateScheduler(
        check: () async {
          calls++;
          throw StateError('boom');
        },
        clock: () => _clock(async),
      )..start();

      _advance(async, const Duration(seconds: 61));
      expect(calls, 1);

      // A throw is not success: the next attempt is a normal interval away,
      // not a minute away.
      _advance(async, const Duration(minutes: 29));
      expect(calls, 1);

      scheduler.stop();
    });
  });

  test('two automatic checks are never closer than half an hour', () {
    fakeAsync((async) {
      var calls = 0;
      final scheduler = UpdateScheduler(
        check: () async {
          calls++;
          return true;
        },
        clock: () => _clock(async),
        random: Random(3),
      )..start();

      _advance(async, const Duration(seconds: 61));
      expect(calls, 1);

      // A second start schedules the first delay again; the gap guard keeps
      // it from checking right away.
      scheduler.start();
      _advance(async, const Duration(seconds: 61));
      expect(calls, 1);

      scheduler.stop();
    });
  });

  test('the wait after a success stays within ten percent', () {
    for (var seed = 0; seed < 20; seed++) {
      final delay = UpdateScheduler(
        check: () async => true,
        random: Random(seed),
      ).nextDelay();
      expect(
        delay,
        greaterThanOrEqualTo(const Duration(hours: 5, minutes: 24)),
      );
      expect(delay, lessThanOrEqualTo(const Duration(hours: 6, minutes: 36)));
    }
  });

  test('the backoff grows until it reaches the normal interval', () {
    expect(UpdateScheduler.delayAfterFailure(1), const Duration(minutes: 30));
    expect(UpdateScheduler.delayAfterFailure(2), const Duration(hours: 1));
    expect(UpdateScheduler.delayAfterFailure(3), const Duration(hours: 2));
    expect(UpdateScheduler.delayAfterFailure(4), const Duration(hours: 4));
    expect(UpdateScheduler.delayAfterFailure(5), const Duration(hours: 6));
    expect(UpdateScheduler.delayAfterFailure(9), const Duration(hours: 6));
    expect(UpdateScheduler.delayAfterFailure(0), UpdateScheduler.interval);
  });
}

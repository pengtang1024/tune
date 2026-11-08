import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/source_retry.dart';

/// A server that drops answers now and then is read again, not given up on.
void main() {
  const quick = [Duration(milliseconds: 1), Duration(milliseconds: 1)];

  group('a read that is tried again', () {
    test('an answer that arrives after a failure is taken', () async {
      var calls = 0;

      final value = await retrySourceRead(
        () async {
          calls++;
          if (calls < 3) throw StateError('bad gateway');
          return 'answer';
        },
        delays: quick,
      );

      expect(value, 'answer');
      expect(calls, 3);
    });

    test('a failure that outlasts the tries is thrown as it was', () async {
      var calls = 0;

      await expectLater(
        retrySourceRead<int>(
          () async {
            calls++;
            throw StateError('still down');
          },
          delays: quick,
        ),
        throwsA(isA<StateError>()),
      );
      expect(calls, 3);
    });

    test('a value the caller rejects is read again', () async {
      var calls = 0;

      final value = await retrySourceRead(
        () async {
          calls++;
          return calls < 2 ? null : 'answer';
        },
        answered: (value) => value != null,
        delays: quick,
      );

      expect(value, 'answer');
      expect(calls, 2);
    });

    test('a value that never satisfies the caller is handed back', () async {
      var calls = 0;

      final value = await retrySourceRead<String?>(
        () async {
          calls++;
          return null;
        },
        answered: (value) => value != null,
        delays: quick,
      );

      // The caller reports what it got instead of the helper hiding it.
      expect(value, isNull);
      expect(calls, 3);
    });

    test('an answer that arrives at once is read once', () async {
      var calls = 0;

      final value = await retrySourceRead(
        () async {
          calls++;
          return 'answer';
        },
        delays: quick,
      );

      expect(value, 'answer');
      expect(calls, 1);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/sources/domain/source_health.dart';
import 'package:tune/features/sources/domain/source_visibility.dart';

SourceHealthReport _report(int score) => SourceHealthReport(
  availability: score,
  configuration: score,
  scan: score,
  freshness: score,
  output: score,
  speed: score,
  reliability: score,
  stability: score,
  playable: score,
  artwork: score,
  metadata: score,
  activity: score,
  score: score,
  healthy: score >= 60,
);

void main() {
  const gate = SourceVisibility();
  Set<String> hidden(
    Map<String, SourceHealthReport> reports, {
    Set<String> local = const {'local'},
    Set<String> withTracks = const {'weak', 'local', 'pinned', 'playing'},
    Set<String> evidence = const {},
    bool empty = false,
    SourceVisibility visibility = gate,
  }) => visibility.hiddenOf(
    reports: reports,
    localSourceIds: local,
    sourcesWithTracks: withTracks,
    sourcesWithEvidence: evidence,
    libraryIsEmpty: empty,
  );

  test('a source below the threshold is hidden and one above stays', () {
    final result = hidden({
      'weak': _report(40),
      'strong': _report(80),
    });
    expect(result, {'weak'});
  });

  test('the threshold is absolute, so a new strong source hides nobody', () {
    final before = hidden({'weak': _report(40), 'strong': _report(80)});
    final after = hidden({
      'weak': _report(40),
      'strong': _report(80),
      'added': _report(90),
    });
    expect(before, after);
  });

  test('a local source is never hidden, however low it scores', () {
    expect(hidden({'local': _report(5)}), isEmpty);
  });

  test('a source with no tracks is never hidden', () {
    expect(hidden({'weak': _report(5)}, withTracks: {'local'}), isEmpty);
  });

  test('a pinned source and the playing source stay', () {
    const pinned = SourceVisibility(alwaysVisible: {'weak'});
    expect(hidden({'weak': _report(1)}, visibility: pinned), isEmpty);
    const playing = SourceVisibility(playingSourceId: 'playing');
    expect(
      hidden({'playing': _report(1)}, visibility: playing),
      isEmpty,
    );
  });

  test('an empty library hides nothing, so a first scan still shows', () {
    expect(hidden({'weak': _report(1)}, empty: true), isEmpty);
  });

  test('a source nobody scanned this session is not hidden', () {
    final result = hidden(
      {'weak': _report(10), 'unscanned': _report(10)},
      withTracks: {'weak', 'unscanned'},
      evidence: {'weak'},
    );
    expect(result, {'weak'});
  });

  test('a raised threshold hides more without touching the data', () {
    const strict = SourceVisibility(threshold: 0.85);
    expect(
      hidden(
        {'weak': _report(40), 'strong': _report(80)},
        withTracks: {'weak', 'strong'},
        visibility: strict,
      ),
      {'weak', 'strong'},
    );
  });

  test('switching the gate off keeps every source', () {
    expect(
      hidden(
        {'weak': _report(0)},
        visibility: const SourceVisibility(),
      ),
      {'weak'},
    );
    expect(
      gate.hiddenOf(
        reports: {'weak': _report(0)},
        localSourceIds: const {},
        sourcesWithTracks: const {'weak'},
        libraryIsEmpty: false,
        enabled: false,
      ),
      isEmpty,
    );
  });
}

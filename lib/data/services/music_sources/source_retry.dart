import 'dart:async';

/// Reads an answer that a server drops now and then.
///
/// Some of the catalogues answer a scan with a bad gateway, a dropped
/// connection, or a body that carries no list at all. A moment later the same
/// request answers properly, so the read is tried again before a scan fails:
/// a scan that gives up on the first hiccup reads as an empty source.
///
/// [read] is called once more after every delay that is left. A read that
/// throws keeps its own failure: when the tries run out the last one is
/// rethrown, so the message the reader sees is the one the server gave.
/// [answered] tells whether the value is the answer the caller wants; a value
/// it rejects is read again, and the last such value is handed back when the
/// tries run out, so the caller can report what it got.
Future<T> retrySourceRead<T>(
  Future<T> Function() read, {
  bool Function(T value)? answered,
  List<Duration> delays = const [
    Duration(milliseconds: 400),
    Duration(milliseconds: 900),
  ],
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      final value = await read();
      if (answered == null || answered(value)) return value;
      if (attempt >= delays.length) return value;
    } catch (_) {
      if (attempt >= delays.length) rethrow;
    }
    await Future<void>.delayed(delays[attempt]);
  }
}

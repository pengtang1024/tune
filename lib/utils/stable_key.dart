/// A short name that stays the same for the same value, between runs.
///
/// The randomised `Object.hashCode` cannot be used for a file name: it
/// changes between runs, so the file of a track would be a new file every
/// time the app starts. Two independent 31 bit djb2 rounds are used instead
/// of one 64 bit FNV-1a round: every intermediate value stays below 2^53, so
/// the web build computes the same name as the native one.
String stableKey(String value) {
  var first = 5381;
  var second = 52711;
  for (final unit in value.codeUnits) {
    first = (first * 33 + unit) & 0x7fffffff;
    second = (second * 31 + unit) & 0x7fffffff;
  }
  return '${first.toRadixString(16).padLeft(8, '0')}'
      '${second.toRadixString(16).padLeft(8, '0')}';
}

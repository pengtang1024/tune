/// A window of dates that a source may keep its items inside.
///
/// Several sources hand over items older than the reader wants: a podcast
/// feed holds years of episodes and a media server holds everything it ever
/// recorded. The window is the same everywhere — a few lengths, a cutoff
/// computed from it, and one reader for the dates the sources write.
abstract final class RecentWindow {
  /// The lengths a window may have, in days.
  static const days = {7, 30, 90, 365};

  /// The day a window of [raw] days starts, or nothing when the reader asked
  /// for everything.
  static DateTime? cutoff(String? raw) {
    final value = int.tryParse(raw?.trim() ?? '');
    if (value == null || !days.contains(value)) return null;
    return DateTime.now().toUtc().subtract(Duration(days: value));
  }

  /// The months feeds write, by their three letters.
  static const _months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  /// The instant a source wrote its date as, or nothing when it cannot be
  /// read.
  ///
  /// A media server writes ISO 8601, an RSS feed writes RFC 822 with any
  /// offset and an Atom feed writes ISO 8601 again; a date of a shape none of
  /// them uses is read as unknown, and an item without a known date is kept.
  static DateTime? dateTimeOf(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return null;

    final iso = DateTime.tryParse(text);
    if (iso != null) return iso.toUtc();

    final match = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3})[a-z]*\s+(\d{2,4})\s+'
      r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([+-]\d{4}|[A-Za-z]{3})?',
    ).firstMatch(text);
    if (match == null) return null;

    final month = _months.indexOf(match.group(2)!.toLowerCase());
    if (month < 0) return null;
    final year = int.parse(
      match.group(3)!.length == 2 ? '20${match.group(3)}' : match.group(3)!,
    );
    final at = DateTime.utc(
      year,
      month + 1,
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
      int.parse(match.group(6) ?? '0'),
    );

    // An offset names the wall clock of the writer, so the instant is the
    // clock minus the offset; GMT and UTC are offsets of nothing.
    final zone = match.group(7) ?? '';
    if (zone.startsWith('+') || zone.startsWith('-')) {
      final sign = zone.startsWith('-') ? -1 : 1;
      final hours = int.tryParse(zone.substring(1, 3)) ?? 0;
      final minutes = int.tryParse(zone.substring(3, 5)) ?? 0;
      return at.subtract(
        Duration(hours: sign * hours, minutes: sign * minutes),
      );
    }
    return at;
  }
}

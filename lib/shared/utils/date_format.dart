/// The added date as the library column reads it: `09-12` inside this year,
/// `2024-05` for an older track, `—` when the library does not know.
String formatAddedAt(int milliseconds) {
  if (milliseconds <= 0) return '—';
  final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
  final now = DateTime.now();
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return date.year == now.year ? '$month-$day' : '${date.year}-$month';
}

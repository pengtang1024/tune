import 'dart:math' as math;

import 'package:tune/domain/models/song.dart';
import 'package:tune/features/discovery/domain/track_listening.dart';

double listenWeight(TrackListening signal, DateTime now) {
  final playedAt = signal.lastPlayedAt;
  final ageDays = playedAt == null
      ? 0.0
      : now.difference(playedAt).inHours / 24;
  final decay = math.pow(0.5, ageDays.clamp(0.0, double.infinity) / 45);
  final positive = signal.listens.clamp(0, 5).toDouble();
  final negative = signal.skips.clamp(0, 3) * 0.5;
  return ((positive - negative) * decay).clamp(0.0, 5.0).toDouble();
}

/// The lower-case form of an artist or genre used to compare names.
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _genreSeparator = RegExp(r'\s*[/,;、]\s*');

String normalizeTasteKey(String value) {
  return value.trim().toLowerCase().replaceAll(_whitespace, ' ');
}

/// The genre keys of a track.
///
/// A source may write the genres as a list or as one line with separators.
/// Both end up as one key per genre, because "Rock/Jazz" and ["Rock", "Jazz"]
/// mean the same thing to the profile.
Iterable<String> genreValuesOf(Song song) sync* {
  final raw = song.genres?.isNotEmpty == true
      ? song.genres!
      : [if (song.genre != null) song.genre!];
  for (final value in raw) {
    for (final part in value.split(_genreSeparator)) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) yield trimmed;
    }
  }
}

Iterable<String> genreKeysOf(Song song) sync* {
  final seen = <String>{};
  for (final value in genreValuesOf(song)) {
    final key = normalizeTasteKey(value);
    if (key.isNotEmpty && seen.add(key)) yield key;
  }
}

/// The decade of a year, or null when the year is not usable.
int? decadeOf(int? year) {
  if (year == null || year < 1900 || year > 2100) return null;
  return (year ~/ 10) * 10;
}

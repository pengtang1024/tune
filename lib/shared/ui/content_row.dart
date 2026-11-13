import 'package:flutter/widgets.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/content_kind.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_facts.dart';

/// The three shapes a track takes in a list.
enum RowShape {
  /// A song: the artist made it and the album holds it.
  track,

  /// A podcast episode or an audiobook chapter: the show holds it and a
  /// voice reads it.
  spokenWord,

  /// A station that never ends: it has no artist, no album and no duration.
  radio,
}

/// The shape of the row that writes [song] down.
RowShape rowShapeOf(Song song) {
  return switch (contentKindOf(song)) {
    ContentKind.music => RowShape.track,
    ContentKind.podcast || ContentKind.audiobook => RowShape.spokenWord,
    ContentKind.radio => RowShape.radio,
  };
}

/// The line under the title of a row.
///
/// A song reads as its artist and its album. A spoken track reads as the
/// show first because that is what tells two episodes apart, and the voice
/// follows. A station reads as whatever happens to be airing, because the
/// names it publishes are not its own artist and album.
String rowSubtitleOf(BuildContext context, Song song) {
  return switch (rowShapeOf(song)) {
    // A station that is airing right now names what plays; one that is only
    // a recording of a broadcast says so, because nothing is live.
    RowShape.radio => song.isLiveStream
        ? (onAirLineOf(context, song) ?? context.loc.playerLiveBadge)
        : context.loc.playerRecordedBadge,
    RowShape.spokenWord => _spokenSubtitle(context, song),
    RowShape.track => _trackSubtitle(context, song),
  };
}

/// The two columns the library table writes after the title.
///
/// A station has neither an artist nor an album of its own: the names it
/// publishes belong to whatever is airing and wait in the details, so both
/// columns stay empty rather than writing the on-air names into slots that
/// mean something else.
({String artist, String album}) rowColumnsOf(BuildContext context, Song song) {
  return switch (rowShapeOf(song)) {
    RowShape.radio => (artist: '', album: ''),
    RowShape.spokenWord => (
      // An episode always belongs to a show, but its voice may be missing:
      // an empty cell is truer than an unknown artist, and the album column
      // already names the show.
      artist: song.artist.trim(),
      album: song.album.trim(),
    ),
    RowShape.track => (
      artist: song.artist.trim().isEmpty
          ? context.loc.playerUnknownArtist
          : song.artist.trim(),
      album: song.album.trim(),
    ),
  };
}

String _trackSubtitle(BuildContext context, Song song) {
  final artist = song.artist.trim();
  final album = song.album.trim();
  final who = artist.isEmpty ? context.loc.playerUnknownArtist : artist;
  return album.isEmpty ? who : '$who · $album';
}

String _spokenSubtitle(BuildContext context, Song song) {
  final show = song.album.trim();
  final voice = song.artist.trim();
  if (show.isEmpty && voice.isEmpty) return context.loc.playerUnknownArtist;
  if (show.isEmpty) return voice;
  // Feeds often repeat the show as the author of every episode; saying it
  // twice would read like two different names.
  if (voice.isEmpty || voice.toLowerCase() == show.toLowerCase()) return show;
  return '$show · $voice';
}

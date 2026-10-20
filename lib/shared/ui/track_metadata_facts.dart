import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_fact.dart';

/// The facts the metadata of a track carries.
///
/// A source knows different things about a track, so the facts appear only
/// when the source told them: the album, the year, the style, the licence and
/// everything else a track can say about itself.
List<TrackFact?> metadataFactsOf(BuildContext context, Song song) {
  return [
    _albumFact(context, song),
    _yearFact(context, song),
    _genreFact(context, song),
    _trackFact(context, song),
    _discFact(context, song),
    _languageFact(context, song),
    _licenseFact(context, song),
    _lyricsFact(context, song),
    _favoriteFact(context, song),
    _performersFact(context, song),
    _addedFact(context, song),
    _descriptionFact(context, song),
    _onAirFact(context, song),
  ];
}

TrackFact? _albumFact(BuildContext context, Song song) {
  if (song.album.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailAlbum,
    value: song.album,
    icon: Icons.album_rounded,
  );
}

TrackFact? _yearFact(BuildContext context, Song song) {
  final year = song.year;
  if (year == null || year <= 0) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailYear,
    value: '$year',
    icon: Icons.calendar_today_rounded,
  );
}

TrackFact? _genreFact(BuildContext context, Song song) {
  final genres = song.genres;
  final value = genres != null && genres.isNotEmpty
      ? genresLabel(genres, context.loc)
      : genreLabel(song.genre ?? '', context.loc);
  if (value.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailGenre,
    value: value,
    icon: Icons.local_offer_rounded,
  );
}

TrackFact? _trackFact(BuildContext context, Song song) {
  final number = song.trackNumber;
  if (number == null || number <= 0) return null;

  final total = song.trackTotal;

  return TrackFact(
    label: context.loc.nowPlayingDetailTrack,
    value: total != null && total > 0 ? '$number / $total' : '$number',
    icon: Icons.music_note_rounded,
  );
}

TrackFact? _discFact(BuildContext context, Song song) {
  final number = song.discNumber;
  if (number == null || number <= 0) return null;

  final total = song.totalDisc;

  return TrackFact(
    label: context.loc.nowPlayingDetailDisc,
    value: total != null && total > 0 ? '$number / $total' : '$number',
    icon: Icons.layers_rounded,
  );
}

TrackFact? _languageFact(BuildContext context, Song song) {
  final language = song.language;
  if (language == null || language.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.language,
    value: language,
    icon: Icons.translate_rounded,
  );
}

TrackFact? _licenseFact(BuildContext context, Song song) {
  final license = song.license;
  if (license == null || license.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailLicense,
    value: license,
    icon: Icons.policy_rounded,
  );
}

TrackFact? _lyricsFact(BuildContext context, Song song) {
  final lyrics = song.lyrics;
  if (lyrics == null || lyrics.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.trackFactLyrics,
    value: context.loc.trackFactLyricsIncluded,
    icon: Icons.lyrics_rounded,
    compact: true,
  );
}

TrackFact? _favoriteFact(BuildContext context, Song song) {
  if (!song.isFavorite) return null;

  return TrackFact(
    label: context.loc.trackFactFavorite,
    value: context.loc.trackFactFavorited,
    icon: Icons.favorite_rounded,
    tone: FactTone.primary,
    compact: true,
    sentence: context.loc.trackFactFavorited,
  );
}

TrackFact? _performersFact(BuildContext context, Song song) {
  final performers = song.performers;
  if (performers == null || performers.isEmpty) return null;

  return TrackFact(
    label: context.loc.trackFactPerformers,
    value: performers.join(' / '),
    icon: Icons.person_rounded,
  );
}

TrackFact? _addedFact(BuildContext context, Song song) {
  if (song.dateAdded <= 0) return null;

  final date = DateTime.fromMillisecondsSinceEpoch(song.dateAdded);
  final locale = Localizations.localeOf(context).toString();

  return TrackFact(
    label: context.loc.trackFactAdded,
    value: DateFormat.yMMMd(locale).format(date),
    icon: Icons.schedule_rounded,
  );
}

TrackFact? _descriptionFact(BuildContext context, Song song) {
  final description = song.description;
  if (description == null || description.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.trackFactDescription,
    value: description,
    icon: Icons.notes_rounded,
  );
}

TrackFact? _onAirFact(BuildContext context, Song song) {
  final onAir = song.sourceData?['nowPlaying']?.toString() ?? '';
  if (onAir.trim().isEmpty) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailNowPlaying,
    value: onAir,
    icon: Icons.radio_rounded,
  );
}

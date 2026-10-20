import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/shared/ui/track_fact.dart';
import 'package:tune/shared/ui/track_metadata_facts.dart';

/// Every fact known about a track, ordered by how much it is worth reading.
///
/// The library, the queue, the search results and the now playing page all
/// read the facts of a track from here, so no two surfaces disagree about
/// what a track is.
List<TrackFact> trackFactsOf(
  BuildContext context,
  Song song, {
  String? sourceName,
  bool compactOnly = false,
}) {
  final facts = <TrackFact?>[
    if (sourceName != null) _sourceFact(context, sourceName),
    _liveFact(context, song),
    ...fileFactsOf(context, song),
    ...metadataFactsOf(context, song),
  ];

  return facts
      .whereType<TrackFact>()
      .where((fact) => !compactOnly || fact.compact)
      .toList(growable: false);
}

/// The facts of a track that fit into a list row.
List<TrackFact> rowFactsOf(BuildContext context, Song song) {
  return trackFactsOf(context, song, compactOnly: true);
}

TrackFact? _sourceFact(BuildContext context, String sourceName) {
  final name = sourceName.trim();
  if (name.isEmpty) return null;

  return TrackFact(
    label: context.loc.trackFactSource,
    value: name,
    icon: Icons.travel_explore_rounded,
    tone: FactTone.primary,
  );
}

TrackFact? _liveFact(BuildContext context, Song song) {
  if (!song.isLiveStream) return null;

  return TrackFact(
    label: context.loc.trackFactLive,
    value: context.loc.playerLiveBadge,
    icon: Icons.podcasts_rounded,
    tone: FactTone.tertiary,
    compact: true,
    sentence: context.loc.playerLiveBadge,
  );
}

/// The facts of the file the track plays from.
List<TrackFact?> fileFactsOf(BuildContext context, Song song) {
  return [
    _storageFact(context, song),
    _formatFact(context, song),
    _qualityFact(context, song),
    _bitrateFact(context, song),
    _sampleRateFact(context, song),
    _sizeFact(context, song),
  ];
}

TrackFact? _storageFact(BuildContext context, Song song) {
  final remote = song.isRemote;

  return TrackFact(
    label: context.loc.trackFactStorage,
    value: remote
        ? context.loc.trackFactStorageRemote
        : context.loc.trackFactStorageLocal,
    icon: remote ? Icons.cloud_rounded : Icons.folder_rounded,
    tone: remote ? FactTone.secondary : FactTone.neutral,
    compact: !remote,
  );
}

TrackFact? _formatFact(BuildContext context, Song song) {
  final format = formatOf(song);
  if (format == null) return null;

  return TrackFact(
    label: context.loc.trackFactFormat,
    value: format,
    icon: Icons.audio_file_rounded,
    compact: true,
  );
}

TrackFact? _qualityFact(BuildContext context, Song song) {
  if (!isLossless(song)) return null;

  final sampleRate = song.sampleRate ?? 0;
  final hiRes = sampleRate > 48000;

  return TrackFact(
    label: context.loc.trackFactQuality,
    value: hiRes
        ? context.loc.trackFactQualityHiRes
        : context.loc.trackFactQualityLossless,
    icon: Icons.high_quality_rounded,
    tone: FactTone.secondary,
    compact: true,
  );
}

TrackFact? _bitrateFact(BuildContext context, Song song) {
  final bitrate = song.bitrate;
  if (bitrate == null || bitrate <= 0) return null;

  return TrackFact(
    label: context.loc.nowPlayingDetailBitrate,
    value: '$bitrate kbps',
    icon: Icons.speed_rounded,
    compact: true,
  );
}

TrackFact? _sampleRateFact(BuildContext context, Song song) {
  final rate = song.sampleRate;
  if (rate == null || rate <= 0) return null;

  final kilohertz = rate / 1000;
  final whole = kilohertz == kilohertz.roundToDouble();
  final value = whole ? '${kilohertz.toInt()}' : kilohertz.toStringAsFixed(1);

  return TrackFact(
    label: context.loc.nowPlayingDetailSampleRate,
    value: '$value kHz',
    icon: Icons.graphic_eq_rounded,
  );
}

TrackFact? _sizeFact(BuildContext context, Song song) {
  final size = song.size;
  if (size == null || size <= 0) return null;

  return TrackFact(
    label: context.loc.trackFactSize,
    value: formatSize(size),
    icon: Icons.data_usage_rounded,
  );
}

/// The format of the file, read from the type or from the address.
String? formatOf(Song song) {
  final type = song.type?.trim();
  if (type != null && type.isNotEmpty) return type.toUpperCase();

  final uri = song.uri;
  final dot = uri.lastIndexOf('.');
  if (dot < 0 || dot == uri.length - 1) return null;

  final extension = uri.substring(dot + 1);
  if (extension.length > 5) return null;
  return extension.toUpperCase();
}

/// Whether the file keeps every bit of the recording.
///
/// A lossless format says so by itself. A file whose format nobody named can
/// still be lossless, but only a bitrate in the range of a CD proves it.
bool isLossless(Song song) {
  const losslessFormats = {'FLAC', 'ALAC', 'WAV', 'APE', 'DSF', 'DFF'};
  final format = formatOf(song);
  if (format != null) return losslessFormats.contains(format);

  final bitrate = song.bitrate;
  return bitrate != null && bitrate >= 1000;
}

/// The size of a file, written the way a reader counts bytes.
String formatSize(int bytes) {
  const kilobyte = 1024;
  const megabyte = kilobyte * 1024;
  if (bytes >= megabyte) {
    return '${(bytes / megabyte).toStringAsFixed(1)} MB';
  }
  return '${(bytes / kilobyte).toStringAsFixed(0)} KB';
}

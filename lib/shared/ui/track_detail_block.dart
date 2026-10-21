import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';

/// One part of a track that is written out under a name.
///
/// The words of the lyrics, the payload the source handed over and the
/// headers a track is played with are too long for a mark, so they get a
/// name and a block of their own.
class TrackDetailBlock {
  /// The name of the part, written above it.
  final String label;

  /// The words of the part.
  final String text;

  const TrackDetailBlock({required this.label, required this.text});
}

/// The parts of a track that no mark can hold.
List<TrackDetailBlock> trackDetailBlocksOf(BuildContext context, Song song) {
  final blocks = <TrackDetailBlock>[];

  final lyrics = song.lyrics?.trim() ?? '';
  if (lyrics.isNotEmpty) {
    blocks.add(
      TrackDetailBlock(label: context.loc.trackFactLyrics, text: lyrics),
    );
  }

  final raw = _rawDataOf(song);
  if (raw != null) {
    blocks.add(
      TrackDetailBlock(label: context.loc.trackFactRawData, text: raw),
    );
  }

  final headers = _headersOf(song);
  if (headers != null) {
    blocks.add(
      TrackDetailBlock(label: context.loc.trackFactHeaders, text: headers),
    );
  }

  return blocks;
}

/// The payload the source handed over, one entry per line.
String? _rawDataOf(Song song) {
  final data = song.sourceData;
  if (data == null || data.isEmpty) return null;

  return data.entries
      .map((entry) => '${entry.key}: ${entry.value}')
      .join('\n');
}

/// The headers the track is played with, one per line.
///
/// A header that carries a secret is written as a mark: the reader wants to
/// know that the track needs a token, not to read the token itself.
String? _headersOf(Song song) {
  final headers = song.httpHeaders;
  if (headers == null || headers.isEmpty) return null;

  return headers.entries
      .map((entry) => '${entry.key}: ${_headerValueOf(entry.key, entry.value)}')
      .join('\n');
}

/// The value of a header, with the secrets hidden.
String _headerValueOf(String name, String value) {
  const secretWords = ['token', 'key', 'secret', 'auth', 'password', 'cookie'];
  final lower = name.toLowerCase();

  return secretWords.any(lower.contains) ? '•••' : value;
}

/// Writes one part of a track out.
///
/// The name of the part stands above the words, the way the names of the
/// addresses stand above theirs.
class TrackDetailBlockView extends StatelessWidget {
  final TrackDetailBlock block;

  const TrackDetailBlockView({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          block.label,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
            weight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          block.text,
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
          ),
        ),
      ],
    );
  }
}

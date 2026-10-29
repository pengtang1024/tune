import 'dart:io';

import 'package:tune/core/utils/sheet_content_key.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/domain/models/song.dart';

/// The sheet the pipeline writes next to the audio: the header carries the
/// account of the vote, the body only the lines the pool agreed on. A
/// disputed line is not written — its place goes to the header instead, so
/// a later re-vote can find what was left out (docs/smart-lyrics.md §7.3).
String buildSmartLrc(
  SmartConsensus consensus, {
  required List<String> origins,
  required DateTime at,
}) {
  final disputed = [
    for (var index = 0; index < consensus.lines.length; index++)
      if (consensus.lines[index].disputed) index,
  ];

  final body = [
    for (final line in consensus.lines)
      if (!line.disputed) '[${_stampOf(line.start)}]${line.text}',
  ];

  // The content key lets a contrast know the exact words it speaks about:
  // the date alone would let a same-day regeneration keep stale lines.
  final header = [
    '[tune:smart]',
    '[votes:${consensus.votesCounted}]',
    '[sources:${origins.join(',')}]',
    if (disputed.isNotEmpty) '[disputed:${disputed.join(',')}]',
    '[sheet:${sheetContentKey(body.join('\n'))}]',
    '[date:${at.toIso8601String().substring(0, 10)}]',
  ];

  return [...header, ...body].join('\n');
}

/// The place in time as the LRC stamp reads it — `[mm:ss.xx]`.
String _stampOf(Duration start) {
  final minutes = start.inMinutes.toString().padLeft(2, '0');
  final seconds = start.inSeconds % 60;
  final centis = (start.inMilliseconds % 1000) ~/ 10;
  String two(int value) => value.toString().padLeft(2, '0');
  return '$minutes:${two(seconds)}.${two(centis)}';
}

/// The audio of [song], when it is on this machine.
///
/// Kept next to the smart sheet's writer so the place of a fetched file and
/// the place of the sheet stay one decision.
File? localAudioOf(Song song) => song.localFile == null
    ? null
    : File(song.localFile!);

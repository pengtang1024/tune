import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_lrc.dart';
import 'package:tune/features/player/domain/lyrics_document.dart';

/// The sheet the pipeline writes next to the audio (docs/smart-lyrics.md
/// §7.3): the header carries the account of the vote, the body only the
/// lines the pool agreed on.
SmartConsensus _consensus(List<ConsensusLine> lines) =>
    SmartConsensus(lines: lines, votesCounted: 4);

void main() {
  test('every agreed line is written with its place in time', () {
    final sheet = buildSmartLrc(
      _consensus([
        const ConsensusLine(
          start: Duration(milliseconds: 12500),
          text: '月亮走我也走',
          disputed: false,
        ),
        const ConsensusLine(
          start: Duration(milliseconds: 72540),
          text: '我送阿哥到村口',
          disputed: false,
        ),
      ]),
      origins: const ['lrclib', 'cloud:whisper-1'],
      at: DateTime(2026, 10, 28),
    );

    expect(sheet.contains('[00:12.50]月亮走我也走'), isTrue);
    expect(sheet.contains('[01:12.54]我送阿哥到村口'), isTrue);
  });

  test('a disputed line leaves the sheet, its place goes to the header', () {
    final sheet = buildSmartLrc(
      _consensus([
        const ConsensusLine(
          start: Duration(milliseconds: 1000),
          text: ' agreed',
          disputed: false,
        ),
        const ConsensusLine(
          start: Duration(milliseconds: 5000),
          text: 'disputed words',
          disputed: true,
        ),
      ]),
      origins: const ['cloud:whisper-1'],
      at: DateTime(2026, 10, 28),
    );

    expect(sheet.contains('disputed words'), isFalse);
    expect(RegExp(r'\[disputed:1\]').hasMatch(sheet), isTrue);
  });

  test('the header survives the parser of the player', () {
    final sheet = buildSmartLrc(
      _consensus([
        const ConsensusLine(
          start: Duration(milliseconds: 1000),
          text: '一句词',
          disputed: false,
        ),
      ]),
      origins: const ['lrclib'],
      at: DateTime(2026, 10, 28),
    );

    final document = LyricsDocument.parse(sheet);

    expect(document.lines.single.text, '一句词');
    expect(document.lines.single.time, const Duration(milliseconds: 1000));
  });

  test('an hour and more still reads as one timestamp', () {
    final sheet = buildSmartLrc(
      _consensus([
        const ConsensusLine(
          start: Duration(minutes: 61, seconds: 5, milliseconds: 400),
          text: '尾声',
          disputed: false,
        ),
      ]),
      origins: const [],
      at: DateTime(2026, 10, 28),
    );

    expect(LyricsDocument.parse(sheet).lines.single.text, '尾声');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_ballot.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_consensus.dart';

/// The pool that votes on the words of one song.
///
/// docs/smart-lyrics.md §6.3: every source hands in a sheet, the sheets are
/// aligned on the timeline and the lines vote. A line the pool cannot agree
/// on leaves marked, it does not leave the song.
LyricsBallot machine(String origin, List<(int, String)> lines) =>
    LyricsBallot(
      origin: origin,
      kind: BallotKind.machine,
      lines: [
        for (final (ms, text) in lines)
          BallotLine(start: Duration(milliseconds: ms), text: text),
      ],
    );

LyricsBallot human(String origin, List<(int, String)> lines) => LyricsBallot(
  origin: origin,
  kind: BallotKind.human,
  lines: [
    for (final (ms, text) in lines)
      BallotLine(start: Duration(milliseconds: ms), text: text),
  ],
);

LyricsBallot knowledge(List<String> lines) =>
    LyricsBallot(
      origin: 'knowledge',
      kind: BallotKind.knowledge,
      lines: [for (final text in lines) BallotLine(start: Duration.zero, text: text)],
    );

void main() {
  group('行级共识', () {
    test('三张机器票唱同一句，行不标记', () {
      final consensus = voteOn([
        machine('a', [(1000, '月亮走我也走'), (5000, '我送阿哥到村口')]),
        machine('b', [(1050, '月亮走我也走'), (5040, '我送阿哥到村口')]),
        machine('c', [(980, '月亮走我也走'), (5100, '我送阿哥到村口')]),
      ]);

      expect(consensus.lines.length, 2);
      expect(consensus.lines.every((line) => !line.disputed), isTrue);
      expect(consensus.lines.first.text, '月亮走我也走');
      expect(consensus.lines.first.start.inMilliseconds, 980,
          reason: '行的起点是唱出这句话的最早时刻');
    });

    test('三张票各执一词，行标记为分歧', () {
      final consensus = voteOn([
        machine('a', [(1000, '月亮走我也走')]),
        machine('b', [(1000, '月亮走了他也走')]),
        machine('c', [(1000, '月亮走着我也走')]),
      ]);

      expect(consensus.lines.length, 1);
      expect(consensus.lines.first.disputed, isTrue);
    });

    test('少于三票时整首要人看过才落盘', () {
      final consensus = voteOn([
        machine('a', [(1000, '一句')]),
        machine('b', [(1000, '一句')]),
      ]);

      expect(consensus.lines.first.disputed, isTrue);
    });

    test('两张人写票压过一张机器票', () {
      final consensus = voteOn([
        human('lrclib', [(1000, '月亮走我也走')]),
        machine('a', [(1000, '月亮走我也走')]),
        machine('b', [(1000, '月亮走他也走')]),
      ]);

      expect(consensus.lines.first.text, '月亮走我也走');
      expect(consensus.lines.first.disputed, isFalse);
    });

    test('一个人写票对两张机器票各不相让时，人写稿赢', () {
      final consensus = voteOn([
        human('lrclib', [(1000, '月亮走我也走')]),
        machine('a', [(1000, '月亮走他 也走')]),
        machine('b', [(1000, '月亮走他也走')]),
      ]);

      expect(consensus.lines.first.text, '月亮走我也走');
      expect(consensus.lines.first.disputed, isFalse,
          reason: '人写票的分量等于两张机器票，平局由人写稿先到先得');
    });

    test('比较时不管标点空格与全半角，正文取胜出票自己的写法', () {
      final consensus = voteOn([
        machine('a', [(1000, '月亮走,我也走!')]),
        machine('b', [(1000, '月亮走 我也走')]),
        machine('c', [(1000, '月亮走，我也走！')]),
      ]);

      expect(consensus.lines.first.text, '月亮走,我也走!');
      expect(consensus.lines.first.disputed, isFalse);
    });

    test('时间差一秒以内并作一行，超过一秒分行', () {
      final consensus = voteOn([
        machine('a', [(1000, '同一行'), (2100, '下一行')]),
        machine('b', [(1400, '同一行'), (2100, '下一行')]),
        machine('c', [(1000, '同一行'), (2100, '下一行')]),
      ]);

      expect(consensus.lines.length, 2);
    });

    test('共识按时间排序', () {
      final consensus = voteOn([
        machine('a', [(5000, '后唱'), (1000, '先唱')]),
        machine('b', [(1000, '先唱'), (5000, '后唱')]),
        machine('c', [(1000, '先唱'), (5000, '后唱')]),
      ]);

      expect(consensus.lines.first.text, '先唱');
      expect(consensus.lines.last.text, '后唱');
    });
  });

  group('知识票', () {
    test('按锚票对上时间轴后入池投票', () {
      final anchor = machine('a', [
        (1000, '月亮走我也走'),
        (5000, '我送阿哥到村口'),
      ]);
      final aligned = alignKnowledgeVote(
        knowledge(['月亮走我也走', '我送阿哥到村口']),
        anchor,
      );

      expect(aligned, isNotNull);
      expect(aligned!.lines.first.start.inMilliseconds, 1000);
      expect(aligned.lines.last.start.inMilliseconds, 5000);
    });

    test('六成对不上就不许入池，防止模型编词', () {
      final anchor = machine('a', [
        (1000, '月亮走我也走'),
        (5000, '我送阿哥到村口'),
        (9000, '屋里iren只有我一个人'),
      ]);
      final aligned = alignKnowledgeVote(
        knowledge(['完全另一首歌', '跟这一首没关系', '一个字都对不上']),
        anchor,
      );

      expect(aligned, isNull);
    });

    test('对上的知识票成为一票之后，两票机器加它仍算三票', () {
      final consensus = voteOn(
        [
          machine('a', [(1000, '月亮走我也走')]),
          machine('b', [(1000, '月亮走我也走')]),
        ],
        knowledge: knowledge(['月亮走我也走']),
      );

      expect(consensus.lines.first.disputed, isFalse);
      expect(consensus.votesCounted, 3);
    });
  });
}

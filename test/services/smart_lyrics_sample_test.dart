import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_sample.dart';

/// The stratified sample of the accuracy audit (docs/smart-lyrics.md §10):
/// four layers — studio, live, rap, non-Chinese — and a draw that is
/// reproducible, so a verification round compares to the one before it.
SmartLyricsCandidate _track(
  String uri, {
  String title = 'A',
  String artist = 'Artist',
  String album = 'Album',
  String genre = '',
  String? language,
}) => SmartLyricsCandidate(
  uri: uri,
  title: title,
  artist: artist,
  album: album,
  genre: genre,
  language: language,
);

void main() {
  group('the layer of a track', () {
    test('a live performance is live, whatever its genre says', () {
      expect(
        layerOf(
          _track('/a', title: 'Night Drive (Live)', genre: 'Rock'),
        ),
        SmartLyricsLayer.live,
      );
      expect(
        layerOf(_track('/b', album: '现场版精选', genre: '流行')),
        SmartLyricsLayer.live,
      );
    });

    test('rap goes by genre, in the words the tags use', () {
      expect(layerOf(_track('/c', genre: 'Hip-Hop')), SmartLyricsLayer.rap);
      expect(layerOf(_track('/d', genre: '说唱')), SmartLyricsLayer.rap);
      expect(layerOf(_track('/e', genre: 'Rap/嘻哈')), SmartLyricsLayer.rap);
    });

    test('a track whose words are not Chinese is its own layer', () {
      expect(
        layerOf(_track('/f', title: 'Night Drive', language: 'en')),
        SmartLyricsLayer.nonChinese,
      );
      expect(
        layerOf(_track('/g', title: 'Night Drive')),
        SmartLyricsLayer.nonChinese,
        reason: 'no tag, no Chinese characters in the title — the words the '
            'pipeline is asked for are probably not Chinese',
      );
      expect(
        layerOf(_track('/h', title: '月亮代表我的心')),
        SmartLyricsLayer.studio,
      );
      expect(
        layerOf(_track('/i', title: '平凡之路', language: 'zh')),
        SmartLyricsLayer.studio,
      );
    });

    test('the layers do not overlap: live, then rap, then language', () {
      expect(
        layerOf(_track('/j', title: 'Battle (Live)', genre: 'Hip-Hop')),
        SmartLyricsLayer.live,
        reason: 'the performance a voice reads is the stronger fact',
      );
      expect(
        layerOf(_track('/k', title: '夜曲', genre: '说唱')),
        SmartLyricsLayer.rap,
      );
      expect(
        layerOf(_track('/l', title: 'Flow', language: 'en', genre: '')),
        SmartLyricsLayer.nonChinese,
      );
    });

    test('a genre that merely mentions the words is not the layer', () {
      expect(
        layerOf(_track('/m', title: '月亮代表我的心', genre: 'Soundtrack')),
        SmartLyricsLayer.studio,
        reason: '"Soundtrack" carries no standalone "rap" — a substring '
            'match inside a word would sort by accident',
      );
    });
  });

  group('the stratified draw', () {
    test('the same library and the same seed draw the same tracks', () {
      final candidates = [
        for (var index = 0; index < 500; index++)
          _track('/studio-$index', title: '月亮第$index'),
      ];

      final first = drawStratified(candidates, perLayer: 200, seed: 7);
      final second = drawStratified(candidates, perLayer: 200, seed: 7);

      expect(first.map((entry) => entry.uri), second.map((entry) => entry.uri));
    });

    test('a different seed draws a different share of the pool', () {
      final candidates = [
        for (var index = 0; index < 500; index++)
          _track('/studio-$index', title: '月亮第$index'),
      ];

      final first = drawStratified(candidates, perLayer: 200, seed: 7);
      final second = drawStratified(candidates, perLayer: 200, seed: 8);

      expect(
        first.map((entry) => entry.uri).toSet(),
        isNot(second.map((entry) => entry.uri).toSet()),
      );
    });

    test('every layer fills up to its budget when the pool lets it', () {
      final candidates = [
        for (var index = 0; index < 300; index++)
          _track('/studio-$index', title: '月亮第$index'),
        for (var index = 0; index < 250; index++)
          _track('/live-$index', title: '现场第$index (Live)'),
        for (var index = 0; index < 210; index++)
          _track('/rap-$index', title: '夜曲第$index', genre: '说唱'),
        for (var index = 0; index < 150; index++)
          _track('/en-$index', title: 'Night $index'),
      ];

      final drawn = drawStratified(candidates, perLayer: 200, seed: 7);

      int count(SmartLyricsLayer layer) =>
          drawn.where((entry) => entry.layer == layer).length;
      expect(count(SmartLyricsLayer.studio), 200);
      expect(count(SmartLyricsLayer.live), 200);
      expect(count(SmartLyricsLayer.rap), 200);
      expect(count(SmartLyricsLayer.nonChinese), 150);
    });

    test('a track lands in exactly one layer, whatever it also looks like', () {
      final candidates = [
        _track('/a', title: 'Battle (Live)', genre: 'Hip-Hop'),
        _track('/b', title: 'Night', language: 'en'),
      ];

      final drawn = drawStratified(candidates, perLayer: 200, seed: 7);

      expect(drawn.map((entry) => entry.uri), ['/a', '/b']);
    });
  });
}

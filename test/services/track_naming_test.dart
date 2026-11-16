import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/music_sources/track_naming.dart';

void main() {
  group('normalizeTrackNaming', () {
    test('专辑写着「艺术家 - 作品」而艺术家为空时拆分', () {
      final naming = normalizeTrackNaming(
        title: '01 Theme, I. C.A.E.',
        artist: '',
        album: 'Edward ELGAR - Enigma Variations',
      );

      expect(naming.artist, 'Edward ELGAR');
      expect(naming.album, 'Enigma Variations');
      expect(naming.title, '01 Theme, I. C.A.E.');
    });

    test('条目声明了 creator 时优先用它', () {
      final naming = normalizeTrackNaming(
        title: '01 Theme',
        artist: '',
        album: 'Elgar - Enigma',
        creator: 'John Barbirolli',
      );

      expect(naming.artist, 'John Barbirolli');
      // 专辑那半句写的是作曲家（Elgar），与指挥家对不上，不该被剥掉。
      expect(naming.album, 'Elgar - Enigma');
    });

    test('标题重复艺术家时去掉前缀', () {
      final naming = normalizeTrackNaming(
        title: 'Handel, Messiah - 103 And the glory of the Lord - Coro',
        artist: 'Handel, G F',
        album: 'Messiah (Disc 1 of 3) - Part One',
      );

      expect(naming.title, '103 And the glory of the Lord - Coro');
      expect(naming.artist, 'Handel, G F');
      expect(naming.album, 'Messiah (Disc 1 of 3) - Part One');
    });

    test('标题整段就是艺术家加曲名时去掉整段前缀', () {
      final naming = normalizeTrackNaming(
        title: 'Ken Verheecke - Autumn Reflections - 06 Falling Leaves',
        artist: 'Ken Verheecke',
        album: 'Autumn Reflections',
      );

      expect(naming.title, 'Autumn Reflections - 06 Falling Leaves');
    });

    test('专辑与标题相同（整条就是一个曲名）时不拆', () {
      final naming = normalizeTrackNaming(
        title: 'Sorrow - line 259',
        artist: '',
        album: 'Sorrow - line 259',
      );

      expect(naming.artist, isEmpty);
      expect(naming.title, 'Sorrow - line 259');
      expect(naming.album, 'Sorrow - line 259');
    });

    test('标题开头不是艺术家时不动它', () {
      final naming = normalizeTrackNaming(
        title: 'Symphony No. 5 - I. Allegro',
        artist: 'Beethoven',
        album: 'Symphonies',
      );

      expect(naming.title, 'Symphony No. 5 - I. Allegro');
    });

    test('纯编号的前缀不会被当成艺术家', () {
      final naming = normalizeTrackNaming(
        title: 'Track 7',
        artist: '',
        album: '12 - Instrumental',
      );

      expect(naming.artist, isEmpty);
      expect(naming.album, '12 - Instrumental');
    });

    test('没有可拆的东西时原样返回', () {
      final naming = normalizeTrackNaming(
        title: 'Blue in Green',
        artist: 'Miles Davis',
        album: 'Kind of Blue',
      );

      expect(naming.title, 'Blue in Green');
      expect(naming.artist, 'Miles Davis');
      expect(naming.album, 'Kind of Blue');
    });
  });
}

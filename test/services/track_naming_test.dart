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
      expect(naming.title, 'Theme, I. C.A.E.');
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

      expect(naming.title, 'And the glory of the Lord');
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
  
  test('a leading track number leaves the title', () {
    expect(
      normalizeTrackNaming(title: '01 Theme, I. C.A.E.', artist: 'Edward ELGAR', album: 'Enigma Variations').title,
      'Theme, I. C.A.E.',
    );
    expect(
      normalizeTrackNaming(title: '01 - The Shade of Cardinal Richelieu.', artist: 'A', album: 'B').title,
      'The Shade of Cardinal Richelieu.',
    );
    expect(
      normalizeTrackNaming(title: '02 II. H.D.S. - P.', artist: 'Edward ELGAR', album: 'Enigma Variations').title,
      'II. H.D.S. - P.',
    );
  });

  test('a number that is part of the name stays', () {
    for (final title in const ['7 Rings', '99 Luftballons', '24K Magic', '1999']) {
      expect(
        normalizeTrackNaming(title: title, artist: 'Someone', album: 'Somewhere').title,
        title,
        reason: title,
      );
    }
  });

  test('an arabic number repeats a roman numeral', () {
    expect(
      normalizeTrackNaming(title: '13 XIII. Romanza; +++', artist: 'Edward ELGAR', album: 'Enigma Variations').title,
      'XIII. Romanza',
    );
  });

  test('a disc track number goes when the album names the disc', () {
    expect(
      normalizeTrackNaming(
        title: "102 Comfort ye - Ev'ry valley",
        artist: 'Handel, G F',
        album: 'Messiah (Disc 1 of 3) - Part One',
      ).title,
      "Comfort ye - Ev'ry valley",
    );
    // 碟号对不上（第二碟的 101）时不动。
    expect(
      normalizeTrackNaming(
        title: '201 He was despised',
        artist: 'Handel, G F',
        album: 'Messiah (Disc 1 of 3) - Part One',
      ).title,
      '201 He was despised',
    );
  });

  test('a performer credit at the end goes', () {
    expect(
      normalizeTrackNaming(
        title: '103 And the glory of the Lord - Coro',
        artist: 'Handel, G F',
        album: 'Messiah (Disc 1 of 3) - Part One',
      ).title,
      'And the glory of the Lord',
    );
    // 不是角色名的尾巴保留：`Ev'ry valley` 是下一句唱词；专辑没写碟号时
    // 开头的 `102` 也无从确认为轨号，一并原样留着。
    expect(
      normalizeTrackNaming(title: "102 Comfort ye - Ev'ry valley", artist: 'Handel, G F', album: 'Messiah').title,
      "102 Comfort ye - Ev'ry valley",
    );
  });

  test('a title keeps no track number even without an artist', () {
    expect(
      normalizeTrackNaming(title: '06 Hazardous Material 2 vbr', artist: '', album: 'Fix').title,
      'Hazardous Material 2 vbr',
    );
    expect(
      normalizeTrackNaming(title: 'Romanza; +++', artist: '', album: 'Enigma').title,
      'Romanza',
    );
  });
});
}

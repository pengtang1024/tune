import 'package:dbus/dbus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/mpris/mpris_values.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'dbus_test_helpers.dart';

void main() {
  group('the wording of the media controls', () {
    test('names the playback states', () {
      expect(mprisStatusName(MprisPlaybackStatus.playing), 'Playing');
      expect(mprisStatusName(MprisPlaybackStatus.paused), 'Paused');
      expect(mprisStatusName(MprisPlaybackStatus.stopped), 'Stopped');
    });

    test('names the repeat modes', () {
      expect(mprisLoopStatusName(MprisLoopStatus.track), 'Track');
      expect(mprisLoopStatusName(MprisLoopStatus.playlist), 'Playlist');
      expect(mprisLoopStatusName(MprisLoopStatus.none), 'None');
      expect(mprisLoopStatusOf('Track'), MprisLoopStatus.track);
      expect(mprisLoopStatusOf('Playlist'), MprisLoopStatus.playlist);
      expect(mprisLoopStatusOf('None'), MprisLoopStatus.none);
    });

    test('puts the track under the object of the controls', () {
      final metadata = mprisMetadataValue(
        '/org/mpris/MediaPlayer2',
        const MprisTrack(
          id: '7',
          title: 'Song',
          artists: ['Artist'],
          album: 'Album',
          length: Duration(minutes: 3),
        ),
      );

      final values = metadata as DBusDict;
      expect(
        dbusProperty(values, 'mpris:trackid'),
        DBusObjectPath('/org/mpris/MediaPlayer2/Track/7'),
      );
      expect(dbusProperty(values, 'xesam:title'), const DBusString('Song'));
      expect(dbusProperty(values, 'mpris:length'), const DBusInt64(180000000));
    });

    test('has no metadata when no track plays', () {
      final metadata = mprisMetadataValue('/org/mpris/MediaPlayer2', null);

      expect((metadata as DBusDict).children, isEmpty);
    });
  });
}

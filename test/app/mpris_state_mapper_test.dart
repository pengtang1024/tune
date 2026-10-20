import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/mpris/mpris_snapshot.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/desktop/application/mpris_state_mapper.dart';
import 'package:tune/features/desktop/application/playback_track_tracker.dart';
import 'package:tune/features/player/domain/play_mode.dart';
import 'package:tune/features/player/domain/playback_state.dart';

void main() {
  group('the state the system controls show', () {
    test('names the state of the player', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      expect(
        mapper.snapshotFor(_state(status: PlaybackStatus.playing)).status,
        MprisPlaybackStatus.playing,
      );
      expect(
        mapper.snapshotFor(_state(status: PlaybackStatus.paused)).status,
        MprisPlaybackStatus.paused,
      );
      expect(
        mapper.snapshotFor(_state(status: PlaybackStatus.idle)).status,
        MprisPlaybackStatus.stopped,
      );
    });

    test('carries the volume, the speed and the order of the queue', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final snapshot = mapper.snapshotFor(
        _state(volume: 0.4, speed: 1.5, playMode: PlayMode.shuffle),
      );

      expect(snapshot.volume, 0.4);
      expect(snapshot.rate, 1.5);
      expect(snapshot.shuffle, isTrue);
      expect(snapshot.loopStatus, MprisLoopStatus.playlist);
    });

    test('names the repeat of one track', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final snapshot = mapper.snapshotFor(_state(playMode: PlayMode.repeatOne));

      expect(snapshot.loopStatus, MprisLoopStatus.track);
    });

    test('offers no position in a live stream', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final live = _state().copyWith(
        queue: [song.copyWith(isLiveStream: true)],
        currentUri: song.uri,
      );

      expect(mapper.snapshotFor(live).canSeek, isFalse);
    });

    test('has no track when the queue is empty', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final empty = _state().copyWith(queue: const [], currentUri: null);

      expect(mapper.snapshotFor(empty).track, isNull);
    });
  });

  group('the number of the track', () {
    test('grows when another track starts', () {
      final tracker = PlaybackTrackTracker();
      final mapper = MprisStateMapper(tracker);

      final first = mapper.snapshotFor(_state());
      final second = mapper.snapshotFor(
        _state().copyWith(
          queue: [song.copyWith(uri: '/music/b.mp3')],
          currentUri: '/music/b.mp3',
        ),
      );

      expect(first.track!.id, isNot(second.track!.id));
    });

    test('stays the same while the same track plays', () {
      final tracker = PlaybackTrackTracker();
      final mapper = MprisStateMapper(tracker);

      final first = mapper.snapshotFor(_state());
      final second = mapper.snapshotFor(
        _state().copyWith(position: const Duration(seconds: 5)),
      );

      expect(second.track!.id, first.track!.id);
    });

    test('tells the desktop that the track changed', () {
      final tracker = PlaybackTrackTracker();

      expect(tracker.remember(song), isTrue);
      expect(tracker.remember(song), isFalse);
    });
  });

  group('the cover of the track', () {
    test('prefers the file next to the music', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final snapshot = mapper.snapshotFor(
        _state().copyWith(
          queue: [song.copyWith(albumArtPath: '/music/cover.png')],
          currentUri: song.uri,
        ),
      );

      expect(snapshot.track!.artUrl, Uri.file('/music/cover.png').toString());
    });

    test('falls back to the address of the network', () {
      final mapper = MprisStateMapper(PlaybackTrackTracker());

      final snapshot = mapper.snapshotFor(
        _state().copyWith(
          queue: [song.copyWith(artworkUrl: 'https://host/cover.png')],
          currentUri: song.uri,
        ),
      );

      expect(snapshot.track!.artUrl, 'https://host/cover.png');
    });
  });
}

/// The track the player plays in the tests.
const song = Song(
  id: 1,
  title: 'Alpha',
  artist: 'Artist A',
  album: 'Album A',
  duration: 180000,
  uri: '/music/a.mp3',
);

/// The state of a player that plays one track.
PlaybackState _state({
  PlaybackStatus status = PlaybackStatus.playing,
  double volume = 1,
  double speed = 1,
  PlayMode playMode = PlayMode.sequential,
}) {
  return PlaybackState(
    status: status,
    volume: volume,
    speed: speed,
    playMode: playMode,
    queue: const [song],
    currentUri: song.uri,
    duration: const Duration(minutes: 3),
  );
}

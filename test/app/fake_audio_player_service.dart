import 'dart:async';

import 'package:tune/data/services/audio_player_service.dart';
import 'package:tune/domain/models/song.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _completionController = StreamController<void>.broadcast();

  Song? playedSong;
  int playCount = 0;
  Completer<void>? playGate;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;

  @override
  Future<void> init() async {}

  @override
  Future<void> play(Song song) async {
    playedSong = song;
    playCount++;
    _position = Duration.zero;
    _duration = Duration(milliseconds: song.durationInMillis);
    if (playGate != null) await playGate!.future;
    _playing = true;
    _playingController.add(true);
    _durationController.add(_duration);
    _positionController.add(_position);
  }

  @override
  Future<void> pause() async {
    _playing = false;
    _playingController.add(false);
  }

  @override
  Future<void> resume() async {
    _playing = true;
    _playingController.add(true);
  }

  @override
  Future<void> stop() async {
    _playing = false;
    _position = Duration.zero;
    _playingController.add(false);
    _positionController.add(_position);
  }

  @override
  Future<void> seekTo(Duration position) async {
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
  }

  @override
  Duration get currentPosition => _position;

  @override
  Duration get duration => _duration;

  @override
  bool get isPlaying => _playing;

  @override
  double get speed => _speed;

  double get volume => _volume;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<bool> get playingStream => _playingController.stream;

  @override
  Stream<void> get completionStream => _completionController.stream;

  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  void complete() {
    _playing = false;
    _completionController.add(null);
  }

  @override
  void dispose() {
    _positionController.close();
    _durationController.close();
    _playingController.close();
    _completionController.close();
  }
}

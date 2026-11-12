import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/media_store_music_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cn.iouf.tune/media_store');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  void answer(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => handler(call),
        );
  }

  test('a MediaStore row becomes a song with its content address', () async {
    answer(
      (call) => [
        {
          'uri': 'content://media/external/audio/media/42',
          'mediaId': 42,
          'title': 'Tune Test Tone',
          'artist': 'Tune QA',
          'album': 'QA',
          'durationMs': 60000,
          'dateAddedSeconds': 1700000000,
          'year': 2024,
          'size': 1234,
          'mimeType': 'audio/mpeg',
        },
      ],
    );

    final songs = await MediaStoreMusicScanner().scanMusic();

    expect(songs, hasLength(1));
    expect(songs.single.title, 'Tune Test Tone');
    expect(songs.single.artist, 'Tune QA');
    expect(songs.single.album, 'QA');
    expect(songs.single.duration, 60000);
    expect(songs.single.dateAdded, 1700000000000);
    expect(songs.single.uri, 'content://media/external/audio/media/42');
    expect(songs.single.externalId, '42');
  });

  test('a denied media permission is an empty library, not a crash', () async {
    answer((call) => throw PlatformException(code: 'permission_denied'));

    expect(await MediaStoreMusicScanner().scanMusic(), isEmpty);
  });

  test('the directory arguments lead to the system library', () async {
    answer(
      (call) => [
        {
          'uri': 'content://media/external/audio/media/7',
          'mediaId': 7,
          'title': 'Seven',
        },
      ],
    );

    final scanner = MediaStoreMusicScanner();
    // The library answers for its whole self: a read is the truth about
    // every local row, folders are not asked.
    expect(scanner.addressesSystemLibrary, isTrue);

    final songs = await scanner.scanMusicInDirectories([
      '/storage/emulated/0/Music',
    ]);

    expect(songs.single.title, 'Seven');
  });
}

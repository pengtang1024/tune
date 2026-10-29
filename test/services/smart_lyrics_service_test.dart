import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/data/services/music_sources/lyrics_provider.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';
import 'package:tune/features/smart_lyrics/domain/channel_health.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/domain/models/song.dart';

import 'fake_http_adapter.dart';
import 'fake_persistence.dart';

/// The single-song loop of M2 (docs/smart-lyrics.md §7.1): the human pool
/// is asked first, the machine channels fill what is missing, the pool
/// votes, the sheet lands next to the audio.
class _Engine extends SmartLyricsEngine {
  _Engine(
    this.id, {
    List<TranscribedSegment>? answer,
    Object? error,
    bool empty = false,
  }) : _answer = answer,
       _error = error,
       _empty = empty;

  final List<TranscribedSegment>? _answer;
  final Object? _error;
  final bool _empty;

  /// The audio the channel was asked to read.
  final List<File> asked = [];

  @override
  final String id;

  @override
  Future<TranscriptionResult> runTranscription(
    SmartAudioInput input, {
    void Function(double progress)? onProgress,
  }) async {
    asked.add(input.audio);
    final error = _error;
    if (error != null) throw error;
    if (_empty) return const TranscriptionResult(segments: []);
    return TranscriptionResult(segments: _answer!, language: 'zh');
  }
}

class _Human implements LyricsProvider {
  final Map<int, String> sheets = {};

  @override
  Future<String?> lookup(Song song) async => sheets[song.id];
}

/// A timed sheet with [words] as its lines, a second apart.
String _sheetText(List<String> words) => [
  for (var index = 0; index < words.length; index++)
    '[00:${(index + 1).toString().padLeft(2, '0')}.00]${words[index]}',
].join('\n');

void main() {
  late Directory root;
  late FileLibraryPaths paths;
  late File audio;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_smart_service');
    paths = FileLibraryPaths(
      FakePersistenceService()..values[LibraryPaths.rootKey] = root.path,
    );
    audio = File(path.join(root.path, 'So What.mp3'))
      ..writeAsStringSync('not really audio');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// A track whose audio is the file the setup wrote.
  Song localSong() => Song(
    id: 1,
    title: 'So What',
    artist: 'Miles Davis',
    uri: audio.path,
  );

  /// A remote track that never fetched a copy and carries no stream.
  Song remoteSong() => const Song(
    id: 1,
    title: 'So What',
    artist: 'Miles Davis',
    uri: 'tune://source.test/so-what',
  );

  SmartLyricsService service({
    List<SmartLyricsEngine> engines = const [],
    List<({String name, LyricsProvider provider})> humanPool = const [],
    SmartTextAssist? assist,
    ChannelHealthLedger? health,
  }) => SmartLyricsService(
    engines: engines,
    humanPool: humanPool,
    paths: paths,
    assist: assist,
    health: health,
  );

  List<TranscribedSegment> segmentsOf(List<String> words) => [
    for (var index = 0; index < words.length; index++)
      TranscribedSegment(
        start: Duration(seconds: index + 1),
        end: Duration(seconds: index + 2),
        text: words[index],
      ),
  ];

  SmartTextAssist assistAnswering(String content) {
    final adapter = FakeHttpAdapter()..body = jsonEncode({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    });
    return SmartTextAssist(
      client: OpenAiCompatibleClient(
        dio: Dio(BaseOptions(responseType: ResponseType.plain))
          ..httpClientAdapter = adapter,
        baseUrl: 'https://api.test/v1',
        apiKey: 'sk-test',
      ),
      model: 'gpt-4o-mini',
    );
  }

  test('the human pool settles it: no channel is asked', () async {
    final engine = _Engine('cloud:whisper-1');
    final human = _Human()..sheets[1] = _sheetText(['一句', '两句']);
    final second = _Human()..sheets[1] = _sheetText(['一句', '两句']);
    final third = _Human()..sheets[1] = _sheetText(['一句', '两句']);

    final outcome = await service(
      engines: [engine],
      humanPool: [
        (name: 'a', provider: human),
        (name: 'b', provider: second),
        (name: 'c', provider: third),
      ],
    ).generate(localSong());

    expect(outcome.saved, isTrue);
    expect(engine.asked, isEmpty, reason: 'the cheap votes came first');
    expect(
      await paths.readSmartLyrics(localSong()),
      isNotNull,
      reason: 'the sheet lands next to the audio',
    );
  });

  test('the machine channels fill the gap; a failed correction keeps the draft', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句', '两句']));
    final human = _Human()..sheets[1] = _sheetText(['一句']);
    // The same answer serves the correction (a wrong count: the draft
    // survives as it was) and the rebuild (a knowledge line).
    final assist = assistAnswering(jsonEncode(['两句']));

    final outcome = await service(
      engines: [engine],
      humanPool: [(name: 'lrclib', provider: human)],
      assist: assist,
    ).generate(localSong());

    expect(outcome.saved, isTrue, reason: 'human + machine + knowledge = 3');
    expect(outcome.votes, 3);
    expect(outcome.origins, containsAll(['lrclib', 'cloud:whisper-1']));
    expect(outcome.disputed, 0);
  });

  test('a disputed line is not written, its place goes to the header', () async {
    final human = _Human()..sheets[1] = _sheetText(['一边一个说法']);
    final engines = [
      _Engine('cloud:a', answer: segmentsOf(['另一句'])),
      _Engine('cloud:b', answer: segmentsOf(['还有一句'])),
      _Engine('cloud:c', answer: segmentsOf(['第四种说法'])),
    ];

    final outcome = await service(
      engines: engines,
      humanPool: [(name: 'lrclib', provider: human)],
    ).generate(localSong());

    expect(outcome.saved, isTrue);
    expect(outcome.disputed, 1);
    final sheet = await paths.readSmartLyrics(localSong());
    expect(sheet, isNotNull);
    expect(sheet!.contains('另一句'), isFalse);
    expect(sheet.contains('[disputed:0]'), isTrue);
  });

  test('a local track is read straight off the disk', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));
    final local = Song(id: 2, title: 'Local', artist: 'A', uri: audio.path);

    await service(engines: [engine]).generate(local);

    expect(engine.asked.single.path, audio.path);
  });

  test('a track with neither a file nor a stream fails before any channel runs', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));

    final outcome = await service(engines: [engine]).generate(remoteSong());

    expect(outcome.failure, SmartLyricsFailure.noAudio);
    expect(engine.asked, isEmpty);
  });

  test('channels that answer nothing leave the song as silence', () async {
    final engine = _Engine('cloud:whisper-1', empty: true);
    final second = _Engine('cloud:whisper-2', empty: true);

    final outcome = await service(
      engines: [engine, second],
    ).generate(localSong());

    expect(outcome.saved, isFalse);
    expect(outcome.failure, SmartLyricsFailure.emptyResult);
    expect(await paths.readSmartLyrics(localSong()), isNull);
  });

  test('channels that all fail are an upload failure', () async {
    final engine = _Engine(
      'cloud:whisper-1',
      error: DioException(requestOptions: RequestOptions(path: '/x')),
    );

    final outcome = await service(engines: [engine]).generate(localSong());

    expect(outcome.failure, SmartLyricsFailure.uploadFailed);
  });

  test('one channel failing does not stop the others', () async {
    final broken = _Engine(
      'cloud:a',
      error: DioException(requestOptions: RequestOptions(path: '/x')),
    );
    final working = _Engine('cloud:b', answer: segmentsOf(['一句', '两句']));
    final human = _Human()..sheets[1] = _sheetText(['一句']);

    final outcome = await service(
      engines: [broken, working],
      humanPool: [(name: 'lrclib', provider: human)],
    ).generate(localSong());

    expect(outcome.saved, isTrue);
    expect(outcome.votes, 2, reason: 'the broken channel is just gone');
  });

  test('a cancelled run writes nothing', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));
    final human = _Human()..sheets[1] = _sheetText(['一句']);

    final outcome = await service(
      engines: [engine],
      humanPool: [(name: 'lrclib', provider: human)],
    ).generate(localSong(), cancelled: () => true);

    expect(outcome.cancelled, isTrue);
    expect(outcome.saved, isFalse);
    expect(await paths.readSmartLyrics(localSong()), isNull);
  });

  test('a channel under the health threshold is not asked this round', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));
    final human = _Human()..sheets[1] = _sheetText(['一句']);
    final ledger = _FakeLedger();

    // Six failures land before the run: the channel waits out the round.
    for (var i = 0; i < 6; i++) {
      ledger.record('cloud:whisper-1', ChannelOutcome.failure);
    }

    await service(
      engines: [engine],
      humanPool: [(name: 'lrclib', provider: human)],
      health: ledger,
    ).generate(localSong());

    expect(engine.asked, isEmpty, reason: 'the pool stops spending on a '
        'channel that keeps failing — the failures counted it down');
  });

  test('every answer lands in the ring', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));
    final silent = _Engine('cloud:other', empty: true);
    final broken = _Engine(
      'cloud:broken',
      error: DioException(requestOptions: RequestOptions(path: '/x')),
    );
    final human = _Human()..sheets[1] = _sheetText(['一句']);
    final ledger = _FakeLedger();

    await service(
      engines: [engine, silent, broken],
      humanPool: [(name: 'lrclib', provider: human)],
      health: ledger,
    ).generate(localSong());

    expect(ledger.recorded['cloud:whisper-1'], [ChannelOutcome.success]);
    expect(ledger.recorded['cloud:other'], [ChannelOutcome.empty]);
    expect(ledger.recorded['cloud:broken'], [ChannelOutcome.failure]);
    expect(ledger.recorded['lrclib'], [ChannelOutcome.success]);
  });
}

/// The rings in memory.
class _FakeLedger implements ChannelHealthLedger {
  final Map<String, List<ChannelOutcome>> recorded = {};

  @override
  ChannelHealth healthOf(String channelId) => ChannelHealth.fromOutcomes(
    recorded[channelId] ?? const [],
  );

  @override
  void record(String channelId, ChannelOutcome outcome) {
    recorded.putIfAbsent(channelId, () => []).add(outcome);
  }
}

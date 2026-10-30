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
    List<String> knowledgeModels = const [],
    ChannelHealthLedger? health,
  }) => SmartLyricsService(
    engines: engines,
    humanPool: humanPool,
    paths: paths,
    assist: assist,
    knowledgeModels: knowledgeModels,
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

  test('a human pool alone writes its best sheet — 每首有词', () async {
    final human = _Human()..sheets[1] = _sheetText(['一句', '两句']);

    final outcome = await service(
      humanPool: [(name: 'lrclib', provider: human)],
    ).generate(localSong());

    expect(outcome.saved, isTrue,
        reason: 'the free check has no machines to wait for; one human '
            'sheet is a sheet worth showing');
    expect(await paths.readSmartLyrics(localSong()), contains('一句'));
  });

  test('a human sheet survives the machines staying quiet', () async {
    final human = _Human()..sheets[1] = _sheetText(['一句', '两句']);
    final broken = _Engine('cloud:whisper-1', error: StateError('no answer'));

    final outcome = await service(
      engines: [broken],
      humanPool: [(name: 'lrclib', provider: human)],
    ).generate(localSong());

    expect(outcome.saved, isTrue,
        reason: 'a failed channel is not a verdict on the words a person '
            'wrote — the sheet must not be discarded as silence');
    expect(await paths.readSmartLyrics(localSong()), contains('一句'));
  });

  test('an empty segment is not a line', () async {
    final engine = _Engine(
      'cloud:whisper-1',
      answer: segmentsOf(['一句', '', '   ']),
    );

    final outcome = await service(engines: [engine]).generate(localSong());
    final sheet = await paths.readSmartLyrics(localSong());

    expect(outcome.saved, isTrue);
    expect(sheet, contains('一句'));
    expect(sheet, isNot(contains('[]')));
    expect(
      sheet!
          .split('\n')
          .where((line) => RegExp(r'^\[\d+:\d{2}\.\d{2}\]').hasMatch(line))
          .length,
      1,
      reason: 'one sung line; the blanks never became rows',
    );
  });

  test('a disk that refuses the sheet is a failed run, not a crash', () async {
    final human = _Human()..sheets[1] = _sheetText(['一句']);
    final refusing = SmartLyricsService(
      engines: const [],
      humanPool: [(name: 'lrclib', provider: human)],
      paths: _ThrowingPaths(),
    );

    final outcome = await refusing.generate(localSong());

    expect(outcome.saved, isFalse);
    expect(outcome.failure, SmartLyricsFailure.uploadFailed);
  });

  test('the machine channels fill the gap; a failed correction keeps the draft', () async {
    final whisper = _Engine('cloud:whisper-1', answer: segmentsOf(['一句', '两句']));
    final paraformer = _Engine('cloud:paraformer', answer: segmentsOf(['一句', '两句']));
    final human = _Human()..sheets[1] = _sheetText(['一句', '两句']);
    final second = _Human()..sheets[1] = _sheetText(['一句', '两句']);
    // The correction answers with the wrong line count — the drafts vote
    // as they were read.
    final assist = assistAnswering(jsonEncode(['两句']));

    final outcome = await service(
      engines: [whisper, paraformer],
      humanPool: [
        (name: 'lrclib', provider: human),
        (name: 'music123', provider: second),
      ],
      assist: assist,
      knowledgeModels: ['gpt-4o-mini', 'deepseek-chat'],
    ).generate(localSong());

    expect(outcome.saved, isTrue, reason: 'the human class plus the machine '
        'class (two distinct families) read the same words — §7.6 admits');
    expect(outcome.votes, 5,
        reason: 'two human + two ASR + one pooled knowledge rebuild — '
            'voteOn weighs the best single sheet, the audit still sees all');
    expect(
      outcome.origins,
      containsAll(['lrclib', 'cloud:whisper-1', 'cloud:paraformer']),
    );
    expect(outcome.disputed, 0);
    expect(outcome.auditChecked, 1,
        reason: 'four voices carried the words — the leave-one-out audit '
            'put the line on trial and it stood every rotation');
    expect(outcome.auditMismatched, 0);
  });

  test('a disputed line is not written, its place goes to the header', () async {
    // Machines fighting only themselves — no human sheet to break the tie.
    final engines = [
      _Engine('cloud:a', answer: segmentsOf(['另一句'])),
      _Engine('cloud:b', answer: segmentsOf(['还有一句'])),
      _Engine('cloud:c', answer: segmentsOf(['第四种说法'])),
    ];

    final outcome = await service(
      engines: engines,
      humanPool: const [],
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

  test('a live stream is never fetched — no fixed recording, no words',
      () async {
    final engine = _Engine(
      'cloud:whisper-1',
      answer: segmentsOf(['一句']),
    );
    const station = Song(
      id: 1,
      title: 'Beat Blender',
      artist: 'SomaFM',
      uri: 'tune://radio/somafm%2Fbeatblender',
      streamUrl: 'https://ice1.somafm.com/beatblender-128-mp3',
      isLiveStream: true,
    );

    final outcome = await service(engines: [engine]).generate(station);

    expect(outcome.failure, SmartLyricsFailure.noAudio);
    expect(engine.asked, isEmpty,
        reason: 'an endless stream would fill the disk and never finish');
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

  test('a parked channel is probed once per run, then waits', () async {
    final engine = _Engine('cloud:whisper-1', answer: segmentsOf(['一句']));
    final human = _Human()..sheets[1] = _sheetText(['一句']);
    final ledger = _FakeLedger();

    // Six failures land before the run: the channel is parked.
    for (var i = 0; i < 6; i++) {
      ledger.record('cloud:whisper-1', ChannelOutcome.failure);
    }
    final pipeline = service(
      engines: [engine],
      humanPool: [(name: 'lrclib', provider: human)],
      health: ledger,
    );

    await pipeline.generate(localSong());
    expect(engine.asked, hasLength(1),
        reason: 'the first ask is the probe — a binary installed after '
            'the failures must be able to come back');

    await pipeline.generate(localSong());
    expect(engine.asked, hasLength(2),
        reason: 'a probe that answers keeps the channel in the run — the '
            'old failures no longer outweigh a living channel');

    final broken = _Engine('cloud:broken', error: StateError('gone'));
    final other = _FakeLedger();
    for (var i = 0; i < 6; i++) {
      other.record('cloud:broken', ChannelOutcome.failure);
    }
    final pipeline2 = service(
      engines: [broken],
      humanPool: [(name: 'lrclib', provider: human)],
      health: other,
    );
    await pipeline2.generate(localSong());
    await pipeline2.generate(localSong());
    expect(broken.asked, hasLength(1),
        reason: 'a probe that fails parks the channel for the rest of the run');
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
/// Paths whose disk refuses every write.
class _ThrowingPaths implements LibraryPaths {
  @override
  Future<void> saveSmartLyrics(Song song, String lyrics) async =>
      throw const FileSystemException('no space left');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('the test only reaches the write');
}

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

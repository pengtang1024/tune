import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/data/services/library/library_paths.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_text.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/features/smart_lyrics/application/smart_lyrics_contrast_controller.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_contrast.dart';
import 'package:tune/providers/persistence_providers.dart';

import '../services/fake_persistence.dart';

/// The contrasts of M7 (docs/smart-lyrics.md §7.5): made once per kind,
/// line for line, keyed by the sheet they speak about.
void main() {
  const song = Song(id: 1, title: '月亮', artist: '歌手', uri: 'https://source.test/moon');
  const smartSheet = '[tune:smart]\n[date:2026-10-29]\n'
      '[00:01.00]一\n[00:02.00]二';

  late Directory root;
  late FileLibraryPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('tune_contrast');
    paths = FileLibraryPaths(
      FakePersistenceService()..values[LibraryPaths.rootKey] = root.path,
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  ProviderContainer containerWith({_ScriptedAssist? assist}) =>
      ProviderContainer(
        overrides: [
          // The real paths over a fake persistence: the controller reads
          // the files the way the app does, and the test reads them back.
          persistenceServiceProvider.overrideWithValue(
            FakePersistenceService()..values[LibraryPaths.rootKey] = root.path,
          ),
          smartLyricsAssistProvider.overrideWithValue(assist),
        ],
      );

  test('the translation lands keyed by the sheet the reader sees', () async {
    await paths.saveSmartLyrics(song, smartSheet);
    final assist = _ScriptedAssist(translation: ['One', 'Two']);
    final container = containerWith(assist: assist);

    final done = await container
        .read(smartLyricsContrastControllerProvider)
        .translate(song);

    expect(done, isTrue);
    final record = contrastFromJson(await paths.readSmartContrast(song))!;
    expect(
      record.sheetDate,
      '2026-10-29',
      reason: 'the sheet names itself; a regenerated sheet will have '
          'another name',
    );
    expect(record.translation, ['One', 'Two']);
    expect(assist.askedLines, 2, reason: 'line for line');
  });

  test('the second kind joins the first on the same sheet', () async {
    await paths.saveSmartLyrics(song, smartSheet);
    final assist = _ScriptedAssist(
      translation: ['One', 'Two'],
      transliteration: ['yi', 'er'],
    );
    final controller = containerWith(assist: assist).read(
      smartLyricsContrastControllerProvider,
    );

    await controller.translate(song);
    await controller.transliterate(song);

    final record = contrastFromJson(await paths.readSmartContrast(song))!;
    expect(record.translation, ['One', 'Two'], reason: 'the first kind is '
        'still there — one press does not cost the other');
    expect(record.transliteration, ['yi', 'er']);
  });

  test('a regenerated sheet lets the old record go', () async {
    await paths.saveSmartContrast(
      song,
      '{"sheetDate":"2026-10-28","transliteration":["jiu"]}',
    );
    await paths.saveSmartLyrics(song, smartSheet);
    final assist = _ScriptedAssist(translation: ['New']);
    final container = containerWith(assist: assist);

    await container.read(smartLyricsContrastControllerProvider).translate(song);

    final record = contrastFromJson(await paths.readSmartContrast(song))!;
    expect(record.translation, ['New']);
    expect(
      record.transliteration,
      isNull,
      reason: 'the old words spoke about a sheet that is not there any more',
    );
  });

  test('the reader sees only the contrasts of the sheet that plays', () async {
    await paths.saveSmartLyrics(song, smartSheet);
    await paths.saveSmartContrast(
      song,
      '{"sheetDate":"2026-10-28","translation":["old"]}',
    );
    final container = containerWith();

    final shown = await container.read(songContrastProvider(song).future);

    expect(shown.isEmpty, isTrue, reason: 'the record speaks about another '
        'sheet — the panel shows nothing rather than words under the '
        'wrong lines');
  });

  test('no text model means no contrast', () async {
    await paths.saveSmartLyrics(song, smartSheet);
    final container = containerWith();

    final done = await container
        .read(smartLyricsContrastControllerProvider)
        .translate(song);

    expect(done, isFalse);
    expect(await paths.readSmartContrast(song), isNull);
  });

  test('a contrast that fails leaves the record alone', () async {
    await paths.saveSmartLyrics(song, smartSheet);
    final assist = _ScriptedAssist(fails: true);
    final container = containerWith(assist: assist);

    final done = await container
        .read(smartLyricsContrastControllerProvider)
        .translate(song);

    expect(done, isFalse);
    expect(await paths.readSmartContrast(song), isNull);
  });
}

/// The text side with an answer in its pocket.
class _ScriptedAssist extends SmartTextAssist {
  _ScriptedAssist({this.translation, this.transliteration, this.fails = false})
    : super(
        // The scripted assist never reaches the wire; the client stands
        // in so the type is the real one.
        client: OpenAiCompatibleClient(
          dio: Dio(),
          baseUrl: 'https://unused.test',
          apiKey: '',
        ),
        model: 'test',
      );

  final List<String>? translation;
  final List<String>? transliteration;
  final bool fails;

  int askedLines = 0;

  @override
  Future<List<String>> translateLines({
    required List<String> lines,
    required String targetLanguage,
  }) async {
    askedLines = lines.length;
    if (fails) throw SmartLyricsTextException('the model said nothing');
    return translation!;
  }

  @override
  Future<List<String>> transliterateLines({required List<String> lines}) async {
    if (fails) throw SmartLyricsTextException('the model said nothing');
    return transliteration!;
  }
}

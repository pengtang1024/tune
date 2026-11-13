import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tune/data/services/impl/library_paths_io.dart';
import 'package:tune/data/services/impl/preference_store.dart';
import 'package:tune/data/services/impl/saf_method_channel.dart';
import 'package:tune/data/services/impl/system_library_row.dart';
import 'package:tune/data/services/library/saf_tree_store.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/smart_lyrics/openai_compatible_engine.dart';
import 'package:tune/data/services/smart_lyrics/smart_lyrics_service.dart';

/// The whole smart-lyrics run of a SAF track, on the device.
///
/// A `content://` track has no path an engine can read, so the native side
/// copies it into the private cache; the copy goes to a real endpoint, the
/// sheet lands in the picked tree and is read back through the channel.
/// The endpoint is a stand-in that answers a timed sheet and counts the
/// bytes it received — the emulator reaches itself, so the real engine does
/// the real upload (docs/android.md §5.3). Run it after a folder was picked:
///
/// ```
/// flutter test integration_test/saf_smart_lyrics_test.dart -d emulator-5554
/// ```
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a SAF track is copied, transcribed, written and read back', (
    tester,
  ) async {
    final PersistenceService persistence = createPersistenceService();
    await persistence.init();

    final tree = SafTreeStore(persistence).treeUri;
    expect(tree, isNotNull, reason: '先在应用里选择一个音乐库文件夹');

    final page = await const SafMethodChannel().listTreePage(
      tree!,
      offset: 0,
      limit: 1,
    );
    expect(page, isNotEmpty, reason: '选中的目录里要有可读的音频');
    final song = songOfSystemRow(page.first);
    expect(song, isNotNull);

    final paths = createLibraryPaths(persistence);

    // The app cache is the folder above a copy: a probe makes one so the
    // test knows where to look for leftovers, then deletes it at once.
    final probe = await paths.temporaryAudioFor(song!);
    expect(probe, isNotNull, reason: '复制应当来自 content:// 文档');
    final cache = probe!.parent.parent;
    await probe.parent.delete(recursive: true);

    // The stand-in endpoint: it reads the whole upload, so an empty or
    // unreadable copy is caught, and answers one timed line.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var received = 0;
    server.listen((request) async {
      if (request.uri.path.endsWith('/audio/transcriptions')) {
        final body = await request.fold<List<int>>(
          <int>[],
          (all, chunk) => all..addAll(chunk),
        );
        received = body.length;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'language': 'zh',
            'segments': [
              {'start': 0.5, 'end': 1.5, 'text': 'SAF 生成验证'},
            ],
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(minutes: 2),
      ),
    );
    final service = SmartLyricsService(
      engines: [
        OpenAiCompatibleEngine(
          model: 'test-asr',
          client: OpenAiCompatibleClient(
            dio: dio,
            baseUrl: 'http://127.0.0.1:${server.port}',
            apiKey: 'test',
          ),
        ),
      ],
      humanPool: const [],
      paths: paths,
    );

    final outcome = await service.generate(song);

    expect(outcome.saved, isTrue, reason: '失败码: ${outcome.failure}');
    expect(
      received,
      greaterThan(1000),
      reason: '引擎收到的应当是整首音频，而不是空的 content:// 地址',
    );

    final sheet = await paths.readSmartLyrics(song);
    expect(sheet, isNotNull, reason: '词稿要能从 SAF 目录读回');
    expect(sheet, contains('SAF 生成验证'));

    final leftovers = cache
        .listSync()
        .whereType<Directory>()
        .where((entry) => entry.path.split('/').last.startsWith('tune_smart_audio_'))
        .toList();
    expect(leftovers, isEmpty, reason: '跑完不该留下复制目录');

    await server.close(force: true);
    dio.close(force: true);
  });
}

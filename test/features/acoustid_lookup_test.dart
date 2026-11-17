import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/acoustid_lookup.dart';

void main() {
  late Directory workspace;

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('tune-acoustid-');
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  group('响应解析', () {
    test('命中返回曲名与艺人', () {
      const body = '{"status":"ok","results":[{"recordings":['
          '{"id":"abc","title":"夜航","artists":[{"name":"某人"}]}]}]}';
      expect(AcoustIdLookup.parseMatch(body), '夜航 — 某人');
    });

    test('只有 id 时返回 id', () {
      const body = '{"status":"ok","results":[{"recordings":[{"id":"abc"}]}]}';
      expect(AcoustIdLookup.parseMatch(body), 'abc');
    });

    test('没命中、状态不对、不是 JSON 都返回 null', () {
      expect(
        AcoustIdLookup.parseMatch('{"status":"ok","results":[]}'),
        isNull,
      );
      expect(
        AcoustIdLookup.parseMatch('{"status":"error","error":{"code":4}}'),
        isNull,
      );
      expect(AcoustIdLookup.parseMatch('<html>'), isNull);
      expect(AcoustIdLookup.parseMatch('{"status":"ok"}'), isNull);
    });
  });

  group('查重', () {
    test('没配 client key 或没有 fpcalc 就是没接，一律 null', () async {
      final file = File('${workspace.path}/a.flac')..writeAsBytesSync(<int>[1]);
      final noKey = AcoustIdLookup(clientKey: '');
      expect(noKey.isConfigured, isFalse);
      expect(await noKey.match(file), isNull);

      final noFpcalc = AcoustIdLookup(clientKey: 'key');
      expect(noFpcalc.isConfigured, isFalse);
      expect(await noFpcalc.match(file), isNull);
    });

    test('配上指纹与响应就能查出命中', () async {
      final file = File('${workspace.path}/a.flac')..writeAsBytesSync(<int>[1]);
      final fpcalc = File('${workspace.path}/fpcalc')..writeAsStringSync('');
      Uri? asked;
      final lookup = AcoustIdLookup(
        clientKey: 'key',
        fpcalc: fpcalc,
        fingerprint: (_) async =>
            const Fingerprint(durationSeconds: 12, value: 'AQADtEmi'),
        fetch: (uri) async {
          asked = uri;
          return '{"status":"ok","results":[{"recordings":['
              '{"id":"abc","title":"夜航","artists":[{"name":"某人"}]}]}]}';
        },
      );
      expect(await lookup.match(file), '夜航 — 某人');
      expect(asked, isNotNull);
      expect(asked!.queryParameters['duration'], '12');
      expect(asked!.queryParameters['fingerprint'], 'AQADtEmi');
      expect(asked!.queryParameters['client'], 'key');
    });

    test('查不了的时候返回 null，不是空字符串', () async {
      final file = File('${workspace.path}/a.flac')..writeAsBytesSync(<int>[1]);
      final fpcalc = File('${workspace.path}/fpcalc')..writeAsStringSync('');
      final failing = AcoustIdLookup(
        clientKey: 'key',
        fpcalc: fpcalc,
        fingerprint: (_) async => null,
      );
      expect(await failing.match(file), isNull);

      final offline = AcoustIdLookup(
        clientKey: 'key',
        fpcalc: fpcalc,
        fingerprint: (_) async =>
            const Fingerprint(durationSeconds: 12, value: 'AQADtEmi'),
        fetch: (_) async => throw const SocketException('offline'),
      );
      expect(await offline.match(file), isNull);
    });
  });

  group('本机工具', () {
    test('PATH 里有 fpcalc 就能找到，没有就是 null', () {
      final bin = Directory('${workspace.path}/bin')..createSync();
      final program = File('${bin.path}/fpcalc')..writeAsStringSync('#!/bin/sh\n');
      expect(
        AcoustIdLookup.findFpcalc(environment: <String, String>{'PATH': bin.path}),
        isNotNull,
      );
      expect(
        AcoustIdLookup.findFpcalc(
          environment: <String, String>{'PATH': '${workspace.path}/nothing'},
        ),
        isNull,
      );
      expect(program.existsSync(), isTrue);
    });

    test('fpcalc 输出能解析，坏输出当算不出', () async {
      final script = File('${workspace.path}/fpcalc-ok')
        ..writeAsStringSync(
          '#!/bin/sh\necho \'{"duration": 12.4, "fingerprint": "AQADtEmi"}\'\n',
        );
      await Process.run('chmod', <String>['+x', script.path]);
      final file = File('${workspace.path}/a.flac')..writeAsBytesSync(<int>[1]);
      final parsed = await AcoustIdLookup.runFpcalc(script, file);
      expect(parsed, isNotNull);
      expect(parsed!.durationSeconds, 12);
      expect(parsed.value, 'AQADtEmi');

      final broken = File('${workspace.path}/fpcalc-bad')
        ..writeAsStringSync('#!/bin/sh\necho not-json\n');
      await Process.run('chmod', <String>['+x', broken.path]);
      expect(await AcoustIdLookup.runFpcalc(broken, file), isNull);
    });
  });
}

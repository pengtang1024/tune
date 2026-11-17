import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tune/features/share/data/share_config.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('tune-share-config');
  });

  tearDown(() async {
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  test('key 落了盘再读回来是同一把，空串会把它清掉', () async {
    final config = ShareConfig(File('${dir.path}/config.json'));
    expect(await config.acoustIdKey(), isEmpty);

    await config.setAcoustIdKey(' abc123 ');
    expect(await config.acoustIdKey(), 'abc123');

    await config.setAcoustIdKey('');
    expect(await config.acoustIdKey(), isEmpty);
  });

  test('配置坏了当空，不让一份坏 JSON 卡住分享页', () async {
    final file = File('${dir.path}/config.json');
    await file.writeAsString('{ not json');

    final config = ShareConfig(file);
    expect(await config.acoustIdKey(), isEmpty);

    // 坏文件仍然可以写回。
    await config.setAcoustIdKey('k');
    expect(await config.acoustIdKey(), 'k');
  });
}

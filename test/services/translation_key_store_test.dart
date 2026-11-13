import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:tune/data/services/translation/translation_key_store.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('translation_keys_test');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  TranslationKeyStore storeIn(Directory directory) {
    return TranslationKeyStore(directory: () async => directory);
  }

  File keyFile() {
    return File(path.join(directory.path, TranslationKeyStore.fileName));
  }

  test('a written key is read back by the next start', () async {
    final store = storeIn(directory);
    await store.init();
    await store.write({'deepseek': 'sk-deep', 'moonshot': 'sk-moon'});

    expect(store.keys, {'deepseek': 'sk-deep', 'moonshot': 'sk-moon'});

    final reopened = storeIn(directory);
    await reopened.init();
    expect(reopened.keys, {'deepseek': 'sk-deep', 'moonshot': 'sk-moon'});
  });

  test('a key without a value is not kept', () async {
    final store = storeIn(directory);
    await store.write({
      'deepseek': '  ',
      'moonshot': 'sk-moon',
      'gemini': '',
      '': 'sk-orphan',
    });

    expect(store.keys, {'moonshot': 'sk-moon'});
    expect(jsonDecode(await keyFile().readAsString()), {'moonshot': 'sk-moon'});
  });

  test('a broken file means no key, and no crash', () async {
    await keyFile().writeAsString('{not a document');

    final store = storeIn(directory);
    await store.init();

    expect(store.keys, isEmpty);
  });

  test('the file is readable by its owner only', () async {
    final store = storeIn(directory);
    await store.write({'deepseek': 'sk-deep'});

    expect(keyFile().statSync().modeString(), 'rw-------');
  }, skip: !Platform.isLinux && !Platform.isMacOS);
}

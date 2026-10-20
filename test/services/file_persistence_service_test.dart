import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tune/data/services/impl/preference_store_io.dart';

/// The store keeps one file per preference, so two processes of the app do
/// not write over each other's keys.
void main() {
  late Directory folder;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    folder = await Directory.systemTemp.createTemp('tune_preferences');
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  FilePersistenceService store() =>
      FilePersistenceService(directory: () async => folder);

  test('every kind of value is written back as it was', () async {
    final service = store();
    await service.init();

    await service.setString('language_code', 'zh');
    await service.setInt('theme_mode', 2);
    await service.setDouble('volume', 0.5);
    await service.setBool('auto_scan_on_startup', false);
    await service.setStringList('custom_scan_paths', ['/music/extra']);

    expect(service.getString('language_code'), 'zh');
    expect(service.getInt('theme_mode'), 2);
    expect(service.getDouble('volume'), 0.5);
    expect(service.getBool('auto_scan_on_startup'), isFalse);
    expect(service.getStringList('custom_scan_paths'), ['/music/extra']);
    expect(service.getKeys(), {
      'language_code',
      'theme_mode',
      'volume',
      'auto_scan_on_startup',
      'custom_scan_paths',
    });
  });

  test('a store that opens later still reads what was written', () async {
    final service = store();
    await service.init();
    await service.setString('language_code', 'zh');

    final opened = store();
    await opened.init();

    expect(opened.getString('language_code'), 'zh');
    expect(opened.containsKey('language_code'), isTrue);
  });

  test('two stores on one folder keep each key of their own', () async {
    final first = store();
    final second = store();
    await first.init();
    await second.init();

    await first.setString('from_first', 'a');
    await second.setString('from_second', 'b');

    final opened = store();
    await opened.init();

    expect(opened.getString('from_first'), 'a');
    expect(opened.getString('from_second'), 'b');
  });

  test('a removed preference is gone for the next store as well', () async {
    final service = store();
    await service.init();
    await service.setString('language_code', 'zh');

    await service.remove('language_code');
    expect(service.containsKey('language_code'), isFalse);

    final opened = store();
    await opened.init();
    expect(opened.containsKey('language_code'), isFalse);
  });

  test('clearing takes every preference away', () async {
    final service = store();
    await service.init();
    await service.setString('language_code', 'zh');
    await service.setInt('theme_mode', 2);

    await service.clear();

    expect(service.getKeys(), isEmpty);
    final opened = store();
    await opened.init();
    expect(opened.getKeys(), isEmpty);
  });

  test('the preferences of the previous store move into the new one', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 2,
      'language_code': 'zh',
      'custom_scan_paths': ['/music/extra'],
    });

    final service = store();
    await service.init();

    expect(service.getInt('theme_mode'), 2);
    expect(service.getString('language_code'), 'zh');
    expect(service.getStringList('custom_scan_paths'), ['/music/extra']);
  });

  test('a preference the new store already holds is not overwritten', () async {
    SharedPreferences.setMockInitialValues({'language_code': 'zh'});

    final service = store();
    await service.init();
    await service.setString('language_code', 'en');

    final opened = store();
    await opened.init();

    expect(opened.getString('language_code'), 'en');
  });
}

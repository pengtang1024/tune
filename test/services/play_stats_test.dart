import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:tune/data/services/persistence_service.dart';
import 'package:tune/data/services/play_stats_service.dart';
import 'package:tune/data/services/m3u_exporter.dart';
import 'package:tune/domain/models/song.dart';

class FakePersistence implements PersistenceService {
  final Map<String, dynamic> store = {};
  @override Future<void> init() async {}
  @override Future<bool> setInt(String k, int v) async { store[k] = v; return true; }
  @override int? getInt(String k) => store[k] as int?;
  @override Future<bool> setBool(String k, bool v) async { store[k] = v; return true; }
  @override bool? getBool(String k) => store[k] as bool?;
  @override Future<bool> setString(String k, String v) async => true;
  @override String? getString(String k) => null;
  @override Future<bool> setDouble(String k, double v) async => true;
  @override double? getDouble(String k) => null;
  @override Future<bool> setStringList(String k, List<String> v) async => true;
  @override List<String>? getStringList(String k) => null;
  @override bool containsKey(String k) => store.containsKey(k);
  @override Future<bool> remove(String k) async { store.remove(k); return true; }
  @override Future<bool> clear() async { store.clear(); return true; }
  @override Set<String> getKeys() => store.keys.toSet();
}

void main() {
  group('PlayStatsService', () {
    late PlayStatsService svc;
    setUp(() => svc = PlayStatsService(FakePersistence()));

    test('initial play count 0', () => expect(svc.getPlayCount(42), 0));
    test('incrementPlayCount', () async {
      await svc.incrementPlayCount(1);
      expect(svc.getPlayCount(1), 1);
    });
    test('toggleFavorite', () async {
      await svc.toggleFavorite(1);
      expect(svc.isFavorite(1), true);
      await svc.toggleFavorite(1);
      expect(svc.isFavorite(1), false);
    });
  });

  group('M3uExporter', () {
    test('exports valid M3U', () async {
      final song = Song.fromMap({'id': 1, 'title': 'T', 'artist': 'A', 'uri': '/s.mp3', 'duration': 240000});
      final dir = await Directory.systemTemp.createTemp('tune_');
      final fp = '${dir.path}/t.m3u';
      try {
        await M3uExporter.exportPlaylist([song], fp, 'Test');
        final c = await File(fp).readAsString();
        expect(c.contains('#EXTM3U'), true);
        expect(c.contains('#PLAYLIST:Test'), true);
        expect(c.contains('#EXTINF:240'), true);
      } finally { await dir.delete(recursive: true); }
    });
  });
}

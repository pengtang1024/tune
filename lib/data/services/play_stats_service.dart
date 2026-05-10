import 'package:tune/data/services/persistence_service.dart';

class PlayStatsService {
  final PersistenceService _persistence;

  PlayStatsService(this._persistence);

  int getPlayCount(int songId) {
    return _persistence.getInt('play_count_$songId') ?? 0;
  }

  Future<void> incrementPlayCount(int songId) async {
    final current = getPlayCount(songId);
    await _persistence.setInt('play_count_$songId', current + 1);
  }

  bool isFavorite(int songId) {
    return _persistence.getBool('fav_$songId') ?? false;
  }

  Future<void> toggleFavorite(int songId) async {
    final current = isFavorite(songId);
    await _persistence.setBool('fav_$songId', !current);
  }

  Future<void> setFavorite(int songId, bool value) async {
    await _persistence.setBool('fav_$songId', value);
  }
}

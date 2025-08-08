import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/audio_repository.dart';

class SearchSongs {
  final AudioRepository repository;

  SearchSongs(this.repository);

  Future<List<Song>> call(String query) async {
    return await repository.searchSongs(query);
  }
}
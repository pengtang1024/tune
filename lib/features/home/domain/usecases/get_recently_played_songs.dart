import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';

class GetRecentlyPlayedSongs {
  final HomeRepository repository;

  GetRecentlyPlayedSongs({required this.repository});

  Future<List<Song>> call() async {
    return await repository.getRecentlyPlayedSongs();
  }
}
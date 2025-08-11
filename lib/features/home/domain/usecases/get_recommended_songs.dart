import 'package:tune/domain/entities/song.dart';
import 'package:tune/features/home/domain/repositories/home_repository.dart';

class GetRecommendedSongs {
  final HomeRepository repository;

  GetRecommendedSongs({required this.repository});

  Future<List<Song>> call() async {
    return await repository.getRecommendedSongs();
  }
}
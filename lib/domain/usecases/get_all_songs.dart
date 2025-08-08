import 'package:tune/domain/entities/song.dart';
import 'package:tune/domain/repositories/audio_repository.dart';

class GetAllSongs {
  final AudioRepository repository;

  GetAllSongs(this.repository);

  Future<List<Song>> call() async {
    return await repository.getAllSongs();
  }
}
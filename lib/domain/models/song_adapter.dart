import 'package:hive/hive.dart';
import 'song.dart';

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 1; // 修改为唯一的类型ID，避免与已注册的适配器冲突

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()
    };

    return Song({
      'id': fields[0] as int? ?? 0,
      'title': fields[1] as String? ?? '',
      'artist': fields[2] as String? ?? '',
      'album': fields[3] as String? ?? '',
      'duration': fields[4] as int? ?? 0,
      'uri': fields[5] as String? ?? '',
      'dateAdded': fields[6] as int? ?? 0,
      'genre': fields[7] as String?,
      'year': fields[8] as int?,
      'bitrate': fields[9] as int?,
      'sampleRate': fields[10] as int?,
      'trackNumber': fields[11] as int?,
      'trackTotal': fields[12] as int?,
      'discNumber': fields[13] as int?,
      'totalDisc': fields[14] as int?,
      'lyrics': fields[15] as String?,
      'genres': fields[16] as List<String>?,
      'performers': fields[17] as List<String>?,
      'language': fields[18] as String?,
      'size': fields[19] as int?,
      'type': fields[20] as String?,
      'isFavorite': fields[21] as bool? ?? false,
      'albumArt': fields[22] as String?,
    });
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(23) // 字段数量
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.uri)
      ..writeByte(6)
      ..write(obj.dateAdded)
      ..writeByte(7)
      ..write(obj.genre)
      ..writeByte(8)
      ..write(obj.year)
      ..writeByte(9)
      ..write(obj.bitrate)
      ..writeByte(10)
      ..write(obj.sampleRate)
      ..writeByte(11)
      ..write(obj.trackNumber)
      ..writeByte(12)
      ..write(obj.trackTotal)
      ..writeByte(13)
      ..write(obj.discNumber)
      ..writeByte(14)
      ..write(obj.totalDisc)
      ..writeByte(15)
      ..write(obj.lyrics)
      ..writeByte(16)
      ..write(obj.genres)
      ..writeByte(17)
      ..write(obj.performers)
      ..writeByte(18)
      ..write(obj.language)
      ..writeByte(19)
      ..write(obj.size)
      ..writeByte(20)
      ..write(obj.type)
      ..writeByte(21)
      ..write(obj.isFavorite)
      ..writeByte(22)
      ..write(obj.albumArt);
  }
}
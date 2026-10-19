import 'package:tune/domain/models/music_source.dart';

/// Built-in source definitions.
///
/// Sources that need credentials start disabled; sources that work without a
/// key are enabled so startup auto-scan can pick them up immediately.
class BuiltInMusicSources {
  const BuiltInMusicSources._();

  static const local = MusicSourceConfig(
    id: 'local',
    name: '本地音乐',
    description: '扫描设备上的音乐文件夹',
    kind: MusicSourceKind.localDirectory,
  );

  static const openverse = MusicSourceConfig(
    id: 'openverse',
    name: 'Openverse',
    description: '开放版权音频聚合：Jamendo、Freesound、Wikimedia 等',
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'piano'},
  );

  static const jamendo = MusicSourceConfig(
    id: 'jamendo',
    name: 'Jamendo',
    description: '独立音乐开放曲库，需要免费 Client ID',
    kind: MusicSourceKind.openCatalog,
    enabled: false,
    settings: {'query': ''},
  );

  static const internetArchive = MusicSourceConfig(
    id: 'internet_archive',
    name: 'Internet Archive',
    description: '互联网档案馆的开放音频收藏',
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'collection:netlabels AND mediatype:audio'},
  );

  static const netease = MusicSourceConfig(
    id: 'netease',
    name: '网易云音乐 API',
    description: '连接自建的 NeteaseCloudMusicApi 服务',
    kind: MusicSourceKind.openApi,
    enabled: false,
    settings: {'keywords': '热门'},
  );

  static const defaults = <MusicSourceConfig>[
    local,
    openverse,
    jamendo,
    internetArchive,
    netease,
  ];
}

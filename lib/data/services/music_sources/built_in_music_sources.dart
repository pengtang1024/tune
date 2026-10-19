import 'package:tune/domain/models/music_source.dart';
import 'package:tune/core/l10n/app_strings.dart';

/// Built-in source definitions.
///
/// Sources that need credentials start disabled; sources that work without a
/// key are enabled so startup auto-scan can pick them up immediately.
class BuiltInMusicSources {
  const BuiltInMusicSources._();

  static final local = MusicSourceConfig(
    id: 'local',
    name: AppStrings.instance.sourceLocalName,
    description: AppStrings.instance.sourceLocalDescription,
    kind: MusicSourceKind.localDirectory,
  );

  static final openverse = MusicSourceConfig(
    id: 'openverse',
    name: 'Openverse',
    description: AppStrings.instance.sourceOpenverseDescription,
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'piano'},
  );

  static final jamendo = MusicSourceConfig(
    id: 'jamendo',
    name: 'Jamendo',
    description: AppStrings.instance.sourceJamendoDescription,
    kind: MusicSourceKind.openCatalog,
    enabled: false,
    settings: {'query': ''},
  );

  static final internetArchive = MusicSourceConfig(
    id: 'internet_archive',
    name: 'Internet Archive',
    description: AppStrings.instance.sourceInternetArchiveDescription,
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'collection:netlabels AND mediatype:audio'},
  );

  static final netease = MusicSourceConfig(
    id: 'netease',
    name: AppStrings.instance.sourceNeteaseName,
    description: AppStrings.instance.sourceNeteaseDescription,
    kind: MusicSourceKind.openApi,
    enabled: false,
    settings: {'keywords': AppStrings.instance.neteaseHotKeyword},
  );

  static final ccmixter = MusicSourceConfig(
    id: 'ccmixter',
    name: 'ccMixter',
    description: AppStrings.instance.sourceCcmixterDescription,
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'jazz'},
  );

  static final itunes = MusicSourceConfig(
    id: 'itunes',
    name: 'iTunes',
    description: AppStrings.instance.sourceItunesDescription,
    kind: MusicSourceKind.openCatalog,
    settings: {'query': 'jazz'},
  );

  static final podcastRss = MusicSourceConfig(
    id: 'podcast_rss',
    name: AppStrings.instance.sourcePodcastRssName,
    description: AppStrings.instance.sourcePodcastRssDescription,
    kind: MusicSourceKind.openApi,
    enabled: false,
    settings: {'feed': ''},
  );

  static final subsonic = MusicSourceConfig(
    id: 'subsonic',
    name: 'Subsonic',
    description: AppStrings.instance.sourceSubsonicDescription,
    kind: MusicSourceKind.openApi,
    enabled: false,
    settings: {'server': '', 'user': '', 'password': ''},
  );

  static final defaults = <MusicSourceConfig>[
    local,
    openverse,
    jamendo,
    internetArchive,
    netease,
    ccmixter,
    itunes,
    podcastRss,
    subsonic,
  ];
}

import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/l10n/app_localizations.dart';

/// Built-in source definitions.
///
/// Sources that need credentials start disabled; sources that work without a
/// key are enabled so startup auto-scan can pick them up immediately.
///
/// The name and the description of a source are written in a language, so the
/// catalogue is a function of the translations: reading it answers with the
/// language of the caller, never with the language of the first call.
class BuiltInMusicSources {
  const BuiltInMusicSources._();

  /// The catalogue of the built-in sources in the language of the app.
  static List<MusicSourceConfig> get defaults => of(AppStrings.instance);

  /// The catalogue of the built-in sources in a language.
  static List<MusicSourceConfig> of(AppLocalizations strings) {
    return [
      MusicSourceConfig(
        id: 'local',
        type: 'local',
        builtIn: true,
        name: strings.sourceLocalName,
        description: strings.sourceLocalDescription,
        kind: MusicSourceKind.localDirectory,
      ),
      MusicSourceConfig(
        id: 'openverse',
        type: 'openverse',
        builtIn: true,
        name: 'Openverse',
        localizedName: strings.sourceOpenverseName,
        description: strings.sourceOpenverseDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'jamendo',
        type: 'jamendo',
        builtIn: true,
        name: 'Jamendo',
        localizedName: strings.sourceJamendoName,
        description: strings.sourceJamendoDescription,
        kind: MusicSourceKind.openCatalog,
        enabled: false,
        settings: {'format': 'mp32'},
      ),
      MusicSourceConfig(
        id: 'internet_archive',
        type: 'internet_archive',
        builtIn: true,
        name: 'Internet Archive',
        localizedName: strings.sourceInternetArchiveName,
        description: strings.sourceInternetArchiveDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'netease',
        type: 'netease',
        builtIn: true,
        name: strings.sourceNeteaseName,
        description: strings.sourceNeteaseDescription,
        kind: MusicSourceKind.openApi,
        enabled: false,
      ),
      MusicSourceConfig(
        id: 'ccmixter',
        type: 'ccmixter',
        builtIn: true,
        name: 'ccMixter',
        localizedName: strings.sourceCcmixterName,
        description: strings.sourceCcmixterDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'itunes',
        type: 'itunes',
        builtIn: true,
        name: 'iTunes',
        localizedName: strings.sourceItunesName,
        description: strings.sourceItunesDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'podcast_rss',
        type: 'podcast_rss',
        builtIn: true,
        name: strings.sourcePodcastRssName,
        description: strings.sourcePodcastRssDescription,
        kind: MusicSourceKind.openApi,
        enabled: false,
        settings: {'feed': ''},
      ),
      MusicSourceConfig(
        id: 'subsonic',
        type: 'subsonic',
        builtIn: true,
        name: 'Subsonic',
        localizedName: strings.sourceSubsonicName,
        description: strings.sourceSubsonicDescription,
        kind: MusicSourceKind.openApi,
        enabled: false,
        settings: {
          'server': '',
          'user': '',
          'password': '',
          'format': 'original',
        },
      ),
      MusicSourceConfig(
        id: 'audius',
        type: 'audius',
        builtIn: true,
        name: 'Audius',
        localizedName: strings.sourceAudiusName,
        description: strings.sourceAudiusDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'radio',
        type: 'radio',
        builtIn: true,
        name: strings.sourceRadioName,
        description: strings.sourceRadioDescription,
        kind: MusicSourceKind.openCatalog,
        settings: {'provider': 'all', 'query': ''},
      ),
      MusicSourceConfig(
        id: 'wikimedia',
        type: 'wikimedia',
        builtIn: true,
        name: 'Wikimedia Commons',
        localizedName: strings.sourceWikimediaName,
        description: strings.sourceWikimediaDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      MusicSourceConfig(
        id: 'jellyfin',
        type: 'jellyfin',
        builtIn: true,
        name: 'Jellyfin',
        localizedName: strings.sourceJellyfinName,
        description: strings.sourceJellyfinDescription,
        kind: MusicSourceKind.openApi,
        enabled: false,
        settings: {'server': '', 'user': '', 'password': ''},
      ),
    ];
  }

  /// The catalogue of the built-in sources in a language, keyed by its type.
  ///
  /// A built-in source and its type share the same key, so the catalogue
  /// answers for the type: an instance the user added of a built-in type
  /// borrows the same name and the same icon.
  static Map<String, MusicSourceConfig> catalogueOf(AppLocalizations strings) {
    return {for (final config in of(strings)) config.id: config};
  }

  /// The catalogue entry of a built-in source in the language of the app.
  static MusicSourceConfig? descriptorOf(String id) {
    return catalogueOf(AppStrings.instance)[id];
  }

  /// The settings the app used to write into a built-in instance.
  ///
  /// They were the app's taste, not the reader's: a source that serves a
  /// browse stream of its own does not need a keyword. An instance that still
  /// carries exactly these settings was never touched by the reader, so they
  /// are taken away when the instance is read back and the platform's own
  /// list takes its place. Settings the reader changed are kept.
  static Map<String, String> retiredSettingsOf(String type) {
    return switch (type) {
      'openverse' => const {'query': 'piano'},
      'internet_archive' => const {
        'query': 'collection:netlabels AND mediatype:audio',
      },
      'ccmixter' => const {'query': 'jazz'},
      'itunes' => const {'query': 'jazz'},
      'audius' => const {'query': 'ambient'},
      'wikimedia' => const {'query': 'piano'},
      'netease' => {'keywords': AppStrings.instance.neteaseHotKeyword},
      _ => const {},
    };
  }

  /// The name of a source in a language.
  ///
  /// A source the user imported keeps the name it was given; only the
  /// built-in ones are named by the catalogue.
  static String nameOf(MusicSourceConfig config, AppLocalizations strings) {
    return catalogueOf(strings)[config.sourceType]?.name ?? config.name;
  }

  /// The description of a source in a language.
  static String descriptionOf(
    MusicSourceConfig config,
    AppLocalizations strings,
  ) {
    return catalogueOf(strings)[config.sourceType]?.description ?? config.description;
  }

  /// The source of the local music folders.
  static MusicSourceConfig get local => _entry('local');

  /// The source of the open catalogues.
  static MusicSourceConfig get openverse => _entry('openverse');

  /// The source of the music of the artists who publish it freely.
  static MusicSourceConfig get jamendo => _entry('jamendo');

  /// The source of the archive of the net.
  static MusicSourceConfig get internetArchive => _entry('internet_archive');

  /// The source of a self-hosted NetEase cloud music service.
  static MusicSourceConfig get netease => _entry('netease');

  /// The source of the recordings of the artists who share them.
  static MusicSourceConfig get ccmixter => _entry('ccmixter');

  /// The source of the previews of the songs of the store.
  static MusicSourceConfig get itunes => _entry('itunes');

  /// The source of the podcasts a feed publishes.
  static MusicSourceConfig get podcastRss => _entry('podcast_rss');

  /// The source of a self-hosted music server.
  static MusicSourceConfig get subsonic => _entry('subsonic');

  /// The source of the tracks the artists publish themselves.
  static MusicSourceConfig get audius => _entry('audius');

  /// The source of the internet radio stations.
  static MusicSourceConfig get radio => _entry('radio');

  /// The source of the sound files of the free repository.
  static MusicSourceConfig get wikimedia => _entry('wikimedia');

  /// The source of a self-hosted media library.
  static MusicSourceConfig get jellyfin => _entry('jellyfin');

  /// The catalogue entry of a built-in source.
  static MusicSourceConfig _entry(String id) {
    final entry = descriptorOf(id);
    if (entry == null) throw StateError('unknown built-in source: $id');
    return entry;
  }
}

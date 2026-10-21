import 'package:tune/core/l10n/app_strings.dart';
import 'package:tune/data/services/music_sources/source_type_catalogue.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/l10n/app_localizations.dart';

/// Built-in source instances.
///
/// An instance is a configuration that came with the app: it can be switched
/// off and configured, but not deleted. The type it belongs to says how it
/// fetches its tracks, and the catalogue of the types says how it is named.
///
/// Sources that need credentials start disabled; sources that work without a
/// key are enabled so startup auto-scan can pick them up immediately.
///
/// The name and the description of a source are written in a language, so the
/// catalogue is a function of the translations: reading it answers with the
/// language of the caller, never with the language of the first call.
class BuiltInMusicSources {
  const BuiltInMusicSources._();

  /// The catalogue of the built-in instances in the language of the app.
  static List<MusicSourceConfig> get defaults => of(AppStrings.instance);

  /// The catalogue of the built-in instances in a language.
  static List<MusicSourceConfig> of(AppLocalizations strings) {
    final types = SourceTypeCatalogue.byType(strings);
    return [
      _instance(types, 'local'),
      _instance(types, 'openverse'),
      _instance(types, 'jamendo', enabled: false, settings: {'format': 'mp32'}),
      _instance(types, 'internet_archive'),
      _instance(types, 'netease', enabled: false),
      _instance(types, 'ccmixter'),
      _instance(types, 'itunes'),
      _instance(types, 'podcast_rss', enabled: false, settings: {'feed': ''}),
      _instance(
        types,
        'subsonic',
        enabled: false,
        settings: {
          'server': '',
          'user': '',
          'password': '',
          'format': 'original',
        },
      ),
      _instance(types, 'audius'),
      _instance(types, 'radio', settings: {'provider': 'all', 'query': ''}),
      _instance(types, 'wikimedia'),
      _instance(
        types,
        'jellyfin',
        enabled: false,
        settings: {'server': '', 'user': '', 'password': ''},
      ),
    ];
  }

  /// The built-in instance of a type.
  ///
  /// The id of a built-in instance is its type, so the two are one key.
  static MusicSourceConfig _instance(
    Map<String, SourceTypeDescriptor> types,
    String type, {
    bool enabled = true,
    Map<String, String> settings = const {},
  }) {
    final descriptor = types[type]!;
    return MusicSourceConfig(
      id: type,
      type: type,
      builtIn: true,
      name: descriptor.name,
      localizedName: descriptor.localizedName,
      description: descriptor.description,
      kind: descriptor.kind,
      enabled: enabled,
      settings: settings,
    );
  }

  /// The catalogue of the built-in instances in a language, keyed by its id.
  static Map<String, MusicSourceConfig> catalogueOf(AppLocalizations strings) {
    return {for (final config in of(strings)) config.id: config};
  }

  /// The catalogue entry of a built-in instance in the language of the app.
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
  /// A source the reader added keeps the name it was given; only the built-in
  /// ones are named by the catalogue.
  static String nameOf(MusicSourceConfig config, AppLocalizations strings) {
    if (!config.builtIn) return config.name;
    return catalogueOf(strings)[config.sourceType]?.name ?? config.name;
  }

  /// The description of a source in a language.
  static String descriptionOf(
    MusicSourceConfig config,
    AppLocalizations strings,
  ) {
    if (!config.builtIn) return config.description;
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

  /// The catalogue entry of a built-in instance.
  static MusicSourceConfig _entry(String id) {
    final entry = descriptorOf(id);
    if (entry == null) throw StateError('unknown built-in source: $id');
    return entry;
  }
}

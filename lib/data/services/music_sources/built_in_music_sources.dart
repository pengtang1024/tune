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
      // The catch-all reach of the archive: every audio item it holds. Its
      // head is whatever the archive counts as most downloaded (religious
      // recitations) and its tail is whatever was uploaded last (unfinished
      // uploads), so it waits in the folded group while the sixteen reaches
      // that name a collection carry the main list.
      _instance(types, 'internet_archive', weight: 400),
      _instance(
        types,
        'internet_archive',
        id: 'live_music_archive',
        name: strings.sourceLiveMusicArchiveName,
        description: strings.sourceLiveMusicArchiveDescription,
        settings: {
          // The pool is tens of thousands of items deep and the second page
          // is still the same era: two pages per scan (measured 182 → 269).
          'pages': '2','query': 'collection:etree AND mediatype:etree'},
      ),
      _instance(
        types,
        'internet_archive',
        id: 'great78',
        name: strings.sourceGreat78Name,
        description: strings.sourceGreat78Description,
        settings: {
          // The pool is tens of thousands of items deep and the second page
          // is still the same era: two pages per scan (measured 182 → 269).
          'pages': '2','query': 'collection:78rpm AND mediatype:audio'},
      ),
      _instance(
        types,
        'internet_archive',
        id: 'netlabels',
        name: strings.sourceNetlabelsName,
        description: strings.sourceNetlabelsDescription,
        settings: {
          // The pool is tens of thousands of items deep and the second page
          // is still the same era: two pages per scan (measured 182 → 269).
          'pages': '2','query': 'collection:netlabels AND mediatype:audio'},
      ),
      _instance(
        types,
        'internet_archive',
        id: 'old_time_radio',
        name: strings.sourceOldTimeRadioName,
        description: strings.sourceOldTimeRadioDescription,
        settings: {'query': 'collection:oldtimeradio AND mediatype:audio'},
      ),
      _instance(
        types,
        'internet_archive',
        id: 'archive_music',
        name: strings.sourceAudioMusicName,
        description: strings.sourceAudioMusicDescription,
        settings: {'query': 'collection:audio_music AND mediatype:audio'},
      ),
      _instance(
        types,
        'internet_archive',
        id: 'unlocked_recordings',
        name: strings.sourceUnlockedRecordingsName,
        description: strings.sourceUnlockedRecordingsDescription,
        settings: {
          'query': 'collection:unlockedrecordings AND mediatype:audio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_music',
        name: strings.sourceCommunityMusicName,
        description: strings.sourceCommunityMusicDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // The community uploads hold talks and poems next to music; the
          // subject narrows them to the four styles people upload most.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              '(subject:rock OR subject:jazz OR subject:blues OR '
              'subject:electronic)',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_classical',
        name: strings.sourceCommunityClassicalName,
        description: strings.sourceCommunityClassicalDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // The classical pool is the other half of the community uploads:
          // it is kept apart from the four styles above, and those four are
          // excluded here so one recording does not arrive twice.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              'subject:(classical) AND NOT '
              'subject:(rock OR jazz OR blues OR electronic)',
          // The list itself is the theme: an item that states no genre
          // keeps this one.
          'theme': 'Classical',
        },
        // Half the size of the community list above and a fifth of it already
        // arrives through the four styles; it waits in the folded group.
        weight: 400,
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_ambient',
        name: strings.sourceCommunityAmbientName,
        description: strings.sourceCommunityAmbientDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // The rest of the community uploads: the long forms and the one-off
          // takes the four styles and the classical pool both leave out.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              'subject:(ambient OR experimental) AND NOT '
              'subject:(rock OR jazz OR blues OR electronic OR classical)',
          // The list itself is the theme: an item that states no genre
          // keeps this one.
          'theme': 'Ambient',
        },
        weight: 400,
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_world',
        name: strings.sourceCommunityWorldName,
        description: strings.sourceCommunityWorldDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // The uploads from outside the styles above: regional music, dub
          // and reggae. Each of the six styles offered so far is excluded, so
          // a recording arrives through one list only.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              'subject:(world OR reggae) AND NOT '
              'subject:(rock OR jazz OR blues OR electronic OR classical OR '
              'ambient OR experimental)',
          // The list itself is the theme: an item that states no genre
          // keeps this one.
          'theme': 'World',
        },
        weight: 400,
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_metal',
        name: strings.sourceCommunityMetalName,
        description: strings.sourceCommunityMetalDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // Metal and punk are filed apart from the nine styles above; the
          // live sets and netlabel EPs sit here.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              'subject:(metal OR punk) AND NOT '
              'subject:(rock OR jazz OR blues OR electronic OR classical OR '
              'ambient OR experimental OR world OR reggae)',
          // The list itself is the theme: an item that states no genre
          // keeps this one.
          'theme': 'Metal',
        },
        weight: 400,
      ),
      _instance(
        types,
        'internet_archive',
        id: 'community_hiphop',
        name: strings.sourceCommunityHiphopName,
        description: strings.sourceCommunityHiphopDescription,
        settings: {
          // Two pages per scan: the pools here are thousands of items deep and
          // a second page doubles what one scan brings (measured: 132 → 256).
          'pages': '2',
          // Hip-hop and funk, filed apart from the eight styles above. A
          // country list is not offered: its most-downloaded head carries a
          // racial slur among the first three titles.
          'query':
              'collection:opensource_audio AND mediatype:audio AND '
              'subject:(hiphop OR funk) AND NOT '
              'subject:(rock OR jazz OR blues OR electronic OR classical OR '
              'ambient OR experimental OR world OR reggae OR metal OR punk)',
          // The list itself is the theme: an item that states no genre
          // keeps this one.
          'theme': 'Hip Hop',
        },
        weight: 400,
      ),
      _instance(
        types,
        'internet_archive',
        id: 'free_music_archive',
        name: strings.sourceFreeMusicArchiveName,
        description: strings.sourceFreeMusicArchiveDescription,
        settings: {
          // The catalogue the Free Music Archive kept when it closed; its
          // items sit in a collection of their own, apart from the community
          // uploads of the archive.
          'query': 'collection:freemusicarchive AND mediatype:audio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'foreign_audio',
        name: strings.sourceForeignAudioName,
        description: strings.sourceForeignAudioDescription,
        settings: {
          // The archive files what it holds outside English under a
          // collection of its own.
          'query': 'collection:audio_foreign AND mediatype:audio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'news_recordings',
        weight: 400,
        name: strings.sourceNewsRecordingsName,
        description: strings.sourceNewsRecordingsDescription,
        settings: {
          'query': 'collection:audio_news AND mediatype:audio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'poetry',
        weight: 400,
        name: strings.sourcePoetryName,
        description: strings.sourcePoetryDescription,
        settings: {
          // The poetry collection of the archive also keeps readings of other
          // kinds; the subject the archivist gave a recording is what makes
          // the reach a reach of poems.
          'query': 'collection:audio_poetry AND mediatype:audio '
              'AND subject:(poetry)',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'poetry_books',
        weight: 400,
        name: strings.sourcePoetryBooksName,
        description: strings.sourcePoetryBooksDescription,
        settings: {
          // The books of poems the archive keeps are mostly the ones LibriVox
          // recorded; the catalogue has an adapter of its own, so the reach
          // leaves them out and keeps what only the archive holds.
          'query': 'collection:audio_bookspoetry AND mediatype:audio '
              'AND subject:(poetry) AND NOT collection:librivoxaudio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'science_talks',
        weight: 400,
        name: strings.sourceScienceTalksName,
        description: strings.sourceScienceTalksDescription,
        settings: {
          // The collection of talks the archive keeps is a mix of science
          // programmes and recordings of other kinds; the subject is what
          // makes the reach a reach of science.
          'query': 'collection:audio_tech AND mediatype:audio '
              'AND subject:(science)',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'radio_recordings',
        name: strings.sourceRadioRecordingsName,
        description: strings.sourceRadioRecordingsDescription,
        settings: {
          // The collection of old time radio has an instance of its own, so
          // this reach leaves those items out to keep the two apart.
          'query':
              'collection:radioprograms AND mediatype:audio AND '
              'NOT collection:oldtimeradio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'archive_podcasts',
        name: strings.sourceArchivePodcastsName,
        description: strings.sourceArchivePodcastsDescription,
        settings: {
          // The archive keeps podcasts after their feeds stop answering, which
          // the podcast directories can no longer show.
          'query': 'collection:podcasts AND mediatype:audio',
        },
      ),
      _instance(
        types,
        'internet_archive',
        id: 'independent_audiobooks',
        name: strings.sourceIndependentAudiobooksName,
        description: strings.sourceIndependentAudiobooksDescription,
        settings: {
          // LibriVox has an adapter of its own; this reach is everything the
          // archive keeps outside it, which the LibriVox source never shows.
          'query':
              'collection:audio_bookspoetry AND mediatype:audio AND '
              'NOT collection:librivoxaudio',
        },
      ),
      _instance(types, 'ccmixter'),
      _instance(types, 'podcast_rss', enabled: false, settings: {'feed': ''}),
      _instance(types, 'podcast_catalog', settings: {'tag': ''}),
      _instance(
        types,
        'podcast_apple',
        settings: {'query': '', 'country': 'US'},
      ),
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
      _instance(
        types,
        'ampache',
        enabled: false,
        settings: {'server': '', 'apiKey': '', 'query': ''},
      ),
      _instance(
        types,
        'koel',
        enabled: false,
        settings: {'server': '', 'email': '', 'password': '', 'query': ''},
      ),
      _instance(
        types,
        'deezer',
        settings: {'query': '', 'genre': '', 'mode': 'songs'},
      ),
      _instance(
        types,
        'itunes',
        enabled: false,
        settings: {'query': '', 'country': 'US'},
      ),
      _instance(
        types,
        'kodi',
        enabled: false,
        settings: {'server': '', 'user': '', 'password': '', 'query': ''},
      ),
      _instance(
        types,
        'lms',
        enabled: false,
        settings: {'server': '', 'user': '', 'password': '', 'query': ''},
      ),
      _instance(
        types,
        'peertube',
        settings: {
          'server': 'https://framatube.org',
          'query': '',
          'category': 'music',
        },
      ),
      _instance(types, 'audius', settings: {'genre': '', 'window': ''}),
      _instance(types, 'radio', settings: {'provider': 'all', 'query': ''}),
      _instance(
        types,
        'azuracast',
        enabled: false,
        settings: {'server': '', 'apiKey': '', 'query': ''},
      ),
      _instance(types, 'wikimedia', settings: {'category': 'all'}),
      _instance(
        types,
        'jellyfin',
        enabled: false,
        settings: {'server': '', 'user': '', 'password': ''},
      ),
      _instance(types, 'librivox', settings: {'genre': ''}),
      _instance(
        types,
        'emby',
        enabled: false,
        settings: {'server': '', 'user': '', 'password': ''},
      ),
      _instance(
        types,
        'plex',
        enabled: false,
        settings: {'server': '', 'token': ''},
      ),
      _instance(
        types,
        'funkwhale',
        enabled: false,
        settings: {'server': '', 'token': '', 'query': ''},
      ),
      _instance(
        types,
        'audiobookshelf',
        enabled: false,
        settings: {'server': '', 'token': '', 'query': ''},
      ),
    ];
  }

  /// The built-in instance of a type.
  ///
  /// The id of an instance is its type unless the instance names its own id:
  /// a type may ship more than once (a second collection of the Internet
  /// Archive), and each of those instances is told apart by its id and its
  /// own name. Country and language are not instances: they are settings of
  /// the type, so one source serves every country and language it knows.
  static MusicSourceConfig _instance(
    Map<String, SourceTypeDescriptor> types,
    String type, {
    String? id,
    String? name,
    String? description,
    bool enabled = true,
    Map<String, String> settings = const {},
    // The folded group of the source list starts below 500 (see
    // SourceWeights.mainThreshold): a reach only some readers want waits
    // there, one tap away, instead of lengthening the main list.
    int? weight,
  }) {
    final descriptor = types[type]!;
    return MusicSourceConfig(
      id: id ?? type,
      type: type,
      builtIn: true,
      name: name ?? descriptor.name,
      localizedName: descriptor.localizedName,
      description: description ?? descriptor.description,
      kind: descriptor.kind,
      enabled: enabled,
      settings: settings,
      weight: weight,
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
  ///
  /// A keyword is written in the language the app was in when it wrote it, so
  /// the value of a key is a set: the keyword is recognized in every language
  /// the app speaks.
  static Map<String, Set<String>> retiredSettingsOf(
    String type, {
    String? instanceId,
  }) {
    return switch (type) {
      'openverse' => const {
        'query': {'piano'},
      },
      // The instances of one type each had a keyword of their own, so the
      // retired values are looked up by instance: a new collection that
      // happens to use the same query is not taken for the old default.
      'internet_archive' => switch (instanceId) {
        'internet_archive' => const {
          'query': {'collection:netlabels AND mediatype:audio'},
        },
        'live_music_archive' => const {
          'query': {'collection:etree'},
        },
        _ => const {},
      },
      'ccmixter' => const {
        'query': {'jazz'},
      },
      'audius' => const {
        'query': {'ambient'},
      },
      'wikimedia' => const {
        'query': {'piano'},
      },
      _ => const {},
    };
  }

  /// The name of a source in a language.
  ///
  /// A source the reader added keeps the name it was given; only the built-in
  /// ones are named by the catalogue. The id of the instance names it, so the
  /// instances a type ships more than once keep their own names.
  static String nameOf(MusicSourceConfig config, AppLocalizations strings) {
    if (!config.builtIn) return config.name;
    return catalogueOf(strings)[config.id]?.name ?? config.name;
  }

  /// The description of a source in a language.
  static String descriptionOf(
    MusicSourceConfig config,
    AppLocalizations strings,
  ) {
    if (!config.builtIn) return config.description;
    return catalogueOf(strings)[config.id]?.description ?? config.description;
  }

  /// The source of the local music folders.
  static MusicSourceConfig get local => _entry('local');

  /// The source of the open catalogues.
  static MusicSourceConfig get openverse => _entry('openverse');

  /// The source of the music of the artists who publish it freely.
  static MusicSourceConfig get jamendo => _entry('jamendo');

  /// The source of the archive of the net.
  static MusicSourceConfig get internetArchive => _entry('internet_archive');

  /// The source of the live recordings the archive keeps.
  static MusicSourceConfig get liveMusicArchive => _entry('live_music_archive');

  /// The source of the public-domain 78 rpm records.
  static MusicSourceConfig get great78 => _entry('great78');

  /// The source of the albums the netlabels released for free.
  static MusicSourceConfig get netlabels => _entry('netlabels');

  /// The source of the radio dramas of the broadcasting golden age.
  static MusicSourceConfig get oldTimeRadio => _entry('old_time_radio');

  /// The source of the music recordings of the archive audio collection.
  static MusicSourceConfig get archiveMusic => _entry('archive_music');

  /// The source of the public-domain records the archive unlocked.
  static MusicSourceConfig get unlockedRecordings =>
      _entry('unlocked_recordings');

  /// The source of the music the archive's community uploads.
  static MusicSourceConfig get communityMusic => _entry('community_music');

  /// The community uploads filed under classical music.
  static MusicSourceConfig get communityClassical =>
      _entry('community_classical');

  /// The community uploads filed under ambient or experimental music.
  static MusicSourceConfig get communityAmbient => _entry('community_ambient');

  /// The community uploads filed under world music or reggae.
  static MusicSourceConfig get communityWorld => _entry('community_world');

  /// The community uploads filed under metal or punk.
  static MusicSourceConfig get communityMetal => _entry('community_metal');

  /// The community uploads filed under hip-hop or funk.
  static MusicSourceConfig get communityHiphop => _entry('community_hiphop');

  /// The source of the audio the archive files outside English.
  static MusicSourceConfig get foreignAudio => _entry('foreign_audio');

  /// The source of the news broadcasts the archive keeps.
  static MusicSourceConfig get newsRecordings => _entry('news_recordings');

  /// The source of the books of poems the archive keeps outside LibriVox.
  static MusicSourceConfig get poetryBooks => _entry('poetry_books');

  /// The source of the science programmes the archive keeps.
  static MusicSourceConfig get scienceTalks => _entry('science_talks');

  /// The source of the poems the archive keeps as readings.
  static MusicSourceConfig get poetry => _entry('poetry');

  /// The source of the albums of the Free Music Archive.
  static MusicSourceConfig get freeMusicArchive => _entry('free_music_archive');

  /// The source of the broadcasts the archive keeps outside old time radio.
  static MusicSourceConfig get radioRecordings => _entry('radio_recordings');

  /// The source of the podcasts the archive keeps after their feeds go quiet.
  static MusicSourceConfig get archivePodcasts => _entry('archive_podcasts');

  /// The source of the audiobooks the archive keeps outside LibriVox.
  static MusicSourceConfig get independentAudiobooks =>
      _entry('independent_audiobooks');

  /// The source of the recordings of the artists who share them.
  static MusicSourceConfig get ccmixter => _entry('ccmixter');

  /// The source of the podcasts a feed publishes.
  static MusicSourceConfig get podcastRss => _entry('podcast_rss');

  /// The source of the podcasts the directory lists.
  static MusicSourceConfig get podcastCatalog => _entry('podcast_catalog');

  /// The source of the podcasts the Apple directory ranks.
  static MusicSourceConfig get podcastApple => _entry('podcast_apple');

  /// The source of a self-hosted music server.
  static MusicSourceConfig get subsonic => _entry('subsonic');

  /// The source of a self-hosted Ampache library.
  static MusicSourceConfig get ampache => _entry('ampache');

  static MusicSourceConfig get koel => _entry('koel');

  /// The source of the music published on a PeerTube server.
  static MusicSourceConfig get peerTube => _entry('peertube');

  /// The source of the music library of a Kodi media centre.
  static MusicSourceConfig get kodi => _entry('kodi');

  /// The source of the library of a Logitech Media Server.
  static MusicSourceConfig get lms => _entry('lms');

  /// The source of the previews of the iTunes store.
  static MusicSourceConfig get itunes => _entry('itunes');

  /// The source of the previews of the Deezer catalogue.
  static MusicSourceConfig get deezer => _entry('deezer');

  /// The source of the tracks the artists publish themselves.
  static MusicSourceConfig get audius => _entry('audius');

  /// The source of the internet radio stations.
  static MusicSourceConfig get radio => _entry('radio');

  /// The source of the stations of a self-hosted AzuraCast server.
  static MusicSourceConfig get azuracast => _entry('azuracast');

  /// The source of the sound files of the free repository.
  static MusicSourceConfig get wikimedia => _entry('wikimedia');

  /// The source of a self-hosted media library.
  static MusicSourceConfig get jellyfin => _entry('jellyfin');

  /// The source of the audiobooks the volunteers of LibriVox read.
  static MusicSourceConfig get librivox => _entry('librivox');

  /// The source of a self-hosted Emby library.
  static MusicSourceConfig get emby => _entry('emby');

  /// The source of a self-hosted Plex library.
  static MusicSourceConfig get plex => _entry('plex');

  /// The source of a federated Funkwhale instance.
  static MusicSourceConfig get funkwhale => _entry('funkwhale');

  /// The source of a self-hosted audiobook server.
  static MusicSourceConfig get audiobookshelf => _entry('audiobookshelf');

  /// The catalogue entry of a built-in instance.
  static MusicSourceConfig _entry(String id) {
    final entry = descriptorOf(id);
    if (entry == null) throw StateError('unknown built-in source: $id');
    return entry;
  }
}

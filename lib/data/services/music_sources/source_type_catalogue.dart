import 'package:tune/domain/models/music_source.dart';
import 'package:tune/l10n/app_localizations.dart';

/// One type of source the app can serve.
///
/// The type says how the tracks are fetched and how the source is drawn; an
/// instance says which one. The name, the icon and the kind belong here, so
/// the interface never names a source of its own.
class SourceTypeDescriptor {
  final String type;

  /// The name of the type: the brand keeps its own spelling, a type that has
  /// no brand writes its name in the language of the reader.
  final String name;

  /// The name of the type in the language of the reader.
  ///
  /// A type named after a brand has one, so the reader knows what the brand
  /// is; a type whose name is already in that language has none.
  final String localizedName;

  final String description;
  final MusicSourceKind kind;

  /// Whether the reader can add an instance of this type.
  ///
  /// The local music folder is a setting of the app, not an instance that can
  /// be repeated, so it is not offered.
  final bool addable;

  const SourceTypeDescriptor({
    required this.type,
    required this.name,
    this.localizedName = '',
    required this.description,
    required this.kind,
    this.addable = true,
  });
}

/// The catalogue of the source types, in the language of the app.
///
/// The catalogue is a function of the translations, like the built-in
/// instances are: reading it answers with the language of the caller, never
/// with the language of the first call.
class SourceTypeCatalogue {
  const SourceTypeCatalogue._();

  /// Every type the app knows, in the order the reader meets them.
  static List<SourceTypeDescriptor> of(AppLocalizations strings) {
    return [
      SourceTypeDescriptor(
        type: 'local',
        name: strings.sourceLocalName,
        description: strings.sourceLocalDescription,
        kind: MusicSourceKind.localDirectory,
        addable: false,
      ),
      SourceTypeDescriptor(
        type: 'openverse',
        name: 'Openverse',
        localizedName: strings.sourceOpenverseName,
        description: strings.sourceOpenverseDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'jamendo',
        name: 'Jamendo',
        localizedName: strings.sourceJamendoName,
        description: strings.sourceJamendoDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'internet_archive',
        name: 'Internet Archive',
        localizedName: strings.sourceInternetArchiveName,
        description: strings.sourceInternetArchiveDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'ccmixter',
        name: 'ccMixter',
        localizedName: strings.sourceCcmixterName,
        description: strings.sourceCcmixterDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'podcast_rss',
        name: strings.sourcePodcastRssName,
        description: strings.sourcePodcastRssDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'podcast_catalog',
        name: strings.sourcePodcastCatalogName,
        description: strings.sourcePodcastCatalogDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'subsonic',
        name: 'Subsonic',
        localizedName: strings.sourceSubsonicName,
        description: strings.sourceSubsonicDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'audius',
        name: 'Audius',
        localizedName: strings.sourceAudiusName,
        description: strings.sourceAudiusDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'radio',
        name: strings.sourceRadioName,
        description: strings.sourceRadioDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'wikimedia',
        name: 'Wikimedia Commons',
        localizedName: strings.sourceWikimediaName,
        description: strings.sourceWikimediaDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'jellyfin',
        name: 'Jellyfin',
        localizedName: strings.sourceJellyfinName,
        description: strings.sourceJellyfinDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'librivox',
        name: 'LibriVox',
        localizedName: strings.sourceLibrivoxName,
        description: strings.sourceLibrivoxDescription,
        kind: MusicSourceKind.openCatalog,
      ),
      SourceTypeDescriptor(
        type: 'emby',
        name: 'Emby',
        localizedName: strings.sourceEmbyName,
        description: strings.sourceEmbyDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'plex',
        name: 'Plex',
        localizedName: strings.sourcePlexName,
        description: strings.sourcePlexDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'funkwhale',
        name: 'Funkwhale',
        localizedName: strings.sourceFunkwhaleName,
        description: strings.sourceFunkwhaleDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'audiobookshelf',
        name: 'Audiobookshelf',
        localizedName: strings.sourceAudiobookshelfName,
        description: strings.sourceAudiobookshelfDescription,
        kind: MusicSourceKind.openApi,
      ),
      SourceTypeDescriptor(
        type: 'direct_url',
        name: strings.sourceDirectUrlName,
        description: strings.sourceDirectUrlDescription,
        kind: MusicSourceKind.custom,
      ),
      SourceTypeDescriptor(
        type: 'm3u',
        name: strings.sourceM3uName,
        description: strings.sourceM3uDescription,
        kind: MusicSourceKind.custom,
      ),
      SourceTypeDescriptor(
        type: 'json_api',
        name: strings.sourceJsonApiName,
        description: strings.sourceJsonApiDescription,
        kind: MusicSourceKind.custom,
      ),
      SourceTypeDescriptor(
        type: 'graphql',
        name: strings.sourceGraphqlName,
        description: strings.sourceGraphqlDescription,
        kind: MusicSourceKind.custom,
      ),
    ];
  }

  /// The catalogue of the types, keyed by the type.
  static Map<String, SourceTypeDescriptor> byType(AppLocalizations strings) {
    return {for (final descriptor in of(strings)) descriptor.type: descriptor};
  }
}

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'A local-first desktop music player';

  @override
  String get appStartFailed => 'Tune failed to start';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get clear => 'Clear';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get chooseFile => 'Choose file';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get scanNow => 'Scan now';

  @override
  String get search => 'Search';

  @override
  String get scanning => 'Scanning';

  @override
  String get updateEyebrow => 'Updates';

  @override
  String get updateTitle => 'Version';

  @override
  String get updateDescription =>
      'Checks the project page for a newer release and installs it';

  @override
  String updateCurrentVersion(String version) {
    return 'Current version $version';
  }

  @override
  String get updateIdle => 'The project page has not been checked yet';

  @override
  String get updateChecking => 'Checking the project page…';

  @override
  String get updateUpToDate => 'This is the newest version';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateDownloading => 'Downloading';

  @override
  String get updateInstalling => 'Installing…';

  @override
  String get updateReady => 'The update is ready; restart to use it';

  @override
  String updateFailed(String error) {
    return 'The check failed: $error';
  }

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateInstall => 'Download and install';

  @override
  String get updateRetry => 'Try again';

  @override
  String get updateRestart => 'Restart now';

  @override
  String get updateNoArchive =>
      'This platform has no automatic install; download it from the release page';

  @override
  String get songMayBeUnavailable => 'May be unavailable';

  @override
  String get about => 'About';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get lightMode => 'Light mode';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get systemMode => 'Follow system';

  @override
  String get libraryTitle => 'Library';

  @override
  String librarySummary(int tracks, int albums, int sources) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    String _temp0 = intl.Intl.pluralLogic(
      tracks,
      locale: localeName,
      other: '$tracksString tracks',
      one: '1 track',
    );
    String _temp1 = intl.Intl.pluralLogic(
      albums,
      locale: localeName,
      other: '$albumsString albums',
      one: '1 album',
    );
    String _temp2 = intl.Intl.pluralLogic(
      sources,
      locale: localeName,
      other: '$sourcesString sources',
      one: '1 source',
    );
    return '$_temp0 · $_temp1 · $_temp2';
  }

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String get libraryFilterSources => 'Filter sources';

  @override
  String get libraryAllSources => 'All sources';

  @override
  String get libraryScanAllSources => 'Scan all sources';

  @override
  String get libraryLoadMore => 'Load more tracks';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks',
      one: '1 track',
    );
    return '$_temp0';
  }

  @override
  String get libraryNoMatchTitle => 'No matching songs';

  @override
  String get libraryNoMatchSubtitle =>
      'Try another keyword or clear the search';

  @override
  String get librarySourceEmptyTitle => 'No songs from this source';

  @override
  String get librarySourceEmptySubtitle =>
      'Switch to all sources or rescan this one';

  @override
  String get libraryViewAllSources => 'Show all sources';

  @override
  String get libraryScanningTitle => 'Scanning music';

  @override
  String get libraryEmptyTitle => 'No music yet';

  @override
  String get libraryEmptySubtitle =>
      'Scan a local folder or an enabled online source, or adjust your sources in settings.';

  @override
  String get libraryLoadFailedTitle => 'Could not load the library';

  @override
  String get libraryAddedToQueue => 'Added to the queue';

  @override
  String libraryScanPaths(String paths) {
    return 'Scan folders: $paths';
  }

  @override
  String get libraryAddToQueue => 'Add to queue';

  @override
  String get libraryAddAllToQueue => 'Add the whole list to the queue';

  @override
  String get libraryViewSongs => 'Songs view';

  @override
  String get libraryViewAlbums => 'Albums view';

  @override
  String get libraryUnknownAlbum => 'Unknown album';

  @override
  String get libraryVariousArtists => 'Various artists';

  @override
  String get libraryBackToAlbums => 'Back to albums';

  @override
  String get queueTitle => 'Queue';

  @override
  String get queueEmptyTitle => 'The queue is empty';

  @override
  String get queueEmptySubtitle =>
      'Pick a song in the library or add songs to the queue';

  @override
  String get queueGoToLibrary => 'Go to library';

  @override
  String get queueClearTitle => 'Clear the queue?';

  @override
  String get queueClearMessage =>
      'Playback stops. The songs stay in your library.';

  @override
  String get queueReorderTooltip => 'Drag to reorder';

  @override
  String get favoritesTitle => 'Liked';

  @override
  String get favoritesSubtitle => 'The tracks you marked with a heart';

  @override
  String get favoritesEyebrow => 'Collection';

  @override
  String get favoritesEmptyTitle => 'No favorites yet';

  @override
  String get favoritesEmptySubtitle =>
      'Tap the heart in the library and the track lands here';

  @override
  String get favoritesGoToLibrary => 'Go to library';

  @override
  String get favoriteAdd => 'Add to favorites';

  @override
  String get favoriteRemove => 'Remove from favorites';

  @override
  String favoritesOutsideLibrary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString more are marked but not in the library';
  }

  @override
  String get favoritesEmptyOutsideTitle =>
      'The marked tracks are not in the library';

  @override
  String get favoritesEmptyOutsideSubtitle =>
      'The library does not hold them; the marks are kept';

  @override
  String get playerNowPlaying => 'Now playing';

  @override
  String get playerExpandNowPlaying => 'Open now playing';

  @override
  String get playerCollapse => 'Collapse';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPlay => 'Play';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerMute => 'Mute';

  @override
  String get playerUnmute => 'Unmute';

  @override
  String get playerPlayModeSequential => 'Repeat all';

  @override
  String get playerPlayModeRepeatOne => 'Repeat one';

  @override
  String get playerPlayModeShuffle => 'Shuffle';

  @override
  String get playerNoSongTitle => 'Pick a song to start';

  @override
  String get playerUnknownArtist => 'Unknown artist';

  @override
  String get playerDockReady => 'Tune · READY';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks in queue',
      one: '1 track in queue',
    );
    return '$_temp0';
  }

  @override
  String playerQueuePosition(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return 'Queue track $indexString';
  }

  @override
  String get nowPlayingEmptyTitle => 'Nothing is playing yet';

  @override
  String get nowPlayingEmptySubtitle => 'Pick one from the library to begin';

  @override
  String get nowPlayingUnnamedTrack => 'Untitled track';

  @override
  String get trackUnknownTitle => 'Unknown song';

  @override
  String playbackFailed(String error) {
    return 'Playback failed: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return 'Could not pause: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return 'Could not resume: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'Could not seek: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return 'Could not set the volume: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return 'Could not set the speed: $error';
  }

  @override
  String get audioSourceLocal => 'Local file';

  @override
  String audioSourceCaching(int percent) {
    return 'Caching $percent%';
  }

  @override
  String get audioSourceCached => 'Offline ready';

  @override
  String get audioSourceFailed => 'Playback failed';

  @override
  String get routerNotFoundTitle => 'Page not found';

  @override
  String get routerBackToLibrary => 'Back to library';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get sourcesSubtitle =>
      'Online catalogs, self-hosted services and scan folders';

  @override
  String get sourcesGroupMore => 'More sources';

  @override
  String get sourcesAdd => 'Add source';

  @override
  String get sourcesAddChooseType => 'Choose a source type';

  @override
  String sourcesAddTitle(String name) {
    return 'Add $name';
  }

  @override
  String get sourcesFieldName => 'Name';

  @override
  String get sourcesFieldNameHint =>
      'Leave empty to use the type name and a number';

  @override
  String get sourcesClearSongs => 'Clear tracks';

  @override
  String sourcesClearSongsTitle(String name) {
    return 'Clear the tracks of $name?';
  }

  @override
  String get sourcesClearSongsHint =>
      'Removes only the tracks this source brought; the source stays';

  @override
  String sourcesSongsCleared(String name) {
    return 'Cleared the tracks of $name';
  }

  @override
  String get sourcesDelete => 'Delete';

  @override
  String sourcesDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get sourcesDeleteHint =>
      'The tracks this source brought in are removed with it.';

  @override
  String get sourcesMenu => 'More actions';

  @override
  String get sourcesMoveUp => 'Move up';

  @override
  String get sourcesMoveDown => 'Move down';

  @override
  String get sourcesMoveToMore => 'Move to More sources';

  @override
  String get sourcesMoveToMain => 'Move to main list';

  @override
  String get sourcesMovedToMore => 'Moved to More sources';

  @override
  String get sourcesMovedToMain => 'Moved to main list';

  @override
  String sourcesHealthScore(int score) {
    return 'Health $score/100';
  }

  @override
  String sourcesHealthBreakdown(
    int availability,
    int configuration,
    int scan,
    int freshness,
    int output,
    int speed,
    int reliability,
    int stability,
    int playable,
    int artwork,
    int metadata,
    int activity,
  ) {
    return 'Available $availability% · Configured $configuration% · Scan $scan% · Fresh $freshness% · Output $output% · Speed $speed% · Reliable $reliability% · Stable $stability% · Playable $playable% · Artwork $artwork% · Metadata $metadata% · Active $activity%';
  }

  @override
  String get sourcesHealthWeightsTitle => 'Health weights';

  @override
  String get sourcesHealthWeightsHint =>
      'Raise a dimension to give it more say in the health score; the total is normalized.';

  @override
  String sourcesHealthWeightsTotal(int total) {
    return 'Total $total · normalized';
  }

  @override
  String get settingsSourceHealthDescription =>
      'The current share of the twelve dimensions; raise one to give it more of the score.';

  @override
  String get settingsAdjustSourceHealthWeights => 'Adjust weights';

  @override
  String get sourcesHealthWeightsReset => 'Reset';

  @override
  String get sourcesHealthAvailability => 'Available';

  @override
  String get sourcesHealthConfiguration => 'Configured';

  @override
  String get sourcesHealthScan => 'Scan';

  @override
  String get sourcesHealthFreshness => 'Fresh';

  @override
  String get sourcesHealthOutput => 'Output';

  @override
  String get sourcesHealthSpeed => 'Speed';

  @override
  String get sourcesHealthReliability => 'Reliable';

  @override
  String get sourcesHealthStability => 'Stable';

  @override
  String get sourcesHealthPlayable => 'Playable';

  @override
  String get sourcesHealthArtwork => 'Artwork';

  @override
  String get sourcesHealthMetadata => 'Metadata';

  @override
  String get sourcesHealthActivity => 'Active';

  @override
  String get sourceDirectUrlName => 'Direct audio';

  @override
  String get sourceDirectUrlDescription =>
      'One address per line; every line becomes a track';

  @override
  String get directUrlFieldUrls => 'Audio addresses';

  @override
  String get directUrlFieldUrlsHint =>
      'One address per line, e.g. https://example.com/song.mp3';

  @override
  String get directUrlHint => 'Fill in the audio addresses, one per line';

  @override
  String get sourceM3uName => 'Playlist';

  @override
  String get sourceM3uDescription =>
      'Read an .m3u or .pls playlist; every entry becomes a track';

  @override
  String get m3uFieldPlaylist => 'Playlist address';

  @override
  String get m3uFieldPlaylistHint => 'e.g. https://example.com/list.m3u';

  @override
  String get m3uHint => 'Fill in the address of the playlist';

  @override
  String get m3uEmptyPlaylist => 'The playlist is empty';

  @override
  String get m3uNoEntries => 'The playlist has no entries';

  @override
  String get jsonFieldListPath => 'List path';

  @override
  String get jsonFieldIdPath => 'Track id path';

  @override
  String get jsonFieldTitlePath => 'Title path';

  @override
  String get jsonFieldArtistPath => 'Artist path';

  @override
  String get jsonFieldAlbumPath => 'Album path';

  @override
  String get jsonFieldCoverPath => 'Cover path';

  @override
  String get jsonFieldUrlPath => 'Stream address path';

  @override
  String get jsonFieldDurationPath => 'Duration path';

  @override
  String get jsonFieldGenrePath => 'Genre path';

  @override
  String get jsonFieldUrlTemplate => 'Stream address template';

  @override
  String get jsonFieldPathHint =>
      'The path in the answer, steps separated by dots, e.g. data.title';

  @override
  String get jsonFieldUrlTemplateHint =>
      'The template of the stream address; the track id is written into the placeholder';

  @override
  String get jsonFieldQueryHint =>
      'The keyword to search with; it replaces the placeholder in the request. Leave it empty to ask the address as it is written';

  @override
  String get jsonFieldUrl => 'API address';

  @override
  String get jsonFieldUrlHint => 'e.g. https://example.com/api/search';

  @override
  String get jsonFieldHeaders => 'Headers';

  @override
  String get jsonFieldHeadersHint =>
      'A JSON object, one key and value per line';

  @override
  String get jsonInvalidObject => 'This text is not a JSON object';

  @override
  String get jsonInvalidResponse => 'The answer of the interface is not JSON';

  @override
  String get jsonNoTracks => 'The interface returned no tracks';

  @override
  String get jsonNoAddressPath =>
      'No path or template for the stream address was filled in';

  @override
  String get sourceJsonApiName => 'JSON API';

  @override
  String get sourceJsonApiDescription => 'Map any JSON API onto tracks';

  @override
  String get jsonApiHint =>
      'Fill in the address of the interface and the paths of the fields';

  @override
  String get jsonApiFieldMethod => 'Method';

  @override
  String get jsonApiFieldMethodHint =>
      'GET or POST; only a POST carries a body';

  @override
  String get jsonApiFieldBody => 'Body';

  @override
  String get jsonApiFieldBodyHint =>
      'The JSON object of a POST; the keyword is written into the placeholder';

  @override
  String get sourceGraphqlName => 'GraphQL API';

  @override
  String get sourceGraphqlDescription =>
      'Ask the interface with a query document; the conditions live in the document';

  @override
  String get graphqlHint =>
      'Fill in the address, the query document and the paths of the fields';

  @override
  String get graphqlFieldQuery => 'Query document';

  @override
  String get graphqlFieldQueryHint =>
      'A GraphQL query document; the conditions live in it. The template is only a starting point: change the fields to the ones the interface has';

  @override
  String get graphqlFieldVariables => 'Variables';

  @override
  String get graphqlFieldVariablesHint =>
      'A JSON object; the keyword is written into the placeholder';

  @override
  String get jsonPreviewNoTracks => 'No tracks found in the answer';

  @override
  String get sourcePreviewTry => 'Try it';

  @override
  String get sourcePreviewRunning => 'Trying…';

  @override
  String sourcePreviewTracks(int count) {
    return '$count tracks found';
  }

  @override
  String get sourceFormShowAdvanced => 'More options';

  @override
  String get sourceFormHideAdvanced => 'Fewer options';

  @override
  String get sourcesAutoScan => 'Scan on startup';

  @override
  String get sourcesAutoScanDescription =>
      'Every enabled source refreshes on startup. A failure never touches your local library.';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Remote sources can take a few seconds';

  @override
  String get sourcesScanCompleted => 'Scan finished';

  @override
  String get sourcesConfigure => 'Configure';

  @override
  String get sourcesUnsupported =>
      'This source is not supported in this version';

  @override
  String get sourcesDisabled => 'Off';

  @override
  String get sourcesNeedsConfiguration => 'Needs configuration';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return 'Needs configuration: $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return 'Last scan $time';
  }

  @override
  String get sourcesAutoScanLocal => 'Local folders are scanned after startup';

  @override
  String get sourcesWaitingFirstScan => 'Waiting for the first scan';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString tracks',
      one: '1 track',
    );
    return '$_temp0 · $time';
  }

  @override
  String get sourcesSkipped => 'Skipped';

  @override
  String get sourcesScanFailed => 'Scan failed';

  @override
  String sourcesDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get sourceKindLocal => 'Local';

  @override
  String get sourceKindOpenCatalog => 'Open catalog';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindCustom => 'Custom';

  @override
  String sourcesConfigureTitle(String name) {
    return 'Configure $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return 'Please fill in $label';
  }

  @override
  String get sourcesFieldNumeric => 'Please enter a number';

  @override
  String get fieldQuery => 'Search keyword';

  @override
  String get fieldQueryOptional => 'Search keyword (optional)';

  @override
  String get fieldBrowse => 'Browse';

  @override
  String get fieldBrowseHint =>
      'What a scan pulls without a keyword; a keyword searches instead';

  @override
  String get browseModeLatest => 'Latest';

  @override
  String get browseModeCharts => 'Charts';

  @override
  String get browseModeDaily => 'Daily picks';

  @override
  String get fieldLimit => 'Tracks per scan';

  @override
  String get fieldLimitFiles => 'Files per scan';

  @override
  String get fieldLimitEpisodes => 'Episodes per scan';

  @override
  String get fieldLimitPodcasts => 'Podcasts per scan';

  @override
  String get fieldLimitStations => 'Stations per scan';

  @override
  String get fieldScanPages => 'Pages per scan';

  @override
  String get fieldScanPagesHint =>
      'How many pages one scan reads, 1–10; more pages take longer';

  @override
  String fieldLimitHint(int count, int max) {
    return '$count by default, $max at most';
  }

  @override
  String get fieldLimitBooks => 'Books per scan';

  @override
  String get fieldLanguage => 'Language';

  @override
  String get fieldLanguageHint => 'Only keep the audiobooks of one language';

  @override
  String get fieldLanguageAll => 'All languages';

  @override
  String get fieldLanguageEnglish => 'English';

  @override
  String get fieldLanguageChinese => 'Chinese';

  @override
  String get fieldLanguageFrench => 'French';

  @override
  String get fieldLanguageGerman => 'German';

  @override
  String get fieldLanguageSpanish => 'Spanish';

  @override
  String get fieldLanguageItalian => 'Italian';

  @override
  String get fieldLanguageJapanese => 'Japanese';

  @override
  String get fieldLanguageRussian => 'Russian';

  @override
  String get fieldLanguagePortuguese => 'Portuguese';

  @override
  String get fieldServer => 'Server address';

  @override
  String get fieldUser => 'User name';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldFormat => 'Quality';

  @override
  String get sourcesNotLoaded => 'The source list is still loading';

  @override
  String get playerLyrics => 'Lyrics';

  @override
  String get lyricsLoading => 'Loading lyrics';

  @override
  String get lyricsFailed => 'Could not load the lyrics';

  @override
  String get lyricsMissing => 'This song has no lyrics';

  @override
  String get lyricsNothingPlaying => 'Nothing is playing yet';

  @override
  String get lyricsInvalidFile => 'This file holds no lyrics';

  @override
  String get lyricsRetry => 'Try again';

  @override
  String get lyricsSearchAgain => 'Look again';

  @override
  String get lyricsChooseFile => 'Choose file';

  @override
  String get lyricsAttached => 'The lyrics are attached';

  @override
  String get lyricsSubtitle => 'The words of the track that plays';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Adjust the look, the language, your library and source health.';

  @override
  String get settingsThemeDescription =>
      'Choose how the interface looks and which language it speaks.';

  @override
  String get settingsLanguageDescription =>
      'Language of the interface and the system menus';

  @override
  String get settingsLibraryDescription =>
      'Tune looks for audio files in these folders only.';

  @override
  String get settingsDefaultPath => 'Default';

  @override
  String get settingsNoDefaultFolder => 'No default music folder found';

  @override
  String get settingsCustomPath => 'Custom';

  @override
  String get settingsSourceCacheLimit => 'Tracks kept per source';

  @override
  String get settingsSourceCacheLimitHint =>
      'Favorites, recently played and recently seen tracks are kept first';

  @override
  String get settingsNoLimit => 'No limit';

  @override
  String get settingsAddFolder => 'Add folder';

  @override
  String get settingsClearLibrary => 'Clear library';

  @override
  String get settingsScanSafetyNote =>
      'Scanning only reads audio files. Nothing on disk is changed or deleted.';

  @override
  String get settingsChooseFolder => 'Choose a music folder';

  @override
  String get settingsFolderAdded => 'Scan folder added';

  @override
  String get settingsLibraryFolder => 'Where the files are kept';

  @override
  String get settingsChangeLibraryFolder => 'Change';

  @override
  String get settingsUseDefaultLibraryFolder => 'Use the default';

  @override
  String get settingsNoLibraryFolder => 'This platform has no music folder';

  @override
  String get settingsScanDone => 'Scan finished';

  @override
  String get settingsClearLibraryTitle => 'Clear the library?';

  @override
  String get settingsClearLibraryMessage =>
      'This only clears the scan history of Tune. Music files on disk stay untouched.';

  @override
  String get settingsLibraryCleared => 'Library cleared';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString folders',
      one: '1 folder',
    );
    return '$_temp0';
  }

  @override
  String get searchOnlineTitle => 'Search online';

  @override
  String get searchOnlineHint =>
      'Search the online sources, e.g. jazz, piano, lo-fi';

  @override
  String get searchOnlineDescription =>
      'Search your enabled online sources. Results are not written to the library.';

  @override
  String get searchOnlinePrompt => 'Search the online sources';

  @override
  String get searchOnlinePromptDescription =>
      'Type a keyword and press enter. Every enabled online source is searched in parallel.';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchNoResultsDescription => 'Try another keyword.';

  @override
  String get searchNoMatch => 'No matching songs';

  @override
  String searchSearching(String query) {
    return 'Searching for “$query”';
  }

  @override
  String get searchPlayAll => 'Play all';

  @override
  String get searchAddToQueue => 'Add to queue';

  @override
  String searchAddedToQueue(String title) {
    return 'Added to the queue: $title';
  }

  @override
  String get searchAddLibraryFailed =>
      'Could not add the tracks to the library';

  @override
  String get searchLoadMore => 'Load more';

  @override
  String get searchNoMore => 'No more results';

  @override
  String get searchAutoSave => 'Auto-add results to the library';

  @override
  String get searchAddToLibrary => 'Add to library';

  @override
  String get searchAddAllToLibrary => 'Add all';

  @override
  String get searchAddedToLibrary => 'Added';

  @override
  String searchAddedManyToLibrary(int count) {
    return 'Added $count tracks to the library';
  }

  @override
  String get searchNoSourcesEnabled =>
      'No online source is enabled. Turn one on in settings first.';

  @override
  String get searchFailedShort => 'Search failed';

  @override
  String searchFailed(String error) {
    return 'Online search failed: $error';
  }

  @override
  String get scanPreparing => 'Preparing the scan...';

  @override
  String get scanNoEnabledSources => 'No source is enabled';

  @override
  String get scanNoLocalFolders => 'No music folder to scan';

  @override
  String scanProgressPercent(int percent) {
    return 'Scanning $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'Every source failed to scan';

  @override
  String scanFailed(String error) {
    return 'Scan failed: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'Could not clear the library: $error';
  }

  @override
  String get scanNoAudioFiles => 'No audio files found';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Scanned $countString songs',
      one: 'Scanned 1 song',
    );
    return '$_temp0';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString songs',
      one: '1 song',
    );
    return '$_temp0';
  }

  @override
  String get scanSourceNotConfigured => 'The source is not configured yet';

  @override
  String get scanCachedTooSoon =>
      'Cache kept, the last scan is still too recent';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    String _temp0 = intl.Intl.pluralLogic(
      sources,
      locale: localeName,
      other: 'Scanned $sourcesString sources',
      one: 'Scanned 1 source',
    );
    String _temp1 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songsString songs',
      one: '1 song',
    );
    return '$_temp0, $_temp1 in total';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    String _temp0 = intl.Intl.pluralLogic(
      songs,
      locale: localeName,
      other: '$songsString songs',
      one: '1 song',
    );
    String _temp1 = intl.Intl.pluralLogic(
      failed,
      locale: localeName,
      other: '$failedString sources failed',
      one: '1 source failed',
    );
    return 'Updated $_temp0, $_temp1';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'Access denied (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited =>
      'Too many requests (HTTP 429). Try again later.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'The service returned HTTP $status';
  }

  @override
  String get sourceErrorTimeout => 'The connection timed out';

  @override
  String get sourceErrorConnection => 'Could not reach the source service';

  @override
  String get sourceErrorCertificate => 'The certificate could not be verified';

  @override
  String get sourceErrorCancelled => 'The request was cancelled';

  @override
  String sourceErrorNetwork(String message) {
    return 'Network request failed: $message';
  }

  @override
  String get sourceErrorUnsupported => 'This source is not supported yet';

  @override
  String get sourceAddressNotHttp => 'Only http(s) addresses are asked';

  @override
  String sourceErrorScanInterval(String interval) {
    return 'The last scan is less than $interval ago';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'The scan timed out after ${seconds}s';
  }

  @override
  String intervalHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String intervalMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get localSourceHint => 'Add a scan folder in the library settings';

  @override
  String get localSourceNotConfigured => 'No local music folder configured';

  @override
  String get openverseHint =>
      'Enter a search keyword, e.g. piano, ambient or jazz';

  @override
  String get openverseFieldQueryHint => 'e.g. piano, ambient, jazz';

  @override
  String get openverseEmptyResponse => 'Openverse returned an empty response';

  @override
  String get openverseNoMatch => 'No matching open audio found';

  @override
  String get sourceLocalName => 'Local music';

  @override
  String get sourceLocalDescription => 'Scan the music folders on this device';

  @override
  String get sourceOpenverseDescription =>
      'Open audio from Jamendo, Freesound, Wikimedia and more';

  @override
  String get sourceOpenverseName => 'Open audio';

  @override
  String get sourceJamendoDescription =>
      'An open catalog of independent music. Needs a free Client ID.';

  @override
  String get sourceJamendoName => 'Indie music';

  @override
  String get sourceInternetArchiveDescription =>
      'The open audio collection of the Internet Archive';

  @override
  String get sourceInternetArchiveName => 'Public domain';

  @override
  String get jamendoHint =>
      'Get a free Client ID at developer.jamendo.com and paste it here';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint =>
      'Apply for free at developer.jamendo.com';

  @override
  String get jamendoFieldQueryHint => 'e.g. jazz, electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo returned an empty response';

  @override
  String get jamendoNoMatch => 'No matching Jamendo tracks';

  @override
  String get internetArchiveHint =>
      'Enter an Internet Archive query, e.g. collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => 'Query';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive returned an unreadable response';

  @override
  String get internetArchiveNoMatch => 'No playable archived audio found';

  @override
  String get downloadUnsupportedPlatform =>
      'This platform has no file system, so downloads cannot be cached';

  @override
  String get audioLoadFailed => 'Audio loading failed';

  @override
  String get audioPathEmpty => 'The audio path is empty';

  @override
  String get ccmixterEmptyResponse => 'ccMixter returned an empty response';

  @override
  String get ccmixterFieldQuery => 'Search tag';

  @override
  String get ccmixterFieldQueryHint => 'e.g. jazz, ambient, electro';

  @override
  String get ccmixterHint =>
      'Enter a ccMixter tag, e.g. jazz, ambient or electro';

  @override
  String get ccmixterNoMatch => 'No matching ccMixter tracks';

  @override
  String get podcastRssEmptyFeed =>
      'The feed address returned an empty document';

  @override
  String get podcastRssFieldFeed => 'Feed address';

  @override
  String get podcastRssFieldFeedHint => 'e.g. https://example.com/podcast.xml';

  @override
  String get podcastRssHint => 'Enter the address of a podcast feed (RSS)';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'The feed address returned XML that cannot be read: $error';
  }

  @override
  String get podcastRssNoMatch => 'The feed has no playable episode';

  @override
  String get sourceCcmixterDescription =>
      'Creative Commons remixes and open music';

  @override
  String get sourceCcmixterName => 'Shared remixes';

  @override
  String get sourceLiveMusicArchiveDescription =>
      'Live recordings the Internet Archive keeps';

  @override
  String get sourceLiveMusicArchiveName => 'Live Music Archive';

  @override
  String get sourcePodcastRssDescription =>
      'Turns any podcast RSS feed into playable episodes';

  @override
  String get sourcePodcastRssName => 'Podcasts';

  @override
  String get sourcePodcastCatalogName => 'Podcast directory';

  @override
  String get sourcePodcastCatalogDescription =>
      'Search the open podcast directory of gpodder, newest episodes first';

  @override
  String get podcastCatalogHint =>
      'Type a keyword to find podcasts, or leave it empty to browse the directory';

  @override
  String get podcastCatalogFieldQueryHint => 'e.g. jazz, history or technology';

  @override
  String get podcastCatalogNoMatch => 'No podcast found';

  @override
  String get sourceSubsonicDescription =>
      'Connects to a self-hosted Navidrome or Subsonic library';

  @override
  String get sourceSubsonicName => 'Self-hosted';

  @override
  String get subsonicAuthFailed =>
      'Cannot reach the music server, check the address and the account';

  @override
  String get subsonicEmptyResponse =>
      'The music server returned an empty response';

  @override
  String subsonicError(String error) {
    return 'The music server reported an error: $error';
  }

  @override
  String get subsonicFieldPasswordHint =>
      'Used to sign the access token, never sent in plain text';

  @override
  String get subsonicFieldQueryHint => 'e.g. jazz, piano';

  @override
  String get subsonicFieldServerHint => 'e.g. http://localhost:4533';

  @override
  String get subsonicFieldUserHint => 'The login name of your music server';

  @override
  String get subsonicHint =>
      'Enter the address and the account of your own music server, e.g. http://localhost:4533';

  @override
  String get subsonicNoMatch => 'No matching tracks';

  @override
  String get sourceAudiusDescription =>
      'Complete tracks from the open Audius network';

  @override
  String get sourceAudiusName => 'Artist uploads';

  @override
  String get audiusHint =>
      'Type a search keyword, e.g. jazz, ambient or electronic';

  @override
  String get audiusFieldQueryHint => 'e.g. jazz, ambient, electronic';

  @override
  String get audiusEmptyResponse => 'Audius returned an empty response';

  @override
  String get audiusNoMatch => 'No matching tracks on Audius';

  @override
  String get sourceRadioDescription => 'Live streams of public internet radio';

  @override
  String get radioHint =>
      'Pick a directory of stations, a keyword filters them';

  @override
  String get radioFieldProvider => 'Station directory';

  @override
  String get radioFieldProviderHint =>
      'All directories, Radio Browser, SomaFM or Radio Paradise';

  @override
  String get radioProviderAll => 'All directories';

  @override
  String get radioFieldCountry => 'Country or region';

  @override
  String get radioFieldCountryHint =>
      'A two-letter country code, e.g. SG, MY, AU or JP; any country the directory lists works';

  @override
  String get radioFieldQuery => 'Station keyword';

  @override
  String get radioFieldQueryHint => 'e.g. jazz, ambient or SomaFM';

  @override
  String get radioNoMatch => 'No matching stations';

  @override
  String get sourceWikimediaDescription => 'Open audio from Wikimedia Commons';

  @override
  String get sourceWikimediaName => 'Free media';

  @override
  String get wikimediaHint =>
      'Type a search keyword, e.g. piano, lecture or birdsong';

  @override
  String get wikimediaFieldQueryHint => 'e.g. piano, lecture, birdsong';

  @override
  String get wikimediaEmptyResponse =>
      'Wikimedia Commons returned an empty response';

  @override
  String get wikimediaNoMatch => 'No playable audio found on Commons';

  @override
  String get sourceFunkwhaleName => 'Federated music';

  @override
  String get sourceFunkwhaleDescription =>
      'Music of a federated Funkwhale instance';

  @override
  String get funkwhaleHint =>
      'Type the address of a Funkwhale instance; a token is only needed for a private library';

  @override
  String get funkwhaleFieldServerHint => 'e.g. https://open.audio';

  @override
  String get funkwhaleFieldToken => 'Access token';

  @override
  String get funkwhaleFieldTokenHint =>
      'Only needed when the instance keeps its library private';

  @override
  String get funkwhaleFieldQueryHint => 'e.g. jazz, folk or electronic';

  @override
  String get funkwhaleEmptyResponse => 'Funkwhale returned an empty response';

  @override
  String get funkwhaleNoMatch => 'No matching tracks on Funkwhale';

  @override
  String get sourceAudiobookshelfName => 'Self-hosted audiobooks';

  @override
  String get sourceAudiobookshelfDescription =>
      'Audiobooks of a self-hosted Audiobookshelf server';

  @override
  String get audiobookshelfHint =>
      'Type the address and the token of your Audiobookshelf server';

  @override
  String get audiobookshelfFieldServerHint => 'e.g. http://localhost:13378';

  @override
  String get audiobookshelfFieldToken => 'Access token';

  @override
  String get audiobookshelfFieldTokenHint =>
      'The API token of your Audiobookshelf account';

  @override
  String get audiobookshelfFieldQueryHint => 'e.g. history, novel or science';

  @override
  String get audiobookshelfEmptyResponse =>
      'Audiobookshelf returned an empty response';

  @override
  String get audiobookshelfNoMatch => 'No audiobook found';

  @override
  String get sourcePlexName => 'Media library';

  @override
  String get sourcePlexDescription => 'Connect to a self-hosted Plex library';

  @override
  String get plexHint => 'Type the address of your Plex server and its token';

  @override
  String get plexFieldServerHint => 'e.g. http://localhost:32400';

  @override
  String get plexFieldToken => 'Access token';

  @override
  String get plexFieldTokenHint => 'The X-Plex-Token of your Plex account';

  @override
  String get plexNoMatch => 'No matching tracks on Plex';

  @override
  String plexInvalidAnswer(String error) {
    return 'The answer of Plex cannot be read: $error';
  }

  @override
  String get sourceJellyfinDescription =>
      'Connect to a self-hosted Jellyfin library';

  @override
  String get sourceJellyfinName => 'Media server';

  @override
  String get jellyfinHint =>
      'Type the address and the account of your Jellyfin server';

  @override
  String get jellyfinFieldServerHint => 'e.g. http://localhost:8096';

  @override
  String get jellyfinFieldUserHint => 'The login name of your Jellyfin account';

  @override
  String get jellyfinFieldPasswordHint => 'Used to obtain an access token';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin returned an empty response';

  @override
  String get jellyfinAuthFailed =>
      'Cannot reach the Jellyfin server, check the address and the account';

  @override
  String get sourceLibrivoxName => 'Audiobooks';

  @override
  String get sourceLibrivoxDescription =>
      'Public-domain audiobooks read by LibriVox volunteers';

  @override
  String get librivoxHint =>
      'Type a book or an author, or leave it empty to browse the most popular audiobooks';

  @override
  String get librivoxFieldQueryHint =>
      'e.g. Alice in Wonderland, Dickens or fairy tales';

  @override
  String get librivoxNoMatch => 'No matching audiobooks';

  @override
  String get librivoxEmptyResponse => 'LibriVox returned an empty response';

  @override
  String librivoxInvalidFeed(String error) {
    return 'The chapter list of a book cannot be read: $error';
  }

  @override
  String get sourceEmbyName => 'Emby library';

  @override
  String get sourceEmbyDescription => 'Connect to a self-hosted Emby library';

  @override
  String get embyHint => 'Type the address and the account of your Emby server';

  @override
  String get embyFieldServerHint => 'e.g. http://localhost:8095';

  @override
  String get embyFieldUserHint => 'The login name of your Emby account';

  @override
  String get embyFieldPasswordHint => 'Used to obtain an access token';

  @override
  String get embyEmptyResponse => 'Emby returned an empty response';

  @override
  String get embyAuthFailed =>
      'Cannot reach the Emby server, check the address and the account';

  @override
  String get audioSourceStreaming => 'Network';

  @override
  String get playerLiveBadge => 'LIVE';

  @override
  String get nowPlayingLiveStream => 'Live stream, no fixed length';

  @override
  String get nowPlayingDetails => 'Track details';

  @override
  String get nowPlayingDetailAlbum => 'Album';

  @override
  String get nowPlayingDetailYear => 'Year';

  @override
  String get nowPlayingDetailGenre => 'Genre';

  @override
  String get nowPlayingDetailBitrate => 'Bitrate';

  @override
  String get nowPlayingDetailSampleRate => 'Sample rate';

  @override
  String get nowPlayingDetailTrack => 'Track';

  @override
  String get nowPlayingDetailDisc => 'Disc';

  @override
  String get nowPlayingDetailLicense => 'License';

  @override
  String get nowPlayingDetailSource => 'Source';

  @override
  String get nowPlayingDetailNowPlaying => 'On air';

  @override
  String get genreRock => 'Rock';

  @override
  String get genrePop => 'Pop';

  @override
  String get genreJazz => 'Jazz';

  @override
  String get genreClassical => 'Classical';

  @override
  String get genreElectronic => 'Electronic';

  @override
  String get genreHipHop => 'Hip-Hop';

  @override
  String get genreBlues => 'Blues';

  @override
  String get genreCountry => 'Country';

  @override
  String get genreFolk => 'Folk';

  @override
  String get genreMetal => 'Metal';

  @override
  String get genrePunk => 'Punk';

  @override
  String get genreReggae => 'Reggae';

  @override
  String get genreLatin => 'Latin';

  @override
  String get genreDance => 'Dance';

  @override
  String get genreAlternative => 'Alternative';

  @override
  String get genreIndie => 'Indie';

  @override
  String get genreAmbient => 'Ambient';

  @override
  String get genreHouse => 'House';

  @override
  String get genreFunk => 'Funk';

  @override
  String get genreGospel => 'Gospel';

  @override
  String get genreWorld => 'World Music';

  @override
  String get genreNewAge => 'New Age';

  @override
  String get genreSoundtrack => 'Soundtrack';

  @override
  String get genreOpera => 'Opera';

  @override
  String get genreExperimental => 'Experimental';

  @override
  String get genreMusicWord => 'music';

  @override
  String get genreMusicWordShort => 'music';

  @override
  String get trackFactSource => 'Source';

  @override
  String get trackFactStorage => 'Location';

  @override
  String get trackFactStorageLocal => 'Local';

  @override
  String get trackFactStorageRemote => 'Remote';

  @override
  String get trackFactFormat => 'Format';

  @override
  String get trackFactQuality => 'Quality';

  @override
  String get trackFactQualityLossless => 'Lossless';

  @override
  String get trackFactQualityHiRes => 'Hi-Res';

  @override
  String get trackFactSize => 'Size';

  @override
  String get trackFactLyrics => 'Lyrics';

  @override
  String get trackFactLyricsIncluded => 'Included';

  @override
  String get trackFactPerformers => 'Performers';

  @override
  String get trackFactAdded => 'Added';

  @override
  String get trackFactDescription => 'Description';

  @override
  String get trackFactLive => 'Live';

  @override
  String get trackFactPath => 'File path';

  @override
  String get trackFactAddress => 'Online address';

  @override
  String get trackDetailsTooltip => 'Details';

  @override
  String get trackDetailsOpenPath => 'Open the file';

  @override
  String get trackDetailsOpenFailed => 'The file could not be opened';

  @override
  String get trackDetailsCopyAddress => 'Copy address';

  @override
  String get trackDetailsCopied => 'Copied to the clipboard';

  @override
  String get trackFactDuration => 'Duration';

  @override
  String get trackFactSourceId => 'Source ID';

  @override
  String get trackFactMediaType => 'Media type';

  @override
  String get trackFactCover => 'Cover';

  @override
  String get trackFactIdentity => 'Identity';

  @override
  String get trackFactHeaders => 'Request headers';

  @override
  String get trackFactRawData => 'Raw data';

  @override
  String get trackDetailsCopyCover => 'Copy cover';

  @override
  String get trackDetailsCopyIdentity => 'Copy identity';

  @override
  String get sourceStatusEnabled => 'Enabled';

  @override
  String get sourceStatusOff => 'Off';

  @override
  String get sourceStatusNeedsSetup => 'Setup needed';

  @override
  String get sourceStatusFailed => 'Failed';

  @override
  String get sourceStatusSkipped => 'Skipped';

  @override
  String get sourceStatusScanned => 'Scanned';

  @override
  String get sourceStatusTracks => 'Tracks';

  @override
  String get sourceStatusLastScan => 'Last scan';

  @override
  String get sourceStatusUnsupported => 'Unsupported';

  @override
  String get sourceStatusWaiting => 'Not scanned';

  @override
  String get jamendoFieldFormatHint => '192 kbps by default';

  @override
  String get subsonicFieldFormatHint => 'Original quality by default';

  @override
  String get subsonicFormatOriginal => 'Original quality';

  @override
  String get sourceRadioName => 'Internet radio';

  @override
  String get settingsEyebrow => 'Preferences';

  @override
  String get settingsSectionInterface => 'Interface';

  @override
  String get settingsLocalFirst => 'Local first';

  @override
  String get libraryEyebrow => 'Library';

  @override
  String get sourcesEyebrow => 'Connections';

  @override
  String get sidebarBrowse => 'Browse';

  @override
  String get sidebarConnect => 'Connect';

  @override
  String get sidebarLocalOnline => 'Local + online';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name desktop · $version';
  }

  @override
  String searchSourceError(String source, String message) {
    return '$source: $message';
  }

  @override
  String get radioNoChannelList => 'SomaFM did not return a list of stations';

  @override
  String get trayPlayPause => 'Play / Pause';

  @override
  String get trayPrevious => 'Previous';

  @override
  String get trayNext => 'Next';

  @override
  String get trayShowWindow => 'Show window';

  @override
  String get trayQuit => 'Quit';

  @override
  String get settingsSectionDesktop => 'Desktop';

  @override
  String get settingsDesktopTitle => 'Desktop integration';

  @override
  String get settingsDesktopDescription =>
      'Keep Tune playing in the background and open audio files with it by default';

  @override
  String get settingsCloseToTray =>
      'Minimize to the tray when the window closes';

  @override
  String get settingsCloseToTrayHint =>
      'Keep playing in the tray after the window is closed';

  @override
  String get settingsMediaControls => 'Show Tune in the system media controls';

  @override
  String get settingsMediaControlsHint =>
      'Let the media keys and the media menu control Tune';

  @override
  String get settingsSetDefaultPlayer => 'Set as default player';

  @override
  String get settingsDefaultPlayerActive => 'Already the default player';

  @override
  String get settingsDefaultPlayerDone => 'Tune is now the default player';

  @override
  String get settingsDefaultPlayerFailed =>
      'Could not change it, install the desktop entry first';

  @override
  String get settingsDefaultPlayerMissingEntry =>
      'The desktop entry is not installed yet, run linux/install-desktop-entry.sh';

  @override
  String get settingsSectionPlayback => 'Playback';

  @override
  String get settingsPlaybackTitle => 'Playback behavior';

  @override
  String get settingsPlaybackDescription =>
      'Startup behavior and what a single click and a double click on a track do';

  @override
  String get settingsResumePlaybackOnStartup =>
      'Resume the last session at launch';

  @override
  String get settingsResumePlaybackOnStartupHint =>
      'The queue and the playback position are always restored when Tune opens. This switch decides whether the song picks up playing right away; turn off to wait, paused';

  @override
  String get settingsReplaceQueueOnClick =>
      'Replace the play queue when a track is clicked';

  @override
  String get settingsReplaceQueueOnClickHint =>
      'When off, a click queues the track and plays it right away; the rest of the queue stays';

  @override
  String get settingsOnlyLikeOnDoubleClick =>
      'Only like the track on a double click';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      'When on, a double click only likes the track and leaves the music alone; when off, it plays the track as well';

  @override
  String get settingsFavoritesDoubleClickPlays =>
      'Play and replace the queue on a double click in Favorites';

  @override
  String get settingsFavoritesDoubleClickPlaysHint =>
      'When on, double-clicking a favorite plays it and replaces the play queue; when off, it only likes the track';

  @override
  String get sidebarDiscover => 'Discover';

  @override
  String get discoverEyebrow => 'DISCOVER';

  @override
  String get discoverTitle => 'What to play';

  @override
  String get discoverSubtitle =>
      'Picked from your library and favorites · computed on this machine';

  @override
  String get discoverRefresh => 'Shuffle picks';

  @override
  String get discoverWhy => 'How picks work';

  @override
  String get discoverWhyTitle => 'How these picks are made';

  @override
  String get discoverWhyBody =>
      'Discover uses only your library, the tracks you liked, the not-interested marks and the optional local listening history, and computes everything on this machine. Nothing is uploaded and no online source is searched for you.';

  @override
  String get discoverWhyLibrary => 'Tracks and metadata in your library';

  @override
  String get discoverWhyHearts => 'Tracks you marked with a heart';

  @override
  String get discoverWhyPrivacy =>
      'Computed locally, cleared whenever you want';

  @override
  String get discoverWhyClose => 'Got it';

  @override
  String get discoverSectionDailyMix => 'Today\'s mix';

  @override
  String discoverSectionArtist(String artist) {
    return 'Because you like $artist';
  }

  @override
  String discoverSectionExplore(String genre) {
    return 'A different taste: $genre';
  }

  @override
  String discoverSectionExploreEra(int decade) {
    return 'Back to the ${decade}s';
  }

  @override
  String get discoverSectionExploreEars => 'Something else';

  @override
  String get discoverSectionFresh => 'Just added';

  @override
  String discoverSectionSource(String source) {
    return 'From $source';
  }

  @override
  String get discoverSectionFallback => 'Picked from your library';

  @override
  String discoverDailyMixSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Familiar tracks + new finds · $countString tracks';
  }

  @override
  String get discoverPlay => 'Play';

  @override
  String get discoverAddAllShort => 'Queue';

  @override
  String get discoverPlayAll => 'Play all';

  @override
  String get discoverAddAllToQueue => 'Queue all';

  @override
  String get discoverShelfBack => 'Previous';

  @override
  String get discoverShelfForward => 'Next';

  @override
  String get discoverMoreActions => 'More actions';

  @override
  String get discoverDismiss => 'Not interested';

  @override
  String discoverDismissed(String title) {
    return 'Fewer picks like “$title”';
  }

  @override
  String get discoverUndo => 'Undo';

  @override
  String discoverAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Queued $countString tracks';
  }

  @override
  String get discoverAlreadyQueued => 'Those tracks are already in the queue';

  @override
  String get discoverReasonFavorite => 'You marked it';

  @override
  String discoverReasonArtist(String artist) {
    return 'Because you like $artist';
  }

  @override
  String discoverReasonGenre(String genre) {
    return 'You like $genre';
  }

  @override
  String discoverReasonEra(int decade) {
    return 'Back to the ${decade}s';
  }

  @override
  String get discoverReasonFresh => 'Just added';

  @override
  String get discoverReasonUnheard => 'Not played yet';

  @override
  String discoverReasonSource(String source) {
    return 'From $source';
  }

  @override
  String get discoverReasonFallback => 'Picked from your library';

  @override
  String get discoverEmptyLibraryTitle => 'Your library is empty';

  @override
  String get discoverEmptyLibrarySubtitle =>
      'Scan local music or connect a source, and the discover page will have something to pick';

  @override
  String get discoverScanMusic => 'Scan music';

  @override
  String get discoverConnectSources => 'Connect sources';

  @override
  String get discoverNoCandidatesTitle => 'Nothing left to recommend';

  @override
  String get discoverNoCandidatesSubtitle =>
      'Browse the library, or clear the not-interested marks';

  @override
  String get discoverGoToLibrary => 'Go to library';

  @override
  String get discoverLoadFailed => 'Discover could not load';

  @override
  String get discoverLoadFailedHint =>
      'The library is not readable right now. Try again in a moment.';

  @override
  String get discoverClearTitle => 'Clear discover history?';

  @override
  String get discoverClearMessage =>
      'This removes the not-interested marks, the artist marks and the local listening history. Favorites, the library and the queue are not touched.';

  @override
  String get discoverCleared => 'Discover history cleared';

  @override
  String get settingsSectionDiscovery => 'Discover';

  @override
  String get settingsDiscoveryTitle => 'Discover page';

  @override
  String get settingsDiscoveryDescription =>
      'Picks are computed on this machine; your library is not uploaded';

  @override
  String get settingsDiscoveryPrivacy =>
      'Picks use only the library, the tracks you liked and the not-interested marks.';

  @override
  String get discoverFavoriteHint =>
      'Mark a few tracks with a heart and the picks get closer';

  @override
  String get settingsDiscoveryUseHistory => 'Local listening history';

  @override
  String get settingsDiscoveryUseHistoryHint =>
      'Stored on this machine to make picks closer to you; turning it off stops recording';

  @override
  String get discoverHistoryHint =>
      'Turn on local listening history and the picks get closer';

  @override
  String get discoverHistoryEnable => 'Turn on';

  @override
  String get discoverClearAll => 'Clear discover history';

  @override
  String get discoverWhyHistory =>
      'Optional local listening history (off by default)';

  @override
  String get settingsSectionSmartLyrics => 'Smart lyrics';

  @override
  String get settingsSmartLyricsTitle => 'Lyrics coverage';

  @override
  String get settingsSmartLyricsDescription =>
      'Tag sheets and lyrics files next to the tracks count; the numbers follow the last scan';

  @override
  String get settingsSmartLyricsTotal => 'Tracks';

  @override
  String get settingsSmartLyricsResolved => 'With lyrics';

  @override
  String get settingsSmartLyricsMissing => 'Gap to fill';

  @override
  String get settingsSmartLyricsPreset => 'Endpoint preset';

  @override
  String get settingsSmartLyricsPresetCustom => 'Custom';

  @override
  String get settingsSmartLyricsApiKey => 'API key';

  @override
  String get settingsSmartLyricsApiKeyHint => 'Paste a key of your own';

  @override
  String get settingsSmartLyricsAdvanced => 'Advanced';

  @override
  String get settingsSmartLyricsBaseUrl => 'Endpoint URL';

  @override
  String get settingsSmartLyricsAsrModels =>
      'Transcription models (comma-separated)';

  @override
  String get settingsSmartLyricsChatModel => 'Text model';

  @override
  String get settingsSmartLyricsPrivacy =>
      'Generating uploads the whole track to the endpoint you configured, and nowhere else.';

  @override
  String get settingsSmartLyricsSampled => 'Sampled';

  @override
  String get settingsSmartLyricsChecked => 'Checked';

  @override
  String get settingsSmartLyricsAccuracy => 'Accuracy';

  @override
  String get settingsSmartLyricsDrawSample => 'Draw the sample';

  @override
  String get settingsSmartLyricsAccuracyNote =>
      'The accuracy is judged by hand on a stratified sample of the resolved tracks (studio / live / rap / non-Chinese); the sample only grows, and the last verdict of a track counts.';

  @override
  String get settingsSmartLyricsLocal => 'Local engine';

  @override
  String get settingsSmartLyricsLocalOff => 'Off';

  @override
  String get settingsSmartLyricsLocalDownload => 'Download the model';

  @override
  String get settingsSmartLyricsLocalBusy => 'Downloading……';

  @override
  String get settingsSmartLyricsLocalReady => 'The model is ready';

  @override
  String get settingsSmartLyricsLocalFailed =>
      'The download failed: try again, or pick another model';

  @override
  String get settingsSmartLyricsBatch => 'Batch fill';

  @override
  String get settingsSmartLyricsBatchStart => 'Fill the library';

  @override
  String get settingsSmartLyricsBatchStop => 'Stop';

  @override
  String get settingsSmartLyricsBatchRetry => 'Recheck the failed tracks';

  @override
  String get settingsSmartLyricsBudget =>
      'Cloud budget (tracks per run, 0 for none)';

  @override
  String settingsSmartLyricsBatchIdle(int pending, int done, int failed) {
    return '$pending waiting · $done done · $failed failed';
  }

  @override
  String settingsSmartLyricsBatchRunning(int pending, int done) {
    return 'Filling: $pending waiting · $done done';
  }

  @override
  String settingsSmartLyricsBudgetPaused(int budget) {
    return 'The cloud budget ($budget tracks) is spent: this run paused — the rest waits';
  }

  @override
  String settingsSmartLyricsBatchFresh(int count) {
    return '$count new tracks are missing; press \"Fill the library\" to queue them';
  }

  @override
  String get settingsSmartLyricsLeakCheck =>
      'Free check: re-asks the human pool when the machine is idle — never the cloud, never the CPU';

  @override
  String get lyricsSmartGenerate => 'Smart lyrics';

  @override
  String get lyricsSmartGenerateNeedsKey =>
      'No key yet — paste one in Settings, Smart lyrics';

  @override
  String get lyricsSmartGenerating =>
      'Generating the lyrics — human sheets first, then the channels; a round takes minutes at most';

  @override
  String get lyricsSmartFailedAudio =>
      'The audio never arrived: no local copy and no stream to pull';

  @override
  String get lyricsSmartFailedUpload =>
      'The channels did not answer: try again later, or check the key and the endpoint in Settings';

  @override
  String get lyricsSmartFailedEmpty => 'No voice was heard';

  @override
  String get lyricsSmartNote =>
      'Machine sheet, from the vote pool — search again for better words';

  @override
  String get lyricsMarkLine => 'This line is wrong';

  @override
  String get lyricsUnmarkLine => 'Take the mark back';

  @override
  String get lyricsMarkSong => 'The whole track is wrong';

  @override
  String get lyricsMarkNotSung => 'This is not sung';

  @override
  String get lyricsMarksTitle => 'Marks';

  @override
  String get lyricsMarksEmpty =>
      'No marks yet — hear a wrong line, press the flag at its end';

  @override
  String lyricsMarkLineNumber(int line) {
    return 'Line $line';
  }

  @override
  String get lyricsMarkReword => 'Reword';

  @override
  String get lyricsMarkRewordTitle => 'Reword this line';

  @override
  String get lyricsMarkRewordSave => 'Save the words';

  @override
  String get lyricsMarkRevoke => 'Take back';

  @override
  String get lyricsMarkWaiting => 'Waiting for the re-solve';

  @override
  String get lyricsMarkResolved => 'Re-solved';

  @override
  String get lyricsMarkReworded => 'Reworded';

  @override
  String get lyricsMarkRevoked => 'Taken back';

  @override
  String get lyricsMarkSourceReader => 'Reader';

  @override
  String get lyricsMarkSourceSystem => 'Pool';

  @override
  String discoverSectionOnlineArtist(String artist) {
    return 'Found online: $artist';
  }

  @override
  String get discoverFindMoreOnline => 'Find more online';

  @override
  String get discoverFindingMore => 'Looking…';

  @override
  String get discoverNoOnlineSources => 'No online source is enabled';

  @override
  String discoverOnlineNoResults(String artist) {
    return 'No more tracks by $artist were found';
  }

  @override
  String get discoverOnlineFailed =>
      'The online lookup failed. Try again later.';

  @override
  String discoverOnlineFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Added $countString online tracks';
  }

  @override
  String get discoverReasonAdjacent => 'Same taste, a different artist';

  @override
  String get discoverLessArtist => 'Show less from this artist';

  @override
  String discoverDismissedArtist(String artist) {
    return 'Fewer picks from $artist';
  }

  @override
  String get discoverSectionFavoriteArtists => 'More from the artists you like';

  @override
  String get discoverReasonCompleted => 'You often finish this one';

  @override
  String smartPromptCorrect(String title, String artist, String draft) {
    return 'Here is a machine transcript of a song; it may hold wrong words. Title \"$title\", artist \"$artist\".\nFix the wrong characters; the number and the order of the lines must stay exactly as they are.\nAnswer with a JSON array of strings only, one line each, nothing else:\n$draft';
  }

  @override
  String smartPromptRebuild(String title, String artist) {
    return 'Write the lyrics of \"$title\" ($artist) from what you know of the song, one line a line, in the order they are sung.\nAnswer with a JSON array of strings only, nothing else. When you are not sure of the song, answer with an empty array — do not invent:';
  }

  @override
  String smartPromptTranslate(String target, String lines) {
    return 'Translate the lyrics below into $target, line for line: the number and the order of the lines must stay exactly as they are.\nAnswer with a JSON array of strings only, one line each, nothing else:\n$lines';
  }

  @override
  String smartPromptTransliterate(String lines) {
    return 'Write the lyrics below in Latin letters the way they sound, line for line: the number and the order of the lines must stay exactly as they are.\nAnswer with a JSON array of strings only, one line each, nothing else:\n$lines';
  }

  @override
  String get smartContrastTargetLanguage => 'Chinese';

  @override
  String get lyricsContrastTranslate => 'Translate';

  @override
  String get lyricsContrastTransliterate => 'Transliterate';

  @override
  String get lyricsContrastDone => 'On the sheet';

  @override
  String get settingsSmartLyricsAutoFill =>
      'Auto-fill: keep filling every track without lyrics until the library has none left';

  @override
  String get librarySortTooltip => 'Sort';

  @override
  String get librarySortRecent => 'Recently added';

  @override
  String get librarySortTitle => 'Title';

  @override
  String get librarySortArtist => 'Artist';

  @override
  String get librarySortAlbum => 'Album';

  @override
  String get librarySortDuration => 'Duration';

  @override
  String get libraryColumnTitle => 'Title';

  @override
  String get libraryColumnArtist => 'Artist';

  @override
  String get libraryColumnAlbum => 'Album';

  @override
  String get libraryColumnAdded => 'Added';

  @override
  String get libraryColumnDuration => 'Duration';

  @override
  String get libraryMoreActions => 'More actions';

  @override
  String get libraryViewColumns => 'Two-column view';

  @override
  String get libraryFilter => 'Filter';

  @override
  String get libraryFilterClearAll => 'Clear all';

  @override
  String get libraryFilterStatus => 'Status';

  @override
  String get libraryFilterStatusAll => 'All';

  @override
  String get libraryFilterStatusLiked => 'Liked';

  @override
  String get libraryFilterStatusWithLyrics => 'With lyrics';

  @override
  String get libraryFilterStatusWithoutLyrics => 'Missing lyrics';

  @override
  String get libraryFilterStatusInstrumental => 'Instrumental';

  @override
  String get libraryFilterGenres => 'Genre';

  @override
  String get libraryFilterDecades => 'Decade';

  @override
  String get libraryFilterArtists => 'Artist';

  @override
  String get libraryFilterLanguages => 'Language';

  @override
  String get libraryFilterFormats => 'Format';

  @override
  String get libraryFilterDurations => 'Duration';

  @override
  String get libraryFilterAdded => 'Added';

  @override
  String get libraryFilterDurationShort => '<2 min';

  @override
  String get libraryFilterDurationMedium => '2–5 min';

  @override
  String get libraryFilterDurationLong => '5–10 min';

  @override
  String get libraryFilterDurationEpic => '>10 min';

  @override
  String get libraryFilterAddedWeek => 'Last 7 days';

  @override
  String get libraryFilterAddedMonth => 'Last 30 days';

  @override
  String get libraryFilterAddedYear => 'Last year';

  @override
  String get libraryFilterAddedOlder => 'Older';

  @override
  String get libraryViewCategories => 'Category view';

  @override
  String get libraryAllSongs => 'All songs';

  @override
  String get libraryTreeExpand => 'Expand categories';

  @override
  String get libraryTreeCollapse => 'Collapse categories';

  @override
  String get languageZh => 'Chinese';

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => 'Japanese';

  @override
  String get languageKo => 'Korean';

  @override
  String get languageFr => 'French';

  @override
  String get languageDe => 'German';

  @override
  String get languageEs => 'Spanish';

  @override
  String get languageRu => 'Russian';
}

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
  String get librarySubtitle =>
      'Every track from your local and online sources';

  @override
  String get libraryClearSearch => 'Clear search';

  @override
  String get libraryFilterSources => 'Filter sources';

  @override
  String get libraryAllSources => 'All sources';

  @override
  String get libraryScanAllSources => 'Scan all sources';

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
  String get queueTitle => 'Queue';

  @override
  String get queueSubtitle => 'Current play order';

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
  String get favoritesTitle => 'Liked';

  @override
  String get favoritesSubtitle => 'The tracks you marked with a heart';

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
  String get sourcesGroupAdded => 'Added by me';

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
  String get fieldLimitStations => 'Stations per scan';

  @override
  String fieldLimitHint(int count, int max) {
    return '$count by default, $max at most';
  }

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
  String get settingsTitle => 'Settings';

  @override
  String get settingsSubtitle =>
      'Adjust the look, the language and your local library.';

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
  String get neteaseHint =>
      'Enter the address of your own NeteaseCloudMusicApi, e.g. http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API address';

  @override
  String get neteaseFieldQueryHint => 'e.g. trending, an artist';

  @override
  String get neteaseHotKeyword => 'trending';

  @override
  String get neteaseEmptyResponse =>
      'The NetEase API returned an empty response';

  @override
  String get neteaseNoStream =>
      'The service returned no playable address. You may need to sign in on the server, or the track is restricted.';

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
  String get sourceNeteaseName => 'NetEase Cloud Music API';

  @override
  String get sourceNeteaseDescription =>
      'Connects to a self-hosted NeteaseCloudMusicApi service';

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
  String get itunesEmptyResponse => 'The iTunes API returned an empty response';

  @override
  String get itunesFieldQueryHint => 'e.g. jazz, piano, lo-fi';

  @override
  String get itunesHint => 'Enter a search keyword, e.g. jazz, piano or lo-fi';

  @override
  String get itunesNoMatch => 'No matching iTunes tracks';

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
  String get sourceItunesDescription =>
      '30 second previews from the iTunes catalog';

  @override
  String get sourceItunesName => 'Store previews';

  @override
  String get sourcePodcastRssDescription =>
      'Turns any podcast RSS feed into playable episodes';

  @override
  String get sourcePodcastRssName => 'Podcasts';

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
  String get libraryEyebrow => 'Collection';

  @override
  String get sourcesEyebrow => 'Connections';

  @override
  String get sidebarCollect => 'Collect';

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
      'What a single click and a double click on a track do';

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
}

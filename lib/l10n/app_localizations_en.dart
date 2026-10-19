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
  String get confirm => 'Confirm';

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
  String get musicLibrary => 'Library';

  @override
  String get navLibrary => 'Library';

  @override
  String get navQueue => 'Queue';

  @override
  String get navSources => 'Sources';

  @override
  String get navSettings => 'Settings';

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
    return '$count tracks';
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
  String get playerNowPlaying => 'Now playing';

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
  String get playerQueue => 'Queue';

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
    return '$count in queue';
  }

  @override
  String get nowPlayingEmptyTitle => 'Nothing is playing yet';

  @override
  String get nowPlayingEmptySubtitle => 'Pick one from the library to begin';

  @override
  String get nowPlayingUnnamedTrack => 'Untitled track';

  @override
  String get nowPlayingLocalMusic => 'Local music';

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
  String audioSourceDownloading(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get audioSourceCached => 'Offline ready';

  @override
  String get audioSourceFailed => 'Download failed';

  @override
  String get routerNotFoundTitle => 'Page not found';

  @override
  String get routerBackToLibrary => 'Back to library';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get sourcesSubtitle => 'Online catalogs and scan folders';

  @override
  String get sourcesAutoScan => 'Scan on startup';

  @override
  String get sourcesAutoScanDescription =>
      'Every enabled source refreshes on startup. A failure never touches your local library.';

  @override
  String get sourcesScanAll => 'Scan all sources';

  @override
  String get sourcesImportPlugin => 'Import plugin';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Remote sources can take a few seconds';

  @override
  String get sourcesScanCompleted => 'Scan finished';

  @override
  String get sourcesImportPluginTitle => 'Import a music plugin';

  @override
  String get sourcesImportPluginMessage =>
      'Plugins are third-party JavaScript. They run inside the app and can reach the network. Only import sources you trust. A plugin stays disabled until you give it a search keyword.';

  @override
  String get sourcesPluginUnreadable => 'Could not read the plugin file';

  @override
  String get sourcesPluginTooLarge => 'The plugin file cannot exceed 2 MB';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return 'Imported and enabled $name';
  }

  @override
  String sourcesPluginImported(String name) {
    return 'Imported $name. It joins the scan once you add a keyword and enable it.';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'Could not import the plugin: $error';
  }

  @override
  String get sourcesPluginActions => 'Plugin actions';

  @override
  String get sourcesConfigure => 'Configure';

  @override
  String get sourcesDeletePlugin => 'Delete plugin';

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
    return '$count tracks · $time';
  }

  @override
  String get sourcesSkipped => 'Skipped';

  @override
  String get sourcesScanFailed => 'Scan failed';

  @override
  String get sourcesDeletePluginTitle => 'Delete the plugin?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return 'This deletes the script, the settings and the scanned songs of $name.';
  }

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
  String get sourceKindPlugin => 'Plugin';

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
  String get sourcesNotLoaded => 'The source list is still loading';

  @override
  String get sourcesPlatformNoPlugin =>
      'This platform does not support JavaScript plugins';

  @override
  String get sourcesUpdatePlugin => 'Update plugin';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name was updated to $version';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name is already up to date';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'Could not update the plugin: $error';
  }

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
  String get settingsAboutTitle => 'About Tune';

  @override
  String get settingsChooseFolder => 'Choose a music folder';

  @override
  String get settingsFolderAdded => 'Scan folder added';

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
    return '$count paths';
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
      'Type a keyword and press enter. Openverse, Jamendo, Internet Archive and every imported plugin are searched in parallel.';

  @override
  String get searchNoResults => 'No results';

  @override
  String get searchNoResultsDescription => 'Try another keyword.';

  @override
  String get searchNoMatch => 'No matching songs';

  @override
  String get searchNoMatchDescription => 'Try another keyword.';

  @override
  String searchSearching(String query) {
    return 'Searching for “$query”';
  }

  @override
  String searchResultCount(int count) {
    return '$count tracks';
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
    return 'Scanned $count songs';
  }

  @override
  String scanSongCountShort(int count) {
    return '$count songs';
  }

  @override
  String get scanSourceNotConfigured => 'The source is not configured yet';

  @override
  String get scanCachedTooSoon =>
      'Cache kept, the last scan is still too recent';

  @override
  String scanSummary(int songs, int sources) {
    return 'Scanned $sources sources, $songs songs in total';
  }

  @override
  String scanUpdated(int failed, int songs) {
    return 'Updated $songs songs, $failed sources failed';
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
  String sourceErrorPluginLoad(String message) {
    return 'Could not load the plugin: $message';
  }

  @override
  String get sourceErrorUnsupported => 'This source is not supported yet';

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
    return '$count hours';
  }

  @override
  String intervalMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get localSourceHint => 'Add a scan folder in the library settings';

  @override
  String get localSourceNotConfigured => 'No local music folder configured';

  @override
  String get pluginSourceHint =>
      'Fill in a search keyword, e.g. an artist, piano or jazz';

  @override
  String get pluginFieldQuery => 'Search keyword';

  @override
  String get pluginFieldHint => 'e.g. an artist, piano, jazz';

  @override
  String pluginImportedVersion(String version) {
    return 'Imported MusicFree plugin · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'Plugin variable $key';
  }

  @override
  String get pluginFileMissing =>
      'The plugin file is missing. Import it again.';

  @override
  String get pluginRuntimeUnsupported =>
      'This platform does not support JavaScript music plugins. Import them on desktop or mobile.';

  @override
  String get pluginCompatLibrary => 'Plugin compatibility library';

  @override
  String get pluginBridgeScript => 'Plugin bridge script';

  @override
  String get pluginInit => 'Plugin initialization';

  @override
  String get pluginScript => 'Plugin script';

  @override
  String get pluginExports => 'Plugin exports';

  @override
  String get pluginNoExports =>
      'The plugin does not export a valid module.exports';

  @override
  String get pluginIncomplete =>
      'The plugin is incomplete: it needs the platform and search methods';

  @override
  String get pluginNoMediaSource =>
      'The plugin does not implement getMediaSource';

  @override
  String get pluginNoStream => 'The plugin returned no playable address';

  @override
  String get pluginRuntimeClosed => 'The plugin runtime is closed';

  @override
  String pluginCallFailed(String label, String message) {
    return '$label failed: $message';
  }

  @override
  String get pluginCallTimeout => 'The plugin call timed out';

  @override
  String get pluginUnknownData =>
      'The plugin returned data that could not be read';

  @override
  String get pluginCallError => 'The plugin call failed';

  @override
  String get pluginNoMatch => 'No matching songs';

  @override
  String pluginNoStreamResults(int count) {
    return 'The plugin returned $count results, but no playable address';
  }

  @override
  String get neteaseHint =>
      'Enter the address of your own NeteaseCloudMusicApi, e.g. http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API address';

  @override
  String get neteaseFieldQuery => 'Search keyword';

  @override
  String get neteaseFieldHint => 'e.g. trending, an artist';

  @override
  String get neteaseFieldLimit => 'Tracks per scan';

  @override
  String get neteaseFieldLimitHint => '20 by default, 50 at most';

  @override
  String get neteaseHotKeyword => 'trending';

  @override
  String get neteaseEmptyResponse =>
      'The NetEase API returned an empty response';

  @override
  String get neteaseNoMatch => 'No matching songs';

  @override
  String get neteaseNoStream =>
      'The service returned no playable address. You may need to sign in on the server, or the track is restricted.';

  @override
  String get openverseHint =>
      'Enter a scan keyword, e.g. piano, ambient or jazz';

  @override
  String get openverseFieldQuery => 'Scan keyword';

  @override
  String get openverseFieldHint => 'e.g. piano, ambient, jazz';

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
  String get sourceJamendoDescription =>
      'An open catalog of independent music. Needs a free Client ID.';

  @override
  String get sourceInternetArchiveDescription =>
      'The open audio collection of the Internet Archive';

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
  String get jamendoFieldQuery => 'Search keyword (optional)';

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
  String get internetArchiveFieldLimit => 'Tracks per scan';

  @override
  String get internetArchiveFieldLimitHint => '8 by default, 20 at most';

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
  String get pluginUpdateNoUrl =>
      'The plugin has no download address, so it cannot be checked for updates';

  @override
  String sourcesPluginUrlDownloadFailed(String error) {
    return 'Could not download the plugin: $error';
  }

  @override
  String pluginStepFailed(String error, String label) {
    return '$label failed: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'Import from URL';

  @override
  String get sourcesPluginUrlTitle => 'Plugin URL';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid => 'Please enter a valid http(s) link';

  @override
  String get pluginUrlInvalid =>
      'The plugin address is invalid, please use an http or https link';

  @override
  String get pluginUrlEmpty => 'The plugin script is empty';

  @override
  String get pluginUrlTooLarge => 'The plugin script exceeds the size limit';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'The plugin sandbox failed to start: $error';
  }

  @override
  String get pluginSandboxStartTimeout =>
      'The plugin sandbox timed out while starting';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'The plugin script exceeds the limit of $limit KB';
  }

  @override
  String get pluginRuntimeTerminated => 'The plugin runtime was terminated';

  @override
  String get pluginRuntimeTimeLimit =>
      'The plugin runtime exceeded its time limit';

  @override
  String get pluginSandboxNotReady => 'The plugin sandbox is not ready yet';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'The plugin call timed out after ${seconds}s';
  }

  @override
  String get pluginRuntimeCrashed => 'The plugin runtime crashed';

  @override
  String pluginFetchShimFailed(String message) {
    return 'The fetch shim failed to load: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return 'Unknown plugin call: $method';
  }

  @override
  String get pluginScriptMissing => 'The plugin script is missing';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'The plugin used more than the limit of $limit and was terminated';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter returned an empty response';

  @override
  String get ccmixterFieldLimit => 'Tracks per scan';

  @override
  String get ccmixterFieldLimitHint => '15 by default, 30 at most';

  @override
  String get ccmixterFieldQuery => 'Scan tag';

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
  String get itunesFieldLimit => 'Tracks per scan';

  @override
  String get itunesFieldLimitHint => '20 by default, 50 at most';

  @override
  String get itunesFieldQuery => 'Search keyword';

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
  String get podcastRssFieldLimit => 'Episodes per scan';

  @override
  String get podcastRssFieldLimitHint => '20 by default, 100 at most';

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
  String get sourceItunesDescription =>
      '30 second previews from the Apple Music catalog';

  @override
  String get sourcePodcastRssDescription =>
      'Turns any podcast RSS feed into playable episodes';

  @override
  String get sourcePodcastRssName => 'Podcasts';

  @override
  String get sourceSubsonicDescription =>
      'Connects to a self-hosted Navidrome or Subsonic library';

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
  String get subsonicFieldLimit => 'Tracks per scan';

  @override
  String get subsonicFieldLimitHint => '25 by default, 100 at most';

  @override
  String get subsonicFieldPassword => 'Password';

  @override
  String get subsonicFieldPasswordHint =>
      'Used to sign the access token, never sent in plain text';

  @override
  String get subsonicFieldQuery => 'Search keyword (optional)';

  @override
  String get subsonicFieldQueryHint => 'e.g. jazz, piano';

  @override
  String get subsonicFieldServer => 'Server address';

  @override
  String get subsonicFieldServerHint => 'e.g. http://localhost:4533';

  @override
  String get subsonicFieldUser => 'User name';

  @override
  String get subsonicFieldUserHint => 'The login name of your music server';

  @override
  String get subsonicHint =>
      'Enter the address and the account of your own music server, e.g. http://localhost:4533';

  @override
  String get subsonicNoMatch => 'No matching tracks';
}

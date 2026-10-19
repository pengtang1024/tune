// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'Ein lokal-zuerst Desktop-Musikplayer';

  @override
  String get appStartFailed => 'Tune konnte nicht gestartet werden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get remove => 'Entfernen';

  @override
  String get clear => 'Leeren';

  @override
  String get close => 'Schließen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get chooseFile => 'Datei wählen';

  @override
  String get unknownError => 'Unbekannter Fehler';

  @override
  String get scanNow => 'Jetzt scannen';

  @override
  String get search => 'Suchen';

  @override
  String get scanning => 'Wird gescannt';

  @override
  String get about => 'Über';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Design';

  @override
  String get lightMode => 'Heller Modus';

  @override
  String get darkMode => 'Dunkler Modus';

  @override
  String get systemMode => 'Systemeinstellung';

  @override
  String get musicLibrary => 'Bibliothek';

  @override
  String get navLibrary => 'Bibliothek';

  @override
  String get navQueue => 'Warteschlange';

  @override
  String get navSources => 'Quellen';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get libraryTitle => 'Bibliothek';

  @override
  String get librarySubtitle => 'Alle Titel aus lokalen und Online-Quellen';

  @override
  String get libraryClearSearch => 'Suche löschen';

  @override
  String get libraryFilterSources => 'Quellen filtern';

  @override
  String get libraryAllSources => 'Alle Quellen';

  @override
  String get libraryScanAllSources => 'Alle Quellen scannen';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Titel';
  }

  @override
  String get libraryNoMatchTitle => 'Keine passenden Titel';

  @override
  String get libraryNoMatchSubtitle =>
      'Anderen Suchbegriff verwenden oder Suche zurücksetzen';

  @override
  String get librarySourceEmptyTitle => 'Keine Titel aus dieser Quelle';

  @override
  String get librarySourceEmptySubtitle =>
      'Zu allen Quellen wechseln oder diese erneut scannen';

  @override
  String get libraryViewAllSources => 'Alle Quellen anzeigen';

  @override
  String get libraryScanningTitle => 'Musik wird gescannt';

  @override
  String get libraryEmptyTitle => 'Noch keine Musik';

  @override
  String get libraryEmptySubtitle =>
      'Ordnen Sie einen lokalen Ordner oder eine aktive Online-Quelle dem Scannen zu, oder passen Sie die Quellen in den Einstellungen an.';

  @override
  String get libraryLoadFailedTitle => 'Bibliothek konnte nicht geladen werden';

  @override
  String get libraryAddedToQueue => 'Zur Warteschlange hinzugefügt';

  @override
  String libraryScanPaths(String paths) {
    return 'Scan-Ordner: $paths';
  }

  @override
  String get libraryAddToQueue => 'Zur Warteschlange';

  @override
  String get queueTitle => 'Warteschlange';

  @override
  String get queueSubtitle => 'Aktuelle Wiedergabereihenfolge';

  @override
  String get queueEmptyTitle => 'Die Warteschlange ist leer';

  @override
  String get queueEmptySubtitle =>
      'Wählen Sie einen Titel aus der Bibliothek oder fügen Sie Titel zur Warteschlange hinzu';

  @override
  String get queueGoToLibrary => 'Zur Bibliothek';

  @override
  String get queueClearTitle => 'Warteschlange leeren?';

  @override
  String get queueClearMessage =>
      'Die Wiedergabe stoppt. Die Titel bleiben in der Bibliothek.';

  @override
  String get playerNowPlaying => 'Aktuelle Wiedergabe';

  @override
  String get playerCollapse => 'Einklappen';

  @override
  String get playerPrevious => 'Vorheriger Titel';

  @override
  String get playerNext => 'Nächster Titel';

  @override
  String get playerPlay => 'Abspielen';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerMute => 'Stumm';

  @override
  String get playerUnmute => 'Ton an';

  @override
  String get playerQueue => 'Warteschlange';

  @override
  String get playerPlayModeSequential => 'Alle wiederholen';

  @override
  String get playerPlayModeRepeatOne => 'Titel wiederholen';

  @override
  String get playerPlayModeShuffle => 'Zufall';

  @override
  String get playerNoSongTitle => 'Wählen Sie einen Titel';

  @override
  String get playerUnknownArtist => 'Unbekannter Künstler';

  @override
  String get playerDockReady => 'Tune · BEREIT';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString in der Warteschlange';
  }

  @override
  String get nowPlayingEmptyTitle => 'Es läuft noch nichts';

  @override
  String get nowPlayingEmptySubtitle =>
      'Wählen Sie einen Titel aus der Bibliothek';

  @override
  String get nowPlayingUnnamedTrack => 'Unbenannter Titel';

  @override
  String get nowPlayingLocalMusic => 'Lokale Musik';

  @override
  String get trackUnknownTitle => 'Unbekannter Titel';

  @override
  String playbackFailed(String error) {
    return 'Wiedergabe fehlgeschlagen: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return 'Pause fehlgeschlagen: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return 'Fortsetzen fehlgeschlagen: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'Springen fehlgeschlagen: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return 'Lautstärke konnte nicht gesetzt werden: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return 'Geschwindigkeit konnte nicht gesetzt werden: $error';
  }

  @override
  String get audioSourceLocal => 'Lokale Datei';

  @override
  String audioSourceDownloading(int percent) {
    return 'Download $percent%';
  }

  @override
  String get audioSourceCached => 'Offline bereit';

  @override
  String get audioSourceFailed => 'Download fehlgeschlagen';

  @override
  String get routerNotFoundTitle => 'Seite nicht gefunden';

  @override
  String get routerBackToLibrary => 'Zurück zur Bibliothek';

  @override
  String get sourcesTitle => 'Quellen';

  @override
  String get sourcesSubtitle =>
      'Online-Kataloge, selbst gehostete Dienste und Scan-Ordner';

  @override
  String get sourcesAutoScan => 'Beim Start scannen';

  @override
  String get sourcesAutoScanDescription =>
      'Jede aktive Quelle wird beim Start aktualisiert. Ein Fehler berührt die lokale Bibliothek nie.';

  @override
  String get sourcesScanAll => 'Alle Quellen scannen';

  @override
  String get sourcesImportPlugin => 'Plugin importieren';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Remote-Quellen können einige Sekunden brauchen';

  @override
  String get sourcesScanCompleted => 'Scan abgeschlossen';

  @override
  String get sourcesImportPluginTitle => 'Musik-Plugin importieren';

  @override
  String get sourcesImportPluginMessage =>
      'Plugins sind JavaScript-Code von Drittanbietern. Sie laufen in der App und können auf das Netzwerk zugreifen. Importieren Sie nur Quellen, denen Sie vertrauen. Ein Plugin bleibt deaktiviert, bis Sie ein Suchwort hinterlegen.';

  @override
  String get sourcesPluginUnreadable =>
      'Plugin-Datei konnte nicht gelesen werden';

  @override
  String get sourcesPluginTooLarge =>
      'Die Plugin-Datei darf höchstens 2 MB groß sein';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return '$name importiert und aktiviert';
  }

  @override
  String sourcesPluginImported(String name) {
    return '$name importiert. Mit Suchwort und Aktivierung nimmt es am Scan teil';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'Plugin-Import fehlgeschlagen: $error';
  }

  @override
  String get sourcesPluginActions => 'Plugin-Aktionen';

  @override
  String get sourcesConfigure => 'Konfigurieren';

  @override
  String get sourcesDeletePlugin => 'Plugin löschen';

  @override
  String get sourcesUnsupported =>
      'Diese Quelle wird in dieser Version nicht unterstützt';

  @override
  String get sourcesDisabled => 'Aus';

  @override
  String get sourcesNeedsConfiguration => 'Konfiguration nötig';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return 'Konfiguration nötig: $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return 'Letzter Scan $time';
  }

  @override
  String get sourcesAutoScanLocal =>
      'Lokale Ordner werden nach dem Start gescannt';

  @override
  String get sourcesWaitingFirstScan => 'Warten auf den ersten Scan';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Titel · $time';
  }

  @override
  String get sourcesSkipped => 'Übersprungen';

  @override
  String get sourcesScanFailed => 'Scan fehlgeschlagen';

  @override
  String get sourcesDeletePluginTitle => 'Plugin löschen?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return 'Damit werden Skript, Einstellungen und gescannte Titel von $name gelöscht.';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get sourceKindLocal => 'Lokal';

  @override
  String get sourceKindOpenCatalog => 'Offener Katalog';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => 'Plugin';

  @override
  String sourcesConfigureTitle(String name) {
    return '$name konfigurieren';
  }

  @override
  String sourcesFieldRequired(String label) {
    return 'Bitte $label ausfüllen';
  }

  @override
  String get sourcesFieldNumeric => 'Bitte eine Zahl eingeben';

  @override
  String get sourcesNotLoaded => 'Die Quellenliste wird noch geladen';

  @override
  String get sourcesPlatformNoPlugin =>
      'Diese Plattform unterstützt keine JavaScript-Plugins';

  @override
  String get sourcesUpdatePlugin => 'Plugin aktualisieren';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name wurde auf $version aktualisiert';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name ist bereits aktuell';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'Plugin-Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get playerLyrics => 'Liedtext';

  @override
  String get lyricsLoading => 'Liedtext wird geladen';

  @override
  String lyricsFailed(String error) {
    return 'Liedtext konnte nicht geladen werden: $error';
  }

  @override
  String get lyricsMissing => 'Dieses Lied hat keinen Liedtext';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsSubtitle =>
      'Darstellung, Sprache und lokale Bibliothek anpassen.';

  @override
  String get settingsThemeDescription =>
      'Wählen Sie das Erscheinungsbild und die Sprache der Oberfläche.';

  @override
  String get settingsLanguageDescription =>
      'Sprache der Oberfläche und der Systemmenüs';

  @override
  String get settingsLibraryDescription =>
      'Tune sucht ausschließlich in diesen Ordnern nach Audiodateien.';

  @override
  String get settingsDefaultPath => 'Standard';

  @override
  String get settingsNoDefaultFolder => 'Kein Standard-Musikordner gefunden';

  @override
  String get settingsCustomPath => 'Benutzerdefiniert';

  @override
  String get settingsAddFolder => 'Ordner hinzufügen';

  @override
  String get settingsClearLibrary => 'Bibliothek leeren';

  @override
  String get settingsScanSafetyNote =>
      'Der Scan liest nur Audiodateien. Am Datenträger wird nichts geändert oder gelöscht.';

  @override
  String get settingsAboutTitle => 'Über Tune';

  @override
  String get settingsChooseFolder => 'Musikordner wählen';

  @override
  String get settingsFolderAdded => 'Scan-Ordner hinzugefügt';

  @override
  String get settingsScanDone => 'Scan abgeschlossen';

  @override
  String get settingsClearLibraryTitle => 'Bibliothek leeren?';

  @override
  String get settingsClearLibraryMessage =>
      'Nur der Scan-Verlauf von Tune wird gelöscht. Audiodateien auf der Festplatte bleiben erhalten.';

  @override
  String get settingsLibraryCleared => 'Bibliothek geleert';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Pfade';
  }

  @override
  String get searchOnlineTitle => 'Online suchen';

  @override
  String get searchOnlineHint =>
      'Online-Quellen durchsuchen, z. B. Jazz, Piano, Lo-Fi';

  @override
  String get searchOnlineDescription =>
      'Durchsucht Ihre aktiven Online-Quellen. Ergebnisse landen nicht in der Bibliothek.';

  @override
  String get searchOnlinePrompt => 'Online-Quellen durchsuchen';

  @override
  String get searchOnlinePromptDescription =>
      'Geben Sie ein Stichwort ein und drücken Sie die Eingabetaste. Alle aktivierten Online-Quellen und importierten Plugins werden parallel durchsucht.';

  @override
  String get searchNoResults => 'Keine Ergebnisse';

  @override
  String get searchNoResultsDescription =>
      'Versuchen Sie ein anderes Stichwort.';

  @override
  String get searchNoMatch => 'Keine passenden Titel';

  @override
  String get searchNoMatchDescription => 'Versuchen Sie ein anderes Stichwort.';

  @override
  String searchSearching(String query) {
    return 'Suche nach „$query“';
  }

  @override
  String searchResultCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Titel';
  }

  @override
  String get searchPlayAll => 'Alle abspielen';

  @override
  String get searchAddToQueue => 'Zur Warteschlange';

  @override
  String searchAddedToQueue(String title) {
    return 'Zur Warteschlange hinzugefügt: $title';
  }

  @override
  String get searchNoSourcesEnabled =>
      'Keine Online-Quelle ist aktiviert. Aktivieren Sie zuerst eine in den Einstellungen.';

  @override
  String get searchFailedShort => 'Suche fehlgeschlagen';

  @override
  String searchFailed(String error) {
    return 'Online-Suche fehlgeschlagen: $error';
  }

  @override
  String get scanPreparing => 'Scan wird vorbereitet…';

  @override
  String get scanNoEnabledSources => 'Keine Quelle ist aktiviert';

  @override
  String get scanNoLocalFolders => 'Kein Musikordner zum Scannen';

  @override
  String scanProgressPercent(int percent) {
    return 'Scan $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'Alle Quellen sind fehlgeschlagen';

  @override
  String scanFailed(String error) {
    return 'Scan fehlgeschlagen: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'Bibliothek konnte nicht geleert werden: $error';
  }

  @override
  String get scanNoAudioFiles => 'Keine Audiodateien gefunden';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Titel gescannt';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString Titel';
  }

  @override
  String get scanSourceNotConfigured =>
      'Die Quelle ist noch nicht konfiguriert';

  @override
  String get scanCachedTooSoon =>
      'Cache beibehalten, der letzte Scan liegt zu kurz zurück';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$sourcesString Quellen gescannt, insgesamt $songsString Titel';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '$songsString Titel aktualisiert, $failedString Quellen fehlgeschlagen';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'Zugriff verweigert (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited =>
      'Zu viele Anfragen (HTTP 429). Bitte später erneut versuchen.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'Die Schnittstelle lieferte HTTP $status';
  }

  @override
  String get sourceErrorTimeout => 'Zeitüberschreitung bei der Verbindung';

  @override
  String get sourceErrorConnection => 'Der Quelldienst ist nicht erreichbar';

  @override
  String get sourceErrorCertificate => 'Zertifikat konnte nicht geprüft werden';

  @override
  String get sourceErrorCancelled => 'Die Anfrage wurde abgebrochen';

  @override
  String sourceErrorNetwork(String message) {
    return 'Netzwerkanfrage fehlgeschlagen: $message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return 'Plugin konnte nicht geladen werden: $message';
  }

  @override
  String get sourceErrorUnsupported =>
      'Diese Quelle wird noch nicht unterstützt';

  @override
  String sourceErrorScanInterval(String interval) {
    return 'Der letzte Scan liegt weniger als $interval zurück';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'Zeitüberschreitung beim Scan nach ${seconds}s';
  }

  @override
  String intervalHours(int count) {
    return '$count Stunden';
  }

  @override
  String intervalMinutes(int count) {
    return '$count Minuten';
  }

  @override
  String get localSourceHint =>
      'Fügen Sie einen Scan-Ordner in den Bibliothekseinstellungen hinzu';

  @override
  String get localSourceNotConfigured =>
      'Kein lokaler Musikordner konfiguriert';

  @override
  String get pluginSourceHint =>
      'Geben Sie ein Suchwort ein, z. B. Künstler, Piano oder Jazz';

  @override
  String get pluginFieldQuery => 'Suchwort';

  @override
  String get pluginFieldHint => 'z. B. Künstler, Piano, Jazz';

  @override
  String pluginImportedVersion(String version) {
    return 'Importiertes MusicFree-Plugin · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'Plugin-Variable $key';
  }

  @override
  String get pluginFileMissing =>
      'Die Plugin-Datei fehlt. Bitte erneut importieren.';

  @override
  String get pluginRuntimeUnsupported =>
      'Diese Plattform unterstützt keine JavaScript-Musikplugins. Importieren Sie sie auf Desktop oder Mobil.';

  @override
  String get pluginCompatLibrary => 'Plugin-Kompatibilitätsbibliothek';

  @override
  String get pluginBridgeScript => 'Plugin-Brückenskript';

  @override
  String get pluginInit => 'Plugin-Initialisierung';

  @override
  String get pluginScript => 'Plugin-Skript';

  @override
  String get pluginExports => 'Plugin-Exporte';

  @override
  String get pluginNoExports =>
      'Das Plugin exportiert kein gültiges module.exports';

  @override
  String get pluginIncomplete =>
      'Das Plugin ist unvollständig: platform- und search-Methode fehlen';

  @override
  String get pluginNoMediaSource =>
      'Das Plugin implementiert getMediaSource nicht';

  @override
  String get pluginNoStream =>
      'Das Plugin hat keine abspielbare Adresse geliefert';

  @override
  String get pluginRuntimeClosed =>
      'Die Plugin-Laufzeitumgebung ist geschlossen';

  @override
  String pluginCallFailed(String label, String message) {
    return '$label fehlgeschlagen: $message';
  }

  @override
  String get pluginCallTimeout => 'Zeitüberschreitung beim Plugin-Aufruf';

  @override
  String get pluginUnknownData => 'Das Plugin lieferte nicht lesbare Daten';

  @override
  String get pluginCallError => 'Der Plugin-Aufruf ist fehlgeschlagen';

  @override
  String get pluginNoMatch => 'Keine passenden Titel';

  @override
  String pluginNoStreamResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Das Plugin lieferte $countString Ergebnisse, aber keine abspielbare Adresse';
  }

  @override
  String get neteaseHint =>
      'Geben Sie die Adresse Ihres eigenen NeteaseCloudMusicApi an, z. B. http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API-Adresse';

  @override
  String get neteaseFieldQuery => 'Suchwort';

  @override
  String get neteaseFieldHint => 'z. B. Trends, ein Künstler';

  @override
  String get neteaseFieldLimit => 'Titel pro Scan';

  @override
  String get neteaseFieldLimitHint => 'Standard 20, höchstens 50';

  @override
  String get neteaseHotKeyword => 'Trends';

  @override
  String get neteaseEmptyResponse =>
      'Die NetEase-API lieferte eine leere Antwort';

  @override
  String get neteaseNoMatch => 'Keine passenden Titel';

  @override
  String get neteaseNoStream =>
      'Der Dienst lieferte keine abspielbare Adresse. Möglicherweise ist eine Anmeldung am Server nötig.';

  @override
  String get openverseHint =>
      'Geben Sie ein Stichwort ein, z. B. Piano, Ambient oder Jazz';

  @override
  String get openverseFieldQuery => 'Suchwort';

  @override
  String get openverseFieldHint => 'z. B. Piano, Ambient, Jazz';

  @override
  String get openverseEmptyResponse => 'Openverse lieferte eine leere Antwort';

  @override
  String get openverseNoMatch => 'Keine passenden offenen Audiodateien';

  @override
  String get sourceLocalName => 'Lokale Musik';

  @override
  String get sourceLocalDescription => 'Musikordner dieses Geräts durchsuchen';

  @override
  String get sourceOpenverseDescription =>
      'Offene Audio-Inhalte von Jamendo, Freesound, Wikimedia und mehr';

  @override
  String get sourceJamendoDescription =>
      'Ein offener Katalog unabhängiger Musik. Benötigt eine kostenlose Client ID.';

  @override
  String get sourceInternetArchiveDescription =>
      'Die offene Audio-Sammlung des Internet Archive';

  @override
  String get sourceNeteaseName => 'NetEase-Cloud-Music-API';

  @override
  String get sourceNeteaseDescription =>
      'Verbindet sich mit einem selbst gehosteten NeteaseCloudMusicApi-Dienst';

  @override
  String get jamendoHint =>
      'Holen Sie sich unter developer.jamendo.com eine kostenlose Client ID';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint =>
      'Kostenlos bei developer.jamendo.com beantragen';

  @override
  String get jamendoFieldQuery => 'Suchwort (optional)';

  @override
  String get jamendoFieldQueryHint => 'z. B. Jazz, Electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo lieferte eine leere Antwort';

  @override
  String get jamendoNoMatch => 'Keine passenden Jamendo-Titel';

  @override
  String get internetArchiveHint =>
      'Geben Sie eine Internet-Archive-Abfrage ein, z. B. collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => 'Abfrage';

  @override
  String get internetArchiveFieldLimit => 'Titel pro Scan';

  @override
  String get internetArchiveFieldLimitHint => 'Standard 8, höchstens 20';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive lieferte eine nicht lesbare Antwort';

  @override
  String get internetArchiveNoMatch =>
      'Keine abspielbare Archiv-Audio gefunden';

  @override
  String get downloadUnsupportedPlatform =>
      'Diese Plattform hat kein Dateisystem, Downloads können nicht zwischengespeichert werden';

  @override
  String get audioLoadFailed => 'Audio konnte nicht geladen werden';

  @override
  String get audioPathEmpty => 'Der Audiopfad ist leer';

  @override
  String get pluginUpdateNoUrl =>
      'Das Plugin hat keine Download-Adresse, daher kann es nicht auf Aktualisierungen geprüft werden';

  @override
  String sourcesPluginUrlDownloadFailed(String error) {
    return 'Plugin konnte nicht geladen werden: $error';
  }

  @override
  String pluginStepFailed(String error, String label) {
    return '$label fehlgeschlagen: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'Von URL importieren';

  @override
  String get sourcesPluginUrlTitle => 'Plugin-URL';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid =>
      'Bitte einen gültigen http(s)-Link eingeben';

  @override
  String get pluginUrlInvalid =>
      'Die Plugin-Adresse ist ungültig, bitte einen http- oder https-Link verwenden';

  @override
  String get pluginUrlEmpty => 'Das Plugin-Skript ist leer';

  @override
  String get pluginUrlTooLarge =>
      'Das Plugin-Skript überschreitet die Größenbeschränkung';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'Die Plugin-Sandbox konnte nicht gestartet werden: $error';
  }

  @override
  String get pluginSandboxStartTimeout =>
      'Zeitüberschreitung beim Start der Plugin-Sandbox';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'Das Plugin-Skript überschreitet das Limit von $limit KB';
  }

  @override
  String get pluginRuntimeTerminated =>
      'Die Plugin-Laufzeitumgebung wurde beendet';

  @override
  String get pluginRuntimeTimeLimit =>
      'Die Plugin-Laufzeitumgebung hat ihr Zeitlimit überschritten';

  @override
  String get pluginSandboxNotReady =>
      'Die Plugin-Sandbox ist noch nicht bereit';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'Der Plugin-Aufruf hat nach ${seconds}s überschritten';
  }

  @override
  String get pluginRuntimeCrashed =>
      'Die Plugin-Laufzeitumgebung ist abgestürzt';

  @override
  String pluginFetchShimFailed(String message) {
    return 'Der fetch-Shim konnte nicht geladen werden: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return 'Unbekannter Plugin-Aufruf: $method';
  }

  @override
  String get pluginScriptMissing => 'Das Plugin-Skript fehlt';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'Der Speicherverbrauch des Plugins hat das Limit von $limit überschritten und es wurde beendet';
  }

  @override
  String get ccmixterEmptyResponse =>
      'ccMixter hat eine leere Antwort geliefert';

  @override
  String get ccmixterFieldLimit => 'Titel pro Scan';

  @override
  String get ccmixterFieldLimitHint => 'Standard 15, höchstens 30';

  @override
  String get ccmixterFieldQuery => 'Such-Tag';

  @override
  String get ccmixterFieldQueryHint => 'z. B. jazz, ambient, electro';

  @override
  String get ccmixterHint =>
      'ccMixter-Tag eingeben, z. B. jazz, ambient oder electro';

  @override
  String get ccmixterNoMatch => 'Keine passenden ccMixter-Titel';

  @override
  String get itunesEmptyResponse =>
      'Die iTunes-API hat eine leere Antwort geliefert';

  @override
  String get itunesFieldLimit => 'Titel pro Scan';

  @override
  String get itunesFieldLimitHint => 'Standard 20, höchstens 50';

  @override
  String get itunesFieldQuery => 'Suchbegriff';

  @override
  String get itunesFieldQueryHint => 'z. B. jazz, piano, lo-fi';

  @override
  String get itunesHint => 'Suchbegriff eingeben, z. B. jazz, piano oder lo-fi';

  @override
  String get itunesNoMatch => 'Keine passenden iTunes-Titel';

  @override
  String get podcastRssEmptyFeed =>
      'Die Feed-Adresse lieferte ein leeres Dokument';

  @override
  String get podcastRssFieldFeed => 'Feed-Adresse';

  @override
  String get podcastRssFieldFeedHint => 'z. B. https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => 'Folgen pro Scan';

  @override
  String get podcastRssFieldLimitHint => 'Standard 20, höchstens 100';

  @override
  String get podcastRssHint => 'Adresse eines Podcast-Feeds (RSS) eingeben';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'Die Feed-Adresse lieferte ein nicht lesbares XML: $error';
  }

  @override
  String get podcastRssNoMatch => 'Der Feed enthält keine abspielbare Folge';

  @override
  String get sourceCcmixterDescription =>
      'Creative-Commons-Remixes und offene Musik';

  @override
  String get sourceItunesDescription =>
      '30 Sekunden Vorschauen aus dem Apple-Music-Katalog';

  @override
  String get sourcePodcastRssDescription =>
      'Macht aus jedem Podcast-RSS-Feed abspielbare Folgen';

  @override
  String get sourcePodcastRssName => 'Podcasts';

  @override
  String get sourceSubsonicDescription =>
      'Verbindet sich mit einer selbst gehosteten Navidrome- oder Subsonic-Bibliothek';

  @override
  String get subsonicAuthFailed =>
      'Der Musikserver ist nicht erreichbar, prüfen Sie Adresse und Konto';

  @override
  String get subsonicEmptyResponse =>
      'Der Musikserver hat eine leere Antwort geliefert';

  @override
  String subsonicError(String error) {
    return 'Der Musikserver meldet einen Fehler: $error';
  }

  @override
  String get subsonicFieldLimit => 'Titel pro Scan';

  @override
  String get subsonicFieldLimitHint => 'Standard 25, höchstens 100';

  @override
  String get subsonicFieldPassword => 'Passwort';

  @override
  String get subsonicFieldPasswordHint =>
      'Signiert das Zugriffstoken und wird nie im Klartext gesendet';

  @override
  String get subsonicFieldQuery => 'Suchbegriff (optional)';

  @override
  String get subsonicFieldQueryHint => 'z. B. jazz, piano';

  @override
  String get subsonicFieldServer => 'Serveradresse';

  @override
  String get subsonicFieldServerHint => 'z. B. http://localhost:4533';

  @override
  String get subsonicFieldUser => 'Benutzername';

  @override
  String get subsonicFieldUserHint => 'Der Anmeldename des Musikservers';

  @override
  String get subsonicHint =>
      'Adresse und Konto des eigenen Musikservers eingeben, z. B. http://localhost:4533';

  @override
  String get subsonicNoMatch => 'Keine passenden Titel';

  @override
  String get sourceAudiusDescription =>
      'Vollständige Titel aus dem offenen Audius-Netzwerk';

  @override
  String get audiusHint =>
      'Suchbegriff eingeben, z. B. jazz, ambient oder electronic';

  @override
  String get audiusFieldQuery => 'Suchbegriff';

  @override
  String get audiusFieldQueryHint => 'z. B. jazz, ambient, electronic';

  @override
  String get audiusFieldLimit => 'Titel pro Scan';

  @override
  String get audiusFieldLimitHint => 'Standard 20, höchstens 50';

  @override
  String get audiusEmptyResponse => 'Audius hat eine leere Antwort geliefert';

  @override
  String get audiusNoMatch => 'Keine passenden Titel bei Audius';

  @override
  String get sourceRadioDescription =>
      'Live-Streams öffentlicher Internetradiosender';

  @override
  String get radioHint =>
      'Verzeichnis der Sender wählen, ein Suchbegriff filtert sie';

  @override
  String get radioFieldProvider => 'Senderverzeichnis';

  @override
  String get radioFieldProviderHint =>
      'Alle Verzeichnisse, Radio Browser, SomaFM oder Radio Paradise';

  @override
  String get radioProviderAll => 'Alle Verzeichnisse';

  @override
  String get radioFieldQuery => 'Suchbegriff für Sender';

  @override
  String get radioFieldQueryHint => 'z. B. jazz, ambient oder SomaFM';

  @override
  String get radioFieldLimit => 'Sender pro Scan';

  @override
  String get radioFieldLimitHint => 'Standard 20, höchstens 100';

  @override
  String get radioNoMatch => 'Keine passenden Sender gefunden';

  @override
  String get sourceWikimediaDescription =>
      'Offenes Audio aus der Wikimedia Commons';

  @override
  String get wikimediaHint =>
      'Suchbegriff eingeben, z. B. piano, lecture oder birdsong';

  @override
  String get wikimediaFieldQuery => 'Suchbegriff';

  @override
  String get wikimediaFieldQueryHint => 'z. B. piano, lecture, birdsong';

  @override
  String get wikimediaFieldLimit => 'Dateien pro Scan';

  @override
  String get wikimediaFieldLimitHint => 'Standard 15, höchstens 30';

  @override
  String get wikimediaEmptyResponse =>
      'Wikimedia Commons hat eine leere Antwort geliefert';

  @override
  String get wikimediaNoMatch => 'Keine abspielbare Audiodatei gefunden';

  @override
  String get sourceJellyfinDescription =>
      'Mit einer eigenen Jellyfin-Bibliothek verbinden';

  @override
  String get jellyfinHint =>
      'Adresse und Konto des eigenen Jellyfin-Servers eingeben';

  @override
  String get jellyfinFieldServer => 'Serveradresse';

  @override
  String get jellyfinFieldServerHint => 'z. B. http://localhost:8096';

  @override
  String get jellyfinFieldUser => 'Benutzername';

  @override
  String get jellyfinFieldUserHint => 'Anmeldename des Jellyfin-Kontos';

  @override
  String get jellyfinFieldPassword => 'Passwort';

  @override
  String get jellyfinFieldPasswordHint =>
      'Wird für den Zugriffstoken verwendet';

  @override
  String get jellyfinFieldLimit => 'Titel pro Scan';

  @override
  String get jellyfinFieldLimitHint => 'Standard 50, höchstens 200';

  @override
  String get jellyfinEmptyResponse =>
      'Jellyfin hat eine leere Antwort geliefert';

  @override
  String get jellyfinNoMatch => 'Keine passenden Titel gefunden';

  @override
  String get jellyfinAuthFailed =>
      'Der Jellyfin-Server ist nicht erreichbar, Adresse und Konto prüfen';

  @override
  String get audioSourceStreaming => 'Live';

  @override
  String get playerLiveBadge => 'LIVE';

  @override
  String get nowPlayingLiveStream => 'Live-Stream ohne feste Länge';

  @override
  String get nowPlayingDetails => 'Titelinformationen';

  @override
  String get nowPlayingDetailAlbum => 'Album';

  @override
  String get nowPlayingDetailYear => 'Jahr';

  @override
  String get nowPlayingDetailGenre => 'Genre';

  @override
  String get nowPlayingDetailBitrate => 'Bitrate';

  @override
  String get nowPlayingDetailSampleRate => 'Abtastrate';

  @override
  String get nowPlayingDetailTrack => 'Titelnummer';

  @override
  String get nowPlayingDetailDisc => 'Disc';

  @override
  String get nowPlayingDetailLanguage => 'Sprache';

  @override
  String get nowPlayingDetailLicense => 'Lizenz';

  @override
  String get nowPlayingDetailSource => 'Quelle';

  @override
  String get nowPlayingDetailNowPlaying => 'Aktuell auf Sendung';

  @override
  String get jamendoFieldFormat => 'Qualität';

  @override
  String get jamendoFieldFormatHint => 'Standard 192 kbps';

  @override
  String get subsonicFieldFormat => 'Qualität';

  @override
  String get subsonicFieldFormatHint => 'Standard: Originalqualität';

  @override
  String get subsonicFormatOriginal => 'Originalqualität';

  @override
  String get sourceRadioName => 'Internetradio';
}

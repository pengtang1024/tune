// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'Un lecteur de musique local d’abord';

  @override
  String get appStartFailed => 'Échec du démarrage de Tune';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Enregistrer';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get clear => 'Vider';

  @override
  String get close => 'Fermer';

  @override
  String get retry => 'Réessayer';

  @override
  String get chooseFile => 'Choisir un fichier';

  @override
  String get unknownError => 'Erreur inconnue';

  @override
  String get scanNow => 'Scanner maintenant';

  @override
  String get search => 'Rechercher';

  @override
  String get scanning => 'Analyse en cours';

  @override
  String get about => 'À propos';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get lightMode => 'Mode clair';

  @override
  String get darkMode => 'Mode sombre';

  @override
  String get systemMode => 'Suivre le système';

  @override
  String get musicLibrary => 'Bibliothèque';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navQueue => 'File d’attente';

  @override
  String get navSources => 'Sources';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get libraryTitle => 'Bibliothèque';

  @override
  String get librarySubtitle =>
      'Tous les titres de vos sources locales et en ligne';

  @override
  String get libraryClearSearch => 'Effacer la recherche';

  @override
  String get libraryFilterSources => 'Filtrer les sources';

  @override
  String get libraryAllSources => 'Toutes les sources';

  @override
  String get libraryScanAllSources => 'Analyser toutes les sources';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString titres';
  }

  @override
  String get libraryNoMatchTitle => 'Aucun titre correspondant';

  @override
  String get libraryNoMatchSubtitle =>
      'Essayez un autre mot-clé ou effacez la recherche';

  @override
  String get librarySourceEmptyTitle => 'Aucun titre pour cette source';

  @override
  String get librarySourceEmptySubtitle =>
      'Passez à toutes les sources ou rescanez celle-ci';

  @override
  String get libraryViewAllSources => 'Afficher toutes les sources';

  @override
  String get libraryScanningTitle => 'Analyse de la musique';

  @override
  String get libraryEmptyTitle => 'Aucune musique pour l’instant';

  @override
  String get libraryEmptySubtitle =>
      'Analysez un dossier local ou une source en ligne activée, ou ajustez vos sources dans les paramètres.';

  @override
  String get libraryLoadFailedTitle => 'Impossible de charger la bibliothèque';

  @override
  String get libraryAddedToQueue => 'Ajouté à la file d’attente';

  @override
  String libraryScanPaths(String paths) {
    return 'Dossiers analysés : $paths';
  }

  @override
  String get libraryAddToQueue => 'Ajouter à la file d’attente';

  @override
  String get queueTitle => 'File d’attente';

  @override
  String get queueSubtitle => 'Ordre de lecture actuel';

  @override
  String get queueEmptyTitle => 'La file d’attente est vide';

  @override
  String get queueEmptySubtitle =>
      'Choisissez un titre dans la bibliothèque ou ajoutez des titres à la file';

  @override
  String get queueGoToLibrary => 'Aller à la bibliothèque';

  @override
  String get queueClearTitle => 'Vider la file d’attente ?';

  @override
  String get queueClearMessage =>
      'La lecture s’arrête. Les titres restent dans la bibliothèque.';

  @override
  String get playerNowPlaying => 'Lecture en cours';

  @override
  String get playerCollapse => 'Réduire';

  @override
  String get playerPrevious => 'Titre précédent';

  @override
  String get playerNext => 'Titre suivant';

  @override
  String get playerPlay => 'Lire';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerMute => 'Muet';

  @override
  String get playerUnmute => 'Réactiver le son';

  @override
  String get playerQueue => 'File d’attente';

  @override
  String get playerPlayModeSequential => 'Tout répéter';

  @override
  String get playerPlayModeRepeatOne => 'Répéter le titre';

  @override
  String get playerPlayModeShuffle => 'Aléatoire';

  @override
  String get playerNoSongTitle => 'Choisissez un titre pour commencer';

  @override
  String get playerUnknownArtist => 'Artiste inconnu';

  @override
  String get playerDockReady => 'Tune · PRÊT';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString dans la file';
  }

  @override
  String get nowPlayingEmptyTitle => 'Aucune lecture en cours';

  @override
  String get nowPlayingEmptySubtitle =>
      'Choisissez un titre dans la bibliothèque';

  @override
  String get nowPlayingUnnamedTrack => 'Titre sans nom';

  @override
  String get nowPlayingLocalMusic => 'Musique locale';

  @override
  String get trackUnknownTitle => 'Titre inconnu';

  @override
  String playbackFailed(String error) {
    return 'Échec de la lecture : $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return 'Impossible de mettre en pause : $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return 'Impossible de reprendre : $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'Impossible de se déplacer : $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return 'Impossible de régler le volume : $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return 'Impossible de régler la vitesse : $error';
  }

  @override
  String get audioSourceLocal => 'Fichier local';

  @override
  String audioSourceDownloading(int percent) {
    return 'Téléchargement $percent%';
  }

  @override
  String get audioSourceCached => 'Prêt hors ligne';

  @override
  String get audioSourceFailed => 'Échec du téléchargement';

  @override
  String get routerNotFoundTitle => 'Page introuvable';

  @override
  String get routerBackToLibrary => 'Retour à la bibliothèque';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get sourcesSubtitle =>
      'Catalogues en ligne, services auto-hébergés et dossiers de scan';

  @override
  String get sourcesAutoScan => 'Analyser au démarrage';

  @override
  String get sourcesAutoScanDescription =>
      'Chaque source active est actualisée au démarrage. Un échec n’altère jamais la bibliothèque locale.';

  @override
  String get sourcesScanAll => 'Analyser toutes les sources';

  @override
  String get sourcesImportPlugin => 'Importer un plugin';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Les sources distantes peuvent prendre quelques secondes';

  @override
  String get sourcesScanCompleted => 'Analyse terminée';

  @override
  String get sourcesImportPluginTitle => 'Importer un plugin musical';

  @override
  String get sourcesImportPluginMessage =>
      'Les plugins sont du JavaScript tiers. Ils s’exécutent dans l’application et peuvent accéder au réseau. N’importez que des sources de confiance. Un plugin reste désactivé tant que vous n’avez pas défini de mot-clé.';

  @override
  String get sourcesPluginUnreadable =>
      'Impossible de lire le fichier du plugin';

  @override
  String get sourcesPluginTooLarge =>
      'Le fichier du plugin ne peut pas dépasser 2 Mo';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return '$name importé et activé';
  }

  @override
  String sourcesPluginImported(String name) {
    return '$name importé. Il participe à l’analyse dès que vous ajoutez un mot-clé et l’activez';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'Échec de l’import du plugin : $error';
  }

  @override
  String get sourcesPluginActions => 'Actions du plugin';

  @override
  String get sourcesConfigure => 'Configurer';

  @override
  String get sourcesDeletePlugin => 'Supprimer le plugin';

  @override
  String get sourcesUnsupported =>
      'Cette source n’est pas prise en charge dans cette version';

  @override
  String get sourcesDisabled => 'Désactivée';

  @override
  String get sourcesNeedsConfiguration => 'Configuration requise';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return 'Configuration requise : $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return 'Dernière analyse $time';
  }

  @override
  String get sourcesAutoScanLocal =>
      'Les dossiers locaux sont analysés au démarrage';

  @override
  String get sourcesWaitingFirstScan => 'En attente de la première analyse';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString titres · $time';
  }

  @override
  String get sourcesSkipped => 'Ignorée';

  @override
  String get sourcesScanFailed => 'Échec de l’analyse';

  @override
  String get sourcesDeletePluginTitle => 'Supprimer le plugin ?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return 'Cela supprime le script, les réglages et les titres analysés de $name.';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name supprimé';
  }

  @override
  String get sourceKindLocal => 'Local';

  @override
  String get sourceKindOpenCatalog => 'Catalogue ouvert';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => 'Plugin';

  @override
  String sourcesConfigureTitle(String name) {
    return 'Configurer $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return 'Veuillez renseigner $label';
  }

  @override
  String get sourcesFieldNumeric => 'Veuillez saisir un nombre';

  @override
  String get sourcesNotLoaded =>
      'La liste des sources est encore en cours de chargement';

  @override
  String get sourcesPlatformNoPlugin =>
      'Cette plateforme ne prend pas en charge les plugins JavaScript';

  @override
  String get sourcesUpdatePlugin => 'Mettre à jour le plugin';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name a été mis à jour vers $version';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name est déjà à jour';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'Échec de la mise à jour du plugin : $error';
  }

  @override
  String get playerLyrics => 'Paroles';

  @override
  String get lyricsLoading => 'Chargement des paroles';

  @override
  String get lyricsFailed => 'Impossible de charger les paroles';

  @override
  String get lyricsMissing => 'Cette chanson n’a pas de paroles';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsSubtitle =>
      'Ajustez l’apparence, la langue et la bibliothèque locale.';

  @override
  String get settingsThemeDescription =>
      'Choisissez l’apparence de l’interface et sa langue.';

  @override
  String get settingsLanguageDescription =>
      'Langue de l’interface et des menus système';

  @override
  String get settingsLibraryDescription =>
      'Tune recherche les fichiers audio dans ces dossiers uniquement.';

  @override
  String get settingsDefaultPath => 'Par défaut';

  @override
  String get settingsNoDefaultFolder =>
      'Aucun dossier musical par défaut trouvé';

  @override
  String get settingsCustomPath => 'Personnalisé';

  @override
  String get settingsAddFolder => 'Ajouter un dossier';

  @override
  String get settingsClearLibrary => 'Vider la bibliothèque';

  @override
  String get settingsScanSafetyNote =>
      'L’analyse se contente de lire les fichiers audio. Rien n’est modifié ni supprimé sur le disque.';

  @override
  String get settingsAboutTitle => 'À propos de Tune';

  @override
  String get settingsChooseFolder => 'Choisir un dossier musical';

  @override
  String get settingsFolderAdded => 'Dossier d’analyse ajouté';

  @override
  String get settingsScanDone => 'Analyse terminée';

  @override
  String get settingsClearLibraryTitle => 'Vider la bibliothèque ?';

  @override
  String get settingsClearLibraryMessage =>
      'Seul l’historique d’analyse de Tune est effacé. Les fichiers audio du disque sont conservés.';

  @override
  String get settingsLibraryCleared => 'Bibliothèque vidée';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString chemins';
  }

  @override
  String get searchOnlineTitle => 'Rechercher en ligne';

  @override
  String get searchOnlineHint =>
      'Recherchez dans les sources en ligne, p. ex. jazz, piano, lo-fi';

  @override
  String get searchOnlineDescription =>
      'Recherche dans vos sources en ligne activées. Les résultats ne sont pas enregistrés dans la bibliothèque.';

  @override
  String get searchOnlinePrompt => 'Rechercher dans les sources en ligne';

  @override
  String get searchOnlinePromptDescription =>
      'Saisissez un mot-clé puis appuyez sur Entrée. Toutes les sources en ligne activées et les plugins importés sont interrogés en parallèle.';

  @override
  String get searchNoResults => 'Aucun résultat';

  @override
  String get searchNoResultsDescription => 'Essayez un autre mot-clé.';

  @override
  String get searchNoMatch => 'Aucun titre correspondant';

  @override
  String get searchNoMatchDescription => 'Essayez un autre mot-clé.';

  @override
  String searchSearching(String query) {
    return 'Recherche de « $query »';
  }

  @override
  String searchResultCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString titres';
  }

  @override
  String get searchPlayAll => 'Tout lire';

  @override
  String get searchAddToQueue => 'Ajouter à la file';

  @override
  String searchAddedToQueue(String title) {
    return 'Ajouté à la file d’attente : $title';
  }

  @override
  String get searchNoSourcesEnabled =>
      'Aucune source en ligne n’est activée. Activez-en une dans les paramètres.';

  @override
  String get searchFailedShort => 'Échec de la recherche';

  @override
  String searchFailed(String error) {
    return 'Échec de la recherche en ligne : $error';
  }

  @override
  String get scanPreparing => 'Préparation de l’analyse…';

  @override
  String get scanNoEnabledSources => 'Aucune source activée';

  @override
  String get scanNoLocalFolders => 'Aucun dossier musical à analyser';

  @override
  String scanProgressPercent(int percent) {
    return 'Analyse $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'Toutes les sources ont échoué';

  @override
  String scanFailed(String error) {
    return 'Échec de l’analyse : $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'Impossible de vider la bibliothèque : $error';
  }

  @override
  String get scanNoAudioFiles => 'Aucun fichier audio trouvé';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString titres analysés';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString titres';
  }

  @override
  String get scanSourceNotConfigured => 'La source n’est pas encore configurée';

  @override
  String get scanCachedTooSoon =>
      'Cache conservée, la dernière analyse est trop récente';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$sourcesString sources analysées, $songsString titres au total';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '$songsString titres mis à jour, échec de $failedString sources';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'Accès refusé (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited =>
      'Trop de requêtes (HTTP 429). Réessayez plus tard.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'Le service a renvoyé HTTP $status';
  }

  @override
  String get sourceErrorTimeout => 'Délai de connexion dépassé';

  @override
  String get sourceErrorConnection =>
      'Impossible de joindre le service de la source';

  @override
  String get sourceErrorCertificate => 'Impossible de vérifier le certificat';

  @override
  String get sourceErrorCancelled => 'La requête a été annulée';

  @override
  String sourceErrorNetwork(String message) {
    return 'Échec de la requête réseau : $message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return 'Impossible de charger le plugin : $message';
  }

  @override
  String get sourceErrorUnsupported =>
      'Cette source n’est pas encore prise en charge';

  @override
  String sourceErrorScanInterval(String interval) {
    return 'La dernière analyse date de moins de $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'L’analyse a expiré après $seconds s';
  }

  @override
  String intervalHours(int count) {
    return '$count heures';
  }

  @override
  String intervalMinutes(int count) {
    return '$count minutes';
  }

  @override
  String get localSourceHint =>
      'Ajoutez un dossier d’analyse dans les paramètres de la bibliothèque';

  @override
  String get localSourceNotConfigured =>
      'Aucun dossier musical local configuré';

  @override
  String get pluginSourceHint =>
      'Renseignez un mot-clé, p. ex. un artiste, piano ou jazz';

  @override
  String get pluginFieldQuery => 'Mot-clé de recherche';

  @override
  String get pluginFieldHint => 'p. ex. artiste, piano, jazz';

  @override
  String pluginImportedVersion(String version) {
    return 'Plugin MusicFree importé · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'Variable du plugin $key';
  }

  @override
  String get pluginFileMissing =>
      'Le fichier du plugin est introuvable. Importez-le à nouveau.';

  @override
  String get pluginRuntimeUnsupported =>
      'Cette plateforme ne prend pas en charge les plugins JavaScript. Importez-les sur ordinateur ou mobile.';

  @override
  String get pluginCompatLibrary => 'Bibliothèque de compatibilité des plugins';

  @override
  String get pluginBridgeScript => 'Script de pont du plugin';

  @override
  String get pluginInit => 'Initialisation du plugin';

  @override
  String get pluginScript => 'Script du plugin';

  @override
  String get pluginExports => 'Exports du plugin';

  @override
  String get pluginNoExports =>
      'Le plugin n’exporte pas de module.exports valide';

  @override
  String get pluginIncomplete =>
      'Le plugin est incomplet : les méthodes platform et search manquent';

  @override
  String get pluginNoMediaSource => 'Le plugin n’implémente pas getMediaSource';

  @override
  String get pluginNoStream => 'Le plugin n’a renvoyé aucune adresse lisible';

  @override
  String get pluginRuntimeClosed => 'L’environnement du plugin est fermé';

  @override
  String get pluginUnknownData => 'Le plugin a renvoyé des données illisibles';

  @override
  String get pluginCallError => 'Échec de l’appel du plugin';

  @override
  String get pluginNoMatch => 'Aucun titre correspondant';

  @override
  String pluginNoStreamResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Le plugin a renvoyé $countString résultats, mais aucune adresse lisible';
  }

  @override
  String get neteaseHint =>
      'Indiquez l’adresse de votre propre NeteaseCloudMusicApi, p. ex. http://localhost:3000';

  @override
  String get neteaseFieldApi => 'Adresse de l’API';

  @override
  String get neteaseFieldQuery => 'Mot-clé de recherche';

  @override
  String get neteaseFieldHint => 'p. ex. tendance, un artiste';

  @override
  String get neteaseFieldLimit => 'Titres par analyse';

  @override
  String get neteaseFieldLimitHint => '20 par défaut, 50 au maximum';

  @override
  String get neteaseHotKeyword => 'Tendances';

  @override
  String get neteaseEmptyResponse => 'L’API NetEase a renvoyé une réponse vide';

  @override
  String get neteaseNoMatch => 'Aucun titre correspondant';

  @override
  String get neteaseNoStream =>
      'Le service n’a renvoyé aucune adresse lisible. Une connexion au serveur peut être nécessaire.';

  @override
  String get openverseHint =>
      'Saisissez un mot-clé, p. ex. piano, ambient ou jazz';

  @override
  String get openverseFieldQuery => 'Mot-clé';

  @override
  String get openverseFieldHint => 'p. ex. piano, ambient, jazz';

  @override
  String get openverseEmptyResponse => 'Openverse a renvoyé une réponse vide';

  @override
  String get openverseNoMatch => 'Aucun audio ouvert correspondant';

  @override
  String get sourceLocalName => 'Musique locale';

  @override
  String get sourceLocalDescription =>
      'Analyse les dossiers musicaux de cet appareil';

  @override
  String get sourceOpenverseDescription =>
      'Audio ouvert de Jamendo, Freesound, Wikimedia et plus encore';

  @override
  String get sourceJamendoDescription =>
      'Un catalogue ouvert de musique indépendante. Nécessite un Client ID gratuit.';

  @override
  String get sourceInternetArchiveDescription =>
      'La collection audio ouverte de l’Internet Archive';

  @override
  String get sourceNeteaseName => 'API NetEase Cloud Music';

  @override
  String get sourceNeteaseDescription =>
      'Se connecte à un service NeteaseCloudMusicApi auto-hébergé';

  @override
  String get jamendoHint =>
      'Obtenez un Client ID gratuit sur developer.jamendo.com';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint =>
      'Demandez-en un gratuitement sur developer.jamendo.com';

  @override
  String get jamendoFieldQuery => 'Mot-clé (facultatif)';

  @override
  String get jamendoFieldQueryHint => 'p. ex. jazz, electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo a renvoyé une réponse vide';

  @override
  String get jamendoNoMatch => 'Aucun titre Jamendo correspondant';

  @override
  String get internetArchiveHint =>
      'Saisissez une requête Internet Archive, p. ex. collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => 'Requête';

  @override
  String get internetArchiveFieldLimit => 'Titres par analyse';

  @override
  String get internetArchiveFieldLimitHint => '8 par défaut, 20 au maximum';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive a renvoyé une réponse illisible';

  @override
  String get internetArchiveNoMatch => 'Aucun audio d’archive lisible trouvé';

  @override
  String get downloadUnsupportedPlatform =>
      'Cette plateforme n’a pas de système de fichiers, les téléchargements ne peuvent pas être mis en cache';

  @override
  String get audioLoadFailed => 'Échec du chargement de l’audio';

  @override
  String get audioPathEmpty => 'Le chemin du fichier audio est vide';

  @override
  String get pluginUpdateNoUrl =>
      'Le plugin n’a pas d’adresse de téléchargement, il ne peut pas vérifier les mises à jour';

  @override
  String pluginStepFailed(String error, String label) {
    return 'Échec de $label : $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'Importer depuis une URL';

  @override
  String get sourcesPluginUrlTitle => 'URL du plugin';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid =>
      'Veuillez saisir un lien http(s) valide';

  @override
  String get pluginUrlInvalid =>
      'L’adresse du plugin est invalide, utilisez un lien http ou https';

  @override
  String get pluginUrlEmpty => 'Le script du plugin est vide';

  @override
  String get pluginUrlTooLarge =>
      'Le script du plugin dépasse la taille maximale';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'Le bac à sable du plugin n’a pas démarré : $error';
  }

  @override
  String get pluginSandboxStartTimeout =>
      'Le bac à sable du plugin a expirué au démarrage';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'Le script du plugin dépasse la limite de $limit Ko';
  }

  @override
  String get pluginRuntimeTerminated =>
      'L’environnement du plugin a été interrompu';

  @override
  String get pluginRuntimeTimeLimit =>
      'L’environnement du plugin a dépassé son limite de temps';

  @override
  String get pluginSandboxNotReady =>
      'Le bac à sable du plugin n’est pas encore prêt';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'L’appel du plugin a expirué après $seconds s';
  }

  @override
  String get pluginRuntimeCrashed => 'L’environnement du plugin a planté';

  @override
  String pluginFetchShimFailed(String message) {
    return 'Le shim fetch n’a pas pu être chargé : $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return 'Appel de plugin inconnu : $method';
  }

  @override
  String get pluginScriptMissing => 'Le script du plugin est introuvable';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'Le plugin a dépassé la limite de $limit et a été interrompu';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter a renvoyé une réponse vide';

  @override
  String get ccmixterFieldLimit => 'Morceaux par analyse';

  @override
  String get ccmixterFieldLimitHint => '15 par défaut, 30 au maximum';

  @override
  String get ccmixterFieldQuery => 'Tag de recherche';

  @override
  String get ccmixterFieldQueryHint => 'par exemple jazz, ambient, electro';

  @override
  String get ccmixterHint =>
      'Saisissez un tag ccMixter, par exemple jazz, ambient ou electro';

  @override
  String get ccmixterNoMatch => 'Aucun morceau ccMixter correspondant';

  @override
  String get itunesEmptyResponse => 'L\'API iTunes a renvoyé une réponse vide';

  @override
  String get itunesFieldLimit => 'Morceaux par analyse';

  @override
  String get itunesFieldLimitHint => '20 par défaut, 50 au maximum';

  @override
  String get itunesFieldQuery => 'Mot-clé';

  @override
  String get itunesFieldQueryHint => 'par exemple jazz, piano, lo-fi';

  @override
  String get itunesHint =>
      'Saisissez un mot-clé, par exemple jazz, piano ou lo-fi';

  @override
  String get itunesNoMatch => 'Aucun morceau iTunes correspondant';

  @override
  String get podcastRssEmptyFeed =>
      'L\'adresse du flux a renvoyé un document vide';

  @override
  String get podcastRssFieldFeed => 'Adresse du flux';

  @override
  String get podcastRssFieldFeedHint =>
      'par exemple https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => 'Épisodes par analyse';

  @override
  String get podcastRssFieldLimitHint => '20 par défaut, 100 au maximum';

  @override
  String get podcastRssHint => 'Saisissez l\'adresse d\'un flux podcast (RSS)';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'L\'adresse du flux a renvoyé un XML illisible : $error';
  }

  @override
  String get podcastRssNoMatch => 'Le flux ne contient aucun épisode lisible';

  @override
  String get sourceCcmixterDescription =>
      'Remixes Creative Commons et musique libre';

  @override
  String get sourceItunesDescription =>
      'Extraits de 30 secondes du catalogue Apple Music';

  @override
  String get sourcePodcastRssDescription =>
      'Transforme un flux RSS de podcast en épisodes jouables';

  @override
  String get sourcePodcastRssName => 'Podcasts';

  @override
  String get sourceSubsonicDescription =>
      'Se connecte à une bibliothèque Navidrome ou Subsonic auto-hébergée';

  @override
  String get subsonicAuthFailed =>
      'Impossible de joindre le serveur de musique, vérifiez l\'adresse et le compte';

  @override
  String get subsonicEmptyResponse =>
      'Le serveur de musique a renvoyé une réponse vide';

  @override
  String subsonicError(String error) {
    return 'Le serveur de musique signale une erreur : $error';
  }

  @override
  String get subsonicFieldLimit => 'Morceaux par analyse';

  @override
  String get subsonicFieldLimitHint => '25 par défaut, 100 au maximum';

  @override
  String get subsonicFieldPassword => 'Mot de passe';

  @override
  String get subsonicFieldPasswordHint =>
      'Signe le jeton d\'accès et n\'est jamais envoyé en clair';

  @override
  String get subsonicFieldQuery => 'Mot-clé (facultatif)';

  @override
  String get subsonicFieldQueryHint => 'par exemple jazz, piano';

  @override
  String get subsonicFieldServer => 'Adresse du serveur';

  @override
  String get subsonicFieldServerHint => 'par exemple http://localhost:4533';

  @override
  String get subsonicFieldUser => 'Nom d\'utilisateur';

  @override
  String get subsonicFieldUserHint =>
      'Le nom de connexion de votre serveur de musique';

  @override
  String get subsonicHint =>
      'Saisissez l\'adresse et le compte de votre serveur de musique, par exemple http://localhost:4533';

  @override
  String get subsonicNoMatch => 'Aucun morceau correspondant';

  @override
  String get sourceAudiusDescription =>
      'Morceaux complets du réseau ouvert Audius';

  @override
  String get audiusHint =>
      'Saisissez un mot-clé, par exemple jazz, ambient ou electronic';

  @override
  String get audiusFieldQuery => 'Mot-clé';

  @override
  String get audiusFieldQueryHint => 'par ex. jazz, ambient, electronic';

  @override
  String get audiusFieldLimit => 'Morceaux par analyse';

  @override
  String get audiusFieldLimitHint => '20 par défaut, 50 au maximum';

  @override
  String get audiusEmptyResponse => 'Audius a renvoyé une réponse vide';

  @override
  String get audiusNoMatch => 'Aucun morceau correspondant sur Audius';

  @override
  String get sourceRadioDescription =>
      'Flux en direct des radios internet publiques';

  @override
  String get radioHint =>
      'Choisissez un annuaire de stations, un mot-clé les filtre';

  @override
  String get radioFieldProvider => 'Annuaire des stations';

  @override
  String get radioFieldProviderHint =>
      'Tous les annuaires, Radio Browser, SomaFM ou Radio Paradise';

  @override
  String get radioProviderAll => 'Tous les annuaires';

  @override
  String get radioFieldQuery => 'Mot-clé de station';

  @override
  String get radioFieldQueryHint => 'par ex. jazz, ambient ou SomaFM';

  @override
  String get radioFieldLimit => 'Stations par analyse';

  @override
  String get radioFieldLimitHint => '20 par défaut, 100 au maximum';

  @override
  String get radioNoMatch => 'Aucune station correspondante';

  @override
  String get sourceWikimediaDescription => 'Audio libre de Wikimedia Commons';

  @override
  String get wikimediaHint =>
      'Saisissez un mot-clé, par exemple piano, lecture ou birdsong';

  @override
  String get wikimediaFieldQuery => 'Mot-clé';

  @override
  String get wikimediaFieldQueryHint => 'par ex. piano, lecture, birdsong';

  @override
  String get wikimediaFieldLimit => 'Fichiers par analyse';

  @override
  String get wikimediaFieldLimitHint => '15 par défaut, 30 au maximum';

  @override
  String get wikimediaEmptyResponse =>
      'Wikimedia Commons a renvoyé une réponse vide';

  @override
  String get wikimediaNoMatch => 'Aucun audio lisible trouvé';

  @override
  String get sourceJellyfinDescription =>
      'Se connecter à une bibliothèque Jellyfin auto-hébergée';

  @override
  String get jellyfinHint =>
      'Saisissez l\'adresse et le compte de votre serveur Jellyfin';

  @override
  String get jellyfinFieldServer => 'Adresse du serveur';

  @override
  String get jellyfinFieldServerHint => 'par ex. http://localhost:8096';

  @override
  String get jellyfinFieldUser => 'Nom d\'utilisateur';

  @override
  String get jellyfinFieldUserHint =>
      'Le nom de connexion de votre compte Jellyfin';

  @override
  String get jellyfinFieldPassword => 'Mot de passe';

  @override
  String get jellyfinFieldPasswordHint => 'Sert à obtenir un jeton d\'accès';

  @override
  String get jellyfinFieldLimit => 'Morceaux par analyse';

  @override
  String get jellyfinFieldLimitHint => '50 par défaut, 200 au maximum';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin a renvoyé une réponse vide';

  @override
  String get jellyfinNoMatch => 'Aucun morceau correspondant';

  @override
  String get jellyfinAuthFailed =>
      'Serveur Jellyfin injoignable, vérifiez l\'adresse et le compte';

  @override
  String get audioSourceStreaming => 'Direct';

  @override
  String get playerLiveBadge => 'EN DIRECT';

  @override
  String get nowPlayingLiveStream => 'Flux en direct, sans durée fixe';

  @override
  String get nowPlayingDetails => 'Informations sur le morceau';

  @override
  String get nowPlayingDetailAlbum => 'Album';

  @override
  String get nowPlayingDetailYear => 'Année';

  @override
  String get nowPlayingDetailGenre => 'Genre';

  @override
  String get nowPlayingDetailBitrate => 'Débit';

  @override
  String get nowPlayingDetailSampleRate => 'Fréquence d\'échantillonnage';

  @override
  String get nowPlayingDetailTrack => 'Piste';

  @override
  String get nowPlayingDetailDisc => 'Disque';

  @override
  String get nowPlayingDetailLanguage => 'Langue';

  @override
  String get nowPlayingDetailLicense => 'Licence';

  @override
  String get nowPlayingDetailSource => 'Source';

  @override
  String get nowPlayingDetailNowPlaying => 'En ce moment';

  @override
  String get jamendoFieldFormat => 'Qualité';

  @override
  String get jamendoFieldFormatHint => '192 kbps par défaut';

  @override
  String get subsonicFieldFormat => 'Qualité';

  @override
  String get subsonicFieldFormatHint => 'Qualité d\'origine par défaut';

  @override
  String get subsonicFormatOriginal => 'Qualité d\'origine';

  @override
  String get sourceRadioName => 'Radio internet';

  @override
  String get settingsEyebrow => 'Préférences';

  @override
  String get settingsSectionInterface => 'Interface';

  @override
  String get settingsSectionLibrary => 'Bibliothèque';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsLocalFirst => 'Local d\'abord';

  @override
  String get libraryEyebrow => 'Collection';

  @override
  String get queueEyebrow => 'File d\'attente';

  @override
  String get sourcesEyebrow => 'Connexions';

  @override
  String get sidebarCollect => 'Collecter';

  @override
  String get sidebarConnect => 'Connecter';

  @override
  String get sidebarLocalOnline => 'Local + en ligne';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name bureau · $version';
  }

  @override
  String get nowPlayingEyebrow => 'En cours de lecture';

  @override
  String searchSourceError(String source, String message) {
    return '$source : $message';
  }

  @override
  String get radioNoChannelList =>
      'SomaFM n\'a pas renvoyé de liste de stations';
}

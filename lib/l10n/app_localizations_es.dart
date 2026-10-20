// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'Un reproductor de música local primero';

  @override
  String get appStartFailed => 'No se pudo iniciar Tune';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'Aceptar';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get clear => 'Vaciar';

  @override
  String get close => 'Cerrar';

  @override
  String get retry => 'Reintentar';

  @override
  String get chooseFile => 'Elegir archivo';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get scanNow => 'Escanear ahora';

  @override
  String get search => 'Buscar';

  @override
  String get scanning => 'Escaneando';

  @override
  String get about => 'Acerca de';

  @override
  String get language => 'Idioma';

  @override
  String get theme => 'Tema';

  @override
  String get lightMode => 'Modo claro';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get systemMode => 'Seguir al sistema';

  @override
  String get musicLibrary => 'Biblioteca';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navQueue => 'Cola';

  @override
  String get navSources => 'Fuentes';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get librarySubtitle =>
      'Todas las pistas de tus fuentes locales y en línea';

  @override
  String get libraryClearSearch => 'Borrar búsqueda';

  @override
  String get libraryFilterSources => 'Filtrar fuentes';

  @override
  String get libraryAllSources => 'Todas las fuentes';

  @override
  String get libraryScanAllSources => 'Escanear todas las fuentes';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString pistas';
  }

  @override
  String get libraryNoMatchTitle => 'Ninguna pista coincide';

  @override
  String get libraryNoMatchSubtitle =>
      'Prueba otra palabra clave o borra la búsqueda';

  @override
  String get librarySourceEmptyTitle => 'No hay pistas de esta fuente';

  @override
  String get librarySourceEmptySubtitle =>
      'Cambia a todas las fuentes o vuelve a escanear esta';

  @override
  String get libraryViewAllSources => 'Ver todas las fuentes';

  @override
  String get libraryScanningTitle => 'Escaneando música';

  @override
  String get libraryEmptyTitle => 'Todavía no hay música';

  @override
  String get libraryEmptySubtitle =>
      'Escanea una carpeta local o una fuente en línea activa, o ajusta tus fuentes en los ajustes.';

  @override
  String get libraryLoadFailedTitle => 'No se pudo cargar la biblioteca';

  @override
  String get libraryAddedToQueue => 'Añadido a la cola';

  @override
  String libraryScanPaths(String paths) {
    return 'Carpetas analizadas: $paths';
  }

  @override
  String get libraryAddToQueue => 'Añadir a la cola';

  @override
  String get queueTitle => 'Cola';

  @override
  String get queueSubtitle => 'Orden de reproducción actual';

  @override
  String get queueEmptyTitle => 'La cola está vacía';

  @override
  String get queueEmptySubtitle =>
      'Elige una canción en la biblioteca o añade canciones a la cola';

  @override
  String get queueGoToLibrary => 'Ir a la biblioteca';

  @override
  String get queueClearTitle => '¿Vaciar la cola?';

  @override
  String get queueClearMessage =>
      'Se detendrá la reproducción. Las canciones siguen en la biblioteca.';

  @override
  String get playerNowPlaying => 'Reproduciendo';

  @override
  String get playerCollapse => 'Contraer';

  @override
  String get playerPrevious => 'Pista anterior';

  @override
  String get playerNext => 'Pista siguiente';

  @override
  String get playerPlay => 'Reproducir';

  @override
  String get playerPause => 'Pausar';

  @override
  String get playerMute => 'Silenciar';

  @override
  String get playerUnmute => 'Activar sonido';

  @override
  String get playerQueue => 'Cola';

  @override
  String get playerPlayModeSequential => 'Repetir todo';

  @override
  String get playerPlayModeRepeatOne => 'Repetir una';

  @override
  String get playerPlayModeShuffle => 'Aleatorio';

  @override
  String get playerNoSongTitle => 'Elige una canción para empezar';

  @override
  String get playerUnknownArtist => 'Artista desconocido';

  @override
  String get playerDockReady => 'Tune · LISTO';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString en la cola';
  }

  @override
  String get nowPlayingEmptyTitle => 'Todavía no se reproduce nada';

  @override
  String get nowPlayingEmptySubtitle =>
      'Elige una de la biblioteca para empezar';

  @override
  String get nowPlayingUnnamedTrack => 'Pista sin título';

  @override
  String get nowPlayingLocalMusic => 'Música local';

  @override
  String get trackUnknownTitle => 'Canción desconocida';

  @override
  String playbackFailed(String error) {
    return 'Error de reproducción: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return 'No se pudo pausar: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return 'No se pudo reanudar: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'No se pudo buscar: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return 'No se pudo ajustar el volumen: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return 'No se pudo ajustar la velocidad: $error';
  }

  @override
  String get audioSourceLocal => 'Archivo local';

  @override
  String audioSourceDownloading(int percent) {
    return 'Descargando $percent%';
  }

  @override
  String get audioSourceCached => 'Listo sin conexión';

  @override
  String get audioSourceFailed => 'Error de descarga';

  @override
  String get routerNotFoundTitle => 'Página no encontrada';

  @override
  String get routerBackToLibrary => 'Volver a la biblioteca';

  @override
  String get sourcesTitle => 'Fuentes';

  @override
  String get sourcesSubtitle =>
      'Catálogos en línea, servicios autoalojados y carpetas de análisis';

  @override
  String get sourcesAutoScan => 'Escanear al iniciar';

  @override
  String get sourcesAutoScanDescription =>
      'Cada fuente activa se actualiza al iniciar. Un fallo nunca afecta a la biblioteca local.';

  @override
  String get sourcesScanAll => 'Escanear todas las fuentes';

  @override
  String get sourcesImportPlugin => 'Importar plugin';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Las fuentes remotas pueden tardar unos segundos';

  @override
  String get sourcesScanCompleted => 'Escaneo finalizado';

  @override
  String get sourcesImportPluginTitle => 'Importar un plugin de música';

  @override
  String get sourcesImportPluginMessage =>
      'Los plugins son JavaScript de terceros. Se ejecutan dentro de la aplicación y pueden acceder a la red. Importa solo fuentes de confianza. Un plugin permanece desactivado hasta que le indiques una palabra clave.';

  @override
  String get sourcesPluginUnreadable => 'No se pudo leer el archivo del plugin';

  @override
  String get sourcesPluginTooLarge =>
      'El archivo del plugin no puede superar los 2 MB';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return '$name importado y activado';
  }

  @override
  String sourcesPluginImported(String name) {
    return '$name importado. Se une al escaneo cuando añades una palabra clave y lo activas';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'No se pudo importar el plugin: $error';
  }

  @override
  String get sourcesPluginActions => 'Acciones del plugin';

  @override
  String get sourcesConfigure => 'Configurar';

  @override
  String get sourcesDeletePlugin => 'Eliminar plugin';

  @override
  String get sourcesUnsupported =>
      'Esta fuente no es compatible con esta versión';

  @override
  String get sourcesDisabled => 'Desactivada';

  @override
  String get sourcesNeedsConfiguration => 'Necesita configuración';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return 'Necesita configuración: $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return 'Último escaneo $time';
  }

  @override
  String get sourcesAutoScanLocal =>
      'Las carpetas locales se escanean tras el inicio';

  @override
  String get sourcesWaitingFirstScan => 'Esperando el primer escaneo';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString pistas · $time';
  }

  @override
  String get sourcesSkipped => 'Omitida';

  @override
  String get sourcesScanFailed => 'Error de escaneo';

  @override
  String get sourcesDeletePluginTitle => '¿Eliminar el plugin?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return 'Esto elimina el script, la configuración y las canciones escaneadas de $name.';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name eliminado';
  }

  @override
  String get sourceKindLocal => 'Local';

  @override
  String get sourceKindOpenCatalog => 'Catálogo abierto';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => 'Plugin';

  @override
  String sourcesConfigureTitle(String name) {
    return 'Configurar $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return 'Rellena $label';
  }

  @override
  String get sourcesFieldNumeric => 'Introduce un número';

  @override
  String get sourcesNotLoaded => 'La lista de fuentes aún se está cargando';

  @override
  String get sourcesPlatformNoPlugin =>
      'Esta plataforma no admite plugins de JavaScript';

  @override
  String get sourcesUpdatePlugin => 'Actualizar plugin';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name se actualizó a $version';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name ya está actualizado';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'No se pudo actualizar el plugin: $error';
  }

  @override
  String get playerLyrics => 'Letra';

  @override
  String get lyricsLoading => 'Cargando la letra';

  @override
  String get lyricsFailed => 'No se pudieron cargar las letras';

  @override
  String get lyricsMissing => 'Esta canción no tiene letra';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSubtitle =>
      'Ajusta la apariencia, el idioma y la biblioteca local.';

  @override
  String get settingsThemeDescription =>
      'Elige el aspecto de la interfaz y su idioma.';

  @override
  String get settingsLanguageDescription =>
      'Idioma de la interfaz y de los menús del sistema';

  @override
  String get settingsLibraryDescription =>
      'Tune busca archivos de audio solo en estas carpetas.';

  @override
  String get settingsDefaultPath => 'Predeterminado';

  @override
  String get settingsNoDefaultFolder =>
      'No se encontró la carpeta de música predeterminada';

  @override
  String get settingsCustomPath => 'Personalizado';

  @override
  String get settingsAddFolder => 'Añadir carpeta';

  @override
  String get settingsClearLibrary => 'Vaciar la biblioteca';

  @override
  String get settingsScanSafetyNote =>
      'El escaneo solo lee archivos de audio. No se modifica ni se borra nada del disco.';

  @override
  String get settingsAboutTitle => 'Acerca de Tune';

  @override
  String get settingsChooseFolder => 'Elegir carpeta de música';

  @override
  String get settingsFolderAdded => 'Carpeta de escaneo añadida';

  @override
  String get settingsScanDone => 'Escaneo finalizado';

  @override
  String get settingsClearLibraryTitle => '¿Vaciar la biblioteca?';

  @override
  String get settingsClearLibraryMessage =>
      'Solo se borra el historial de escaneo de Tune. Los archivos de música del disco se conservan.';

  @override
  String get settingsLibraryCleared => 'Biblioteca vaciada';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString rutas';
  }

  @override
  String get searchOnlineTitle => 'Buscar en línea';

  @override
  String get searchOnlineHint =>
      'Busca en las fuentes en línea, p. ej. jazz, piano, lo-fi';

  @override
  String get searchOnlineDescription =>
      'Busca en tus fuentes en línea activas. Los resultados no se guardan en la biblioteca.';

  @override
  String get searchOnlinePrompt => 'Buscar en las fuentes en línea';

  @override
  String get searchOnlinePromptDescription =>
      'Escribe una palabra clave y pulsa Enter. Todas las fuentes en línea activadas y los plugins importados se consultan en paralelo.';

  @override
  String get searchNoResults => 'Sin resultados';

  @override
  String get searchNoResultsDescription => 'Prueba otra palabra clave.';

  @override
  String get searchNoMatch => 'Ninguna pista coincide';

  @override
  String get searchNoMatchDescription => 'Prueba otra palabra clave.';

  @override
  String searchSearching(String query) {
    return 'Buscando «$query»';
  }

  @override
  String searchResultCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString pistas';
  }

  @override
  String get searchPlayAll => 'Reproducir todo';

  @override
  String get searchAddToQueue => 'Añadir a la cola';

  @override
  String searchAddedToQueue(String title) {
    return 'Añadido a la cola: $title';
  }

  @override
  String get searchNoSourcesEnabled =>
      'No hay ninguna fuente en línea activa. Activa una en los ajustes.';

  @override
  String get searchFailedShort => 'Error en la búsqueda';

  @override
  String searchFailed(String error) {
    return 'Error en la búsqueda en línea: $error';
  }

  @override
  String get scanPreparing => 'Preparando el escaneo…';

  @override
  String get scanNoEnabledSources => 'No hay ninguna fuente activa';

  @override
  String get scanNoLocalFolders => 'No hay carpetas de música para escanear';

  @override
  String scanProgressPercent(int percent) {
    return 'Escaneo $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'Fallaron todas las fuentes';

  @override
  String scanFailed(String error) {
    return 'Error de escaneo: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'No se pudo vaciar la biblioteca: $error';
  }

  @override
  String get scanNoAudioFiles => 'No se encontraron archivos de audio';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString canciones escaneadas';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString canciones';
  }

  @override
  String get scanSourceNotConfigured => 'La fuente aún no está configurada';

  @override
  String get scanCachedTooSoon =>
      'Caché conservado, el último escaneo es demasiado reciente';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$sourcesString fuentes escaneadas, $songsString canciones en total';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '$songsString canciones actualizadas, $failedString fuentes fallaron';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'Acceso denegado (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited =>
      'Demasiadas solicitudes (HTTP 429). Inténtalo más tarde.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'El servicio devolvió HTTP $status';
  }

  @override
  String get sourceErrorTimeout => 'La conexión ha caducado';

  @override
  String get sourceErrorConnection =>
      'No se pudo conectar con el servicio de la fuente';

  @override
  String get sourceErrorCertificate => 'No se pudo verificar el certificado';

  @override
  String get sourceErrorCancelled => 'Se canceló la solicitud';

  @override
  String sourceErrorNetwork(String message) {
    return 'Error en la solicitud de red: $message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return 'No se pudo cargar el plugin: $message';
  }

  @override
  String get sourceErrorUnsupported => 'Esta fuente aún no es compatible';

  @override
  String sourceErrorScanInterval(String interval) {
    return 'El último escaneo fue hace menos de $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'El escaneo expiró tras $seconds s';
  }

  @override
  String intervalHours(int count) {
    return '$count horas';
  }

  @override
  String intervalMinutes(int count) {
    return '$count minutos';
  }

  @override
  String get localSourceHint =>
      'Añade una carpeta de escaneo en los ajustes de la biblioteca';

  @override
  String get localSourceNotConfigured =>
      'No hay ninguna carpeta de música local configurada';

  @override
  String get pluginSourceHint =>
      'Indica una palabra clave, p. ej. un artista, piano o jazz';

  @override
  String get pluginFieldQuery => 'Palabra clave';

  @override
  String get pluginFieldHint => 'p. ej. artista, piano, jazz';

  @override
  String pluginImportedVersion(String version) {
    return 'Plugin MusicFree importado · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'Variable del plugin $key';
  }

  @override
  String get pluginFileMissing =>
      'Falta el archivo del plugin. Impórtalo de nuevo.';

  @override
  String get pluginRuntimeUnsupported =>
      'Esta plataforma no admite plugins de JavaScript. Impórtalos en escritorio o móvil.';

  @override
  String get pluginCompatLibrary => 'Biblioteca de compatibilidad de plugins';

  @override
  String get pluginBridgeScript => 'Script puente del plugin';

  @override
  String get pluginInit => 'Inicialización del plugin';

  @override
  String get pluginScript => 'Script del plugin';

  @override
  String get pluginExports => 'Exportaciones del plugin';

  @override
  String get pluginNoExports => 'El plugin no exporta un module.exports válido';

  @override
  String get pluginIncomplete =>
      'El plugin está incompleto: faltan los métodos platform y search';

  @override
  String get pluginNoMediaSource => 'El plugin no implementa getMediaSource';

  @override
  String get pluginNoStream =>
      'El plugin no devolvió una dirección reproducible';

  @override
  String get pluginRuntimeClosed =>
      'El entorno de ejecución del plugin está cerrado';

  @override
  String get pluginUnknownData => 'El plugin devolvió datos ilegibles';

  @override
  String get pluginCallError => 'La llamada al plugin falló';

  @override
  String get pluginNoMatch => 'Ninguna pista coincide';

  @override
  String pluginNoStreamResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'El plugin devolvió $countString resultados, pero ninguna dirección reproducible';
  }

  @override
  String get neteaseHint =>
      'Indica la dirección de tu propio NeteaseCloudMusicApi, p. ej. http://localhost:3000';

  @override
  String get neteaseFieldApi => 'Dirección de la API';

  @override
  String get neteaseFieldQuery => 'Palabra clave';

  @override
  String get neteaseFieldHint => 'p. ej. tendencia, un artista';

  @override
  String get neteaseFieldLimit => 'Pistas por escaneo';

  @override
  String get neteaseFieldLimitHint => '20 por defecto, 50 como máximo';

  @override
  String get neteaseHotKeyword => 'Tendencias';

  @override
  String get neteaseEmptyResponse =>
      'La API de NetEase devolvió una respuesta vacía';

  @override
  String get neteaseNoMatch => 'Ninguna pista coincide';

  @override
  String get neteaseNoStream =>
      'El servicio no devolvió una dirección reproducible. Puede hacer falta iniciar sesión en el servidor.';

  @override
  String get openverseHint =>
      'Indica una palabra clave, p. ej. piano, ambient o jazz';

  @override
  String get openverseFieldQuery => 'Palabra clave';

  @override
  String get openverseFieldHint => 'p. ej. piano, ambient, jazz';

  @override
  String get openverseEmptyResponse => 'Openverse devolvió una respuesta vacía';

  @override
  String get openverseNoMatch => 'No hay audio abierto que coincida';

  @override
  String get sourceLocalName => 'Música local';

  @override
  String get sourceLocalDescription =>
      'Escanea las carpetas de música de este dispositivo';

  @override
  String get sourceOpenverseDescription =>
      'Audio abierto de Jamendo, Freesound, Wikimedia y más';

  @override
  String get sourceJamendoDescription =>
      'Un catálogo abierto de música independiente. Necesita un Client ID gratuito.';

  @override
  String get sourceInternetArchiveDescription =>
      'La colección de audio abierto de Internet Archive';

  @override
  String get sourceNeteaseName => 'API de NetEase Cloud Music';

  @override
  String get sourceNeteaseDescription =>
      'Se conecta con un servicio NeteaseCloudMusicApi autoalojado';

  @override
  String get jamendoHint =>
      'Consigue un Client ID gratuito en developer.jamendo.com';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint =>
      'Solicítalo gratis en developer.jamendo.com';

  @override
  String get jamendoFieldQuery => 'Palabra clave (opcional)';

  @override
  String get jamendoFieldQueryHint => 'p. ej. jazz, electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo devolvió una respuesta vacía';

  @override
  String get jamendoNoMatch => 'Ninguna pista de Jamendo coincide';

  @override
  String get internetArchiveHint =>
      'Escribe una consulta de Internet Archive, p. ej. collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => 'Consulta';

  @override
  String get internetArchiveFieldLimit => 'Pistas por escaneo';

  @override
  String get internetArchiveFieldLimitHint => '8 por defecto, 20 como máximo';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive devolvió una respuesta ilegible';

  @override
  String get internetArchiveNoMatch =>
      'No se encontró audio de archivo reproducible';

  @override
  String get downloadUnsupportedPlatform =>
      'Esta plataforma no tiene sistema de archivos, no se pueden guardar las descargas';

  @override
  String get audioLoadFailed => 'No se pudo cargar el audio';

  @override
  String get audioPathEmpty => 'La ruta del archivo de audio está vacía';

  @override
  String get pluginUpdateNoUrl =>
      'El plugin no tiene dirección de descarga, así que no puede comprobarse';

  @override
  String pluginStepFailed(String error, String label) {
    return 'Error en $label: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'Importar desde una URL';

  @override
  String get sourcesPluginUrlTitle => 'URL del plugin';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid => 'Introduce un enlace http(s) válido';

  @override
  String get pluginUrlInvalid =>
      'La dirección del plugin no es válida, usa un enlace http o https';

  @override
  String get pluginUrlEmpty => 'El script del plugin está vacío';

  @override
  String get pluginUrlTooLarge =>
      'El script del plugin supera el límite de tamaño';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'El entorno aislado del plugin no se pudo iniciar: $error';
  }

  @override
  String get pluginSandboxStartTimeout =>
      'El entorno aislado del plugin tardó demasiado en iniciarse';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'El script del plugin supera el límite de $limit KB';
  }

  @override
  String get pluginRuntimeTerminated =>
      'El entorno de ejecución del plugin fue terminado';

  @override
  String get pluginRuntimeTimeLimit =>
      'El entorno de ejecución del plugin superó su límite de tiempo';

  @override
  String get pluginSandboxNotReady =>
      'El entorno aislado del plugin aún no está listo';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'La llamada al plugin expiró tras $seconds s';
  }

  @override
  String get pluginRuntimeCrashed =>
      'El entorno de ejecución del plugin se bloqueó';

  @override
  String pluginFetchShimFailed(String message) {
    return 'No se pudo cargar el shim de fetch: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return 'Llamada de plugin desconocida: $method';
  }

  @override
  String get pluginScriptMissing => 'Falta el script del plugin';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'El plugin superó el límite de $limit y fue terminado';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter devolvió una respuesta vacía';

  @override
  String get ccmixterFieldLimit => 'Pistas por escaneo';

  @override
  String get ccmixterFieldLimitHint => '15 por defecto, 30 como máximo';

  @override
  String get ccmixterFieldQuery => 'Etiqueta de búsqueda';

  @override
  String get ccmixterFieldQueryHint => 'p. ej. jazz, ambient, electro';

  @override
  String get ccmixterHint =>
      'Introduce una etiqueta de ccMixter, p. ej. jazz, ambient o electro';

  @override
  String get ccmixterNoMatch => 'No hay pistas de ccMixter coincidentes';

  @override
  String get itunesEmptyResponse =>
      'La API de iTunes devolvió una respuesta vacía';

  @override
  String get itunesFieldLimit => 'Pistas por escaneo';

  @override
  String get itunesFieldLimitHint => '20 por defecto, 50 como máximo';

  @override
  String get itunesFieldQuery => 'Palabra clave';

  @override
  String get itunesFieldQueryHint => 'p. ej. jazz, piano, lo-fi';

  @override
  String get itunesHint =>
      'Introduce una palabra clave, p. ej. jazz, piano o lo-fi';

  @override
  String get itunesNoMatch => 'No hay pistas de iTunes coincidentes';

  @override
  String get podcastRssEmptyFeed =>
      'La dirección del feed devolvió un documento vacío';

  @override
  String get podcastRssFieldFeed => 'Dirección del feed';

  @override
  String get podcastRssFieldFeedHint =>
      'p. ej. https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => 'Episodios por escaneo';

  @override
  String get podcastRssFieldLimitHint => '20 por defecto, 100 como máximo';

  @override
  String get podcastRssHint =>
      'Introduce la dirección de un feed de podcast (RSS)';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'La dirección del feed devolvió XML ilegible: $error';
  }

  @override
  String get podcastRssNoMatch => 'El feed no tiene episodios reproducibles';

  @override
  String get sourceCcmixterDescription =>
      'Remixes de Creative Commons y música abierta';

  @override
  String get sourceItunesDescription =>
      'Fragmentos de 30 segundos del catálogo de Apple Music';

  @override
  String get sourcePodcastRssDescription =>
      'Convierte cualquier feed RSS de podcast en episodios reproducibles';

  @override
  String get sourcePodcastRssName => 'Podcasts';

  @override
  String get sourceSubsonicDescription =>
      'Se conecta a una biblioteca Navidrome o Subsonic autoalojada';

  @override
  String get subsonicAuthFailed =>
      'No se puede conectar con el servidor de música, revisa la dirección y la cuenta';

  @override
  String get subsonicEmptyResponse =>
      'El servidor de música devolvió una respuesta vacía';

  @override
  String subsonicError(String error) {
    return 'El servidor de música informa de un error: $error';
  }

  @override
  String get subsonicFieldLimit => 'Pistas por escaneo';

  @override
  String get subsonicFieldLimitHint => '25 por defecto, 100 como máximo';

  @override
  String get subsonicFieldPassword => 'Contraseña';

  @override
  String get subsonicFieldPasswordHint =>
      'Firma el token de acceso y nunca se envía en texto plano';

  @override
  String get subsonicFieldQuery => 'Palabra clave (opcional)';

  @override
  String get subsonicFieldQueryHint => 'p. ej. jazz, piano';

  @override
  String get subsonicFieldServer => 'Dirección del servidor';

  @override
  String get subsonicFieldServerHint => 'p. ej. http://localhost:4533';

  @override
  String get subsonicFieldUser => 'Nombre de usuario';

  @override
  String get subsonicFieldUserHint =>
      'El nombre de acceso de tu servidor de música';

  @override
  String get subsonicHint =>
      'Introduce la dirección y la cuenta de tu servidor de música, p. ej. http://localhost:4533';

  @override
  String get subsonicNoMatch => 'No hay pistas coincidentes';

  @override
  String get sourceAudiusDescription =>
      'Pistas completas de la red abierta Audius';

  @override
  String get audiusHint =>
      'Escribe una palabra clave, p. ej. jazz, ambient o electronic';

  @override
  String get audiusFieldQuery => 'Palabra clave';

  @override
  String get audiusFieldQueryHint => 'p. ej. jazz, ambient, electronic';

  @override
  String get audiusFieldLimit => 'Pistas por análisis';

  @override
  String get audiusFieldLimitHint => '20 por defecto, 50 como máximo';

  @override
  String get audiusEmptyResponse => 'Audius devolvió una respuesta vacía';

  @override
  String get audiusNoMatch => 'No hay pistas coincidentes en Audius';

  @override
  String get sourceRadioDescription =>
      'Emisiones en directo de radios públicas';

  @override
  String get radioHint =>
      'Elige un directorio de emisoras, una palabra clave las filtra';

  @override
  String get radioFieldProvider => 'Directorio de emisoras';

  @override
  String get radioFieldProviderHint =>
      'Todos los directorios, Radio Browser, SomaFM o Radio Paradise';

  @override
  String get radioProviderAll => 'Todos los directorios';

  @override
  String get radioFieldQuery => 'Palabra clave de emisora';

  @override
  String get radioFieldQueryHint => 'p. ej. jazz, ambient o SomaFM';

  @override
  String get radioFieldLimit => 'Emisoras por análisis';

  @override
  String get radioFieldLimitHint => '20 por defecto, 100 como máximo';

  @override
  String get radioNoMatch => 'No hay emisoras coincidentes';

  @override
  String get sourceWikimediaDescription => 'Audio abierto de Wikimedia Commons';

  @override
  String get wikimediaHint =>
      'Escribe una palabra clave, p. ej. piano, lecture o birdsong';

  @override
  String get wikimediaFieldQuery => 'Palabra clave';

  @override
  String get wikimediaFieldQueryHint => 'p. ej. piano, lecture, birdsong';

  @override
  String get wikimediaFieldLimit => 'Archivos por análisis';

  @override
  String get wikimediaFieldLimitHint => '15 por defecto, 30 como máximo';

  @override
  String get wikimediaEmptyResponse =>
      'Wikimedia Commons devolvió una respuesta vacía';

  @override
  String get wikimediaNoMatch => 'No se encontró audio reproducible';

  @override
  String get sourceJellyfinDescription =>
      'Conectar con una biblioteca Jellyfin autoalojada';

  @override
  String get jellyfinHint =>
      'Escribe la dirección y la cuenta de tu servidor Jellyfin';

  @override
  String get jellyfinFieldServer => 'Dirección del servidor';

  @override
  String get jellyfinFieldServerHint => 'p. ej. http://localhost:8096';

  @override
  String get jellyfinFieldUser => 'Nombre de usuario';

  @override
  String get jellyfinFieldUserHint =>
      'El nombre de inicio de sesión de tu cuenta Jellyfin';

  @override
  String get jellyfinFieldPassword => 'Contraseña';

  @override
  String get jellyfinFieldPasswordHint =>
      'Sirve para obtener un token de acceso';

  @override
  String get jellyfinFieldLimit => 'Pistas por análisis';

  @override
  String get jellyfinFieldLimitHint => '50 por defecto, 200 como máximo';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin devolvió una respuesta vacía';

  @override
  String get jellyfinNoMatch => 'No hay pistas coincidentes';

  @override
  String get jellyfinAuthFailed =>
      'No se puede conectar con el servidor Jellyfin, revisa la dirección y la cuenta';

  @override
  String get audioSourceStreaming => 'En directo';

  @override
  String get playerLiveBadge => 'EN DIRECTO';

  @override
  String get nowPlayingLiveStream => 'Emisión en directo, sin duración fija';

  @override
  String get nowPlayingDetails => 'Detalles de la pista';

  @override
  String get nowPlayingDetailAlbum => 'Álbum';

  @override
  String get nowPlayingDetailYear => 'Año';

  @override
  String get nowPlayingDetailGenre => 'Género';

  @override
  String get nowPlayingDetailBitrate => 'Tasa de bits';

  @override
  String get nowPlayingDetailSampleRate => 'Frecuencia de muestreo';

  @override
  String get nowPlayingDetailTrack => 'Pista';

  @override
  String get nowPlayingDetailDisc => 'Disco';

  @override
  String get nowPlayingDetailLanguage => 'Idioma';

  @override
  String get nowPlayingDetailLicense => 'Licencia';

  @override
  String get nowPlayingDetailSource => 'Fuente';

  @override
  String get nowPlayingDetailNowPlaying => 'En emisión';

  @override
  String get jamendoFieldFormat => 'Calidad';

  @override
  String get jamendoFieldFormatHint => '192 kbps por defecto';

  @override
  String get subsonicFieldFormat => 'Calidad';

  @override
  String get subsonicFieldFormatHint => 'Calidad original por defecto';

  @override
  String get subsonicFormatOriginal => 'Calidad original';

  @override
  String get sourceRadioName => 'Radio por internet';

  @override
  String get settingsEyebrow => 'Preferencias';

  @override
  String get settingsSectionInterface => 'Interfaz';

  @override
  String get settingsSectionLibrary => 'Biblioteca';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsLocalFirst => 'Local primero';

  @override
  String get libraryEyebrow => 'Colección';

  @override
  String get queueEyebrow => 'Cola';

  @override
  String get sourcesEyebrow => 'Conexiones';

  @override
  String get sidebarCollect => 'Coleccionar';

  @override
  String get sidebarConnect => 'Conectar';

  @override
  String get sidebarLocalOnline => 'Local + en línea';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name escritorio · $version';
  }

  @override
  String get nowPlayingEyebrow => 'Reproduciendo';

  @override
  String searchSourceError(String source, String message) {
    return '$source: $message';
  }

  @override
  String get radioNoChannelList => 'SomaFM no devolvió una lista de emisoras';
}

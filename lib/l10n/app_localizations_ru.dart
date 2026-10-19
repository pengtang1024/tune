// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'Локальный десктопный плеер';

  @override
  String get appStartFailed => 'Не удалось запустить Tune';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'ОК';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get remove => 'Убрать';

  @override
  String get clear => 'Очистить';

  @override
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get chooseFile => 'Выбрать файл';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get scanNow => 'Сканировать сейчас';

  @override
  String get search => 'Поиск';

  @override
  String get scanning => 'Сканирование';

  @override
  String get about => 'О программе';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get lightMode => 'Светлая тема';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get systemMode => 'Как в системе';

  @override
  String get musicLibrary => 'Библиотека';

  @override
  String get navLibrary => 'Библиотека';

  @override
  String get navQueue => 'Очередь';

  @override
  String get navSources => 'Источники';

  @override
  String get navSettings => 'Настройки';

  @override
  String get libraryTitle => 'Библиотека';

  @override
  String get librarySubtitle => 'Все треки из локальных и онлайн-источников';

  @override
  String get libraryClearSearch => 'Очистить поиск';

  @override
  String get libraryFilterSources => 'Фильтр источников';

  @override
  String get libraryAllSources => 'Все источники';

  @override
  String get libraryScanAllSources => 'Сканировать все источники';

  @override
  String libraryTrackCount(int count) {
    return '$count треков';
  }

  @override
  String get libraryNoMatchTitle => 'Нет подходящих треков';

  @override
  String get libraryNoMatchSubtitle =>
      'Попробуйте другое слово или очистите поиск';

  @override
  String get librarySourceEmptyTitle => 'В этом источнике нет треков';

  @override
  String get librarySourceEmptySubtitle =>
      'Переключитесь на все источники или пересканируйте этот';

  @override
  String get libraryViewAllSources => 'Показать все источники';

  @override
  String get libraryScanningTitle => 'Идёт сканирование музыки';

  @override
  String get libraryEmptyTitle => 'Музыки пока нет';

  @override
  String get libraryEmptySubtitle =>
      'Просканируйте локальную папку или включённый онлайн-источник либо настройте источники в параметрах.';

  @override
  String get libraryLoadFailedTitle => 'Не удалось загрузить библиотеку';

  @override
  String get libraryAddedToQueue => 'Добавлено в очередь';

  @override
  String libraryScanPaths(String paths) {
    return 'Папки сканирования: $paths';
  }

  @override
  String get libraryAddToQueue => 'В очередь';

  @override
  String get queueTitle => 'Очередь';

  @override
  String get queueSubtitle => 'Текущий порядок воспроизведения';

  @override
  String get queueEmptyTitle => 'Очередь пуста';

  @override
  String get queueEmptySubtitle =>
      'Выберите трек в библиотеке или добавьте треки в очередь';

  @override
  String get queueGoToLibrary => 'Перейти в библиотеку';

  @override
  String get queueClearTitle => 'Очистить очередь?';

  @override
  String get queueClearMessage =>
      'Воспроизведение остановится. Треки останутся в библиотеке.';

  @override
  String get playerNowPlaying => 'Сейчас играет';

  @override
  String get playerCollapse => 'Свернуть';

  @override
  String get playerPrevious => 'Предыдущий трек';

  @override
  String get playerNext => 'Следующий трек';

  @override
  String get playerPlay => 'Воспроизвести';

  @override
  String get playerPause => 'Пауза';

  @override
  String get playerMute => 'Без звука';

  @override
  String get playerUnmute => 'Включить звук';

  @override
  String get playerQueue => 'Очередь';

  @override
  String get playerPlayModeSequential => 'Повтор всех';

  @override
  String get playerPlayModeRepeatOne => 'Повтор трека';

  @override
  String get playerPlayModeShuffle => 'Перемешать';

  @override
  String get playerNoSongTitle => 'Выберите трек для начала';

  @override
  String get playerUnknownArtist => 'Неизвестный исполнитель';

  @override
  String get playerDockReady => 'Tune · ГОТОВО';

  @override
  String playerQueueSummary(int count) {
    return 'в очереди $count';
  }

  @override
  String get nowPlayingEmptyTitle => 'Пока ничего не играет';

  @override
  String get nowPlayingEmptySubtitle => 'Выберите трек из библиотеки';

  @override
  String get nowPlayingUnnamedTrack => 'Без названия';

  @override
  String get nowPlayingLocalMusic => 'Локальная музыка';

  @override
  String get trackUnknownTitle => 'Неизвестный трек';

  @override
  String playbackFailed(String error) {
    return 'Не удалось воспроизвести: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return 'Не удалось поставить на паузу: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return 'Не удалось продолжить: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'Не удалось перемотать: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return 'Не удалось изменить громкость: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return 'Не удалось изменить скорость: $error';
  }

  @override
  String get audioSourceLocal => 'Локальный файл';

  @override
  String audioSourceDownloading(int percent) {
    return 'Загрузка $percent%';
  }

  @override
  String get audioSourceCached => 'Готово офлайн';

  @override
  String get audioSourceFailed => 'Ошибка загрузки';

  @override
  String get routerNotFoundTitle => 'Страница не найдена';

  @override
  String get routerBackToLibrary => 'Вернуться в библиотеку';

  @override
  String get sourcesTitle => 'Источники';

  @override
  String get sourcesSubtitle =>
      'Онлайн-каталоги, собственные сервисы и папки для сканирования';

  @override
  String get sourcesAutoScan => 'Сканировать при запуске';

  @override
  String get sourcesAutoScanDescription =>
      'Каждый включённый источник обновляется при запуске. Сбой не затрагивает локальную библиотеку.';

  @override
  String get sourcesScanAll => 'Сканировать все источники';

  @override
  String get sourcesImportPlugin => 'Импорт плагина';

  @override
  String get sourcesScanMayTakeSeconds =>
      'Удалённым источникам может потребоваться несколько секунд';

  @override
  String get sourcesScanCompleted => 'Сканирование завершено';

  @override
  String get sourcesImportPluginTitle => 'Импорт музыкального плагина';

  @override
  String get sourcesImportPluginMessage =>
      'Плагины — это сторонний JavaScript. Они выполняются внутри приложения и могут обращаться к сети. Импортируйте только доверенные источники. Плагин останется выключенным, пока не задан поисковый запрос.';

  @override
  String get sourcesPluginUnreadable => 'Не удалось прочитать файл плагина';

  @override
  String get sourcesPluginTooLarge => 'Файл плагина не может превышать 2 МБ';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return 'Импортирован и включён $name';
  }

  @override
  String sourcesPluginImported(String name) {
    return 'Импортирован $name. Участвует в сканировании после добавления запроса и включения';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'Не удалось импортировать плагин: $error';
  }

  @override
  String get sourcesPluginActions => 'Действия с плагином';

  @override
  String get sourcesConfigure => 'Настроить';

  @override
  String get sourcesDeletePlugin => 'Удалить плагин';

  @override
  String get sourcesUnsupported =>
      'Этот источник не поддерживается в текущей версии';

  @override
  String get sourcesDisabled => 'Выключен';

  @override
  String get sourcesNeedsConfiguration => 'Требуется настройка';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return 'Требуется настройка: $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return 'Последнее сканирование $time';
  }

  @override
  String get sourcesAutoScanLocal =>
      'Локальные папки сканируются после запуска';

  @override
  String get sourcesWaitingFirstScan => 'Ожидание первого сканирования';

  @override
  String sourcesScannedCount(int count, String time) {
    return '$count треков · $time';
  }

  @override
  String get sourcesSkipped => 'Пропущено';

  @override
  String get sourcesScanFailed => 'Сканирование не удалось';

  @override
  String get sourcesDeletePluginTitle => 'Удалить плагин?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return 'Будут удалены скрипт, настройки и просканированные треки $name.';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name удалён';
  }

  @override
  String get sourceKindLocal => 'Локальный';

  @override
  String get sourceKindOpenCatalog => 'Открытый каталог';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => 'Плагин';

  @override
  String sourcesConfigureTitle(String name) {
    return 'Настройка $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return 'Заполните $label';
  }

  @override
  String get sourcesFieldNumeric => 'Введите число';

  @override
  String get sourcesNotLoaded => 'Список источников ещё загружается';

  @override
  String get sourcesPlatformNoPlugin =>
      'Эта платформа не поддерживает плагины JavaScript';

  @override
  String get sourcesUpdatePlugin => 'Обновить плагин';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name обновлён до $version';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name уже обновлён';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'Не удалось обновить плагин: $error';
  }

  @override
  String get playerLyrics => 'Слова';

  @override
  String get lyricsLoading => 'Загрузка слов песни';

  @override
  String lyricsFailed(String error) {
    return 'Не удалось загрузить слова: $error';
  }

  @override
  String get lyricsMissing => 'У этой песни нет слов';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSubtitle =>
      'Настройте внешний вид, язык и локальную библиотеку.';

  @override
  String get settingsThemeDescription =>
      'Выберите оформление интерфейса и язык.';

  @override
  String get settingsLanguageDescription => 'Язык интерфейса и системных меню';

  @override
  String get settingsLibraryDescription =>
      'Tune ищет аудиофайлы только в этих папках.';

  @override
  String get settingsDefaultPath => 'По умолчанию';

  @override
  String get settingsNoDefaultFolder => 'Папка музыки по умолчанию не найдена';

  @override
  String get settingsCustomPath => 'Своя';

  @override
  String get settingsAddFolder => 'Добавить папку';

  @override
  String get settingsClearLibrary => 'Очистить библиотеку';

  @override
  String get settingsScanSafetyNote =>
      'Сканирование только читает аудиофайлы. На диске ничего не изменяется и не удаляется.';

  @override
  String get settingsAboutTitle => 'О программе Tune';

  @override
  String get settingsChooseFolder => 'Выберите папку музыки';

  @override
  String get settingsFolderAdded => 'Папка сканирования добавлена';

  @override
  String get settingsScanDone => 'Сканирование завершено';

  @override
  String get settingsClearLibraryTitle => 'Очистить библиотеку?';

  @override
  String get settingsClearLibraryMessage =>
      'Очищается только история сканирования Tune. Музыкальные файлы на диске не удаляются.';

  @override
  String get settingsLibraryCleared => 'Библиотека очищена';

  @override
  String settingsPathsCount(int count) {
    return '$count путей';
  }

  @override
  String get searchOnlineTitle => 'Поиск в сети';

  @override
  String get searchOnlineHint =>
      'Ищите в онлайн-источниках, например jazz, piano, lo-fi';

  @override
  String get searchOnlineDescription =>
      'Ищет по включённым онлайн-источникам. Результаты не попадают в библиотеку.';

  @override
  String get searchOnlinePrompt => 'Поиск по онлайн-источникам';

  @override
  String get searchOnlinePromptDescription =>
      'Введите запрос и нажмите Enter. Все включённые онлайн-источники и импортированные плагины ищутся параллельно.';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get searchNoResultsDescription => 'Попробуйте другой запрос.';

  @override
  String get searchNoMatch => 'Нет подходящих треков';

  @override
  String get searchNoMatchDescription => 'Попробуйте другой запрос.';

  @override
  String searchSearching(String query) {
    return 'Поиск «$query»';
  }

  @override
  String searchResultCount(int count) {
    return '$count треков';
  }

  @override
  String get searchPlayAll => 'Воспроизвести всё';

  @override
  String get searchAddToQueue => 'В очередь';

  @override
  String searchAddedToQueue(String title) {
    return 'Добавлено в очередь: $title';
  }

  @override
  String get searchNoSourcesEnabled =>
      'Ни один онлайн-источник не включён. Сначала включите его в настройках.';

  @override
  String get searchFailedShort => 'Ошибка поиска';

  @override
  String searchFailed(String error) {
    return 'Ошибка поиска в сети: $error';
  }

  @override
  String get scanPreparing => 'Подготовка сканирования…';

  @override
  String get scanNoEnabledSources => 'Нет включённых источников';

  @override
  String get scanNoLocalFolders => 'Нет папок для сканирования';

  @override
  String scanProgressPercent(int percent) {
    return 'Сканирование $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'Все источники не удалось просканировать';

  @override
  String scanFailed(String error) {
    return 'Сканирование не удалось: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'Не удалось очистить библиотеку: $error';
  }

  @override
  String get scanNoAudioFiles => 'Аудиофайлы не найдены';

  @override
  String scanSongCount(int count) {
    return 'Просканировано треков: $count';
  }

  @override
  String scanSongCountShort(int count) {
    return '$count треков';
  }

  @override
  String get scanSourceNotConfigured => 'Источник ещё не настроен';

  @override
  String get scanCachedTooSoon =>
      'Кэш сохранён, с прошлого сканирования прошло мало времени';

  @override
  String scanSummary(int songs, int sources) {
    return 'Просканировано источников: $sources, треков: $songs';
  }

  @override
  String scanUpdated(int failed, int songs) {
    return 'Обновлено треков: $songs, источников с ошибкой: $failed';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'Доступ запрещён (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited =>
      'Слишком много запросов (HTTP 429). Повторите позже.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'Сервис вернул HTTP $status';
  }

  @override
  String get sourceErrorTimeout => 'Истекло время ожидания соединения';

  @override
  String get sourceErrorConnection =>
      'Не удалось подключиться к сервису источника';

  @override
  String get sourceErrorCertificate => 'Не удалось проверить сертификат';

  @override
  String get sourceErrorCancelled => 'Запрос отменён';

  @override
  String sourceErrorNetwork(String message) {
    return 'Сетевой запрос не удался: $message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return 'Не удалось загрузить плагин: $message';
  }

  @override
  String get sourceErrorUnsupported => 'Этот источник пока не поддерживается';

  @override
  String sourceErrorScanInterval(String interval) {
    return 'С прошлого сканирования прошло меньше $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'Сканирование превысило $seconds с';
  }

  @override
  String intervalHours(int count) {
    return '$count ч';
  }

  @override
  String intervalMinutes(int count) {
    return '$count мин';
  }

  @override
  String get localSourceHint =>
      'Добавьте папку сканирования в настройках библиотеки';

  @override
  String get localSourceNotConfigured => 'Локальная папка музыки не настроена';

  @override
  String get pluginSourceHint =>
      'Укажите поисковый запрос, например исполнитель, piano или jazz';

  @override
  String get pluginFieldQuery => 'Поисковый запрос';

  @override
  String get pluginFieldHint => 'например исполнитель, piano, jazz';

  @override
  String pluginImportedVersion(String version) {
    return 'Импортированный плагин MusicFree · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'Переменная плагина $key';
  }

  @override
  String get pluginFileMissing =>
      'Файл плагина не найден. Импортируйте его снова.';

  @override
  String get pluginRuntimeUnsupported =>
      'Эта платформа не поддерживает плагины JavaScript. Импортируйте их на компьютере или телефоне.';

  @override
  String get pluginCompatLibrary => 'Библиотека совместимости плагинов';

  @override
  String get pluginBridgeScript => 'Скрипт-мост для плагинов';

  @override
  String get pluginInit => 'Инициализация плагина';

  @override
  String get pluginScript => 'Скрипт плагина';

  @override
  String get pluginExports => 'Экспорт плагина';

  @override
  String get pluginNoExports =>
      'Плагин не экспортирует корректный module.exports';

  @override
  String get pluginIncomplete =>
      'Плагин неполон: нужны методы platform и search';

  @override
  String get pluginNoMediaSource => 'Плагин не реализует getMediaSource';

  @override
  String get pluginNoStream => 'Плагин не вернул воспроизводимый адрес';

  @override
  String get pluginRuntimeClosed => 'Среда выполнения плагина закрыта';

  @override
  String pluginCallFailed(String label, String message) {
    return 'Не удалось выполнить $label: $message';
  }

  @override
  String get pluginCallTimeout => 'Истекло время вызова плагина';

  @override
  String get pluginUnknownData => 'Плагин вернул нечитаемые данные';

  @override
  String get pluginCallError => 'Вызов плагина не удался';

  @override
  String get pluginNoMatch => 'Нет подходящих треков';

  @override
  String pluginNoStreamResults(int count) {
    return 'Плагин вернул $count результатов, но без воспроизводимого адреса';
  }

  @override
  String get neteaseHint =>
      'Укажите адрес собственного NeteaseCloudMusicApi, например http://localhost:3000';

  @override
  String get neteaseFieldApi => 'Адрес API';

  @override
  String get neteaseFieldQuery => 'Поисковый запрос';

  @override
  String get neteaseFieldHint => 'например, популярное или исполнитель';

  @override
  String get neteaseFieldLimit => 'Треков за сканирование';

  @override
  String get neteaseFieldLimitHint => 'По умолчанию 20, максимум 50';

  @override
  String get neteaseHotKeyword => 'Популярное';

  @override
  String get neteaseEmptyResponse => 'API NetEase вернул пустой ответ';

  @override
  String get neteaseNoMatch => 'Нет подходящих треков';

  @override
  String get neteaseNoStream =>
      'Сервис не вернул воспроизводимый адрес. Возможно, нужен вход на сервере.';

  @override
  String get openverseHint =>
      'Укажите запрос, например piano, ambient или jazz';

  @override
  String get openverseFieldQuery => 'Поисковый запрос';

  @override
  String get openverseFieldHint => 'например piano, ambient, jazz';

  @override
  String get openverseEmptyResponse => 'Openverse вернул пустой ответ';

  @override
  String get openverseNoMatch => 'Подходящие открытые аудио не найдены';

  @override
  String get sourceLocalName => 'Локальная музыка';

  @override
  String get sourceLocalDescription => 'Сканирует музыкальные папки устройства';

  @override
  String get sourceOpenverseDescription =>
      'Открытый аудио из Jamendo, Freesound, Wikimedia и др.';

  @override
  String get sourceJamendoDescription =>
      'Открытый каталог независимой музыки. Нужен бесплатный Client ID.';

  @override
  String get sourceInternetArchiveDescription =>
      'Открытая коллекция аудио Internet Archive';

  @override
  String get sourceNeteaseName => 'API NetEase Cloud Music';

  @override
  String get sourceNeteaseDescription =>
      'Подключается к собственному NeteaseCloudMusicApi';

  @override
  String get jamendoHint =>
      'Получите бесплатный Client ID на developer.jamendo.com';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint =>
      'Заявите бесплатно на developer.jamendo.com';

  @override
  String get jamendoFieldQuery => 'Поисковый запрос (необязательно)';

  @override
  String get jamendoFieldQueryHint => 'например, jazz, electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo вернул пустой ответ';

  @override
  String get jamendoNoMatch => 'Нет подходящих треков Jamendo';

  @override
  String get internetArchiveHint =>
      'Укажите запрос Internet Archive, например collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => 'Запрос';

  @override
  String get internetArchiveFieldLimit => 'Треков за сканирование';

  @override
  String get internetArchiveFieldLimitHint => 'По умолчанию 8, максимум 20';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive вернул нечитаемый ответ';

  @override
  String get internetArchiveNoMatch =>
      'Не найдено воспроизводимого аудио архива';

  @override
  String get downloadUnsupportedPlatform =>
      'У этой платформе нет файловой системы, загрузки не сохраняются';

  @override
  String get audioLoadFailed => 'Не удалось загрузить аудио';

  @override
  String get audioPathEmpty => 'Путь к аудиофайлу пуст';

  @override
  String get pluginUpdateNoUrl =>
      'У плагина нет адреса загрузки, поэтому обновления проверить нельзя';

  @override
  String sourcesPluginUrlDownloadFailed(String error) {
    return 'Не удалось загрузить плагин: $error';
  }

  @override
  String pluginStepFailed(String error, String label) {
    return 'Сбой $label: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'Импорт по ссылке';

  @override
  String get sourcesPluginUrlTitle => 'Ссылка на плагин';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid => 'Введите действительную ссылку http(s)';

  @override
  String get pluginUrlInvalid =>
      'Адрес плагина неверен, используйте ссылку http или https';

  @override
  String get pluginUrlEmpty => 'Скрипт плагина пуст';

  @override
  String get pluginUrlTooLarge => 'Скрипт плагина превышает лимит размера';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'Песоча плагина не запустилась: $error';
  }

  @override
  String get pluginSandboxStartTimeout =>
      'Песоча плагина не успела запуститься';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'Скрипт плагина превышает лимит в $limit КБ';
  }

  @override
  String get pluginRuntimeTerminated => 'Среда выполнения плагина завершена';

  @override
  String get pluginRuntimeTimeLimit =>
      'Среда выполнения плагина превысила лимит времени';

  @override
  String get pluginSandboxNotReady => 'Песоча плагина ещё не готова';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'Вызов плагина истёк по таймауту через $seconds с';
  }

  @override
  String get pluginRuntimeCrashed =>
      'Среда выполнения плагина аварийно завершилась';

  @override
  String pluginFetchShimFailed(String message) {
    return 'Не удалось загрузить шим fetch: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return 'Неизвестный вызов плагина: $method';
  }

  @override
  String get pluginScriptMissing => 'Скрипт плагина не найден';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'Плагин превысил лимит в $limit и был завершён';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter вернул пустой ответ';

  @override
  String get ccmixterFieldLimit => 'Треков за проход';

  @override
  String get ccmixterFieldLimitHint => 'По умолчанию 15, максимум 30';

  @override
  String get ccmixterFieldQuery => 'Тег для поиска';

  @override
  String get ccmixterFieldQueryHint => 'например jazz, ambient, electro';

  @override
  String get ccmixterHint =>
      'Введите тег ccMixter, например jazz, ambient или electro';

  @override
  String get ccmixterNoMatch => 'Подходящих треков ccMixter не найдено';

  @override
  String get itunesEmptyResponse => 'API iTunes вернул пустой ответ';

  @override
  String get itunesFieldLimit => 'Треков за проход';

  @override
  String get itunesFieldLimitHint => 'По умолчанию 20, максимум 50';

  @override
  String get itunesFieldQuery => 'Поисковый запрос';

  @override
  String get itunesFieldQueryHint => 'например jazz, piano, lo-fi';

  @override
  String get itunesHint =>
      'Введите поисковый запрос, например jazz, piano или lo-fi';

  @override
  String get itunesNoMatch => 'Подходящих треков iTunes не найдено';

  @override
  String get podcastRssEmptyFeed => 'Адрес ленты вернул пустой документ';

  @override
  String get podcastRssFieldFeed => 'Адрес ленты';

  @override
  String get podcastRssFieldFeedHint =>
      'например https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => 'Эпизодов за проход';

  @override
  String get podcastRssFieldLimitHint => 'По умолчанию 20, максимум 100';

  @override
  String get podcastRssHint => 'Введите адрес подкаста (RSS)';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'Адрес ленты вернул неразбираемый XML: $error';
  }

  @override
  String get podcastRssNoMatch => 'В ленте нет воспроизводимых эпизодов';

  @override
  String get sourceCcmixterDescription =>
      'Ремиксы Creative Commons и открытая музыка';

  @override
  String get sourceItunesDescription =>
      '30-секундные отрывки из каталога Apple Music';

  @override
  String get sourcePodcastRssDescription =>
      'Превращает любую RSS-ленту подкаста в воспроизводимые эпизоды';

  @override
  String get sourcePodcastRssName => 'Подкасты';

  @override
  String get sourceSubsonicDescription =>
      'Подключается к своей библиотеке Navidrome или Subsonic';

  @override
  String get subsonicAuthFailed =>
      'Не удалось связаться с музыкальным сервером, проверьте адрес и учётную запись';

  @override
  String get subsonicEmptyResponse => 'Музыкальный сервер вернул пустой ответ';

  @override
  String subsonicError(String error) {
    return 'Музыкальный сервер сообщил об ошибке: $error';
  }

  @override
  String get subsonicFieldLimit => 'Треков за проход';

  @override
  String get subsonicFieldLimitHint => 'По умолчанию 25, максимум 100';

  @override
  String get subsonicFieldPassword => 'Пароль';

  @override
  String get subsonicFieldPasswordHint =>
      'Используется для подписи токена и не передаётся открытым текстом';

  @override
  String get subsonicFieldQuery => 'Поисковый запрос (необязательно)';

  @override
  String get subsonicFieldQueryHint => 'например jazz, piano';

  @override
  String get subsonicFieldServer => 'Адрес сервера';

  @override
  String get subsonicFieldServerHint => 'например http://localhost:4533';

  @override
  String get subsonicFieldUser => 'Имя пользователя';

  @override
  String get subsonicFieldUserHint => 'Имя для входа на музыкальный сервер';

  @override
  String get subsonicHint =>
      'Введите адрес и учётную запись своего музыкального сервера, например http://localhost:4533';

  @override
  String get subsonicNoMatch => 'Подходящих треков не найдено';

  @override
  String get sourceAudiusDescription => 'Полные треки из открытой сети Audius';

  @override
  String get audiusHint =>
      'Введите поисковый запрос, например jazz, ambient или electronic';

  @override
  String get audiusFieldQuery => 'Поисковый запрос';

  @override
  String get audiusFieldQueryHint => 'например jazz, ambient, electronic';

  @override
  String get audiusFieldLimit => 'Треков за скан';

  @override
  String get audiusFieldLimitHint => 'По умолчанию 20, максимум 50';

  @override
  String get audiusEmptyResponse => 'Audius вернул пустой ответ';

  @override
  String get audiusNoMatch => 'Подходящих треков на Audius нет';

  @override
  String get sourceRadioDescription =>
      'Прямые трансляции публичных интернет-радиостанций';

  @override
  String get radioHint => 'Выберите каталог станций, запрос отфильтрует их';

  @override
  String get radioFieldProvider => 'Каталог станций';

  @override
  String get radioFieldProviderHint =>
      'Все каталоги, Radio Browser, SomaFM или Radio Paradise';

  @override
  String get radioProviderAll => 'Все каталоги';

  @override
  String get radioFieldQuery => 'Ключевое слово станции';

  @override
  String get radioFieldQueryHint => 'например jazz, ambient или SomaFM';

  @override
  String get radioFieldLimit => 'Станций за скан';

  @override
  String get radioFieldLimitHint => 'По умолчанию 20, максимум 100';

  @override
  String get radioNoMatch => 'Подходящих станций нет';

  @override
  String get sourceWikimediaDescription => 'Открытое аудио из Викисклада';

  @override
  String get wikimediaHint =>
      'Введите запрос, например piano, lecture или birdsong';

  @override
  String get wikimediaFieldQuery => 'Поисковый запрос';

  @override
  String get wikimediaFieldQueryHint => 'например piano, lecture, birdsong';

  @override
  String get wikimediaFieldLimit => 'Файлов за скан';

  @override
  String get wikimediaFieldLimitHint => 'По умолчанию 15, максимум 30';

  @override
  String get wikimediaEmptyResponse => 'Викисклад вернул пустой ответ';

  @override
  String get wikimediaNoMatch => 'Играбельного аудио не найдено';

  @override
  String get sourceJellyfinDescription =>
      'Подключение к своей библиотеке Jellyfin';

  @override
  String get jellyfinHint =>
      'Введите адрес и учётную запись своего сервера Jellyfin';

  @override
  String get jellyfinFieldServer => 'Адрес сервера';

  @override
  String get jellyfinFieldServerHint => 'например http://localhost:8096';

  @override
  String get jellyfinFieldUser => 'Имя пользователя';

  @override
  String get jellyfinFieldUserHint => 'Имя входа в учётную запись Jellyfin';

  @override
  String get jellyfinFieldPassword => 'Пароль';

  @override
  String get jellyfinFieldPasswordHint =>
      'Используется для получения токена доступа';

  @override
  String get jellyfinFieldLimit => 'Треков за скан';

  @override
  String get jellyfinFieldLimitHint => 'По умолчанию 50, максимум 200';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin вернул пустой ответ';

  @override
  String get jellyfinNoMatch => 'Подходящих треков нет';

  @override
  String get jellyfinAuthFailed =>
      'Не удалось связаться с сервером Jellyfin, проверьте адрес и учётную запись';

  @override
  String get audioSourceStreaming => 'Прямой эфир';

  @override
  String get playerLiveBadge => 'ЭФИР';

  @override
  String get nowPlayingLiveStream =>
      'Прямой эфир без фиксированной длительности';

  @override
  String get nowPlayingDetails => 'Сведения о треке';

  @override
  String get nowPlayingDetailAlbum => 'Альбом';

  @override
  String get nowPlayingDetailYear => 'Год';

  @override
  String get nowPlayingDetailGenre => 'Жанр';

  @override
  String get nowPlayingDetailBitrate => 'Битрейт';

  @override
  String get nowPlayingDetailSampleRate => 'Частота дискретизации';

  @override
  String get nowPlayingDetailTrack => 'Дорожка';

  @override
  String get nowPlayingDetailDisc => 'Диск';

  @override
  String get nowPlayingDetailLanguage => 'Язык';

  @override
  String get nowPlayingDetailLicense => 'Лицензия';

  @override
  String get nowPlayingDetailSource => 'Источник';

  @override
  String get nowPlayingDetailNowPlaying => 'В эфире';

  @override
  String get jamendoFieldFormat => 'Качество';

  @override
  String get jamendoFieldFormatHint => 'По умолчанию 192 kbps';

  @override
  String get subsonicFieldFormat => 'Качество';

  @override
  String get subsonicFieldFormatHint => 'По умолчанию исходное качество';

  @override
  String get subsonicFormatOriginal => 'Исходное качество';

  @override
  String get sourceRadioName => 'Интернет-радио';
}

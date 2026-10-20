// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => '로컬 우선 데스크톱 음악 플레이어';

  @override
  String get appStartFailed => 'Tune 을 시작하지 못했습니다';

  @override
  String get cancel => '취소';

  @override
  String get ok => '확인';

  @override
  String get save => '저장';

  @override
  String get delete => '삭제';

  @override
  String get remove => '제거';

  @override
  String get clear => '지우기';

  @override
  String get close => '닫기';

  @override
  String get retry => '다시 시도';

  @override
  String get chooseFile => '파일 선택';

  @override
  String get unknownError => '알 수 없는 오류';

  @override
  String get scanNow => '지금 스캔';

  @override
  String get search => '검색';

  @override
  String get scanning => '스캔 중';

  @override
  String get about => '정보';

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get lightMode => '라이트 모드';

  @override
  String get darkMode => '다크 모드';

  @override
  String get systemMode => '시스템 설정';

  @override
  String get musicLibrary => '라이브러리';

  @override
  String get navLibrary => '라이브러리';

  @override
  String get navQueue => '재생 대기열';

  @override
  String get navSources => '소스';

  @override
  String get navSettings => '설정';

  @override
  String get libraryTitle => '라이브러리';

  @override
  String get librarySubtitle => '로컬 및 온라인 소스의 모든 트랙';

  @override
  String get libraryClearSearch => '검색 지우기';

  @override
  String get libraryFilterSources => '소스 필터';

  @override
  String get libraryAllSources => '모든 소스';

  @override
  String get libraryScanAllSources => '모든 소스 스캔';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 곡';
  }

  @override
  String get libraryNoMatchTitle => '일치하는 곡이 없습니다';

  @override
  String get libraryNoMatchSubtitle => '다른 키워드를 쓰거나 검색 조건을 지우세요';

  @override
  String get librarySourceEmptyTitle => '이 소스에는 곡이 없습니다';

  @override
  String get librarySourceEmptySubtitle => '모든 소스로 전환하거나 이 소스를 다시 스캔하세요';

  @override
  String get libraryViewAllSources => '모든 소스 보기';

  @override
  String get libraryScanningTitle => '음악을 스캔하는 중';

  @override
  String get libraryEmptyTitle => '아직 음악이 없습니다';

  @override
  String get libraryEmptySubtitle =>
      '로컬 폴더나 활성화된 온라인 소스를 스캔하거나 설정에서 소스를 조정하세요.';

  @override
  String get libraryLoadFailedTitle => '라이브러리를 불러오지 못했습니다';

  @override
  String get libraryAddedToQueue => '재생 대기열에 추가했습니다';

  @override
  String libraryScanPaths(String paths) {
    return '스캔 폴더: $paths';
  }

  @override
  String get libraryAddToQueue => '재생 대기열에 추가';

  @override
  String get queueTitle => '재생 대기열';

  @override
  String get queueSubtitle => '현재 재생 순서';

  @override
  String get queueEmptyTitle => '재생 대기열이 비어 있습니다';

  @override
  String get queueEmptySubtitle => '라이브러리에서 곡을 고르거나 곡을 대기열에 추가하세요';

  @override
  String get queueGoToLibrary => '라이브러리로';

  @override
  String get queueClearTitle => '재생 대기열을 비울까요?';

  @override
  String get queueClearMessage => '재생이 중지됩니다. 곡은 라이브러리에 그대로 남습니다.';

  @override
  String get playerNowPlaying => '재생 중';

  @override
  String get playerCollapse => '접기';

  @override
  String get playerPrevious => '이전 곡';

  @override
  String get playerNext => '다음 곡';

  @override
  String get playerPlay => '재생';

  @override
  String get playerPause => '일시정지';

  @override
  String get playerMute => '음소거';

  @override
  String get playerUnmute => '음소거 해제';

  @override
  String get playerQueue => '재생 대기열';

  @override
  String get playerPlayModeSequential => '전체 반복';

  @override
  String get playerPlayModeRepeatOne => '한 곡 반복';

  @override
  String get playerPlayModeShuffle => '셔플';

  @override
  String get playerNoSongTitle => '시작할 곡을 선택하세요';

  @override
  String get playerUnknownArtist => '알 수 없는 아티스트';

  @override
  String get playerDockReady => 'Tune · 준비 완료';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '대기열 $countString곡';
  }

  @override
  String get nowPlayingEmptyTitle => '아직 재생 중인 곡이 없습니다';

  @override
  String get nowPlayingEmptySubtitle => '라이브러리에서 곡을 골라 시작하세요';

  @override
  String get nowPlayingUnnamedTrack => '제목 없는 트랙';

  @override
  String get nowPlayingLocalMusic => '로컬 음악';

  @override
  String get trackUnknownTitle => '알 수 없는 곡';

  @override
  String playbackFailed(String error) {
    return '재생에 실패했습니다: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return '일시정지하지 못했습니다: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return '재생을 재개하지 못했습니다: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return '탐색에 실패했습니다: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return '음량 설정에 실패했습니다: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return '재생 속도 설정에 실패했습니다: $error';
  }

  @override
  String get audioSourceLocal => '로컬 파일';

  @override
  String audioSourceDownloading(int percent) {
    return '다운로드 중 $percent%';
  }

  @override
  String get audioSourceCached => '오프라인 준비됨';

  @override
  String get audioSourceFailed => '다운로드 실패';

  @override
  String get routerNotFoundTitle => '페이지를 찾을 수 없습니다';

  @override
  String get routerBackToLibrary => '라이브러리로 돌아가기';

  @override
  String get sourcesTitle => '소스';

  @override
  String get sourcesSubtitle => '온라인 카탈로그, 자체 호스팅 서비스, 스캔 폴더';

  @override
  String get sourcesAutoScan => '시작할 때 자동 스캔';

  @override
  String get sourcesAutoScanDescription =>
      '활성화된 소스는 시작할 때마다 새로 고쳐집니다. 실패해도 로컬 라이브러리에는 영향을 주지 않습니다.';

  @override
  String get sourcesScanAll => '모든 소스 스캔';

  @override
  String get sourcesImportPlugin => '플러그인 가져오기';

  @override
  String get sourcesScanMayTakeSeconds => '원격 소스는 몇 초가 걸릴 수 있습니다';

  @override
  String get sourcesScanCompleted => '스캔이 완료되었습니다';

  @override
  String get sourcesImportPluginTitle => '음악 플러그인 가져오기';

  @override
  String get sourcesImportPluginMessage =>
      '플러그인은 서드파티 JavaScript로 앱 안에서 실행되며 네트워크에 접근할 수 있습니다. 신뢰할 수 있는 소스만 가져오세요. 검색 키워드를 입력해야 활성화됩니다.';

  @override
  String get sourcesPluginUnreadable => '플러그인 파일을 읽을 수 없습니다';

  @override
  String get sourcesPluginTooLarge => '플러그인 파일은 2 MB를 넘을 수 없습니다';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return '$name을(를) 가져와 활성화했습니다';
  }

  @override
  String sourcesPluginImported(String name) {
    return '$name을(를) 가져왔습니다. 키워드를 입력하고 활성화하면 검사에 참여합니다';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return '플러그인을 가져오지 못했습니다: $error';
  }

  @override
  String get sourcesPluginActions => '플러그인 작업';

  @override
  String get sourcesConfigure => '설정';

  @override
  String get sourcesDeletePlugin => '플러그인 삭제';

  @override
  String get sourcesUnsupported => '현재 버전에서는 이 소스를 지원하지 않습니다';

  @override
  String get sourcesDisabled => '꺼짐';

  @override
  String get sourcesNeedsConfiguration => '설정 필요';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return '설정 필요: $hint';
  }

  @override
  String sourcesLastScan(String time) {
    return '마지막 스캔 $time';
  }

  @override
  String get sourcesAutoScanLocal => '시작 후 로컬 폴더를 자동으로 스캔합니다';

  @override
  String get sourcesWaitingFirstScan => '첫 스캔 대기 중';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곡 · $time';
  }

  @override
  String get sourcesSkipped => '건너뜀';

  @override
  String get sourcesScanFailed => '스캔 실패';

  @override
  String get sourcesDeletePluginTitle => '플러그인을 삭제할까요?';

  @override
  String sourcesDeletePluginMessage(String name) {
    return '$name의 스크립트, 설정 및 스캔된 곡이 삭제됩니다.';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name을(를) 삭제했습니다';
  }

  @override
  String get sourceKindLocal => '로컬';

  @override
  String get sourceKindOpenCatalog => '오픈 카탈로그';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => '플러그인';

  @override
  String sourcesConfigureTitle(String name) {
    return '$name 설정';
  }

  @override
  String sourcesFieldRequired(String label) {
    return '$label을(를) 입력하세요';
  }

  @override
  String get sourcesFieldNumeric => '숫자를 입력하세요';

  @override
  String get sourcesNotLoaded => '소스 목록을 불러오는 중입니다';

  @override
  String get sourcesPlatformNoPlugin => '이 플랫폼은 JavaScript 플러그인을 지원하지 않습니다';

  @override
  String get sourcesUpdatePlugin => '플러그인 업데이트';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name을(를) $version으로 업데이트했습니다.';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name은(는) 이미 최신상태입니다.';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return '플러그인 업데이트에 실패했습니다: $error';
  }

  @override
  String get playerLyrics => '가산';

  @override
  String get lyricsLoading => '가산 로드를 불러오서다.';

  @override
  String get lyricsFailed => '가사를 불러올 수 없습니다';

  @override
  String get lyricsMissing => '이 공에는 가산이 없어요.';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSubtitle => '화면, 언어 및 로컬 라이브러리를 조정하세요.';

  @override
  String get settingsThemeDescription => '화면의 밝기 테마와 표시 언어를 선택하세요.';

  @override
  String get settingsLanguageDescription => '인터페이스와 시스템 메뉴의 언어';

  @override
  String get settingsLibraryDescription => 'Tune은 이 폴더 안의 오디오 파일만 찾습니다.';

  @override
  String get settingsDefaultPath => '기본';

  @override
  String get settingsNoDefaultFolder => '기본 음악 폴더를 찾을 수 없습니다';

  @override
  String get settingsCustomPath => '사용자 지정';

  @override
  String get settingsAddFolder => '폴더 추가';

  @override
  String get settingsClearLibrary => '라이브러리 지우기';

  @override
  String get settingsScanSafetyNote =>
      '스캔은 오디오 파일만 읽으며 디스크 내용을 변경하거나 삭제하지 않습니다.';

  @override
  String get settingsAboutTitle => 'Tune 정보';

  @override
  String get settingsChooseFolder => '음악 폴더 선택';

  @override
  String get settingsFolderAdded => '스캔 폴더를 추가했습니다';

  @override
  String get settingsScanDone => '스캔이 완료되었습니다';

  @override
  String get settingsClearLibraryTitle => '라이브러리를 비울까요?';

  @override
  String get settingsClearLibraryMessage =>
      'Tune의 스캔 기록만 지웁니다. 디스크의 음악 파일은 삭제되지 않습니다.';

  @override
  String get settingsLibraryCleared => '라이브러리를 비웠습니다';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString개';
  }

  @override
  String get searchOnlineTitle => '온라인 검색';

  @override
  String get searchOnlineHint => '온라인 소스를 검색하세요 (jazz, 피아노, lo-fi)';

  @override
  String get searchOnlineDescription =>
      '활성화된 온라인 소스를 검색합니다. 결과는 라이브러리에 저장되지 않습니다.';

  @override
  String get searchOnlinePrompt => '온라인 소스 검색';

  @override
  String get searchOnlinePromptDescription =>
      '키워드를 입력하고 Enter 키를 누르면 활성화된 온라인音源과 가져온 플러그인이 동시에 검색됩니다.';

  @override
  String get searchNoResults => '결과 없음';

  @override
  String get searchNoResultsDescription => '다른 키워드로 다시 시도하세요.';

  @override
  String get searchNoMatch => '일치하는 곡이 없습니다';

  @override
  String get searchNoMatchDescription => '다른 키워드로 다시 시도하세요.';

  @override
  String searchSearching(String query) {
    return '“$query” 검색 중';
  }

  @override
  String searchResultCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곡';
  }

  @override
  String get searchPlayAll => '전체 재생';

  @override
  String get searchAddToQueue => '대기열에 추가';

  @override
  String searchAddedToQueue(String title) {
    return '대기열에 추가했습니다: $title';
  }

  @override
  String get searchNoSourcesEnabled => '활성화된 온라인 소스가 없습니다. 먼저 설정에서 켜세요.';

  @override
  String get searchFailedShort => '검색실패';

  @override
  String searchFailed(String error) {
    return '온라인 검색에 실패했습니다: $error';
  }

  @override
  String get scanPreparing => '스캔 준비 중…';

  @override
  String get scanNoEnabledSources => '활성화된 소스가 없습니다';

  @override
  String get scanNoLocalFolders => '검사할 음악 폴더가 없습니다';

  @override
  String scanProgressPercent(int percent) {
    return '스캔 중 $percent%';
  }

  @override
  String get scanAllSourcesFailed => '모든 소스 검사 실패';

  @override
  String scanFailed(String error) {
    return '스캔 실패: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return '라이브러리를 비우지 못했습니다: $error';
  }

  @override
  String get scanNoAudioFiles => '오디오 파일을 찾을 수 없습니다';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곡을 스캔했습니다';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString곡';
  }

  @override
  String get scanSourceNotConfigured => '소스가 아직 설정되지 않았습니다';

  @override
  String get scanCachedTooSoon => '마지막 검사 간격이 짧아 캐시를 유지했습니다';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$sourcesString개 소스, 총 $songsString곡을 스캔했습니다';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '$songsString곡을 업데이트했고 $failedString개 소스가 실패했습니다';
  }

  @override
  String sourceErrorForbidden(int status) {
    return '접근이 거부되었습니다 (HTTP $status)';
  }

  @override
  String get sourceErrorRateLimited => '요청이 너무 많습니다 (HTTP 429). 잠시 후 다시 시도하세요.';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'API가 HTTP $status를 반환했습니다';
  }

  @override
  String get sourceErrorTimeout => '연결 시간이 초과되었습니다';

  @override
  String get sourceErrorConnection => '소스 서비스에 연결할 수 없습니다';

  @override
  String get sourceErrorCertificate => '인증서를 확인할 수 없습니다';

  @override
  String get sourceErrorCancelled => '요청이 취소되었습니다';

  @override
  String sourceErrorNetwork(String message) {
    return '네트워크 요청에 실패했습니다: $message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return '플러그인을 불러오지 못했습니다: $message';
  }

  @override
  String get sourceErrorUnsupported => '이 소스는 아직 지원되지 않습니다';

  @override
  String sourceErrorScanInterval(String interval) {
    return '마지막 스캔 후 $interval가 지나지 않았습니다';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return '스캔이 $seconds초 후 시간 초과되었습니다';
  }

  @override
  String intervalHours(int count) {
    return '$count시간';
  }

  @override
  String intervalMinutes(int count) {
    return '$count분';
  }

  @override
  String get localSourceHint => '라이브러리 설정에서 스캔 폴더를 추가하세요';

  @override
  String get localSourceNotConfigured => '로컬 음악 폴더가 설정되지 않았습니다';

  @override
  String get pluginSourceHint => '검색 키워드를 입력하세요 (예: 아티스트, piano, jazz)';

  @override
  String get pluginFieldQuery => '검색 키워드';

  @override
  String get pluginFieldHint => '예: 아티스트, piano, jazz';

  @override
  String pluginImportedVersion(String version) {
    return '가져온 MusicFree 플러그인 · v$version';
  }

  @override
  String pluginVariable(String key) {
    return '플러그인 변수 $key';
  }

  @override
  String get pluginFileMissing => '플러그인 파일이 없습니다. 다시 가져오세요.';

  @override
  String get pluginRuntimeUnsupported =>
      '이 플랫폼은 JavaScript 음악 플러그인을 지원하지 않습니다. 데스크톱이나 모바일에서 가져오세요.';

  @override
  String get pluginCompatLibrary => '플러그인 호환 라이브러리';

  @override
  String get pluginBridgeScript => '플러그인 브리지 스크립트';

  @override
  String get pluginInit => '플러그인 초기화';

  @override
  String get pluginScript => '플러그인 스크립트';

  @override
  String get pluginExports => '플러그인 내보내기';

  @override
  String get pluginNoExports => '플러그인이 유효한 module.exports를 내보내지 않았습니다';

  @override
  String get pluginIncomplete => '플러그인이 불완전합니다: platform과 search 메서드가 필요합니다';

  @override
  String get pluginNoMediaSource => '플러그인이 getMediaSource를 구현하지 않았습니다';

  @override
  String get pluginNoStream => '플러그인이 재생 가능한 주소를 반환하지 않았습니다';

  @override
  String get pluginRuntimeClosed => '플러그인 실행 환경이 종료되었습니다';

  @override
  String get pluginUnknownData => '플러그인이 읽을 수 없는 데이터를 반환했습니다';

  @override
  String get pluginCallError => '플러그인 호출에 실패했습니다';

  @override
  String get pluginNoMatch => '일치하는 곡이 없습니다';

  @override
  String pluginNoStreamResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '플러그인이 $countString개의 결과를 반환했지만 재생 가능한 주소가 없습니다';
  }

  @override
  String get neteaseHint =>
      '자체 NeteaseCloudMusicApi 주소를 입력하세요 (예: http://localhost:3000)';

  @override
  String get neteaseFieldApi => 'API 주소';

  @override
  String get neteaseFieldQuery => '검색 키워드';

  @override
  String get neteaseFieldHint => '예: 인기, 아티스트';

  @override
  String get neteaseFieldLimit => '스캔할 곡 수';

  @override
  String get neteaseFieldLimitHint => '기본 20, 최대 50';

  @override
  String get neteaseHotKeyword => '인기';

  @override
  String get neteaseEmptyResponse => 'NetEase API가 빈 응답을 반환했습니다';

  @override
  String get neteaseNoMatch => '일치하는 곡이 없습니다';

  @override
  String get neteaseNoStream => 'API가 재생 가능한 주소를 반환하지 않았습니다(서버 로그인이 필요할 수 있음)';

  @override
  String get openverseHint => '스캔 키워드를 입력하세요 (예: piano, ambient, jazz)';

  @override
  String get openverseFieldQuery => '검색 키워드';

  @override
  String get openverseFieldHint => '예: piano, ambient, jazz';

  @override
  String get openverseEmptyResponse => 'Openverse가 빈 응답을 반환했습니다';

  @override
  String get openverseNoMatch => '일치하는 오픈 오디오가 없습니다';

  @override
  String get sourceLocalName => '로컬 음악';

  @override
  String get sourceLocalDescription => '기기의 음악 폴더를 스캔';

  @override
  String get sourceOpenverseDescription =>
      'Jamendo, Freesound, Wikimedia 등의 오픈 음악 모음';

  @override
  String get sourceJamendoDescription => '독립 음악의 오픈 카탈로그. 무료 Client ID가 필요합니다.';

  @override
  String get sourceInternetArchiveDescription => 'Internet Archive의 오픈 음악 모음';

  @override
  String get sourceNeteaseName => 'NetEase Cloud Music API';

  @override
  String get sourceNeteaseDescription => '자체 NeteaseCloudMusicApi 서비스에 연결합니다.';

  @override
  String get jamendoHint => 'developer.jamendo.com에서 무료 Client ID를 받아 입력하세요.';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint => 'developer.jamendo.com에서 무료로 신청';

  @override
  String get jamendoFieldQuery => '검색 키氏하다(옵션)';

  @override
  String get jamendoFieldQueryHint => '예: jazz, electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo가 빈 응답을 반환했습니다.';

  @override
  String get jamendoNoMatch => '일치하는 Jamendo 트랙이 없습니다.';

  @override
  String get internetArchiveHint =>
      'Internet Archive 검색 조건을 입력하세요 (예: collection:netlabels AND mediatype:audio).';

  @override
  String get internetArchiveFieldQuery => '검색 조건';

  @override
  String get internetArchiveFieldLimit => '스캔할 트랙 수';

  @override
  String get internetArchiveFieldLimitHint => '기본 8, 최대 20';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive가 읽을 수 없는 응답을 반환했습니다.';

  @override
  String get internetArchiveNoMatch => '재생 가능한 아카이브 음악을 찾지 못했습니다.';

  @override
  String get downloadUnsupportedPlatform =>
      '이 플랫폼에는 파일 시스템이 없어 다운로드를 저장할 수 없습니다.';

  @override
  String get audioLoadFailed => '오디오 로드에 실패했습니다.';

  @override
  String get audioPathEmpty => '오디오 파일 경로가 비어 있습니다.';

  @override
  String get pluginUpdateNoUrl => '플러그인 다운로드 주소가 기록되어 있지 않아 업데이트를 확인할 수 없습니다.';

  @override
  String pluginStepFailed(String error, String label) {
    return '$label에 실패했습니다: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'URL에서 가져오기';

  @override
  String get sourcesPluginUrlTitle => '플러그인 URL';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid => '유효한 http(s) 링크를 입력하세요.';

  @override
  String get pluginUrlInvalid => '플러그인 주소가 올바르지 않습니다. http 또는 https 링크를 사용하세요.';

  @override
  String get pluginUrlEmpty => '플러그인 스크립이 비어 있습니다.';

  @override
  String get pluginUrlTooLarge => '플러그인 스크립이 크기 제한을 초과했습니다.';

  @override
  String pluginSandboxStartFailed(String error) {
    return '플러그인 샌드박스를 시작하지 못했습니다: $error';
  }

  @override
  String get pluginSandboxStartTimeout => '플러그인 샌드박스 시작이 시간 초과되었습니다.';

  @override
  String pluginScriptTooLarge(String limit) {
    return '플러그인 스크립이 $limit KB 제한을 초과했습니다.';
  }

  @override
  String get pluginRuntimeTerminated => '플러그인 런타임이 종료되었습니다.';

  @override
  String get pluginRuntimeTimeLimit => '플러그인 런타임이 실행 시간 제한을 초과했습니다.';

  @override
  String get pluginSandboxNotReady => '플러그인 샌드박스가 아직 준비되지 않았습니다.';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return '플러그인 호출이 $seconds초 후 시간 초과되었습니다.';
  }

  @override
  String get pluginRuntimeCrashed => '플러그인 런타임이 예기치 않게 종료되었습니다.';

  @override
  String pluginFetchShimFailed(String message) {
    return 'fetch 셰임 로드가 실패했습니다: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return '알 수 없는 플러그인 호출입니다: $method';
  }

  @override
  String get pluginScriptMissing => '플러그인 스크립이 없습니다.';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return '플러그인 메모리 사용량이 $limit을 초과하여 종료되었습니다.';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter가 빈 응답을 반환했습니다';

  @override
  String get ccmixterFieldLimit => '스캔당 곡 수';

  @override
  String get ccmixterFieldLimitHint => '기본 15, 최대 30';

  @override
  String get ccmixterFieldQuery => '검색 태그';

  @override
  String get ccmixterFieldQueryHint => '예: jazz, ambient, electro';

  @override
  String get ccmixterHint => 'ccMixter 태그를 입력하세요 (예: jazz, ambient, electro)';

  @override
  String get ccmixterNoMatch => '일치하는 ccMixter 곡을 찾을 수 없습니다';

  @override
  String get itunesEmptyResponse => 'iTunes API가 빈 응답을 반환했습니다';

  @override
  String get itunesFieldLimit => '스캔당 곡 수';

  @override
  String get itunesFieldLimitHint => '기본 20, 최대 50';

  @override
  String get itunesFieldQuery => '검색어';

  @override
  String get itunesFieldQueryHint => '예: jazz, piano, lo-fi';

  @override
  String get itunesHint => '검색어를 입력하세요 (예: jazz, piano, lo-fi)';

  @override
  String get itunesNoMatch => '일치하는 iTunes 곡을 찾을 수 없습니다';

  @override
  String get podcastRssEmptyFeed => '피드 주소가 빈 문서를 반환했습니다';

  @override
  String get podcastRssFieldFeed => '피드 주소';

  @override
  String get podcastRssFieldFeedHint => '예: https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => '스캔당 에피소드 수';

  @override
  String get podcastRssFieldLimitHint => '기본 20, 최대 100';

  @override
  String get podcastRssHint => '팟캐스트 피드(RSS) 주소를 입력하세요';

  @override
  String podcastRssInvalidFeed(String error) {
    return '피드 주소가 읽을 수 없는 XML을 반환했습니다: $error';
  }

  @override
  String get podcastRssNoMatch => '피드에 재생할 수 있는 에피소드가 없습니다';

  @override
  String get sourceCcmixterDescription => 'Creative Commons 리믹스와 열린 음악';

  @override
  String get sourceItunesDescription => 'Apple Music 카탈로그의 30초 미리듣기';

  @override
  String get sourcePodcastRssDescription =>
      '모든 podcast RSS 피드를 재생 가능한 에피소드로 바꿉니다';

  @override
  String get sourcePodcastRssName => '팟캐스트';

  @override
  String get sourceSubsonicDescription =>
      '자체 호스팅 Navidrome 또는 Subsonic 라이브러리에 연결합니다';

  @override
  String get subsonicAuthFailed => '음악 서버에 연결할 수 없습니다. 주소와 계정을 확인하세요';

  @override
  String get subsonicEmptyResponse => '음악 서버가 빈 응답을 반환했습니다';

  @override
  String subsonicError(String error) {
    return '음악 서버가 오류를 반환했습니다: $error';
  }

  @override
  String get subsonicFieldLimit => '스캔당 곡 수';

  @override
  String get subsonicFieldLimitHint => '기본 25, 최대 100';

  @override
  String get subsonicFieldPassword => '비밀번호';

  @override
  String get subsonicFieldPasswordHint => '액세스 토큰 서명에 사용되며 평문으로 전송되지 않습니다';

  @override
  String get subsonicFieldQuery => '검색어(선택)';

  @override
  String get subsonicFieldQueryHint => '예: jazz, piano';

  @override
  String get subsonicFieldServer => '서버 주소';

  @override
  String get subsonicFieldServerHint => '예: http://localhost:4533';

  @override
  String get subsonicFieldUser => '사용자 이름';

  @override
  String get subsonicFieldUserHint => '음악 서버의 로그인 이름';

  @override
  String get subsonicHint =>
      '자체 음악 서버 주소와 계정을 입력하세요 (예: http://localhost:4533)';

  @override
  String get subsonicNoMatch => '일치하는 곡을 찾을 수 없습니다';

  @override
  String get sourceAudiusDescription => '열린 음악 네트워크 Audius의 전체 트랙';

  @override
  String get audiusHint => '검색 키워드를 입력하세요 (예: jazz, ambient, electronic)';

  @override
  String get audiusFieldQuery => '검색 키워드';

  @override
  String get audiusFieldQueryHint => '예: jazz, ambient, electronic';

  @override
  String get audiusFieldLimit => '한 번에 스캔할 곡 수';

  @override
  String get audiusFieldLimitHint => '기본 20, 최대 50';

  @override
  String get audiusEmptyResponse => 'Audius가 빈 응답을 반환했습니다';

  @override
  String get audiusNoMatch => '조건에 맞는 Audius 트랙이 없습니다';

  @override
  String get sourceRadioDescription => '공개 인터넷 라디오의 라이브 스트림';

  @override
  String get radioHint => '방송국 디렉터리를 고르고 키워드로 거를 수 있습니다';

  @override
  String get radioFieldProvider => '방송국 디렉터리';

  @override
  String get radioFieldProviderHint =>
      '전체 디렉터리, Radio Browser, SomaFM 또는 Radio Paradise';

  @override
  String get radioProviderAll => '전체 디렉터리';

  @override
  String get radioFieldQuery => '방송국 키워드';

  @override
  String get radioFieldQueryHint => '예: jazz, ambient 또는 SomaFM';

  @override
  String get radioFieldLimit => '한 번에 스캔할 방송국 수';

  @override
  String get radioFieldLimitHint => '기본 20, 최대 100';

  @override
  String get radioNoMatch => '조건에 맞는 방송국이 없습니다';

  @override
  String get sourceWikimediaDescription => '위키미디어 커먼즈의 열린 오디오';

  @override
  String get wikimediaHint => '검색 키워드를 입력하세요 (예: piano, lecture, birdsong)';

  @override
  String get wikimediaFieldQuery => '검색 키워드';

  @override
  String get wikimediaFieldQueryHint => '예: piano, lecture, birdsong';

  @override
  String get wikimediaFieldLimit => '한 번에 스캔할 파일 수';

  @override
  String get wikimediaFieldLimitHint => '기본 15, 최대 30';

  @override
  String get wikimediaEmptyResponse => '위키미디어 커먼즈가 빈 응답을 반환했습니다';

  @override
  String get wikimediaNoMatch => '재생할 수 있는 오디오를 찾지 못했습니다';

  @override
  String get sourceJellyfinDescription => '직접 호스팅한 Jellyfin 라이브러리에 연결합니다';

  @override
  String get jellyfinHint => 'Jellyfin 서버 주소와 계정을 입력하세요';

  @override
  String get jellyfinFieldServer => '서버 주소';

  @override
  String get jellyfinFieldServerHint => '예: http://localhost:8096';

  @override
  String get jellyfinFieldUser => '사용자 이름';

  @override
  String get jellyfinFieldUserHint => 'Jellyfin 계정의 로그인 이름';

  @override
  String get jellyfinFieldPassword => '비밀번호';

  @override
  String get jellyfinFieldPasswordHint => '액세스 토큰을 얻는 데 사용합니다';

  @override
  String get jellyfinFieldLimit => '한 번에 스캔할 곡 수';

  @override
  String get jellyfinFieldLimitHint => '기본 50, 최대 200';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin이 빈 응답을 반환했습니다';

  @override
  String get jellyfinNoMatch => '조건에 맞는 트랙이 없습니다';

  @override
  String get jellyfinAuthFailed => 'Jellyfin 서버에 연결할 수 없습니다. 주소와 계정을 확인하세요';

  @override
  String get audioSourceStreaming => '라이브';

  @override
  String get playerLiveBadge => '라이브 중';

  @override
  String get nowPlayingLiveStream => '라이브 스트림이라 고정 길이가 없습니다';

  @override
  String get nowPlayingDetails => '곡 정보';

  @override
  String get nowPlayingDetailAlbum => '앨범';

  @override
  String get nowPlayingDetailYear => '연도';

  @override
  String get nowPlayingDetailGenre => '장르';

  @override
  String get nowPlayingDetailBitrate => '비트레이트';

  @override
  String get nowPlayingDetailSampleRate => '샘플레이트';

  @override
  String get nowPlayingDetailTrack => '트랙 번호';

  @override
  String get nowPlayingDetailDisc => '디스크 번호';

  @override
  String get nowPlayingDetailLanguage => '언어';

  @override
  String get nowPlayingDetailLicense => '라이선스';

  @override
  String get nowPlayingDetailSource => '출처';

  @override
  String get nowPlayingDetailNowPlaying => '방송 중';

  @override
  String get jamendoFieldFormat => '음질';

  @override
  String get jamendoFieldFormatHint => '기본 192 kbps';

  @override
  String get subsonicFieldFormat => '음질';

  @override
  String get subsonicFieldFormatHint => '기본은 원본 음질';

  @override
  String get subsonicFormatOriginal => '원본 음질';

  @override
  String get sourceRadioName => '인터넷 라디오';

  @override
  String get settingsEyebrow => '환경설정';

  @override
  String get settingsSectionInterface => '인터페이스';

  @override
  String get settingsSectionLibrary => '라이브러리';

  @override
  String get settingsSectionAbout => '정보';

  @override
  String get settingsLocalFirst => '로컬 우선';

  @override
  String get libraryEyebrow => '컬렉션';

  @override
  String get queueEyebrow => '대기열';

  @override
  String get sourcesEyebrow => '연결';

  @override
  String get sidebarCollect => '컬렉션';

  @override
  String get sidebarConnect => '연결';

  @override
  String get sidebarLocalOnline => '로컬 + 온라인';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name 데스크톱 · $version';
  }

  @override
  String get nowPlayingEyebrow => '재생 중';

  @override
  String searchSourceError(String source, String message) {
    return '$source: $message';
  }

  @override
  String get radioNoChannelList => 'SomaFM이 방송 목록을 반환하지 않았습니다';
}

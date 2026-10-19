// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => 'ローカル優先のデスクトップ音楽プレーヤー';

  @override
  String get appStartFailed => 'Tune を起動できませんでした';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get save => '保存';

  @override
  String get delete => '削除';

  @override
  String get remove => '削除';

  @override
  String get clear => 'クリア';

  @override
  String get close => '閉じる';

  @override
  String get retry => '再試行';

  @override
  String get confirm => '確認';

  @override
  String get chooseFile => 'ファイルを選択';

  @override
  String get unknownError => '不明なエラー';

  @override
  String get scanNow => '今すぐスキャン';

  @override
  String get search => '検索';

  @override
  String get scanning => 'スキャン中';

  @override
  String get about => '概要';

  @override
  String get language => '言語';

  @override
  String get theme => 'テーマ';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get systemMode => 'システムに従う';

  @override
  String get musicLibrary => 'ライブラリ';

  @override
  String get navLibrary => 'ライブラリ';

  @override
  String get navQueue => 'キュー';

  @override
  String get navSources => 'ソース';

  @override
  String get navSettings => '設定';

  @override
  String get libraryTitle => 'ライブラリ';

  @override
  String get librarySubtitle => 'ローカルとオンラインのソースのすべてのトラック';

  @override
  String get libraryClearSearch => '検索をクリア';

  @override
  String get libraryFilterSources => 'ソースで絞り込む';

  @override
  String get libraryAllSources => 'すべてのソース';

  @override
  String get libraryScanAllSources => 'すべてのソースをスキャン';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 曲';
  }

  @override
  String get libraryNoMatchTitle => '一致する曲がありません';

  @override
  String get libraryNoMatchSubtitle => '別のキーワードを試すか、検索条件を消してください';

  @override
  String get librarySourceEmptyTitle => 'このソースには曲がありません';

  @override
  String get librarySourceEmptySubtitle => 'すべてのソースに切り替えるか、このソースを再スキャンしてください';

  @override
  String get libraryViewAllSources => 'すべてのソースを見る';

  @override
  String get libraryScanningTitle => '音楽をスキャン中';

  @override
  String get libraryEmptyTitle => 'まだ曲がありません';

  @override
  String get libraryEmptySubtitle =>
      'ローカルフォルダまたは有効なオンラインソースをスキャンするか、設定でソースを調整してください。';

  @override
  String get libraryLoadFailedTitle => 'ライブラリを読み込めませんでした';

  @override
  String get libraryAddedToQueue => 'キューに追加しました';

  @override
  String libraryScanPaths(String paths) {
    return 'スキャン対象：$paths';
  }

  @override
  String get libraryAddToQueue => 'キューに追加';

  @override
  String get queueTitle => 'キュー';

  @override
  String get queueSubtitle => '現在の再生順';

  @override
  String get queueEmptyTitle => 'キューは空です';

  @override
  String get queueEmptySubtitle => 'ライブラリから曲を選ぶか、曲をキューに追加してください';

  @override
  String get queueGoToLibrary => 'ライブラリへ';

  @override
  String get queueClearTitle => 'キューを空にしますか？';

  @override
  String get queueClearMessage => '再生は停止します。曲がライブラリから削除されることはありません。';

  @override
  String get playerNowPlaying => '再生中';

  @override
  String get playerCollapse => '閉じる';

  @override
  String get playerPrevious => '前の曲';

  @override
  String get playerNext => '次の曲';

  @override
  String get playerPlay => '再生';

  @override
  String get playerPause => '一時停止';

  @override
  String get playerMute => 'ミュート';

  @override
  String get playerUnmute => 'ミュート解除';

  @override
  String get playerQueue => 'キュー';

  @override
  String get playerPlayModeSequential => '全曲リピート';

  @override
  String get playerPlayModeRepeatOne => '1曲リピート';

  @override
  String get playerPlayModeShuffle => 'シャッフル';

  @override
  String get playerNoSongTitle => '曲を選んで始めましょう';

  @override
  String get playerUnknownArtist => '不明なアーティスト';

  @override
  String get playerDockReady => 'Tune · 準備完了';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'キュー $countString 曲';
  }

  @override
  String get nowPlayingEmptyTitle => 'まだ再生中の曲はありません';

  @override
  String get nowPlayingEmptySubtitle => 'ライブラリから曲を選んで始めましょう';

  @override
  String get nowPlayingUnnamedTrack => '無題のトラック';

  @override
  String get nowPlayingLocalMusic => 'ローカル音楽';

  @override
  String get trackUnknownTitle => '不明な曲';

  @override
  String playbackFailed(String error) {
    return '再生に失敗しました: $error';
  }

  @override
  String playbackPauseFailed(String error) {
    return '一時停止に失敗しました: $error';
  }

  @override
  String playbackResumeFailed(String error) {
    return '再生の再開に失敗しました: $error';
  }

  @override
  String playbackSeekFailed(String error) {
    return 'シークに失敗しました: $error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return '音量の設定に失敗しました: $error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return '再生速度の設定に失敗しました: $error';
  }

  @override
  String get audioSourceLocal => 'ローカルファイル';

  @override
  String audioSourceDownloading(int percent) {
    return 'ダウンロード中 $percent%';
  }

  @override
  String get audioSourceCached => 'オフライン準備完了';

  @override
  String get audioSourceFailed => 'ダウンロード失敗';

  @override
  String get routerNotFoundTitle => 'ページが見つかりません';

  @override
  String get routerBackToLibrary => 'ライブラリへ戻る';

  @override
  String get sourcesTitle => 'ソース';

  @override
  String get sourcesSubtitle => 'オンラインカタログ、セルフホストサービス、スキャンフォルダ';

  @override
  String get sourcesAutoScan => '起動時に自動スキャン';

  @override
  String get sourcesAutoScanDescription =>
      '有効なソースは起動時に自動で更新されます。失敗してもローカルライブラリには影響しません。';

  @override
  String get sourcesScanAll => 'すべてのソースをスキャン';

  @override
  String get sourcesImportPlugin => 'プラグインを取り込む';

  @override
  String get sourcesScanMayTakeSeconds => 'リモートソースは数秒かかることがあります';

  @override
  String get sourcesScanCompleted => 'スキャンが完了しました';

  @override
  String get sourcesImportPluginTitle => '音楽プラグインの取り込み';

  @override
  String get sourcesImportPluginMessage =>
      'プラグインは第三者の JavaScript で、アプリ内で実行されネットワークにアクセスできます。信頼できるものだけを取り込んでください。検索キーワードを入力すると有効になります。';

  @override
  String get sourcesPluginUnreadable => 'プラグインファイルを読み込めませんでした';

  @override
  String get sourcesPluginTooLarge => 'プラグインファイルは 2 MB までです';

  @override
  String sourcesPluginImportedEnabled(String name) {
    return '$name を有効にして取り込みました';
  }

  @override
  String sourcesPluginImported(String name) {
    return '$name を取り込みました。キーワードを入力して有効にするとスキャンされます';
  }

  @override
  String sourcesPluginImportFailed(String error) {
    return 'プラグインの取り込みに失敗しました：$error';
  }

  @override
  String get sourcesPluginActions => 'プラグインの操作';

  @override
  String get sourcesConfigure => '設定';

  @override
  String get sourcesDeletePlugin => 'プラグインを削除';

  @override
  String get sourcesUnsupported => 'このバージョンではこのソースに未対応です';

  @override
  String get sourcesDisabled => 'オフ';

  @override
  String get sourcesNeedsConfiguration => '設定が必要です';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return '設定が必要：$hint';
  }

  @override
  String sourcesLastScan(String time) {
    return '前回のスキャン $time';
  }

  @override
  String get sourcesAutoScanLocal => '起動後にローカルフォルダを自動スキャンします';

  @override
  String get sourcesWaitingFirstScan => '初回のスキャンを待っています';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 曲 · $time';
  }

  @override
  String get sourcesSkipped => 'スキップしました';

  @override
  String get sourcesScanFailed => 'スキャンに失敗しました';

  @override
  String get sourcesDeletePluginTitle => 'プラグインを削除しますか？';

  @override
  String sourcesDeletePluginMessage(String name) {
    return '$name のスクリプト、設定、スキャン済みの曲が削除されます。';
  }

  @override
  String sourcesDeleted(String name) {
    return '$name を削除しました';
  }

  @override
  String get sourceKindLocal => 'ローカル';

  @override
  String get sourceKindOpenCatalog => 'オープンカタログ';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindPlugin => 'プラグイン';

  @override
  String sourcesConfigureTitle(String name) {
    return '$name を設定';
  }

  @override
  String sourcesFieldRequired(String label) {
    return '$label を入力してください';
  }

  @override
  String get sourcesFieldNumeric => '数値を入力してください';

  @override
  String get sourcesNotLoaded => 'ソース一覧を読み込んでいます';

  @override
  String get sourcesPlatformNoPlugin => 'このプラットフォームは JavaScript プラグインに未対応です';

  @override
  String get sourcesUpdatePlugin => 'プラグインを更新';

  @override
  String sourcesPluginUpdated(String name, String version) {
    return '$name を $version に更新しました';
  }

  @override
  String sourcesPluginUpToDate(String name) {
    return '$name はすでに最新です';
  }

  @override
  String sourcesPluginUpdateFailed(String error) {
    return 'プラグインの更新に失敗しました: $error';
  }

  @override
  String get playerLyrics => '歌詞';

  @override
  String get lyricsLoading => '歌詞を読み込んでいます';

  @override
  String lyricsFailed(String error) {
    return '歌詞を読み込めませんでした: $error';
  }

  @override
  String get lyricsMissing => 'この曲には歌詞がありません';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '外観と言語、ローカルライブラリを調整します。';

  @override
  String get settingsThemeDescription => '画面の見た目と言語を選びます。';

  @override
  String get settingsLanguageDescription => '画面とシステムメニューの言語';

  @override
  String get settingsLibraryDescription => 'Tune はこのフォルダ内の音声ファイルのみを検索します。';

  @override
  String get settingsDefaultPath => 'デフォルト';

  @override
  String get settingsNoDefaultFolder => 'デフォルトの音楽フォルダが見つかりません';

  @override
  String get settingsCustomPath => 'カスタム';

  @override
  String get settingsAddFolder => 'フォルダを追加';

  @override
  String get settingsClearLibrary => 'ライブラリを空にする';

  @override
  String get settingsScanSafetyNote => 'スキャンは音声ファイルを読むだけで、ディスクの内容を変更・削除しません。';

  @override
  String get settingsAboutTitle => 'Tune について';

  @override
  String get settingsChooseFolder => '音楽フォルダを選択';

  @override
  String get settingsFolderAdded => 'スキャン先を追加しました';

  @override
  String get settingsScanDone => 'スキャンが完了しました';

  @override
  String get settingsClearLibraryTitle => 'ライブラリを空にしますか？';

  @override
  String get settingsClearLibraryMessage =>
      'Tune のスキャン履歴だけを消します。ディスク上の音楽ファイルは削除されません。';

  @override
  String get settingsLibraryCleared => 'ライブラリを空にしました';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 件';
  }

  @override
  String get searchOnlineTitle => 'オンライン検索';

  @override
  String get searchOnlineHint => 'オンラインソースを検索します（jazz、ピアノ、lo-fi など）';

  @override
  String get searchOnlineDescription => '有効なオンラインソースを検索します。結果はライブラリに保存されません。';

  @override
  String get searchOnlinePrompt => 'オンラインソースを検索';

  @override
  String get searchOnlinePromptDescription =>
      'キーワードを入力して Enter キーを押すと、有効なオンライン音源と取り込んだプラグインが並行して検索されます。';

  @override
  String get searchNoResults => '結果がありません';

  @override
  String get searchNoResultsDescription => '別のキーワードでお試しください。';

  @override
  String get searchNoMatch => '一致する曲が見つかりません';

  @override
  String get searchNoMatchDescription => '別のキーワードでお試しください。';

  @override
  String searchSearching(String query) {
    return '「$query」を検索中';
  }

  @override
  String searchResultCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 曲';
  }

  @override
  String get searchPlayAll => 'すべて再生';

  @override
  String get searchAddToQueue => 'キューに追加';

  @override
  String searchAddedToQueue(String title) {
    return 'キューに追加しました：$title';
  }

  @override
  String get searchNoSourcesEnabled => '有効なオンラインソースがありません。先に設定で有効にしてください。';

  @override
  String get searchFailedShort => '検索に失敗しました';

  @override
  String searchFailed(String error) {
    return 'オンライン検索に失敗しました：$error';
  }

  @override
  String get scanPreparing => 'スキャンを準備中…';

  @override
  String get scanNoEnabledSources => '有効なソースがありません';

  @override
  String get scanNoLocalFolders => 'スキャンできる音楽フォルダがありません';

  @override
  String scanProgressPercent(int percent) {
    return 'スキャン中 $percent%';
  }

  @override
  String get scanAllSourcesFailed => 'すべてのソースのスキャンに失敗しました';

  @override
  String scanFailed(String error) {
    return 'スキャンに失敗しました: $error';
  }

  @override
  String clearLibraryFailed(String error) {
    return 'ライブラリを空にできませんでした: $error';
  }

  @override
  String get scanNoAudioFiles => '音声ファイルが見つかりません';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 曲をスキャンしました';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 曲';
  }

  @override
  String get scanSourceNotConfigured => 'ソースが未設定です';

  @override
  String get scanCachedTooSoon => '前回のスキャン間隔が近いため、キャッシュを保持しました';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$sourcesString 個のソース、合計 $songsString 曲をスキャンしました';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '$songsString 曲を更新し、$failedString 個のソースが失敗しました';
  }

  @override
  String sourceErrorForbidden(int status) {
    return 'アクセスが拒否されました（HTTP $status）';
  }

  @override
  String get sourceErrorRateLimited => 'リクエストが多すぎます（HTTP 429）。しばらくしてからお試しください。';

  @override
  String sourceErrorHttpStatus(int status) {
    return 'API が HTTP $status を返しました';
  }

  @override
  String get sourceErrorTimeout => '接続がタイムアウトしました';

  @override
  String get sourceErrorConnection => 'ソースサービスに接続できません';

  @override
  String get sourceErrorCertificate => '証明書を検証できません';

  @override
  String get sourceErrorCancelled => 'リクエストはキャンセルされました';

  @override
  String sourceErrorNetwork(String message) {
    return 'ネットワークリクエストに失敗しました：$message';
  }

  @override
  String sourceErrorPluginLoad(String message) {
    return 'プラグインを読み込めませんでした：$message';
  }

  @override
  String get sourceErrorUnsupported => 'このソースはまだ未対応です';

  @override
  String sourceErrorScanInterval(String interval) {
    return '前回のスキャンから $interval 未満です';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return 'スキャンが $seconds 秒でタイムアウトしました';
  }

  @override
  String intervalHours(int count) {
    return '$count 時間';
  }

  @override
  String intervalMinutes(int count) {
    return '$count 分';
  }

  @override
  String get localSourceHint => 'ライブラリ設定でスキャン先を追加してください';

  @override
  String get localSourceNotConfigured => 'ローカル音楽フォルダが未設定です';

  @override
  String get pluginSourceHint => '検索キーワードを入力してください（例：アーティスト、piano、jazz）';

  @override
  String get pluginFieldQuery => '検索キーワード';

  @override
  String get pluginFieldHint => '例：アーティスト、piano、jazz';

  @override
  String pluginImportedVersion(String version) {
    return '取り込んだ MusicFree プラグイン · v$version';
  }

  @override
  String pluginVariable(String key) {
    return 'プラグイン変数 $key';
  }

  @override
  String get pluginFileMissing => 'プラグインファイルがありません。もう一度取り込んでください。';

  @override
  String get pluginRuntimeUnsupported =>
      'このプラットフォームは JavaScript 音楽プラグインに未対応です。デスクトップまたはモバイルで取り込んでください。';

  @override
  String get pluginCompatLibrary => 'プラグイン互換ライブラリ';

  @override
  String get pluginBridgeScript => 'プラグインブリッジスクリプト';

  @override
  String get pluginInit => 'プラグインの初期化';

  @override
  String get pluginScript => 'プラグインスクリプト';

  @override
  String get pluginExports => 'プラグインのエクスポート';

  @override
  String get pluginNoExports => 'プラグインが有効な module.exports をエクスポートしていません';

  @override
  String get pluginIncomplete => 'プラグインが不完全です：platform と search メソッドが必要です';

  @override
  String get pluginNoMediaSource => 'プラグインが getMediaSource を実装していません';

  @override
  String get pluginNoStream => 'プラグインが再生可能なアドレスを返しませんでした';

  @override
  String get pluginRuntimeClosed => 'プラグインの実行環境が閉じました';

  @override
  String pluginCallFailed(String label, String message) {
    return '$label に失敗しました：$message';
  }

  @override
  String get pluginCallTimeout => 'プラグインの呼び出しがタイムアウトしました';

  @override
  String get pluginUnknownData => 'プラグインが読み取れないデータを返しました';

  @override
  String get pluginCallError => 'プラグインの呼び出しに失敗しました';

  @override
  String get pluginNoMatch => '一致する曲が見つかりません';

  @override
  String pluginNoStreamResults(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'プラグインは $countString 件の結果を返しましたが、再生可能なアドレスがありませんでした';
  }

  @override
  String get neteaseHint =>
      '自前の NeteaseCloudMusicApi のアドレスを入力してください（例：http://localhost:3000）';

  @override
  String get neteaseFieldApi => 'API アドレス';

  @override
  String get neteaseFieldQuery => '検索キーワード';

  @override
  String get neteaseFieldHint => '例：人気、アーティスト';

  @override
  String get neteaseFieldLimit => '1回のスキャン件数';

  @override
  String get neteaseFieldLimitHint => '既定は 20、最大 50';

  @override
  String get neteaseHotKeyword => '人気';

  @override
  String get neteaseEmptyResponse => 'NetEase API が空のレスポンスを返しました';

  @override
  String get neteaseNoMatch => '一致する曲が見つかりません';

  @override
  String get neteaseNoStream =>
      'API が再生可能なアドレスを返しませんでした（サーバーでのログインが必要な場合があります）';

  @override
  String get openverseHint => 'スキャンキーワードを入力してください（例：piano、ambient、jazz）';

  @override
  String get openverseFieldQuery => '検索キーワード';

  @override
  String get openverseFieldHint => '例：piano、ambient、jazz';

  @override
  String get openverseEmptyResponse => 'Openverse が空のレスポンスを返しました';

  @override
  String get openverseNoMatch => '一致するオープンオーディオが見つかりません';

  @override
  String get sourceLocalName => 'ローカル音楽';

  @override
  String get sourceLocalDescription => 'デバイス上の音楽フォルダをスキャン';

  @override
  String get sourceOpenverseDescription =>
      'Jamendo、Freesound、Wikimedia などのオープン音楽の集い';

  @override
  String get sourceJamendoDescription => '独立音楽のオープンカタログ。無料の Client ID が必要です。';

  @override
  String get sourceInternetArchiveDescription => 'Internet Archive のオープン音楽集';

  @override
  String get sourceNeteaseName => 'NetEase Cloud Music API';

  @override
  String get sourceNeteaseDescription => '自前の NeteaseCloudMusicApi サーバーに接続します';

  @override
  String get jamendoHint =>
      'developer.jamendo.com で無料の Client ID を取得して入力してください';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint => 'developer.jamendo.com で無料申請';

  @override
  String get jamendoFieldQuery => '検索キーワード（任意）';

  @override
  String get jamendoFieldQueryHint => '例：jazz、electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo が空のレスポンスを返しました';

  @override
  String get jamendoNoMatch => '一致する Jamendo 曲が見つかりません';

  @override
  String get internetArchiveHint =>
      'Internet Archive の検索条件を入力してください（例：collection:netlabels AND mediatype:audio）';

  @override
  String get internetArchiveFieldQuery => '検索条件';

  @override
  String get internetArchiveFieldLimit => '1回のスキャン件数';

  @override
  String get internetArchiveFieldLimitHint => '既定は 8、最大 20';

  @override
  String get internetArchiveInvalidResponse =>
      'Internet Archive が読み取りできないレスポンスを返しました';

  @override
  String get internetArchiveNoMatch => '再生可能なアーカイブ音楽が見つかりません';

  @override
  String get downloadUnsupportedPlatform =>
      'このプラットフォムにはファイルシステムがないため、ダウンロードの保存はできません';

  @override
  String get audioLoadFailed => '音声の読み込みに失敗しました';

  @override
  String get audioPathEmpty => '音声のパスが空です';

  @override
  String get pluginUpdateNoUrl => 'プラグインにダウンロード元が記録されていないためアップデートを確認できません';

  @override
  String sourcesPluginUrlDownloadFailed(String error) {
    return 'プラグインをダウンロードできませんでした: $error';
  }

  @override
  String pluginStepFailed(String error, String label) {
    return '$label に失敗しました: $error';
  }

  @override
  String get sourcesImportPluginFromUrl => 'URL からインポート';

  @override
  String get sourcesPluginUrlTitle => 'プラグインの URL';

  @override
  String get sourcesPluginUrlHint => 'https://example.com/plugin.js';

  @override
  String get sourcesPluginUrlInvalid => '有効な http(s)リンクを入力してください';

  @override
  String get pluginUrlInvalid => 'プラグインのアドレスが無効です。http または https のリンクを使ってください';

  @override
  String get pluginUrlEmpty => 'プラグインスクリプトが空です';

  @override
  String get pluginUrlTooLarge => 'プラグインスクリプトがサイズ上限を超えました';

  @override
  String pluginSandboxStartFailed(String error) {
    return 'プラグインのサンドボックスを起動できません: $error';
  }

  @override
  String get pluginSandboxStartTimeout => 'プラグインのサンドボックスの起動がタイムアウトしました';

  @override
  String pluginScriptTooLarge(String limit) {
    return 'プラグインスクリプトが $limit KB の上限を超えました';
  }

  @override
  String get pluginRuntimeTerminated => 'プラグインのランタイムは終止されました';

  @override
  String get pluginRuntimeTimeLimit => 'プラグインのランタイムが実行時間上限を超えました';

  @override
  String get pluginSandboxNotReady => 'プラグインのサンドボックスはまだ準備されていません';

  @override
  String pluginCallTimeoutDetailed(int seconds) {
    return 'プラグインの呼び出しが $seconds 秒でタイムアウトしました';
  }

  @override
  String get pluginRuntimeCrashed => 'プラグインのランタイムがクラッシュしました';

  @override
  String pluginFetchShimFailed(String message) {
    return 'fetch シムの読み込みに失敗しました: $message';
  }

  @override
  String pluginUnknownCall(String method) {
    return '未知のプラグイン呼び出しです: $method';
  }

  @override
  String get pluginScriptMissing => 'プラグインスクリプトが存在しません';

  @override
  String pluginMemoryLimitExceeded(String limit) {
    return 'プラグインのメモリ使用量が $limit を超えたため終止されました';
  }

  @override
  String get ccmixterEmptyResponse => 'ccMixter が空のレスポンスを返しました';

  @override
  String get ccmixterFieldLimit => '1回のスキャン件数';

  @override
  String get ccmixterFieldLimitHint => '既定は 15、最大 30';

  @override
  String get ccmixterFieldQuery => '検索タグ';

  @override
  String get ccmixterFieldQueryHint => '例：jazz、ambient、electro';

  @override
  String get ccmixterHint => 'ccMixter のタグを入力してください（例：jazz、ambient、electro）';

  @override
  String get ccmixterNoMatch => '一致する ccMixter 曲が見つかりません';

  @override
  String get itunesEmptyResponse => 'iTunes API が空のレスポンスを返しました';

  @override
  String get itunesFieldLimit => '1回のスキャン件数';

  @override
  String get itunesFieldLimitHint => '既定は 20、最大 50';

  @override
  String get itunesFieldQuery => '検索キーワード';

  @override
  String get itunesFieldQueryHint => '例：jazz、piano、lo-fi';

  @override
  String get itunesHint => '検索キーワードを入力してください（例：jazz、piano、lo-fi）';

  @override
  String get itunesNoMatch => '一致する iTunes 曲が見つかりません';

  @override
  String get podcastRssEmptyFeed => 'フィードのアドレスが空のドキュメントを返しました';

  @override
  String get podcastRssFieldFeed => 'フィードのアドレス';

  @override
  String get podcastRssFieldFeedHint => '例：https://example.com/podcast.xml';

  @override
  String get podcastRssFieldLimit => '1回のスキャン件数';

  @override
  String get podcastRssFieldLimitHint => '既定は 20、最大 100';

  @override
  String get podcastRssHint => 'ポッドキャストフィード（RSS）のアドレスを入力してください';

  @override
  String podcastRssInvalidFeed(String error) {
    return 'フィードのアドレスが読み取れない XML を返しました: $error';
  }

  @override
  String get podcastRssNoMatch => 'フィードに再生できるエピソードがありません';

  @override
  String get sourceCcmixterDescription => 'Creative Commons のリミックスとオープン音楽';

  @override
  String get sourceItunesDescription => 'Apple Music カタログの 30 秒プレビュー';

  @override
  String get sourcePodcastRssDescription =>
      '任意の podcast RSS フィードを再生可能なエピソードに変換します';

  @override
  String get sourcePodcastRssName => 'ポッドキャスト';

  @override
  String get sourceSubsonicDescription =>
      '自前の Navidrome / Subsonic 音楽ライブラリに接続します';

  @override
  String get subsonicAuthFailed => '音楽サーバーに接続できません。アドレスとアカウントを確認してください';

  @override
  String get subsonicEmptyResponse => '音楽サーバーが空のレスポンスを返しました';

  @override
  String subsonicError(String error) {
    return '音楽サーバーがエラーを返しました: $error';
  }

  @override
  String get subsonicFieldLimit => '1回のスキャン件数';

  @override
  String get subsonicFieldLimitHint => '既定は 25、最大 100';

  @override
  String get subsonicFieldPassword => 'パスワード';

  @override
  String get subsonicFieldPasswordHint => 'アクセストークンの署名に使われ、平文で送信されません';

  @override
  String get subsonicFieldQuery => '検索キーワード（任意）';

  @override
  String get subsonicFieldQueryHint => '例：jazz、piano';

  @override
  String get subsonicFieldServer => 'サーバーアドレス';

  @override
  String get subsonicFieldServerHint => '例：http://localhost:4533';

  @override
  String get subsonicFieldUser => 'ユーザー名';

  @override
  String get subsonicFieldUserHint => '音楽サーバーのログインユーザー名';

  @override
  String get subsonicHint =>
      '自前の音楽サーバーのアドレスとアカウントを入力してください（例：http://localhost:4533）';

  @override
  String get subsonicNoMatch => '一致する曲が見つかりません';

  @override
  String get sourceAudiusDescription => 'オープンな音楽ネットワーク Audius のフルトラック';

  @override
  String get audiusHint => '検索キーワードを入力します（例：jazz、ambient、electronic）';

  @override
  String get audiusFieldQuery => '検索キーワード';

  @override
  String get audiusFieldQueryHint => '例：jazz、ambient、electronic';

  @override
  String get audiusFieldLimit => '1 回のスキャン件数';

  @override
  String get audiusFieldLimitHint => '既定 20、最大 50';

  @override
  String get audiusEmptyResponse => 'Audius が空の応答を返しました';

  @override
  String get audiusNoMatch => '条件に一致する Audius のトラックがありません';

  @override
  String get sourceRadioDescription => '公開インターネットラジオのライブ配信';

  @override
  String get radioHint => '放送局のディレクトリを選び、キーワードで絞り込めます';

  @override
  String get radioFieldProvider => '放送局のディレクトリ';

  @override
  String get radioFieldProviderHint =>
      'すべてのディレクトリ、Radio Browser、SomaFM、Radio Paradise';

  @override
  String get radioProviderAll => 'すべてのディレクトリ';

  @override
  String get radioFieldQuery => '放送局のキーワード';

  @override
  String get radioFieldQueryHint => '例：jazz、ambient、SomaFM';

  @override
  String get radioFieldLimit => '1 回のスキャンする局数';

  @override
  String get radioFieldLimitHint => '既定 20、最大 100';

  @override
  String get radioNoMatch => '条件に一致する放送局がありません';

  @override
  String get sourceWikimediaDescription => 'ウィキメディア・コモンズのオープン音声';

  @override
  String get wikimediaHint => '検索キーワードを入力します（例：piano、lecture、birdsong）';

  @override
  String get wikimediaFieldQuery => '検索キーワード';

  @override
  String get wikimediaFieldQueryHint => '例：piano、lecture、birdsong';

  @override
  String get wikimediaFieldLimit => '1 回のスキャン件数';

  @override
  String get wikimediaFieldLimitHint => '既定 15、最大 30';

  @override
  String get wikimediaEmptyResponse => 'ウィキメディア・コモンズが空の応答を返しました';

  @override
  String get wikimediaNoMatch => '再生できる音声が見つかりません';

  @override
  String get sourceJellyfinDescription => '自前の Jellyfin ライブラリに接続します';

  @override
  String get jellyfinHint => 'Jellyfin サーバーのアドレスとアカウントを入力します';

  @override
  String get jellyfinFieldServer => 'サーバーアドレス';

  @override
  String get jellyfinFieldServerHint => '例：http://localhost:8096';

  @override
  String get jellyfinFieldUser => 'ユーザー名';

  @override
  String get jellyfinFieldUserHint => 'Jellyfin アカウントのログイン名';

  @override
  String get jellyfinFieldPassword => 'パスワード';

  @override
  String get jellyfinFieldPasswordHint => 'アクセストークンの取得に使用します';

  @override
  String get jellyfinFieldLimit => '1 回のスキャン件数';

  @override
  String get jellyfinFieldLimitHint => '既定 50、最大 200';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin が空の応答を返しました';

  @override
  String get jellyfinNoMatch => '条件に一致するトラックがありません';

  @override
  String get jellyfinAuthFailed => 'Jellyfin サーバーに接続できません。アドレスとアカウントを確認してください';

  @override
  String get audioSourceStreaming => 'ライブ';

  @override
  String get playerLiveBadge => 'ライブ配信中';

  @override
  String get nowPlayingLiveStream => 'ライブ配信のため固定長はありません';

  @override
  String get nowPlayingDetails => 'トラック情報';

  @override
  String get nowPlayingDetailAlbum => 'アルバム';

  @override
  String get nowPlayingDetailYear => '年';

  @override
  String get nowPlayingDetailGenre => 'ジャンル';

  @override
  String get nowPlayingDetailBitrate => 'ビットレート';

  @override
  String get nowPlayingDetailSampleRate => 'サンプリング周波数';

  @override
  String get nowPlayingDetailTrack => 'トラック番号';

  @override
  String get nowPlayingDetailDisc => 'ディスク番号';

  @override
  String get nowPlayingDetailLanguage => '言語';

  @override
  String get nowPlayingDetailLicense => 'ライセンス';

  @override
  String get nowPlayingDetailSource => 'ソース';

  @override
  String get nowPlayingDetailNowPlaying => '放送中';

  @override
  String get jamendoFieldFormat => '音質';

  @override
  String get jamendoFieldFormatHint => '既定は 192 kbps';

  @override
  String get subsonicFieldFormat => '音質';

  @override
  String get subsonicFieldFormatHint => '既定は元と同じ音質';

  @override
  String get subsonicFormatOriginal => '元の音質';

  @override
  String get sourceRadioName => 'インターネットラジオ';
}

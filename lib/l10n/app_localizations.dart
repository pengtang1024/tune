import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地优先的桌面音乐播放器'**
  String get appTagline;

  /// No description provided for @appStartFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune 启动失败'**
  String get appStartFailed;

  /// No description provided for @cancel.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In zh_CN, this message translates to:
  /// **'确定'**
  String get ok;

  /// No description provided for @save.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @remove.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @clear.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空'**
  String get clear;

  /// No description provided for @close.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @chooseFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择文件'**
  String get chooseFile;

  /// No description provided for @unknownError.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知错误'**
  String get unknownError;

  /// No description provided for @scanNow.
  ///
  /// In zh_CN, this message translates to:
  /// **'立即扫描'**
  String get scanNow;

  /// No description provided for @search.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @scanning.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描中'**
  String get scanning;

  /// No description provided for @updateEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'更新'**
  String get updateEyebrow;

  /// No description provided for @updateTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本'**
  String get updateTitle;

  /// No description provided for @updateDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'检查项目发布页是否有新版本，并直接安装'**
  String get updateDescription;

  /// No description provided for @updateCurrentVersion.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前版本 {version}'**
  String updateCurrentVersion(String version);

  /// No description provided for @updateIdle.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有检查过发布页'**
  String get updateIdle;

  /// No description provided for @updateChecking.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在检查发布页…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In zh_CN, this message translates to:
  /// **'已经是最新版本'**
  String get updateUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In zh_CN, this message translates to:
  /// **'新版本 {version} 可用'**
  String updateAvailable(String version);

  /// No description provided for @updateDownloading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在下载'**
  String get updateDownloading;

  /// No description provided for @updateInstalling.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在安装…'**
  String get updateInstalling;

  /// No description provided for @updateReady.
  ///
  /// In zh_CN, this message translates to:
  /// **'更新已就绪，重启后生效'**
  String get updateReady;

  /// No description provided for @updateFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'检查失败：{error}'**
  String updateFailed(String error);

  /// No description provided for @updateCheck.
  ///
  /// In zh_CN, this message translates to:
  /// **'检查更新'**
  String get updateCheck;

  /// No description provided for @updateInstall.
  ///
  /// In zh_CN, this message translates to:
  /// **'下载并安装'**
  String get updateInstall;

  /// No description provided for @updateRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get updateRetry;

  /// No description provided for @updateRestart.
  ///
  /// In zh_CN, this message translates to:
  /// **'立即重启'**
  String get updateRestart;

  /// No description provided for @updateNoArchive.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个平台不支持自动安装，请到发布页手动下载'**
  String get updateNoArchive;

  /// No description provided for @about.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @language.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题'**
  String get theme;

  /// No description provided for @lightMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色模式'**
  String get lightMode;

  /// No description provided for @darkMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @systemMode.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统'**
  String get systemMode;

  /// No description provided for @libraryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库'**
  String get libraryTitle;

  /// No description provided for @librarySummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'{tracks} 首歌曲 · {albums} 张专辑 · {sources} 个来源'**
  String librarySummary(int tracks, int albums, int sources);

  /// No description provided for @libraryClearSearch.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除搜索'**
  String get libraryClearSearch;

  /// No description provided for @libraryFilterSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'筛选来源'**
  String get libraryFilterSources;

  /// No description provided for @libraryAllSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部来源'**
  String get libraryAllSources;

  /// No description provided for @libraryScanAllSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描全部音源'**
  String get libraryScanAllSources;

  /// No description provided for @libraryTrackCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 首'**
  String libraryTrackCount(int count);

  /// No description provided for @libraryNoMatchTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有匹配的歌曲'**
  String get libraryNoMatchTitle;

  /// No description provided for @libraryNoMatchSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'换个关键词，或清除搜索条件'**
  String get libraryNoMatchSubtitle;

  /// No description provided for @librarySourceEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'该来源暂无歌曲'**
  String get librarySourceEmptyTitle;

  /// No description provided for @librarySourceEmptySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'切换到全部来源，或重新扫描该音源'**
  String get librarySourceEmptySubtitle;

  /// No description provided for @libraryViewAllSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看全部来源'**
  String get libraryViewAllSources;

  /// No description provided for @libraryScanningTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在扫描音乐'**
  String get libraryScanningTitle;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有音乐'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描本地目录或已启用的在线音源，也可以在设置中调整音源。'**
  String get libraryEmptySubtitle;

  /// No description provided for @libraryLoadFailedTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库加载失败'**
  String get libraryLoadFailedTitle;

  /// No description provided for @libraryAddedToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入播放队列'**
  String get libraryAddedToQueue;

  /// No description provided for @libraryScanPaths.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描目录：{paths}'**
  String libraryScanPaths(String paths);

  /// No description provided for @libraryAddToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'加入播放队列'**
  String get libraryAddToQueue;

  /// No description provided for @libraryAddAllToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'将整个列表加入队列'**
  String get libraryAddAllToQueue;

  /// No description provided for @libraryViewSongs.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌曲视图'**
  String get libraryViewSongs;

  /// No description provided for @libraryViewAlbums.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑视图'**
  String get libraryViewAlbums;

  /// No description provided for @libraryUnknownAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知专辑'**
  String get libraryUnknownAlbum;

  /// No description provided for @libraryVariousArtists.
  ///
  /// In zh_CN, this message translates to:
  /// **'多位艺术家'**
  String get libraryVariousArtists;

  /// No description provided for @libraryBackToAlbums.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回专辑'**
  String get libraryBackToAlbums;

  /// No description provided for @queueTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放队列'**
  String get queueTitle;

  /// No description provided for @queueEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放队列是空的'**
  String get queueEmptyTitle;

  /// No description provided for @queueEmptySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'从音乐库选择歌曲，或把歌曲加入队列'**
  String get queueEmptySubtitle;

  /// No description provided for @queueGoToLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'去音乐库'**
  String get queueGoToLibrary;

  /// No description provided for @queueClearTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空播放队列？'**
  String get queueClearTitle;

  /// No description provided for @queueClearMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前播放会停止，队列中的歌曲不会从音乐库删除。'**
  String get queueClearMessage;

  /// No description provided for @queueReorderTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'拖动排序'**
  String get queueReorderTooltip;

  /// No description provided for @favoritesTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'喜欢'**
  String get favoritesTitle;

  /// No description provided for @favoritesSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'标了心的曲子都在这里'**
  String get favoritesSubtitle;

  /// No description provided for @favoritesEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get favoritesEyebrow;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有喜欢的曲子'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'在音乐库里点一下红心，喜欢的曲子就会收在这里'**
  String get favoritesEmptySubtitle;

  /// No description provided for @favoritesGoToLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'去音乐库'**
  String get favoritesGoToLibrary;

  /// No description provided for @favoriteAdd.
  ///
  /// In zh_CN, this message translates to:
  /// **'加入收藏'**
  String get favoriteAdd;

  /// No description provided for @favoriteRemove.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消收藏'**
  String get favoriteRemove;

  /// No description provided for @favoritesOutsideLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'另有 {count} 首标过，但不在音乐库里'**
  String favoritesOutsideLibrary(int count);

  /// No description provided for @favoritesEmptyOutsideTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'标过的歌不在音乐库里'**
  String get favoritesEmptyOutsideTitle;

  /// No description provided for @favoritesEmptyOutsideSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库里找不到它们，标记还留着'**
  String get favoritesEmptyOutsideSubtitle;

  /// No description provided for @playerNowPlaying.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放'**
  String get playerNowPlaying;

  /// No description provided for @playerExpandNowPlaying.
  ///
  /// In zh_CN, this message translates to:
  /// **'展开正在播放'**
  String get playerExpandNowPlaying;

  /// No description provided for @playerCollapse.
  ///
  /// In zh_CN, this message translates to:
  /// **'收起'**
  String get playerCollapse;

  /// No description provided for @playerPrevious.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一首'**
  String get playerPrevious;

  /// No description provided for @playerNext.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一首'**
  String get playerNext;

  /// No description provided for @playerPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get playerPlay;

  /// No description provided for @playerPause.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停'**
  String get playerPause;

  /// No description provided for @playerMute.
  ///
  /// In zh_CN, this message translates to:
  /// **'静音'**
  String get playerMute;

  /// No description provided for @playerUnmute.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复音量'**
  String get playerUnmute;

  /// No description provided for @playerPlayModeSequential.
  ///
  /// In zh_CN, this message translates to:
  /// **'列表循环'**
  String get playerPlayModeSequential;

  /// No description provided for @playerPlayModeRepeatOne.
  ///
  /// In zh_CN, this message translates to:
  /// **'单曲循环'**
  String get playerPlayModeRepeatOne;

  /// No description provided for @playerPlayModeShuffle.
  ///
  /// In zh_CN, this message translates to:
  /// **'随机播放'**
  String get playerPlayModeShuffle;

  /// No description provided for @playerNoSongTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择一首歌开始'**
  String get playerNoSongTitle;

  /// No description provided for @playerUnknownArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知艺术家'**
  String get playerUnknownArtist;

  /// No description provided for @playerDockReady.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune · 就绪'**
  String get playerDockReady;

  /// No description provided for @playerQueueSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'队列 {count} 首'**
  String playerQueueSummary(int count);

  /// No description provided for @playerQueuePosition.
  ///
  /// In zh_CN, this message translates to:
  /// **'队列第 {index} 首'**
  String playerQueuePosition(int index);

  /// No description provided for @nowPlayingEmptyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有播放的曲目'**
  String get nowPlayingEmptyTitle;

  /// No description provided for @nowPlayingEmptySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'从音乐库里挑一首开始'**
  String get nowPlayingEmptySubtitle;

  /// No description provided for @nowPlayingUnnamedTrack.
  ///
  /// In zh_CN, this message translates to:
  /// **'未命名曲目'**
  String get nowPlayingUnnamedTrack;

  /// No description provided for @trackUnknownTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知歌曲'**
  String get trackUnknownTitle;

  /// No description provided for @playbackFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放失败：{error}'**
  String playbackFailed(String error);

  /// No description provided for @playbackPauseFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停失败：{error}'**
  String playbackPauseFailed(String error);

  /// No description provided for @playbackResumeFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'继续播放失败：{error}'**
  String playbackResumeFailed(String error);

  /// No description provided for @playbackSeekFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'跳转失败：{error}'**
  String playbackSeekFailed(String error);

  /// No description provided for @playbackVolumeFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置音量失败：{error}'**
  String playbackVolumeFailed(String error);

  /// No description provided for @playbackSpeedFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置速度失败：{error}'**
  String playbackSpeedFailed(String error);

  /// No description provided for @audioSourceLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地文件'**
  String get audioSourceLocal;

  /// No description provided for @audioSourceCaching.
  ///
  /// In zh_CN, this message translates to:
  /// **'缓存中 {percent}%'**
  String audioSourceCaching(int percent);

  /// No description provided for @audioSourceCached.
  ///
  /// In zh_CN, this message translates to:
  /// **'已缓存'**
  String get audioSourceCached;

  /// No description provided for @audioSourceFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放失败'**
  String get audioSourceFailed;

  /// No description provided for @routerNotFoundTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'页面不存在'**
  String get routerNotFoundTitle;

  /// No description provided for @routerBackToLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回音乐库'**
  String get routerBackToLibrary;

  /// No description provided for @sourcesTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'音源'**
  String get sourcesTitle;

  /// No description provided for @sourcesSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线曲库、自建服务与扫描目录'**
  String get sourcesSubtitle;

  /// No description provided for @sourcesGroupMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多音源'**
  String get sourcesGroupMore;

  /// No description provided for @sourcesAdd.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加音源'**
  String get sourcesAdd;

  /// No description provided for @sourcesAddChooseType.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择音源类型'**
  String get sourcesAddChooseType;

  /// No description provided for @sourcesAddTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加 {name}'**
  String sourcesAddTitle(String name);

  /// No description provided for @sourcesFieldName.
  ///
  /// In zh_CN, this message translates to:
  /// **'名称'**
  String get sourcesFieldName;

  /// No description provided for @sourcesFieldNameHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'留空则用类型名加序号'**
  String get sourcesFieldNameHint;

  /// No description provided for @sourcesDelete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除'**
  String get sourcesDelete;

  /// No description provided for @sourcesDeleteTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除「{name}」？'**
  String sourcesDeleteTitle(String name);

  /// No description provided for @sourcesDeleteHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个音源带来的曲目也会一并移除。'**
  String get sourcesDeleteHint;

  /// No description provided for @sourcesMenu.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多操作'**
  String get sourcesMenu;

  /// No description provided for @sourcesMoveUp.
  ///
  /// In zh_CN, this message translates to:
  /// **'上移'**
  String get sourcesMoveUp;

  /// No description provided for @sourcesMoveDown.
  ///
  /// In zh_CN, this message translates to:
  /// **'下移'**
  String get sourcesMoveDown;

  /// No description provided for @sourcesMoveToMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'移到更多音源'**
  String get sourcesMoveToMore;

  /// No description provided for @sourcesMoveToMain.
  ///
  /// In zh_CN, this message translates to:
  /// **'移回主列表'**
  String get sourcesMoveToMain;

  /// No description provided for @sourcesMovedToMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'已移到更多音源'**
  String get sourcesMovedToMore;

  /// No description provided for @sourcesMovedToMain.
  ///
  /// In zh_CN, this message translates to:
  /// **'已移回主列表'**
  String get sourcesMovedToMain;

  /// No description provided for @sourcesHealthScore.
  ///
  /// In zh_CN, this message translates to:
  /// **'健康度 {score}/100'**
  String sourcesHealthScore(int score);

  /// No description provided for @sourcesHealthBreakdown.
  ///
  /// In zh_CN, this message translates to:
  /// **'可用 {availability}% · 配置 {configuration}% · 扫描 {scan}% · 新鲜 {freshness}% · 产出 {output}% · 速度 {speed}% · 可靠 {reliability}% · 稳定 {stability}% · 可播放 {playable}% · 封面 {artwork}% · 元数据 {metadata}% · 活跃 {activity}%'**
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
  );

  /// No description provided for @sourcesHealthWeightsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'健康度权重'**
  String get sourcesHealthWeightsTitle;

  /// No description provided for @sourcesHealthWeightsHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'调高某个维度，它在健康度里的分量更大；总权重会自动归一化。'**
  String get sourcesHealthWeightsHint;

  /// No description provided for @sourcesHealthWeightsTotal.
  ///
  /// In zh_CN, this message translates to:
  /// **'总权重 {total} · 自动归一化'**
  String sourcesHealthWeightsTotal(int total);

  /// No description provided for @settingsSourceHealthDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'十二个维度当前的分量；调高一个维度，它在健康度里的占比就更大。'**
  String get settingsSourceHealthDescription;

  /// No description provided for @settingsAdjustSourceHealthWeights.
  ///
  /// In zh_CN, this message translates to:
  /// **'调整权重'**
  String get settingsAdjustSourceHealthWeights;

  /// No description provided for @sourcesHealthWeightsReset.
  ///
  /// In zh_CN, this message translates to:
  /// **'恢复默认'**
  String get sourcesHealthWeightsReset;

  /// No description provided for @sourcesHealthAvailability.
  ///
  /// In zh_CN, this message translates to:
  /// **'可用'**
  String get sourcesHealthAvailability;

  /// No description provided for @sourcesHealthConfiguration.
  ///
  /// In zh_CN, this message translates to:
  /// **'配置'**
  String get sourcesHealthConfiguration;

  /// No description provided for @sourcesHealthScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描'**
  String get sourcesHealthScan;

  /// No description provided for @sourcesHealthFreshness.
  ///
  /// In zh_CN, this message translates to:
  /// **'新鲜'**
  String get sourcesHealthFreshness;

  /// No description provided for @sourcesHealthOutput.
  ///
  /// In zh_CN, this message translates to:
  /// **'产出'**
  String get sourcesHealthOutput;

  /// No description provided for @sourcesHealthSpeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'速度'**
  String get sourcesHealthSpeed;

  /// No description provided for @sourcesHealthReliability.
  ///
  /// In zh_CN, this message translates to:
  /// **'可靠'**
  String get sourcesHealthReliability;

  /// No description provided for @sourcesHealthStability.
  ///
  /// In zh_CN, this message translates to:
  /// **'稳定'**
  String get sourcesHealthStability;

  /// No description provided for @sourcesHealthPlayable.
  ///
  /// In zh_CN, this message translates to:
  /// **'可播放'**
  String get sourcesHealthPlayable;

  /// No description provided for @sourcesHealthArtwork.
  ///
  /// In zh_CN, this message translates to:
  /// **'封面'**
  String get sourcesHealthArtwork;

  /// No description provided for @sourcesHealthMetadata.
  ///
  /// In zh_CN, this message translates to:
  /// **'元数据'**
  String get sourcesHealthMetadata;

  /// No description provided for @sourcesHealthActivity.
  ///
  /// In zh_CN, this message translates to:
  /// **'活跃'**
  String get sourcesHealthActivity;

  /// No description provided for @sourceDirectUrlName.
  ///
  /// In zh_CN, this message translates to:
  /// **'直链音频'**
  String get sourceDirectUrlName;

  /// No description provided for @sourceDirectUrlDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'一行一条地址，每条变成一首曲目'**
  String get sourceDirectUrlDescription;

  /// No description provided for @directUrlFieldUrls.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频地址'**
  String get directUrlFieldUrls;

  /// No description provided for @directUrlFieldUrlsHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'一行一条地址，例如 https://example.com/song.mp3'**
  String get directUrlFieldUrlsHint;

  /// No description provided for @directUrlHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写音频地址，一行一条'**
  String get directUrlHint;

  /// No description provided for @sourceM3uName.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get sourceM3uName;

  /// No description provided for @sourceM3uDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'读一个 .m3u 或 .pls 播放列表，条目变成曲目'**
  String get sourceM3uDescription;

  /// No description provided for @m3uFieldPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表地址'**
  String get m3uFieldPlaylist;

  /// No description provided for @m3uFieldPlaylistHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 https://example.com/list.m3u'**
  String get m3uFieldPlaylistHint;

  /// No description provided for @m3uHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写播放列表地址'**
  String get m3uHint;

  /// No description provided for @m3uEmptyPlaylist.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表是空的'**
  String get m3uEmptyPlaylist;

  /// No description provided for @m3uNoEntries.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表里没有条目'**
  String get m3uNoEntries;

  /// No description provided for @jsonFieldListPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'列表路径'**
  String get jsonFieldListPath;

  /// No description provided for @jsonFieldIdPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'曲目 id 路径'**
  String get jsonFieldIdPath;

  /// No description provided for @jsonFieldTitlePath.
  ///
  /// In zh_CN, this message translates to:
  /// **'标题路径'**
  String get jsonFieldTitlePath;

  /// No description provided for @jsonFieldArtistPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌手路径'**
  String get jsonFieldArtistPath;

  /// No description provided for @jsonFieldAlbumPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑路径'**
  String get jsonFieldAlbumPath;

  /// No description provided for @jsonFieldCoverPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'封面路径'**
  String get jsonFieldCoverPath;

  /// No description provided for @jsonFieldUrlPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放地址路径'**
  String get jsonFieldUrlPath;

  /// No description provided for @jsonFieldDurationPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'时长路径'**
  String get jsonFieldDurationPath;

  /// No description provided for @jsonFieldGenrePath.
  ///
  /// In zh_CN, this message translates to:
  /// **'流派路径'**
  String get jsonFieldGenrePath;

  /// No description provided for @jsonFieldUrlTemplate.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放地址模板'**
  String get jsonFieldUrlTemplate;

  /// No description provided for @jsonFieldPathHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'响应里的路径，逐段用点分开，如 data.title'**
  String get jsonFieldPathHint;

  /// No description provided for @jsonFieldUrlTemplateHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放地址的模板，曲目 id 会填进占位处'**
  String get jsonFieldUrlTemplateHint;

  /// No description provided for @jsonFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索用的关键词，会替换请求里的占位符；留空就按地址原样问一次'**
  String get jsonFieldQueryHint;

  /// No description provided for @jsonFieldUrl.
  ///
  /// In zh_CN, this message translates to:
  /// **'接口地址'**
  String get jsonFieldUrl;

  /// No description provided for @jsonFieldUrlHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 https://example.com/api/search'**
  String get jsonFieldUrlHint;

  /// No description provided for @jsonFieldHeaders.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求头'**
  String get jsonFieldHeaders;

  /// No description provided for @jsonFieldHeadersHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'JSON 对象，一行一个键和值'**
  String get jsonFieldHeadersHint;

  /// No description provided for @jsonInvalidObject.
  ///
  /// In zh_CN, this message translates to:
  /// **'这段文字不是 JSON 对象'**
  String get jsonInvalidObject;

  /// No description provided for @jsonInvalidResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'接口返回的不是 JSON'**
  String get jsonInvalidResponse;

  /// No description provided for @jsonNoTracks.
  ///
  /// In zh_CN, this message translates to:
  /// **'接口没有返回曲目'**
  String get jsonNoTracks;

  /// No description provided for @jsonNoAddressPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有填写播放地址的路径或模板'**
  String get jsonNoAddressPath;

  /// No description provided for @sourceJsonApiName.
  ///
  /// In zh_CN, this message translates to:
  /// **'JSON 接口'**
  String get sourceJsonApiName;

  /// No description provided for @sourceJsonApiDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'把任意 JSON 接口映射成曲目'**
  String get sourceJsonApiDescription;

  /// No description provided for @jsonApiHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写接口地址与各字段的路径'**
  String get jsonApiHint;

  /// No description provided for @jsonApiFieldMethod.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求方式'**
  String get jsonApiFieldMethod;

  /// No description provided for @jsonApiFieldMethodHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'GET 或 POST；只有 POST 带请求体'**
  String get jsonApiFieldMethodHint;

  /// No description provided for @jsonApiFieldBody.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求体'**
  String get jsonApiFieldBody;

  /// No description provided for @jsonApiFieldBodyHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'POST 时的 JSON 对象；关键词会填进占位符'**
  String get jsonApiFieldBodyHint;

  /// No description provided for @sourceGraphqlName.
  ///
  /// In zh_CN, this message translates to:
  /// **'GraphQL 接口'**
  String get sourceGraphqlName;

  /// No description provided for @sourceGraphqlDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'用一份查询文档问接口，筛选条件写在文档里'**
  String get sourceGraphqlDescription;

  /// No description provided for @graphqlHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写接口地址、查询文档与各字段的路径'**
  String get graphqlHint;

  /// No description provided for @graphqlFieldQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'查询文档'**
  String get graphqlFieldQuery;

  /// No description provided for @graphqlFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'GraphQL 查询文档，筛选条件写在里面；模板只是个起点，字段要改成接口里有的'**
  String get graphqlFieldQueryHint;

  /// No description provided for @graphqlFieldVariables.
  ///
  /// In zh_CN, this message translates to:
  /// **'变量'**
  String get graphqlFieldVariables;

  /// No description provided for @graphqlFieldVariablesHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'JSON 对象；关键词会填进占位符'**
  String get graphqlFieldVariablesHint;

  /// No description provided for @jsonPreviewNoTracks.
  ///
  /// In zh_CN, this message translates to:
  /// **'返回里没有认出曲目'**
  String get jsonPreviewNoTracks;

  /// No description provided for @sourcePreviewTry.
  ///
  /// In zh_CN, this message translates to:
  /// **'试一下'**
  String get sourcePreviewTry;

  /// No description provided for @sourcePreviewRunning.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在试…'**
  String get sourcePreviewRunning;

  /// No description provided for @sourcePreviewTracks.
  ///
  /// In zh_CN, this message translates to:
  /// **'认出 {count} 首'**
  String sourcePreviewTracks(int count);

  /// No description provided for @sourceFormShowAdvanced.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多选项'**
  String get sourceFormShowAdvanced;

  /// No description provided for @sourceFormHideAdvanced.
  ///
  /// In zh_CN, this message translates to:
  /// **'收起选项'**
  String get sourceFormHideAdvanced;

  /// No description provided for @sourcesAutoScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'启动时自动扫描'**
  String get sourcesAutoScan;

  /// No description provided for @sourcesAutoScanDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'所有已启用音源都会在启动后自动刷新，失败不会影响本地库。'**
  String get sourcesAutoScanDescription;

  /// No description provided for @sourcesScanMayTakeSeconds.
  ///
  /// In zh_CN, this message translates to:
  /// **'含远程音源时可能需要数秒'**
  String get sourcesScanMayTakeSeconds;

  /// No description provided for @sourcesScanCompleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描已完成'**
  String get sourcesScanCompleted;

  /// No description provided for @sourcesConfigure.
  ///
  /// In zh_CN, this message translates to:
  /// **'配置'**
  String get sourcesConfigure;

  /// No description provided for @sourcesUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前版本不支持该音源'**
  String get sourcesUnsupported;

  /// No description provided for @sourcesDisabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭'**
  String get sourcesDisabled;

  /// No description provided for @sourcesNeedsConfiguration.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要配置'**
  String get sourcesNeedsConfiguration;

  /// No description provided for @sourcesNeedsConfigurationHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'需要配置：{hint}'**
  String sourcesNeedsConfigurationHint(String hint);

  /// No description provided for @sourcesLastScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次扫描 {time}'**
  String sourcesLastScan(String time);

  /// No description provided for @sourcesAutoScanLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'启动后自动扫描本地目录'**
  String get sourcesAutoScanLocal;

  /// No description provided for @sourcesWaitingFirstScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'等待首次扫描'**
  String get sourcesWaitingFirstScan;

  /// No description provided for @sourcesScannedCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已扫描 {count} 首 · {time}'**
  String sourcesScannedCount(int count, String time);

  /// No description provided for @sourcesSkipped.
  ///
  /// In zh_CN, this message translates to:
  /// **'已跳过'**
  String get sourcesSkipped;

  /// No description provided for @sourcesScanFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描失败'**
  String get sourcesScanFailed;

  /// No description provided for @sourcesDeleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'已删除 {name}'**
  String sourcesDeleted(String name);

  /// No description provided for @sourceKindLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地'**
  String get sourceKindLocal;

  /// No description provided for @sourceKindOpenCatalog.
  ///
  /// In zh_CN, this message translates to:
  /// **'开放曲库'**
  String get sourceKindOpenCatalog;

  /// No description provided for @sourceKindOpenApi.
  ///
  /// In zh_CN, this message translates to:
  /// **'API'**
  String get sourceKindOpenApi;

  /// No description provided for @sourceKindCustom.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义'**
  String get sourceKindCustom;

  /// No description provided for @sourcesConfigureTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'配置 {name}'**
  String sourcesConfigureTitle(String name);

  /// No description provided for @sourcesFieldRequired.
  ///
  /// In zh_CN, this message translates to:
  /// **'请填写{label}'**
  String sourcesFieldRequired(String label);

  /// No description provided for @sourcesFieldNumeric.
  ///
  /// In zh_CN, this message translates to:
  /// **'请输入数字'**
  String get sourcesFieldNumeric;

  /// No description provided for @fieldQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索关键词'**
  String get fieldQuery;

  /// No description provided for @fieldQueryOptional.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索关键词（可选）'**
  String get fieldQueryOptional;

  /// No description provided for @fieldBrowse.
  ///
  /// In zh_CN, this message translates to:
  /// **'浏览流'**
  String get fieldBrowse;

  /// No description provided for @fieldBrowseHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'不填关键词时拉取的内容；填了关键词就按关键词搜'**
  String get fieldBrowseHint;

  /// No description provided for @browseModeLatest.
  ///
  /// In zh_CN, this message translates to:
  /// **'最新'**
  String get browseModeLatest;

  /// No description provided for @browseModeCharts.
  ///
  /// In zh_CN, this message translates to:
  /// **'排行'**
  String get browseModeCharts;

  /// No description provided for @browseModeDaily.
  ///
  /// In zh_CN, this message translates to:
  /// **'每日推荐'**
  String get browseModeDaily;

  /// No description provided for @fieldLimit.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描数量'**
  String get fieldLimit;

  /// No description provided for @fieldLimitFiles.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描文件数'**
  String get fieldLimitFiles;

  /// No description provided for @fieldLimitEpisodes.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描集数'**
  String get fieldLimitEpisodes;

  /// No description provided for @fieldLimitPodcasts.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描播客数'**
  String get fieldLimitPodcasts;

  /// No description provided for @fieldLimitStations.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描电台数'**
  String get fieldLimitStations;

  /// No description provided for @fieldLimitHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认 {count}，最大 {max}'**
  String fieldLimitHint(int count, int max);

  /// No description provided for @fieldLimitBooks.
  ///
  /// In zh_CN, this message translates to:
  /// **'每次扫描书数'**
  String get fieldLimitBooks;

  /// No description provided for @fieldLanguage.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get fieldLanguage;

  /// No description provided for @fieldLanguageHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'只保留一种语言的有声书'**
  String get fieldLanguageHint;

  /// No description provided for @fieldLanguageAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'不限制语言'**
  String get fieldLanguageAll;

  /// No description provided for @fieldLanguageEnglish.
  ///
  /// In zh_CN, this message translates to:
  /// **'英语'**
  String get fieldLanguageEnglish;

  /// No description provided for @fieldLanguageChinese.
  ///
  /// In zh_CN, this message translates to:
  /// **'中文'**
  String get fieldLanguageChinese;

  /// No description provided for @fieldLanguageFrench.
  ///
  /// In zh_CN, this message translates to:
  /// **'法语'**
  String get fieldLanguageFrench;

  /// No description provided for @fieldLanguageGerman.
  ///
  /// In zh_CN, this message translates to:
  /// **'德语'**
  String get fieldLanguageGerman;

  /// No description provided for @fieldLanguageSpanish.
  ///
  /// In zh_CN, this message translates to:
  /// **'西班牙语'**
  String get fieldLanguageSpanish;

  /// No description provided for @fieldLanguageItalian.
  ///
  /// In zh_CN, this message translates to:
  /// **'意大利语'**
  String get fieldLanguageItalian;

  /// No description provided for @fieldLanguageJapanese.
  ///
  /// In zh_CN, this message translates to:
  /// **'日语'**
  String get fieldLanguageJapanese;

  /// No description provided for @fieldLanguageRussian.
  ///
  /// In zh_CN, this message translates to:
  /// **'俄语'**
  String get fieldLanguageRussian;

  /// No description provided for @fieldLanguagePortuguese.
  ///
  /// In zh_CN, this message translates to:
  /// **'葡萄牙语'**
  String get fieldLanguagePortuguese;

  /// No description provided for @fieldServer.
  ///
  /// In zh_CN, this message translates to:
  /// **'服务器地址'**
  String get fieldServer;

  /// No description provided for @fieldUser.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户名'**
  String get fieldUser;

  /// No description provided for @fieldPassword.
  ///
  /// In zh_CN, this message translates to:
  /// **'密码'**
  String get fieldPassword;

  /// No description provided for @fieldFormat.
  ///
  /// In zh_CN, this message translates to:
  /// **'音质'**
  String get fieldFormat;

  /// No description provided for @sourcesNotLoaded.
  ///
  /// In zh_CN, this message translates to:
  /// **'音源列表尚未加载完成'**
  String get sourcesNotLoaded;

  /// No description provided for @playerLyrics.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词'**
  String get playerLyrics;

  /// No description provided for @lyricsLoading.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在加载歌词'**
  String get lyricsLoading;

  /// No description provided for @lyricsFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词加载失败'**
  String get lyricsFailed;

  /// No description provided for @lyricsMissing.
  ///
  /// In zh_CN, this message translates to:
  /// **'这首歌没有歌词'**
  String get lyricsMissing;

  /// No description provided for @lyricsNothingPlaying.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有正在播放的曲目'**
  String get lyricsNothingPlaying;

  /// No description provided for @lyricsInvalidFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个文件里没有歌词'**
  String get lyricsInvalidFile;

  /// No description provided for @lyricsRetry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get lyricsRetry;

  /// No description provided for @lyricsSearchAgain.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新查找'**
  String get lyricsSearchAgain;

  /// No description provided for @lyricsChooseFile.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择歌词文件'**
  String get lyricsChooseFile;

  /// No description provided for @lyricsAttached.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词已关联'**
  String get lyricsAttached;

  /// No description provided for @lyricsSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放的那首歌的词'**
  String get lyricsSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'调整外观、语言、音乐库与音源健康度。'**
  String get settingsSubtitle;

  /// No description provided for @settingsThemeDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择界面的明暗气质和显示语言。'**
  String get settingsThemeDescription;

  /// No description provided for @settingsLanguageDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'界面文字和系统菜单语言'**
  String get settingsLanguageDescription;

  /// No description provided for @settingsLibraryDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune 只会在这些目录中查找音频文件。'**
  String get settingsLibraryDescription;

  /// No description provided for @settingsDefaultPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认'**
  String get settingsDefaultPath;

  /// No description provided for @settingsNoDefaultFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到默认音乐目录'**
  String get settingsNoDefaultFolder;

  /// No description provided for @settingsCustomPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义'**
  String get settingsCustomPath;

  /// No description provided for @settingsAddFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加文件夹'**
  String get settingsAddFolder;

  /// No description provided for @settingsClearLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空音乐库'**
  String get settingsClearLibrary;

  /// No description provided for @settingsScanSafetyNote.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描只读取音频文件，不会修改或删除磁盘内容。'**
  String get settingsScanSafetyNote;

  /// No description provided for @settingsChooseFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择音乐文件夹'**
  String get settingsChooseFolder;

  /// No description provided for @settingsFolderAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已添加扫描目录'**
  String get settingsFolderAdded;

  /// No description provided for @settingsLibraryFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件存放位置'**
  String get settingsLibraryFolder;

  /// No description provided for @settingsChangeLibraryFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'更换位置'**
  String get settingsChangeLibraryFolder;

  /// No description provided for @settingsUseDefaultLibraryFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'用默认位置'**
  String get settingsUseDefaultLibraryFolder;

  /// No description provided for @settingsNoLibraryFolder.
  ///
  /// In zh_CN, this message translates to:
  /// **'这个平台没有音乐目录'**
  String get settingsNoLibraryFolder;

  /// No description provided for @settingsScanDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描完成'**
  String get settingsScanDone;

  /// No description provided for @settingsClearLibraryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空音乐库？'**
  String get settingsClearLibraryTitle;

  /// No description provided for @settingsClearLibraryMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'只会清除 Tune 的扫描记录，不会删除磁盘上的音乐文件。'**
  String get settingsClearLibraryMessage;

  /// No description provided for @settingsLibraryCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库已清空'**
  String get settingsLibraryCleared;

  /// No description provided for @settingsPathsCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 个目录'**
  String settingsPathsCount(int count);

  /// No description provided for @searchOnlineTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线搜索'**
  String get searchOnlineTitle;

  /// No description provided for @searchOnlineHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索在线音源，例如 jazz、钢琴、lo-fi'**
  String get searchOnlineHint;

  /// No description provided for @searchOnlineDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索已启用的在线音源；结果不会写入音乐库'**
  String get searchOnlineDescription;

  /// No description provided for @searchOnlinePrompt.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索在线音源'**
  String get searchOnlinePrompt;

  /// No description provided for @searchOnlinePromptDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入关键词后按回车；所有已启用的在线音源会并行搜索。'**
  String get searchOnlinePromptDescription;

  /// No description provided for @searchNoResults.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有结果'**
  String get searchNoResults;

  /// No description provided for @searchNoResultsDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'换个关键词再试一次。'**
  String get searchNoResultsDescription;

  /// No description provided for @searchNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的歌曲'**
  String get searchNoMatch;

  /// No description provided for @searchSearching.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在搜索「{query}」'**
  String searchSearching(String query);

  /// No description provided for @searchPlayAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放全部'**
  String get searchPlayAll;

  /// No description provided for @searchAddToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'加入队列'**
  String get searchAddToQueue;

  /// No description provided for @searchAddedToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入队列：{title}'**
  String searchAddedToQueue(String title);

  /// No description provided for @searchNoSourcesEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有启用在线音源，请先在设置中开启'**
  String get searchNoSourcesEnabled;

  /// No description provided for @searchFailedShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索失败'**
  String get searchFailedShort;

  /// No description provided for @searchFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线搜索失败：{error}'**
  String searchFailed(String error);

  /// No description provided for @scanPreparing.
  ///
  /// In zh_CN, this message translates to:
  /// **'准备扫描...'**
  String get scanPreparing;

  /// No description provided for @scanNoEnabledSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有启用的音源'**
  String get scanNoEnabledSources;

  /// No description provided for @scanNoLocalFolders.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有可扫描的音乐目录'**
  String get scanNoLocalFolders;

  /// No description provided for @scanProgressPercent.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描中 {percent}%'**
  String scanProgressPercent(int percent);

  /// No description provided for @scanAllSourcesFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'所有音源扫描失败'**
  String get scanAllSourcesFailed;

  /// No description provided for @scanFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描失败：{error}'**
  String scanFailed(String error);

  /// No description provided for @clearLibraryFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'清空音乐库失败：{error}'**
  String clearLibraryFailed(String error);

  /// No description provided for @scanNoAudioFiles.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到音频文件'**
  String get scanNoAudioFiles;

  /// No description provided for @scanSongCount.
  ///
  /// In zh_CN, this message translates to:
  /// **'已扫描 {count} 首歌曲'**
  String scanSongCount(int count);

  /// No description provided for @scanSongCountShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 首歌曲'**
  String scanSongCountShort(int count);

  /// No description provided for @scanSourceNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'音源尚未配置'**
  String get scanSourceNotConfigured;

  /// No description provided for @scanCachedTooSoon.
  ///
  /// In zh_CN, this message translates to:
  /// **'已保留缓存，距上次扫描不足间隔'**
  String get scanCachedTooSoon;

  /// No description provided for @scanSummary.
  ///
  /// In zh_CN, this message translates to:
  /// **'已扫描 {sources} 个音源，共 {songs} 首歌曲'**
  String scanSummary(int songs, int sources);

  /// No description provided for @scanUpdated.
  ///
  /// In zh_CN, this message translates to:
  /// **'已更新 {songs} 首歌曲，{failed} 个音源失败'**
  String scanUpdated(int failed, int songs);

  /// No description provided for @sourceErrorForbidden.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问被拒绝（HTTP {status}）'**
  String sourceErrorForbidden(int status);

  /// No description provided for @sourceErrorRateLimited.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求过于频繁（HTTP 429），请稍后再试'**
  String get sourceErrorRateLimited;

  /// No description provided for @sourceErrorHttpStatus.
  ///
  /// In zh_CN, this message translates to:
  /// **'接口返回 HTTP {status}'**
  String sourceErrorHttpStatus(int status);

  /// No description provided for @sourceErrorTimeout.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络连接超时'**
  String get sourceErrorTimeout;

  /// No description provided for @sourceErrorConnection.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法连接音源服务'**
  String get sourceErrorConnection;

  /// No description provided for @sourceErrorCertificate.
  ///
  /// In zh_CN, this message translates to:
  /// **'证书校验失败'**
  String get sourceErrorCertificate;

  /// No description provided for @sourceErrorCancelled.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求已取消'**
  String get sourceErrorCancelled;

  /// No description provided for @sourceErrorNetwork.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络请求失败：{message}'**
  String sourceErrorNetwork(String message);

  /// No description provided for @sourceErrorUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂不支持该音源'**
  String get sourceErrorUnsupported;

  /// No description provided for @sourceAddressNotHttp.
  ///
  /// In zh_CN, this message translates to:
  /// **'只支持 http(s) 地址'**
  String get sourceAddressNotHttp;

  /// No description provided for @sourceErrorScanInterval.
  ///
  /// In zh_CN, this message translates to:
  /// **'距上次扫描不足 {interval}'**
  String sourceErrorScanInterval(String interval);

  /// No description provided for @sourceErrorScanTimeout.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描超时（{seconds}s）'**
  String sourceErrorScanTimeout(int seconds);

  /// No description provided for @intervalHours.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 小时'**
  String intervalHours(int count);

  /// No description provided for @intervalMinutes.
  ///
  /// In zh_CN, this message translates to:
  /// **'{count} 分钟'**
  String intervalMinutes(int count);

  /// No description provided for @localSourceHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'在音乐库设置中添加扫描目录'**
  String get localSourceHint;

  /// No description provided for @localSourceNotConfigured.
  ///
  /// In zh_CN, this message translates to:
  /// **'未配置本地音乐目录'**
  String get localSourceNotConfigured;

  /// No description provided for @openverseHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写搜索关键词，例如 piano、ambient 或 jazz'**
  String get openverseHint;

  /// No description provided for @openverseFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 piano、ambient、jazz'**
  String get openverseFieldQueryHint;

  /// No description provided for @openverseEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Openverse 返回了空响应'**
  String get openverseEmptyResponse;

  /// No description provided for @openverseNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的开放音频'**
  String get openverseNoMatch;

  /// No description provided for @sourceLocalName.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地音乐'**
  String get sourceLocalName;

  /// No description provided for @sourceLocalDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描设备上的音乐文件夹'**
  String get sourceLocalDescription;

  /// No description provided for @sourceOpenverseDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'开放版权音频聚合：Jamendo、Freesound、Wikimedia 等'**
  String get sourceOpenverseDescription;

  /// No description provided for @sourceOpenverseName.
  ///
  /// In zh_CN, this message translates to:
  /// **'开放版权聚合'**
  String get sourceOpenverseName;

  /// No description provided for @sourceJamendoDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'独立音乐开放曲库，需要免费 Client ID'**
  String get sourceJamendoDescription;

  /// No description provided for @sourceJamendoName.
  ///
  /// In zh_CN, this message translates to:
  /// **'独立音乐曲库'**
  String get sourceJamendoName;

  /// No description provided for @sourceInternetArchiveDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Internet Archive 的开放音频收藏'**
  String get sourceInternetArchiveDescription;

  /// No description provided for @sourceInternetArchiveName.
  ///
  /// In zh_CN, this message translates to:
  /// **'公共领域音频'**
  String get sourceInternetArchiveName;

  /// No description provided for @jamendoHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'在 developer.jamendo.com 免费申请 Client ID 后填入'**
  String get jamendoHint;

  /// No description provided for @jamendoFieldClientId.
  ///
  /// In zh_CN, this message translates to:
  /// **'Client ID'**
  String get jamendoFieldClientId;

  /// No description provided for @jamendoFieldClientIdHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'在 developer.jamendo.com 免费申请'**
  String get jamendoFieldClientIdHint;

  /// No description provided for @jamendoFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 jazz、electronic'**
  String get jamendoFieldQueryHint;

  /// No description provided for @jamendoEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Jamendo 返回了空响应'**
  String get jamendoEmptyResponse;

  /// No description provided for @jamendoNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的 Jamendo 曲目'**
  String get jamendoNoMatch;

  /// No description provided for @internetArchiveHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写 Internet Archive 收录条件，例如 collection:netlabels AND mediatype:audio'**
  String get internetArchiveHint;

  /// No description provided for @internetArchiveFieldQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'收录条件'**
  String get internetArchiveFieldQuery;

  /// No description provided for @internetArchiveInvalidResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Internet Archive 返回了无法识别的响应'**
  String get internetArchiveInvalidResponse;

  /// No description provided for @internetArchiveNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到可播放的归档音频'**
  String get internetArchiveNoMatch;

  /// No description provided for @downloadUnsupportedPlatform.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前平台没有文件系统，无法缓存下载'**
  String get downloadUnsupportedPlatform;

  /// No description provided for @audioLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频加载失败'**
  String get audioLoadFailed;

  /// No description provided for @audioPathEmpty.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频文件路径为空'**
  String get audioPathEmpty;

  /// No description provided for @ccmixterEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'ccMixter 返回了空响应'**
  String get ccmixterEmptyResponse;

  /// No description provided for @ccmixterFieldQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索标签'**
  String get ccmixterFieldQuery;

  /// No description provided for @ccmixterFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 jazz、ambient、electro'**
  String get ccmixterFieldQueryHint;

  /// No description provided for @ccmixterHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写 ccMixter 标签，例如 jazz、ambient 或 electro'**
  String get ccmixterHint;

  /// No description provided for @ccmixterNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的 ccMixter 曲目'**
  String get ccmixterNoMatch;

  /// No description provided for @podcastRssEmptyFeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'订阅地址返回了空内容'**
  String get podcastRssEmptyFeed;

  /// No description provided for @podcastRssFieldFeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'订阅地址'**
  String get podcastRssFieldFeed;

  /// No description provided for @podcastRssFieldFeedHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 https://example.com/podcast.xml'**
  String get podcastRssFieldFeedHint;

  /// No description provided for @podcastRssHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写播客订阅地址（RSS）'**
  String get podcastRssHint;

  /// No description provided for @podcastRssInvalidFeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'订阅地址返回了无法解析的 XML：{error}'**
  String podcastRssInvalidFeed(String error);

  /// No description provided for @podcastRssNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'订阅源里没有可播放的单集'**
  String get podcastRssNoMatch;

  /// No description provided for @sourceCcmixterDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Creative Commons 混音与开放音乐曲库'**
  String get sourceCcmixterDescription;

  /// No description provided for @sourceCcmixterName.
  ///
  /// In zh_CN, this message translates to:
  /// **'共享混音素材'**
  String get sourceCcmixterName;

  /// No description provided for @sourceLiveMusicArchiveDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Internet Archive 收藏的现场录音'**
  String get sourceLiveMusicArchiveDescription;

  /// No description provided for @sourceLiveMusicArchiveName.
  ///
  /// In zh_CN, this message translates to:
  /// **'现场音乐档案'**
  String get sourceLiveMusicArchiveName;

  /// No description provided for @sourcePodcastRssDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'把任意 RSS 播客订阅变成可播放的单集'**
  String get sourcePodcastRssDescription;

  /// No description provided for @sourcePodcastRssName.
  ///
  /// In zh_CN, this message translates to:
  /// **'播客订阅'**
  String get sourcePodcastRssName;

  /// No description provided for @sourcePodcastCatalogName.
  ///
  /// In zh_CN, this message translates to:
  /// **'播客目录'**
  String get sourcePodcastCatalogName;

  /// No description provided for @sourcePodcastCatalogDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索 gpodder 开放播客目录，取最新单集'**
  String get sourcePodcastCatalogDescription;

  /// No description provided for @podcastCatalogHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入关键词找播客，留空则浏览目录'**
  String get podcastCatalogHint;

  /// No description provided for @podcastCatalogFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如爵士、历史、科技'**
  String get podcastCatalogFieldQueryHint;

  /// No description provided for @podcastCatalogNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到播客'**
  String get podcastCatalogNoMatch;

  /// No description provided for @sourceSubsonicDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接自建的 Navidrome / Subsonic 音乐库'**
  String get sourceSubsonicDescription;

  /// No description provided for @sourceSubsonicName.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建音乐库'**
  String get sourceSubsonicName;

  /// No description provided for @subsonicAuthFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法连接音乐服务器，请检查地址与账号'**
  String get subsonicAuthFailed;

  /// No description provided for @subsonicEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐服务器返回了空响应'**
  String get subsonicEmptyResponse;

  /// No description provided for @subsonicError.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐服务器返回错误：{error}'**
  String subsonicError(String error);

  /// No description provided for @subsonicFieldPasswordHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'用于计算访问令牌，不会明文发送'**
  String get subsonicFieldPasswordHint;

  /// No description provided for @subsonicFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 jazz、piano'**
  String get subsonicFieldQueryHint;

  /// No description provided for @subsonicFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 http://localhost:4533'**
  String get subsonicFieldServerHint;

  /// No description provided for @subsonicFieldUserHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建音乐库的登录用户名'**
  String get subsonicFieldUserHint;

  /// No description provided for @subsonicHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写自建音乐库的地址与账号，例如 http://localhost:4533'**
  String get subsonicHint;

  /// No description provided for @subsonicNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的曲目'**
  String get subsonicNoMatch;

  /// No description provided for @sourceAudiusDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Audius 上音乐人直发的完整曲目'**
  String get sourceAudiusDescription;

  /// No description provided for @sourceAudiusName.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐人直发'**
  String get sourceAudiusName;

  /// No description provided for @audiusHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写搜索关键词，例如 jazz、ambient 或 electronic'**
  String get audiusHint;

  /// No description provided for @audiusFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 jazz、ambient、electronic'**
  String get audiusFieldQueryHint;

  /// No description provided for @audiusEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Audius 返回了空响应'**
  String get audiusEmptyResponse;

  /// No description provided for @audiusNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的 Audius 曲目'**
  String get audiusNoMatch;

  /// No description provided for @sourceRadioDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'公开网络电台的直播流'**
  String get sourceRadioDescription;

  /// No description provided for @radioHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择电台目录，关键词可进一步过滤'**
  String get radioHint;

  /// No description provided for @radioFieldProvider.
  ///
  /// In zh_CN, this message translates to:
  /// **'电台目录'**
  String get radioFieldProvider;

  /// No description provided for @radioFieldProviderHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部目录、Radio Browser、SomaFM 或 Radio Paradise'**
  String get radioFieldProviderHint;

  /// No description provided for @radioProviderAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部目录'**
  String get radioProviderAll;

  /// No description provided for @radioFieldCountry.
  ///
  /// In zh_CN, this message translates to:
  /// **'国家/地区'**
  String get radioFieldCountry;

  /// No description provided for @radioFieldCountryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'两位国家代码，例如 SG、MY、AU、JP；目录里有的国家都可以填'**
  String get radioFieldCountryHint;

  /// No description provided for @radioFieldQuery.
  ///
  /// In zh_CN, this message translates to:
  /// **'电台关键词'**
  String get radioFieldQuery;

  /// No description provided for @radioFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 jazz、ambient 或 SomaFM'**
  String get radioFieldQueryHint;

  /// No description provided for @radioNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到匹配的电台'**
  String get radioNoMatch;

  /// No description provided for @sourceWikimediaDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'Wikimedia Commons 的开放音频'**
  String get sourceWikimediaDescription;

  /// No description provided for @sourceWikimediaName.
  ///
  /// In zh_CN, this message translates to:
  /// **'自由授权媒体'**
  String get sourceWikimediaName;

  /// No description provided for @wikimediaHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写搜索关键词，例如 piano、lecture 或 birdsong'**
  String get wikimediaHint;

  /// No description provided for @wikimediaFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 piano、lecture、birdsong'**
  String get wikimediaFieldQueryHint;

  /// No description provided for @wikimediaEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Wikimedia Commons 返回了空响应'**
  String get wikimediaEmptyResponse;

  /// No description provided for @wikimediaNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到可播放的共享音频'**
  String get wikimediaNoMatch;

  /// No description provided for @sourceFunkwhaleName.
  ///
  /// In zh_CN, this message translates to:
  /// **'联邦音乐'**
  String get sourceFunkwhaleName;

  /// No description provided for @sourceFunkwhaleDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'联邦 Funkwhale 实例里的音乐'**
  String get sourceFunkwhaleDescription;

  /// No description provided for @funkwhaleHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写 Funkwhale 实例地址；只有私密库需要令牌'**
  String get funkwhaleHint;

  /// No description provided for @funkwhaleFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 https://open.audio'**
  String get funkwhaleFieldServerHint;

  /// No description provided for @funkwhaleFieldToken.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问令牌'**
  String get funkwhaleFieldToken;

  /// No description provided for @funkwhaleFieldTokenHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'实例的库私密时才需要'**
  String get funkwhaleFieldTokenHint;

  /// No description provided for @funkwhaleFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如爵士、民谣、电子'**
  String get funkwhaleFieldQueryHint;

  /// No description provided for @funkwhaleEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Funkwhale 返回了空响应'**
  String get funkwhaleEmptyResponse;

  /// No description provided for @funkwhaleNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'Funkwhale 上没有匹配的曲目'**
  String get funkwhaleNoMatch;

  /// No description provided for @sourceAudiobookshelfName.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建有声书'**
  String get sourceAudiobookshelfName;

  /// No description provided for @sourceAudiobookshelfDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建 Audiobookshelf 服务器里的有声书'**
  String get sourceAudiobookshelfDescription;

  /// No description provided for @audiobookshelfHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写 Audiobookshelf 服务器的地址与令牌'**
  String get audiobookshelfHint;

  /// No description provided for @audiobookshelfFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 http://localhost:13378'**
  String get audiobookshelfFieldServerHint;

  /// No description provided for @audiobookshelfFieldToken.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问令牌'**
  String get audiobookshelfFieldToken;

  /// No description provided for @audiobookshelfFieldTokenHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'Audiobookshelf 账号的 API 令牌'**
  String get audiobookshelfFieldTokenHint;

  /// No description provided for @audiobookshelfFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如历史、小说、科学'**
  String get audiobookshelfFieldQueryHint;

  /// No description provided for @audiobookshelfEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Audiobookshelf 返回了空响应'**
  String get audiobookshelfEmptyResponse;

  /// No description provided for @audiobookshelfNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到有声书'**
  String get audiobookshelfNoMatch;

  /// No description provided for @sourcePlexName.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建媒体库'**
  String get sourcePlexName;

  /// No description provided for @sourcePlexDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接自建的 Plex 媒体库'**
  String get sourcePlexDescription;

  /// No description provided for @plexHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写 Plex 服务器的地址与访问令牌'**
  String get plexHint;

  /// No description provided for @plexFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 http://localhost:32400'**
  String get plexFieldServerHint;

  /// No description provided for @plexFieldToken.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问令牌'**
  String get plexFieldToken;

  /// No description provided for @plexFieldTokenHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'Plex 账号的 X-Plex-Token'**
  String get plexFieldTokenHint;

  /// No description provided for @plexNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'Plex 上没有匹配的曲目'**
  String get plexNoMatch;

  /// No description provided for @plexInvalidAnswer.
  ///
  /// In zh_CN, this message translates to:
  /// **'读不出 Plex 的回答：{error}'**
  String plexInvalidAnswer(String error);

  /// No description provided for @sourceJellyfinDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接自建的 Jellyfin 媒体库'**
  String get sourceJellyfinDescription;

  /// No description provided for @sourceJellyfinName.
  ///
  /// In zh_CN, this message translates to:
  /// **'自建媒体库'**
  String get sourceJellyfinName;

  /// No description provided for @jellyfinHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写自建 Jellyfin 的地址与账号'**
  String get jellyfinHint;

  /// No description provided for @jellyfinFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 http://localhost:8096'**
  String get jellyfinFieldServerHint;

  /// No description provided for @jellyfinFieldUserHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'Jellyfin 的登录用户名'**
  String get jellyfinFieldUserHint;

  /// No description provided for @jellyfinFieldPasswordHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'用于换取访问令牌'**
  String get jellyfinFieldPasswordHint;

  /// No description provided for @jellyfinEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Jellyfin 返回了空响应'**
  String get jellyfinEmptyResponse;

  /// No description provided for @jellyfinAuthFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法连接 Jellyfin 服务器，请检查地址与账号'**
  String get jellyfinAuthFailed;

  /// No description provided for @sourceLibrivoxName.
  ///
  /// In zh_CN, this message translates to:
  /// **'有声书'**
  String get sourceLibrivoxName;

  /// No description provided for @sourceLibrivoxDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'LibriVox 志愿者朗读的公版有声书'**
  String get sourceLibrivoxDescription;

  /// No description provided for @librivoxHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入书名或作者，留空则浏览最热门的有声书'**
  String get librivoxHint;

  /// No description provided for @librivoxFieldQueryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如爱丽丝梦游仙境、狄更斯、童话'**
  String get librivoxFieldQueryHint;

  /// No description provided for @librivoxNoMatch.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有匹配的有声书'**
  String get librivoxNoMatch;

  /// No description provided for @librivoxEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'LibriVox 返回了空响应'**
  String get librivoxEmptyResponse;

  /// No description provided for @librivoxInvalidFeed.
  ///
  /// In zh_CN, this message translates to:
  /// **'读不出一本书的章节列表：{error}'**
  String librivoxInvalidFeed(String error);

  /// No description provided for @sourceEmbyName.
  ///
  /// In zh_CN, this message translates to:
  /// **'Emby 媒体库'**
  String get sourceEmbyName;

  /// No description provided for @sourceEmbyDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接自建的 Emby 媒体库'**
  String get sourceEmbyDescription;

  /// No description provided for @embyHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'填写自建 Emby 的地址与账号'**
  String get embyHint;

  /// No description provided for @embyFieldServerHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'例如 http://localhost:8095'**
  String get embyFieldServerHint;

  /// No description provided for @embyFieldUserHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'Emby 的登录用户名'**
  String get embyFieldUserHint;

  /// No description provided for @embyFieldPasswordHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'用于换取访问令牌'**
  String get embyFieldPasswordHint;

  /// No description provided for @embyEmptyResponse.
  ///
  /// In zh_CN, this message translates to:
  /// **'Emby 返回了空响应'**
  String get embyEmptyResponse;

  /// No description provided for @embyAuthFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法连接 Emby 服务器，请检查地址与账号'**
  String get embyAuthFailed;

  /// No description provided for @audioSourceStreaming.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络'**
  String get audioSourceStreaming;

  /// No description provided for @playerLiveBadge.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播中'**
  String get playerLiveBadge;

  /// No description provided for @nowPlayingLiveStream.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播流，没有固定时长'**
  String get nowPlayingLiveStream;

  /// No description provided for @nowPlayingDetails.
  ///
  /// In zh_CN, this message translates to:
  /// **'曲目信息'**
  String get nowPlayingDetails;

  /// No description provided for @nowPlayingDetailAlbum.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑'**
  String get nowPlayingDetailAlbum;

  /// No description provided for @nowPlayingDetailYear.
  ///
  /// In zh_CN, this message translates to:
  /// **'年份'**
  String get nowPlayingDetailYear;

  /// No description provided for @nowPlayingDetailGenre.
  ///
  /// In zh_CN, this message translates to:
  /// **'流派'**
  String get nowPlayingDetailGenre;

  /// No description provided for @nowPlayingDetailBitrate.
  ///
  /// In zh_CN, this message translates to:
  /// **'码率'**
  String get nowPlayingDetailBitrate;

  /// No description provided for @nowPlayingDetailSampleRate.
  ///
  /// In zh_CN, this message translates to:
  /// **'采样率'**
  String get nowPlayingDetailSampleRate;

  /// No description provided for @nowPlayingDetailTrack.
  ///
  /// In zh_CN, this message translates to:
  /// **'音轨'**
  String get nowPlayingDetailTrack;

  /// No description provided for @nowPlayingDetailDisc.
  ///
  /// In zh_CN, this message translates to:
  /// **'碟片'**
  String get nowPlayingDetailDisc;

  /// No description provided for @nowPlayingDetailLicense.
  ///
  /// In zh_CN, this message translates to:
  /// **'许可'**
  String get nowPlayingDetailLicense;

  /// No description provided for @nowPlayingDetailSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'来源'**
  String get nowPlayingDetailSource;

  /// No description provided for @nowPlayingDetailNowPlaying.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放'**
  String get nowPlayingDetailNowPlaying;

  /// No description provided for @genreRock.
  ///
  /// In zh_CN, this message translates to:
  /// **'摇滚'**
  String get genreRock;

  /// No description provided for @genrePop.
  ///
  /// In zh_CN, this message translates to:
  /// **'流行'**
  String get genrePop;

  /// No description provided for @genreJazz.
  ///
  /// In zh_CN, this message translates to:
  /// **'爵士'**
  String get genreJazz;

  /// No description provided for @genreClassical.
  ///
  /// In zh_CN, this message translates to:
  /// **'古典'**
  String get genreClassical;

  /// No description provided for @genreElectronic.
  ///
  /// In zh_CN, this message translates to:
  /// **'电子'**
  String get genreElectronic;

  /// No description provided for @genreHipHop.
  ///
  /// In zh_CN, this message translates to:
  /// **'说唱'**
  String get genreHipHop;

  /// No description provided for @genreBlues.
  ///
  /// In zh_CN, this message translates to:
  /// **'蓝调'**
  String get genreBlues;

  /// No description provided for @genreCountry.
  ///
  /// In zh_CN, this message translates to:
  /// **'乡村'**
  String get genreCountry;

  /// No description provided for @genreFolk.
  ///
  /// In zh_CN, this message translates to:
  /// **'民谣'**
  String get genreFolk;

  /// No description provided for @genreMetal.
  ///
  /// In zh_CN, this message translates to:
  /// **'金属'**
  String get genreMetal;

  /// No description provided for @genrePunk.
  ///
  /// In zh_CN, this message translates to:
  /// **'朋克'**
  String get genrePunk;

  /// No description provided for @genreReggae.
  ///
  /// In zh_CN, this message translates to:
  /// **'雷鬼'**
  String get genreReggae;

  /// No description provided for @genreLatin.
  ///
  /// In zh_CN, this message translates to:
  /// **'拉丁'**
  String get genreLatin;

  /// No description provided for @genreDance.
  ///
  /// In zh_CN, this message translates to:
  /// **'舞曲'**
  String get genreDance;

  /// No description provided for @genreAlternative.
  ///
  /// In zh_CN, this message translates to:
  /// **'另类'**
  String get genreAlternative;

  /// No description provided for @genreIndie.
  ///
  /// In zh_CN, this message translates to:
  /// **'独立'**
  String get genreIndie;

  /// No description provided for @genreAmbient.
  ///
  /// In zh_CN, this message translates to:
  /// **'环境音乐'**
  String get genreAmbient;

  /// No description provided for @genreHouse.
  ///
  /// In zh_CN, this message translates to:
  /// **'浩室'**
  String get genreHouse;

  /// No description provided for @genreFunk.
  ///
  /// In zh_CN, this message translates to:
  /// **'放克'**
  String get genreFunk;

  /// No description provided for @genreGospel.
  ///
  /// In zh_CN, this message translates to:
  /// **'福音'**
  String get genreGospel;

  /// No description provided for @genreWorld.
  ///
  /// In zh_CN, this message translates to:
  /// **'世界音乐'**
  String get genreWorld;

  /// No description provided for @genreNewAge.
  ///
  /// In zh_CN, this message translates to:
  /// **'新世纪'**
  String get genreNewAge;

  /// No description provided for @genreSoundtrack.
  ///
  /// In zh_CN, this message translates to:
  /// **'原声'**
  String get genreSoundtrack;

  /// No description provided for @genreOpera.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌剧'**
  String get genreOpera;

  /// No description provided for @genreExperimental.
  ///
  /// In zh_CN, this message translates to:
  /// **'实验'**
  String get genreExperimental;

  /// No description provided for @genreMusicWord.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐'**
  String get genreMusicWord;

  /// No description provided for @genreMusicWordShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'乐'**
  String get genreMusicWordShort;

  /// No description provided for @trackFactSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'来源'**
  String get trackFactSource;

  /// No description provided for @trackFactStorage.
  ///
  /// In zh_CN, this message translates to:
  /// **'位置'**
  String get trackFactStorage;

  /// No description provided for @trackFactStorageLocal.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地'**
  String get trackFactStorageLocal;

  /// No description provided for @trackFactStorageRemote.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线'**
  String get trackFactStorageRemote;

  /// No description provided for @trackFactFormat.
  ///
  /// In zh_CN, this message translates to:
  /// **'格式'**
  String get trackFactFormat;

  /// No description provided for @trackFactQuality.
  ///
  /// In zh_CN, this message translates to:
  /// **'音质'**
  String get trackFactQuality;

  /// No description provided for @trackFactQualityLossless.
  ///
  /// In zh_CN, this message translates to:
  /// **'无损'**
  String get trackFactQualityLossless;

  /// No description provided for @trackFactQualityHiRes.
  ///
  /// In zh_CN, this message translates to:
  /// **'高解析'**
  String get trackFactQualityHiRes;

  /// No description provided for @trackFactSize.
  ///
  /// In zh_CN, this message translates to:
  /// **'大小'**
  String get trackFactSize;

  /// No description provided for @trackFactLyrics.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词'**
  String get trackFactLyrics;

  /// No description provided for @trackFactLyricsIncluded.
  ///
  /// In zh_CN, this message translates to:
  /// **'已包含'**
  String get trackFactLyricsIncluded;

  /// No description provided for @trackFactPerformers.
  ///
  /// In zh_CN, this message translates to:
  /// **'演奏者'**
  String get trackFactPerformers;

  /// No description provided for @trackFactAdded.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加时间'**
  String get trackFactAdded;

  /// No description provided for @trackFactDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'简介'**
  String get trackFactDescription;

  /// No description provided for @trackFactLive.
  ///
  /// In zh_CN, this message translates to:
  /// **'直播'**
  String get trackFactLive;

  /// No description provided for @trackFactPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'文件路径'**
  String get trackFactPath;

  /// No description provided for @trackFactAddress.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线地址'**
  String get trackFactAddress;

  /// No description provided for @trackDetailsTooltip.
  ///
  /// In zh_CN, this message translates to:
  /// **'查看详情'**
  String get trackDetailsTooltip;

  /// No description provided for @trackDetailsOpenPath.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开文件'**
  String get trackDetailsOpenPath;

  /// No description provided for @trackDetailsOpenFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'打不开这个文件'**
  String get trackDetailsOpenFailed;

  /// No description provided for @trackDetailsCopyAddress.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制地址'**
  String get trackDetailsCopyAddress;

  /// No description provided for @trackDetailsCopied.
  ///
  /// In zh_CN, this message translates to:
  /// **'已复制到剪贴板'**
  String get trackDetailsCopied;

  /// No description provided for @trackFactDuration.
  ///
  /// In zh_CN, this message translates to:
  /// **'时长'**
  String get trackFactDuration;

  /// No description provided for @trackFactSourceId.
  ///
  /// In zh_CN, this message translates to:
  /// **'来源编号'**
  String get trackFactSourceId;

  /// No description provided for @trackFactMediaType.
  ///
  /// In zh_CN, this message translates to:
  /// **'媒体类型'**
  String get trackFactMediaType;

  /// No description provided for @trackFactCover.
  ///
  /// In zh_CN, this message translates to:
  /// **'封面'**
  String get trackFactCover;

  /// No description provided for @trackFactIdentity.
  ///
  /// In zh_CN, this message translates to:
  /// **'身份'**
  String get trackFactIdentity;

  /// No description provided for @trackFactHeaders.
  ///
  /// In zh_CN, this message translates to:
  /// **'请求头'**
  String get trackFactHeaders;

  /// No description provided for @trackFactRawData.
  ///
  /// In zh_CN, this message translates to:
  /// **'原始数据'**
  String get trackFactRawData;

  /// No description provided for @trackDetailsCopyCover.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制封面'**
  String get trackDetailsCopyCover;

  /// No description provided for @trackDetailsCopyIdentity.
  ///
  /// In zh_CN, this message translates to:
  /// **'复制身份'**
  String get trackDetailsCopyIdentity;

  /// No description provided for @sourceStatusEnabled.
  ///
  /// In zh_CN, this message translates to:
  /// **'已启用'**
  String get sourceStatusEnabled;

  /// No description provided for @sourceStatusOff.
  ///
  /// In zh_CN, this message translates to:
  /// **'已关闭'**
  String get sourceStatusOff;

  /// No description provided for @sourceStatusNeedsSetup.
  ///
  /// In zh_CN, this message translates to:
  /// **'待配置'**
  String get sourceStatusNeedsSetup;

  /// No description provided for @sourceStatusFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'失败'**
  String get sourceStatusFailed;

  /// No description provided for @sourceStatusSkipped.
  ///
  /// In zh_CN, this message translates to:
  /// **'已跳过'**
  String get sourceStatusSkipped;

  /// No description provided for @sourceStatusScanned.
  ///
  /// In zh_CN, this message translates to:
  /// **'已扫描'**
  String get sourceStatusScanned;

  /// No description provided for @sourceStatusTracks.
  ///
  /// In zh_CN, this message translates to:
  /// **'曲目'**
  String get sourceStatusTracks;

  /// No description provided for @sourceStatusLastScan.
  ///
  /// In zh_CN, this message translates to:
  /// **'上次扫描'**
  String get sourceStatusLastScan;

  /// No description provided for @sourceStatusUnsupported.
  ///
  /// In zh_CN, this message translates to:
  /// **'不支持'**
  String get sourceStatusUnsupported;

  /// No description provided for @sourceStatusWaiting.
  ///
  /// In zh_CN, this message translates to:
  /// **'待扫描'**
  String get sourceStatusWaiting;

  /// No description provided for @jamendoFieldFormatHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认 192 kbps'**
  String get jamendoFieldFormatHint;

  /// No description provided for @subsonicFieldFormatHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认原始音质'**
  String get subsonicFieldFormatHint;

  /// No description provided for @subsonicFormatOriginal.
  ///
  /// In zh_CN, this message translates to:
  /// **'原始音质'**
  String get subsonicFormatOriginal;

  /// No description provided for @sourceRadioName.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络电台'**
  String get sourceRadioName;

  /// No description provided for @settingsEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'偏好'**
  String get settingsEyebrow;

  /// No description provided for @settingsSectionInterface.
  ///
  /// In zh_CN, this message translates to:
  /// **'界面'**
  String get settingsSectionInterface;

  /// No description provided for @settingsLocalFirst.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地优先'**
  String get settingsLocalFirst;

  /// No description provided for @libraryEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'资料库'**
  String get libraryEyebrow;

  /// No description provided for @sourcesEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接'**
  String get sourcesEyebrow;

  /// No description provided for @sidebarBrowse.
  ///
  /// In zh_CN, this message translates to:
  /// **'浏览'**
  String get sidebarBrowse;

  /// No description provided for @sidebarConnect.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接'**
  String get sidebarConnect;

  /// No description provided for @sidebarLocalOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地 + 在线'**
  String get sidebarLocalOnline;

  /// No description provided for @sidebarVersionLine.
  ///
  /// In zh_CN, this message translates to:
  /// **'{name} 桌面版 · {version}'**
  String sidebarVersionLine(String name, String version);

  /// No description provided for @searchSourceError.
  ///
  /// In zh_CN, this message translates to:
  /// **'{source}：{message}'**
  String searchSourceError(String source, String message);

  /// No description provided for @radioNoChannelList.
  ///
  /// In zh_CN, this message translates to:
  /// **'SomaFM 没有返回电台列表'**
  String get radioNoChannelList;

  /// No description provided for @trayPlayPause.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放 / 暂停'**
  String get trayPlayPause;

  /// No description provided for @trayPrevious.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一首'**
  String get trayPrevious;

  /// No description provided for @trayNext.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一首'**
  String get trayNext;

  /// No description provided for @trayShowWindow.
  ///
  /// In zh_CN, this message translates to:
  /// **'显示主窗口'**
  String get trayShowWindow;

  /// No description provided for @trayQuit.
  ///
  /// In zh_CN, this message translates to:
  /// **'退出'**
  String get trayQuit;

  /// No description provided for @settingsSectionDesktop.
  ///
  /// In zh_CN, this message translates to:
  /// **'桌面'**
  String get settingsSectionDesktop;

  /// No description provided for @settingsDesktopTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'桌面集成'**
  String get settingsDesktopTitle;

  /// No description provided for @settingsDesktopDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'让 Tune 在后台继续播放，并成为默认的音频播放器'**
  String get settingsDesktopDescription;

  /// No description provided for @settingsCloseToTray.
  ///
  /// In zh_CN, this message translates to:
  /// **'关闭窗口时最小化到托盘'**
  String get settingsCloseToTray;

  /// No description provided for @settingsCloseToTrayHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'关掉窗口后仍在托盘里继续播放'**
  String get settingsCloseToTrayHint;

  /// No description provided for @settingsMediaControls.
  ///
  /// In zh_CN, this message translates to:
  /// **'在系统媒体中心显示 Tune'**
  String get settingsMediaControls;

  /// No description provided for @settingsMediaControlsHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'让媒体键和媒体菜单控制 Tune'**
  String get settingsMediaControlsHint;

  /// No description provided for @settingsSetDefaultPlayer.
  ///
  /// In zh_CN, this message translates to:
  /// **'设为默认播放器'**
  String get settingsSetDefaultPlayer;

  /// No description provided for @settingsDefaultPlayerActive.
  ///
  /// In zh_CN, this message translates to:
  /// **'已是默认播放器'**
  String get settingsDefaultPlayerActive;

  /// No description provided for @settingsDefaultPlayerDone.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune 已经是默认播放器了'**
  String get settingsDefaultPlayerDone;

  /// No description provided for @settingsDefaultPlayerFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置失败，请先安装桌面项'**
  String get settingsDefaultPlayerFailed;

  /// No description provided for @settingsDefaultPlayerMissingEntry.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没有安装桌面项，先运行 linux/install-desktop-entry.sh'**
  String get settingsDefaultPlayerMissingEntry;

  /// No description provided for @settingsSectionPlayback.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get settingsSectionPlayback;

  /// No description provided for @settingsPlaybackTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放行为'**
  String get settingsPlaybackTitle;

  /// No description provided for @settingsPlaybackDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'决定启动时的播放行为，以及单击、双击歌曲时会发生什么'**
  String get settingsPlaybackDescription;

  /// No description provided for @settingsResumePlaybackOnStartup.
  ///
  /// In zh_CN, this message translates to:
  /// **'启动时继续上次播放'**
  String get settingsResumePlaybackOnStartup;

  /// No description provided for @settingsResumePlaybackOnStartupHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开 Tune 时恢复队列和播放进度，停在暂停状态；关掉后从空白队列开始'**
  String get settingsResumePlaybackOnStartupHint;

  /// No description provided for @settingsReplaceQueueOnClick.
  ///
  /// In zh_CN, this message translates to:
  /// **'单击歌曲时替换播放队列'**
  String get settingsReplaceQueueOnClick;

  /// No description provided for @settingsReplaceQueueOnClickHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'关掉时单击只把这首排进队列并立即播放，队列里的其余曲目保留'**
  String get settingsReplaceQueueOnClickHint;

  /// No description provided for @settingsOnlyLikeOnDoubleClick.
  ///
  /// In zh_CN, this message translates to:
  /// **'双击时只标成喜欢'**
  String get settingsOnlyLikeOnDoubleClick;

  /// No description provided for @settingsOnlyLikeOnDoubleClickHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'打开时双击只标成喜欢，不打断正在放的曲子；关掉时双击照常播放并标成喜欢'**
  String get settingsOnlyLikeOnDoubleClickHint;

  /// No description provided for @sidebarDiscover.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现'**
  String get sidebarDiscover;

  /// No description provided for @discoverEyebrow.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现'**
  String get discoverEyebrow;

  /// No description provided for @discoverTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'今天听什么'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'从你的音乐库和喜欢的曲目里挑的 · 只在本机计算'**
  String get discoverSubtitle;

  /// No description provided for @discoverRefresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'换一批'**
  String get discoverRefresh;

  /// No description provided for @discoverWhy.
  ///
  /// In zh_CN, this message translates to:
  /// **'怎么推荐'**
  String get discoverWhy;

  /// No description provided for @discoverWhyTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐怎么来的'**
  String get discoverWhyTitle;

  /// No description provided for @discoverWhyBody.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现页只用你的音乐库、标心的曲目、不感兴趣标记和可选的本地播放记录，在本机计算。不会上传，也不会替你搜索在线音源。'**
  String get discoverWhyBody;

  /// No description provided for @discoverWhyLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库里的曲目和元数据'**
  String get discoverWhyLibrary;

  /// No description provided for @discoverWhyHearts.
  ///
  /// In zh_CN, this message translates to:
  /// **'你标了心的曲目'**
  String get discoverWhyHearts;

  /// No description provided for @discoverWhyPrivacy.
  ///
  /// In zh_CN, this message translates to:
  /// **'只在你的电脑上计算，随时可以清除'**
  String get discoverWhyPrivacy;

  /// No description provided for @discoverWhyClose.
  ///
  /// In zh_CN, this message translates to:
  /// **'知道了'**
  String get discoverWhyClose;

  /// No description provided for @discoverSectionDailyMix.
  ///
  /// In zh_CN, this message translates to:
  /// **'今日混音'**
  String get discoverSectionDailyMix;

  /// No description provided for @discoverSectionArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'因为你喜欢 {artist}'**
  String discoverSectionArtist(String artist);

  /// No description provided for @discoverSectionExplore.
  ///
  /// In zh_CN, this message translates to:
  /// **'换个口味：{genre}'**
  String discoverSectionExplore(String genre);

  /// No description provided for @discoverSectionExploreEra.
  ///
  /// In zh_CN, this message translates to:
  /// **'回到 {decade} 年代'**
  String discoverSectionExploreEra(int decade);

  /// No description provided for @discoverSectionExploreEars.
  ///
  /// In zh_CN, this message translates to:
  /// **'换换耳朵'**
  String get discoverSectionExploreEars;

  /// No description provided for @discoverSectionFresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'刚入库'**
  String get discoverSectionFresh;

  /// No description provided for @discoverSectionSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'来自 {source}'**
  String discoverSectionSource(String source);

  /// No description provided for @discoverSectionFallback.
  ///
  /// In zh_CN, this message translates to:
  /// **'从你的音乐库挑的'**
  String get discoverSectionFallback;

  /// No description provided for @discoverDailyMixSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'熟悉的曲目 + 新发现 · {count} 首'**
  String discoverDailyMixSubtitle(int count);

  /// No description provided for @discoverPlay.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get discoverPlay;

  /// No description provided for @discoverAddAllShort.
  ///
  /// In zh_CN, this message translates to:
  /// **'加入队列'**
  String get discoverAddAllShort;

  /// No description provided for @discoverPlayAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放全部'**
  String get discoverPlayAll;

  /// No description provided for @discoverAddAllToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部加入队列'**
  String get discoverAddAllToQueue;

  /// No description provided for @discoverShelfBack.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一组'**
  String get discoverShelfBack;

  /// No description provided for @discoverShelfForward.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一组'**
  String get discoverShelfForward;

  /// No description provided for @discoverMoreActions.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多操作'**
  String get discoverMoreActions;

  /// No description provided for @discoverDismiss.
  ///
  /// In zh_CN, this message translates to:
  /// **'不感兴趣'**
  String get discoverDismiss;

  /// No description provided for @discoverDismissed.
  ///
  /// In zh_CN, this message translates to:
  /// **'已减少「{title}」的推荐'**
  String discoverDismissed(String title);

  /// No description provided for @discoverUndo.
  ///
  /// In zh_CN, this message translates to:
  /// **'撤销'**
  String get discoverUndo;

  /// No description provided for @discoverAddedToQueue.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入 {count} 首'**
  String discoverAddedToQueue(int count);

  /// No description provided for @discoverAlreadyQueued.
  ///
  /// In zh_CN, this message translates to:
  /// **'这些歌已经在队列里了'**
  String get discoverAlreadyQueued;

  /// No description provided for @discoverReasonFavorite.
  ///
  /// In zh_CN, this message translates to:
  /// **'你标了心'**
  String get discoverReasonFavorite;

  /// No description provided for @discoverReasonArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'因为你喜欢 {artist}'**
  String discoverReasonArtist(String artist);

  /// No description provided for @discoverReasonGenre.
  ///
  /// In zh_CN, this message translates to:
  /// **'你喜欢 {genre}'**
  String discoverReasonGenre(String genre);

  /// No description provided for @discoverReasonEra.
  ///
  /// In zh_CN, this message translates to:
  /// **'回到 {decade} 年代'**
  String discoverReasonEra(int decade);

  /// No description provided for @discoverReasonFresh.
  ///
  /// In zh_CN, this message translates to:
  /// **'刚入库'**
  String get discoverReasonFresh;

  /// No description provided for @discoverReasonUnheard.
  ///
  /// In zh_CN, this message translates to:
  /// **'还没听过'**
  String get discoverReasonUnheard;

  /// No description provided for @discoverReasonSource.
  ///
  /// In zh_CN, this message translates to:
  /// **'来自 {source}'**
  String discoverReasonSource(String source);

  /// No description provided for @discoverReasonFallback.
  ///
  /// In zh_CN, this message translates to:
  /// **'从你的音乐库挑的'**
  String get discoverReasonFallback;

  /// No description provided for @discoverEmptyLibraryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库还是空的'**
  String get discoverEmptyLibraryTitle;

  /// No description provided for @discoverEmptyLibrarySubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描本地音乐或连接一个音源，发现页才有东西可挑'**
  String get discoverEmptyLibrarySubtitle;

  /// No description provided for @discoverScanMusic.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描音乐'**
  String get discoverScanMusic;

  /// No description provided for @discoverConnectSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'连接音源'**
  String get discoverConnectSources;

  /// No description provided for @discoverNoCandidatesTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'能推荐的都听过了'**
  String get discoverNoCandidatesTitle;

  /// No description provided for @discoverNoCandidatesSubtitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'去音乐库逛逛，或清掉不感兴趣标记'**
  String get discoverNoCandidatesSubtitle;

  /// No description provided for @discoverGoToLibrary.
  ///
  /// In zh_CN, this message translates to:
  /// **'去音乐库'**
  String get discoverGoToLibrary;

  /// No description provided for @discoverLoadFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现页加载失败'**
  String get discoverLoadFailed;

  /// No description provided for @discoverLoadFailedHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库暂时读不出来，稍后再试'**
  String get discoverLoadFailedHint;

  /// No description provided for @discoverClearTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除推荐记录？'**
  String get discoverClearTitle;

  /// No description provided for @discoverClearMessage.
  ///
  /// In zh_CN, this message translates to:
  /// **'会删除单曲与歌手的「少推荐」标记和本地播放记录；喜欢、音乐库和播放队列不受影响。'**
  String get discoverClearMessage;

  /// No description provided for @discoverCleared.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐记录已清除'**
  String get discoverCleared;

  /// No description provided for @settingsSectionDiscovery.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现'**
  String get settingsSectionDiscovery;

  /// No description provided for @settingsDiscoveryTitle.
  ///
  /// In zh_CN, this message translates to:
  /// **'发现页'**
  String get settingsDiscoveryTitle;

  /// No description provided for @settingsDiscoveryDescription.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐只在本机计算，不上传你的音乐库'**
  String get settingsDiscoveryDescription;

  /// No description provided for @settingsDiscoveryPrivacy.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐只使用音乐库、标心的曲目和不感兴趣标记。'**
  String get settingsDiscoveryPrivacy;

  /// No description provided for @discoverFavoriteHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'标几首喜欢的歌，推荐会更准'**
  String get discoverFavoriteHint;

  /// No description provided for @settingsDiscoveryUseHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地播放记录'**
  String get settingsDiscoveryUseHistory;

  /// No description provided for @settingsDiscoveryUseHistoryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'只保存在本机，让推荐更贴近你；关闭后不再记录'**
  String get settingsDiscoveryUseHistoryHint;

  /// No description provided for @discoverHistoryHint.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启本地播放记录，推荐会更贴近你'**
  String get discoverHistoryHint;

  /// No description provided for @discoverHistoryEnable.
  ///
  /// In zh_CN, this message translates to:
  /// **'开启'**
  String get discoverHistoryEnable;

  /// No description provided for @discoverClearAll.
  ///
  /// In zh_CN, this message translates to:
  /// **'清除推荐记录'**
  String get discoverClearAll;

  /// No description provided for @discoverWhyHistory.
  ///
  /// In zh_CN, this message translates to:
  /// **'可选的本地播放记录（默认关闭）'**
  String get discoverWhyHistory;

  /// No description provided for @discoverSectionOnlineArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线找到的 {artist}'**
  String discoverSectionOnlineArtist(String artist);

  /// No description provided for @discoverFindMoreOnline.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线找更多'**
  String get discoverFindMoreOnline;

  /// No description provided for @discoverFindingMore.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在找…'**
  String get discoverFindingMore;

  /// No description provided for @discoverNoOnlineSources.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有启用的在线音源'**
  String get discoverNoOnlineSources;

  /// No description provided for @discoverOnlineNoResults.
  ///
  /// In zh_CN, this message translates to:
  /// **'没有找到更多 {artist} 的歌'**
  String discoverOnlineNoResults(String artist);

  /// No description provided for @discoverOnlineFailed.
  ///
  /// In zh_CN, this message translates to:
  /// **'在线查找失败，稍后再试'**
  String get discoverOnlineFailed;

  /// No description provided for @discoverOnlineFound.
  ///
  /// In zh_CN, this message translates to:
  /// **'已加入 {count} 首在线结果'**
  String discoverOnlineFound(int count);

  /// No description provided for @discoverReasonAdjacent.
  ///
  /// In zh_CN, this message translates to:
  /// **'同一种口味，换个人'**
  String get discoverReasonAdjacent;

  /// No description provided for @discoverLessArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'少推荐这位歌手'**
  String get discoverLessArtist;

  /// No description provided for @discoverDismissedArtist.
  ///
  /// In zh_CN, this message translates to:
  /// **'已减少「{artist}」的推荐'**
  String discoverDismissedArtist(String artist);

  /// No description provided for @discoverSectionFavoriteArtists.
  ///
  /// In zh_CN, this message translates to:
  /// **'更多来自你标心的歌手'**
  String get discoverSectionFavoriteArtists;

  /// No description provided for @discoverReasonCompleted.
  ///
  /// In zh_CN, this message translates to:
  /// **'你常把这首听完'**
  String get discoverReasonCompleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

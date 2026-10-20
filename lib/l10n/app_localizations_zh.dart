// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => '本地优先的桌面音乐播放器';

  @override
  String get appStartFailed => 'Tune 启动失败';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get clear => '清空';

  @override
  String get close => '关闭';

  @override
  String get retry => '重试';

  @override
  String get chooseFile => '选择文件';

  @override
  String get unknownError => '未知错误';

  @override
  String get scanNow => '立即扫描';

  @override
  String get search => '搜索';

  @override
  String get scanning => '扫描中';

  @override
  String get about => '关于';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get libraryTitle => '音乐库';

  @override
  String get librarySubtitle => '本地与在线音源的全部曲目';

  @override
  String get libraryClearSearch => '清除搜索';

  @override
  String get libraryFilterSources => '筛选来源';

  @override
  String get libraryAllSources => '全部来源';

  @override
  String get libraryScanAllSources => '扫描全部音源';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首';
  }

  @override
  String get libraryNoMatchTitle => '没有匹配的歌曲';

  @override
  String get libraryNoMatchSubtitle => '换个关键词，或清除搜索条件';

  @override
  String get librarySourceEmptyTitle => '该来源暂无歌曲';

  @override
  String get librarySourceEmptySubtitle => '切换到全部来源，或重新扫描该音源';

  @override
  String get libraryViewAllSources => '查看全部来源';

  @override
  String get libraryScanningTitle => '正在扫描音乐';

  @override
  String get libraryEmptyTitle => '还没有音乐';

  @override
  String get libraryEmptySubtitle => '扫描本地目录或已启用的在线音源，也可以在设置中调整音源。';

  @override
  String get libraryLoadFailedTitle => '音乐库加载失败';

  @override
  String get libraryAddedToQueue => '已加入播放队列';

  @override
  String libraryScanPaths(String paths) {
    return '扫描目录：$paths';
  }

  @override
  String get libraryAddToQueue => '加入播放队列';

  @override
  String get libraryAddAllToQueue => '将整个列表加入队列';

  @override
  String get queueTitle => '播放队列';

  @override
  String get queueSubtitle => '当前播放顺序';

  @override
  String get queueEmptyTitle => '播放队列是空的';

  @override
  String get queueEmptySubtitle => '从音乐库选择歌曲，或把歌曲加入队列';

  @override
  String get queueGoToLibrary => '去音乐库';

  @override
  String get queueClearTitle => '清空播放队列？';

  @override
  String get queueClearMessage => '当前播放会停止，队列中的歌曲不会从音乐库删除。';

  @override
  String get favoritesTitle => '喜欢';

  @override
  String get favoritesSubtitle => '标了心的曲子都在这里';

  @override
  String get favoritesEmptyTitle => '还没有喜欢的曲子';

  @override
  String get favoritesEmptySubtitle => '在音乐库里点一下红心，喜欢的曲子就会收在这里';

  @override
  String get favoritesGoToLibrary => '去音乐库';

  @override
  String get favoriteAdd => '加入收藏';

  @override
  String get favoriteRemove => '取消收藏';

  @override
  String get playerNowPlaying => '正在播放';

  @override
  String get playerExpandNowPlaying => '展开正在播放';

  @override
  String get playerCollapse => '收起';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerMute => '静音';

  @override
  String get playerUnmute => '恢复音量';

  @override
  String get playerPlayModeSequential => '列表循环';

  @override
  String get playerPlayModeRepeatOne => '单曲循环';

  @override
  String get playerPlayModeShuffle => '随机播放';

  @override
  String get playerNoSongTitle => '选择一首歌开始';

  @override
  String get playerUnknownArtist => '未知艺术家';

  @override
  String get playerDockReady => 'Tune · 就绪';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '队列 $countString 首';
  }

  @override
  String playerQueuePosition(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return '队列第 $indexString 首';
  }

  @override
  String get nowPlayingEmptyTitle => '还没有播放的曲目';

  @override
  String get nowPlayingEmptySubtitle => '从音乐库里挑一首开始';

  @override
  String get nowPlayingUnnamedTrack => '未命名曲目';

  @override
  String get trackUnknownTitle => '未知歌曲';

  @override
  String playbackFailed(String error) {
    return '播放失败：$error';
  }

  @override
  String playbackPauseFailed(String error) {
    return '暂停失败：$error';
  }

  @override
  String playbackResumeFailed(String error) {
    return '继续播放失败：$error';
  }

  @override
  String playbackSeekFailed(String error) {
    return '跳转失败：$error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return '设置音量失败：$error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return '设置速度失败：$error';
  }

  @override
  String get audioSourceLocal => '本地文件';

  @override
  String audioSourceCaching(int percent) {
    return '缓存中 $percent%';
  }

  @override
  String get audioSourceCached => '已缓存';

  @override
  String get audioSourceFailed => '播放失败';

  @override
  String get routerNotFoundTitle => '页面不存在';

  @override
  String get routerBackToLibrary => '返回音乐库';

  @override
  String get sourcesTitle => '音源';

  @override
  String get sourcesSubtitle => '在线曲库、自建服务与扫描目录';

  @override
  String get sourcesGroupMore => '更多音源';

  @override
  String get sourcesGroupAdded => '我添加的';

  @override
  String get sourcesAdd => '添加音源';

  @override
  String get sourcesAddChooseType => '选择音源类型';

  @override
  String sourcesAddTitle(String name) {
    return '添加 $name';
  }

  @override
  String get sourcesFieldName => '名称';

  @override
  String get sourcesFieldNameHint => '留空则用类型名加序号';

  @override
  String get sourcesDelete => '删除';

  @override
  String sourcesDeleteTitle(String name) {
    return '删除「$name」？';
  }

  @override
  String get sourcesDeleteHint => '这个音源带来的曲目也会一并移除。';

  @override
  String get sourcesMenu => '更多操作';

  @override
  String get sourceDirectUrlName => '直链音频';

  @override
  String get sourceDirectUrlDescription => '一行一条地址，每条变成一首曲目';

  @override
  String get directUrlFieldUrls => '音频地址';

  @override
  String get directUrlFieldUrlsHint => '一行一条地址，例如 https://example.com/song.mp3';

  @override
  String get directUrlHint => '填写音频地址，一行一条';

  @override
  String get sourceM3uName => '播放列表';

  @override
  String get sourceM3uDescription => '读一个 .m3u 或 .pls 播放列表，条目变成曲目';

  @override
  String get m3uFieldPlaylist => '播放列表地址';

  @override
  String get m3uFieldPlaylistHint => '例如 https://example.com/list.m3u';

  @override
  String get m3uHint => '填写播放列表地址';

  @override
  String get m3uEmptyPlaylist => '播放列表是空的';

  @override
  String get m3uNoEntries => '播放列表里没有条目';

  @override
  String get jsonFieldListPath => '列表路径';

  @override
  String get jsonFieldIdPath => '曲目 id 路径';

  @override
  String get jsonFieldTitlePath => '标题路径';

  @override
  String get jsonFieldArtistPath => '歌手路径';

  @override
  String get jsonFieldAlbumPath => '专辑路径';

  @override
  String get jsonFieldCoverPath => '封面路径';

  @override
  String get jsonFieldUrlPath => '播放地址路径';

  @override
  String get jsonFieldDurationPath => '时长路径';

  @override
  String get jsonFieldGenrePath => '流派路径';

  @override
  String get jsonFieldUrlTemplate => '播放地址模板';

  @override
  String get jsonFieldPathHint => '响应里的路径，逐段用点分开，如 data.title';

  @override
  String get jsonFieldUrlTemplateHint => '播放地址的模板，曲目 id 会填进占位处';

  @override
  String get jsonFieldQueryHint => '搜索用的关键词，会替换请求里的占位符';

  @override
  String get jsonFieldUrl => '接口地址';

  @override
  String get jsonFieldUrlHint => '例如 https://example.com/api/search';

  @override
  String get jsonFieldHeaders => '请求头';

  @override
  String get jsonFieldHeadersHint => 'JSON 对象，一行一个键和值';

  @override
  String get jsonInvalidObject => '这段文字不是 JSON 对象';

  @override
  String get jsonInvalidResponse => '接口返回的不是 JSON';

  @override
  String get jsonNoTracks => '接口没有返回曲目';

  @override
  String get jsonNoAddressPath => '没有填写播放地址的路径或模板';

  @override
  String get sourceJsonApiName => 'JSON 接口';

  @override
  String get sourceJsonApiDescription => '把任意 JSON 接口映射成曲目';

  @override
  String get jsonApiHint => '填写接口地址与各字段的路径';

  @override
  String get jsonApiFieldMethod => '请求方式';

  @override
  String get jsonApiFieldMethodHint => '默认 GET；写了请求体就用 POST';

  @override
  String get jsonApiFieldBody => '请求体';

  @override
  String get jsonApiFieldBodyHint => 'POST 时的 JSON 对象；关键词会填进占位符';

  @override
  String get sourcesAutoScan => '启动时自动扫描';

  @override
  String get sourcesAutoScanDescription => '所有已启用音源都会在启动后自动刷新，失败不会影响本地库。';

  @override
  String get sourcesScanMayTakeSeconds => '含远程音源时可能需要数秒';

  @override
  String get sourcesScanCompleted => '扫描已完成';

  @override
  String get sourcesConfigure => '配置';

  @override
  String get sourcesUnsupported => '当前版本不支持该音源';

  @override
  String get sourcesDisabled => '已关闭';

  @override
  String get sourcesNeedsConfiguration => '需要配置';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return '需要配置：$hint';
  }

  @override
  String sourcesLastScan(String time) {
    return '上次扫描 $time';
  }

  @override
  String get sourcesAutoScanLocal => '启动后自动扫描本地目录';

  @override
  String get sourcesWaitingFirstScan => '等待首次扫描';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已扫描 $countString 首 · $time';
  }

  @override
  String get sourcesSkipped => '已跳过';

  @override
  String get sourcesScanFailed => '扫描失败';

  @override
  String sourcesDeleted(String name) {
    return '已删除 $name';
  }

  @override
  String get sourceKindLocal => '本地';

  @override
  String get sourceKindOpenCatalog => '开放曲库';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindCustom => '自定义';

  @override
  String sourcesConfigureTitle(String name) {
    return '配置 $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return '请填写$label';
  }

  @override
  String get sourcesFieldNumeric => '请输入数字';

  @override
  String get fieldQuery => '搜索关键词';

  @override
  String get fieldQueryOptional => '搜索关键词（可选）';

  @override
  String get fieldBrowse => '浏览流';

  @override
  String get fieldBrowseHint => '不填关键词时拉取的内容；填了关键词就按关键词搜';

  @override
  String get browseModeLatest => '最新';

  @override
  String get browseModeCharts => '排行';

  @override
  String get browseModeDaily => '每日推荐';

  @override
  String get fieldLimit => '每次扫描数量';

  @override
  String get fieldLimitFiles => '每次扫描文件数';

  @override
  String get fieldLimitEpisodes => '每次扫描集数';

  @override
  String get fieldLimitStations => '每次扫描电台数';

  @override
  String fieldLimitHint(int count, int max) {
    return '默认 $count，最大 $max';
  }

  @override
  String get fieldServer => '服务器地址';

  @override
  String get fieldUser => '用户名';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldFormat => '音质';

  @override
  String get sourcesNotLoaded => '音源列表尚未加载完成';

  @override
  String get playerLyrics => '歌词';

  @override
  String get lyricsLoading => '正在加载歌词';

  @override
  String get lyricsFailed => '歌词加载失败';

  @override
  String get lyricsMissing => '这首歌没有歌词';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '调整外观、语言和本地音乐库。';

  @override
  String get settingsThemeDescription => '选择界面的明暗气质和显示语言。';

  @override
  String get settingsLanguageDescription => '界面文字和系统菜单语言';

  @override
  String get settingsLibraryDescription => 'Tune 只会在这些目录中查找音频文件。';

  @override
  String get settingsDefaultPath => '默认';

  @override
  String get settingsNoDefaultFolder => '未找到默认音乐目录';

  @override
  String get settingsCustomPath => '自定义';

  @override
  String get settingsAddFolder => '添加文件夹';

  @override
  String get settingsClearLibrary => '清空音乐库';

  @override
  String get settingsScanSafetyNote => '扫描只读取音频文件，不会修改或删除磁盘内容。';

  @override
  String get settingsChooseFolder => '选择音乐文件夹';

  @override
  String get settingsFolderAdded => '已添加扫描目录';

  @override
  String get settingsLibraryFolder => '文件存放位置';

  @override
  String get settingsChangeLibraryFolder => '更换位置';

  @override
  String get settingsUseDefaultLibraryFolder => '用默认位置';

  @override
  String get settingsNoLibraryFolder => '这个平台没有音乐目录';

  @override
  String get settingsScanDone => '扫描完成';

  @override
  String get settingsClearLibraryTitle => '清空音乐库？';

  @override
  String get settingsClearLibraryMessage => '只会清除 Tune 的扫描记录，不会删除磁盘上的音乐文件。';

  @override
  String get settingsLibraryCleared => '音乐库已清空';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 个目录';
  }

  @override
  String get searchOnlineTitle => '在线搜索';

  @override
  String get searchOnlineHint => '搜索在线音源，例如 jazz、钢琴、lo-fi';

  @override
  String get searchOnlineDescription => '搜索已启用的在线音源；结果不会写入音乐库';

  @override
  String get searchOnlinePrompt => '搜索在线音源';

  @override
  String get searchOnlinePromptDescription => '输入关键词后按回车；所有已启用的在线音源会并行搜索。';

  @override
  String get searchNoResults => '没有结果';

  @override
  String get searchNoResultsDescription => '换个关键词再试一次。';

  @override
  String get searchNoMatch => '没有找到匹配的歌曲';

  @override
  String searchSearching(String query) {
    return '正在搜索「$query」';
  }

  @override
  String get searchPlayAll => '播放全部';

  @override
  String get searchAddToQueue => '加入队列';

  @override
  String searchAddedToQueue(String title) {
    return '已加入队列：$title';
  }

  @override
  String get searchNoSourcesEnabled => '没有启用在线音源，请先在设置中开启';

  @override
  String get searchFailedShort => '搜索失败';

  @override
  String searchFailed(String error) {
    return '在线搜索失败：$error';
  }

  @override
  String get scanPreparing => '准备扫描...';

  @override
  String get scanNoEnabledSources => '没有启用的音源';

  @override
  String get scanNoLocalFolders => '没有可扫描的音乐目录';

  @override
  String scanProgressPercent(int percent) {
    return '扫描中 $percent%';
  }

  @override
  String get scanAllSourcesFailed => '所有音源扫描失败';

  @override
  String scanFailed(String error) {
    return '扫描失败：$error';
  }

  @override
  String clearLibraryFailed(String error) {
    return '清空音乐库失败：$error';
  }

  @override
  String get scanNoAudioFiles => '未找到音频文件';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已扫描 $countString 首歌曲';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首歌曲';
  }

  @override
  String get scanSourceNotConfigured => '音源尚未配置';

  @override
  String get scanCachedTooSoon => '已保留缓存，距上次扫描不足间隔';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '已扫描 $sourcesString 个音源，共 $songsString 首歌曲';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '已更新 $songsString 首歌曲，$failedString 个音源失败';
  }

  @override
  String sourceErrorForbidden(int status) {
    return '访问被拒绝（HTTP $status）';
  }

  @override
  String get sourceErrorRateLimited => '请求过于频繁（HTTP 429），请稍后再试';

  @override
  String sourceErrorHttpStatus(int status) {
    return '接口返回 HTTP $status';
  }

  @override
  String get sourceErrorTimeout => '网络连接超时';

  @override
  String get sourceErrorConnection => '无法连接音源服务';

  @override
  String get sourceErrorCertificate => '证书校验失败';

  @override
  String get sourceErrorCancelled => '请求已取消';

  @override
  String sourceErrorNetwork(String message) {
    return '网络请求失败：$message';
  }

  @override
  String get sourceErrorUnsupported => '暂不支持该音源';

  @override
  String sourceErrorScanInterval(String interval) {
    return '距上次扫描不足 $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return '扫描超时（${seconds}s）';
  }

  @override
  String intervalHours(int count) {
    return '$count 小时';
  }

  @override
  String intervalMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get localSourceHint => '在音乐库设置中添加扫描目录';

  @override
  String get localSourceNotConfigured => '未配置本地音乐目录';

  @override
  String get neteaseHint =>
      '填写自建的 NeteaseCloudMusicApi 地址，例如 http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API 地址';

  @override
  String get neteaseFieldQueryHint => '例如 热门、周杰伦';

  @override
  String get neteaseHotKeyword => '热门';

  @override
  String get neteaseEmptyResponse => '网易云 API 返回了空响应';

  @override
  String get neteaseNoStream => '接口未返回可播放地址（可能需要在服务端登录或受版权限制）';

  @override
  String get openverseHint => '填写搜索关键词，例如 piano、ambient 或 jazz';

  @override
  String get openverseFieldQueryHint => '例如 piano、ambient、jazz';

  @override
  String get openverseEmptyResponse => 'Openverse 返回了空响应';

  @override
  String get openverseNoMatch => '没有找到匹配的开放音频';

  @override
  String get sourceLocalName => '本地音乐';

  @override
  String get sourceLocalDescription => '扫描设备上的音乐文件夹';

  @override
  String get sourceOpenverseDescription =>
      '开放版权音频聚合：Jamendo、Freesound、Wikimedia 等';

  @override
  String get sourceOpenverseName => '开放版权聚合';

  @override
  String get sourceJamendoDescription => '独立音乐开放曲库，需要免费 Client ID';

  @override
  String get sourceJamendoName => '独立音乐曲库';

  @override
  String get sourceInternetArchiveDescription => 'Internet Archive 的开放音频收藏';

  @override
  String get sourceInternetArchiveName => '公共领域音频';

  @override
  String get sourceNeteaseName => '网易云音乐 API';

  @override
  String get sourceNeteaseDescription => '连接自建的 NeteaseCloudMusicApi 服务';

  @override
  String get jamendoHint => '在 developer.jamendo.com 免费申请 Client ID 后填入';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint => '在 developer.jamendo.com 免费申请';

  @override
  String get jamendoFieldQueryHint => '例如 jazz、electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo 返回了空响应';

  @override
  String get jamendoNoMatch => '没有找到匹配的 Jamendo 曲目';

  @override
  String get internetArchiveHint =>
      '填写 Internet Archive 收录条件，例如 collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => '收录条件';

  @override
  String get internetArchiveInvalidResponse => 'Internet Archive 返回了无法识别的响应';

  @override
  String get internetArchiveNoMatch => '没有找到可播放的归档音频';

  @override
  String get downloadUnsupportedPlatform => '当前平台没有文件系统，无法缓存下载';

  @override
  String get audioLoadFailed => '音频加载失败';

  @override
  String get audioPathEmpty => '音频文件路径为空';

  @override
  String get ccmixterEmptyResponse => 'ccMixter 返回了空响应';

  @override
  String get ccmixterFieldQuery => '搜索标签';

  @override
  String get ccmixterFieldQueryHint => '例如 jazz、ambient、electro';

  @override
  String get ccmixterHint => '填写 ccMixter 标签，例如 jazz、ambient 或 electro';

  @override
  String get ccmixterNoMatch => '没有找到匹配的 ccMixter 曲目';

  @override
  String get itunesEmptyResponse => 'iTunes API 返回了空响应';

  @override
  String get itunesFieldQueryHint => '例如 jazz、piano、lo-fi';

  @override
  String get itunesHint => '填写搜索关键词，例如 jazz、piano 或 lo-fi';

  @override
  String get itunesNoMatch => '没有找到匹配的 iTunes 曲目';

  @override
  String get podcastRssEmptyFeed => '订阅地址返回了空内容';

  @override
  String get podcastRssFieldFeed => '订阅地址';

  @override
  String get podcastRssFieldFeedHint => '例如 https://example.com/podcast.xml';

  @override
  String get podcastRssHint => '填写播客订阅地址（RSS）';

  @override
  String podcastRssInvalidFeed(String error) {
    return '订阅地址返回了无法解析的 XML：$error';
  }

  @override
  String get podcastRssNoMatch => '订阅源里没有可播放的单集';

  @override
  String get sourceCcmixterDescription => 'Creative Commons 混音与开放音乐曲库';

  @override
  String get sourceCcmixterName => '共享混音素材';

  @override
  String get sourceItunesDescription => 'iTunes 目录的 30 秒试听片段';

  @override
  String get sourceItunesName => '商店试听片段';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS 播客订阅变成可播放的单集';

  @override
  String get sourcePodcastRssName => '播客订阅';

  @override
  String get sourceSubsonicDescription => '连接自建的 Navidrome / Subsonic 音乐库';

  @override
  String get sourceSubsonicName => '自建音乐库';

  @override
  String get subsonicAuthFailed => '无法连接音乐服务器，请检查地址与账号';

  @override
  String get subsonicEmptyResponse => '音乐服务器返回了空响应';

  @override
  String subsonicError(String error) {
    return '音乐服务器返回错误：$error';
  }

  @override
  String get subsonicFieldPasswordHint => '用于计算访问令牌，不会明文发送';

  @override
  String get subsonicFieldQueryHint => '例如 jazz、piano';

  @override
  String get subsonicFieldServerHint => '例如 http://localhost:4533';

  @override
  String get subsonicFieldUserHint => '自建音乐库的登录用户名';

  @override
  String get subsonicHint => '填写自建音乐库的地址与账号，例如 http://localhost:4533';

  @override
  String get subsonicNoMatch => '没有找到匹配的曲目';

  @override
  String get sourceAudiusDescription => 'Audius 上音乐人直发的完整曲目';

  @override
  String get sourceAudiusName => '音乐人直发';

  @override
  String get audiusHint => '填写搜索关键词，例如 jazz、ambient 或 electronic';

  @override
  String get audiusFieldQueryHint => '例如 jazz、ambient、electronic';

  @override
  String get audiusEmptyResponse => 'Audius 返回了空响应';

  @override
  String get audiusNoMatch => '没有找到匹配的 Audius 曲目';

  @override
  String get sourceRadioDescription => '公开网络电台的直播流';

  @override
  String get radioHint => '选择电台目录，关键词可进一步过滤';

  @override
  String get radioFieldProvider => '电台目录';

  @override
  String get radioFieldProviderHint =>
      '全部目录、Radio Browser、SomaFM 或 Radio Paradise';

  @override
  String get radioProviderAll => '全部目录';

  @override
  String get radioFieldQuery => '电台关键词';

  @override
  String get radioFieldQueryHint => '例如 jazz、ambient 或 SomaFM';

  @override
  String get radioNoMatch => '没有找到匹配的电台';

  @override
  String get sourceWikimediaDescription => 'Wikimedia Commons 的开放音频';

  @override
  String get sourceWikimediaName => '自由授权媒体';

  @override
  String get wikimediaHint => '填写搜索关键词，例如 piano、lecture 或 birdsong';

  @override
  String get wikimediaFieldQueryHint => '例如 piano、lecture、birdsong';

  @override
  String get wikimediaEmptyResponse => 'Wikimedia Commons 返回了空响应';

  @override
  String get wikimediaNoMatch => '没有找到可播放的共享音频';

  @override
  String get sourceJellyfinDescription => '连接自建的 Jellyfin 媒体库';

  @override
  String get sourceJellyfinName => '自建媒体库';

  @override
  String get jellyfinHint => '填写自建 Jellyfin 的地址与账号';

  @override
  String get jellyfinFieldServerHint => '例如 http://localhost:8096';

  @override
  String get jellyfinFieldUserHint => 'Jellyfin 的登录用户名';

  @override
  String get jellyfinFieldPasswordHint => '用于换取访问令牌';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin 返回了空响应';

  @override
  String get jellyfinAuthFailed => '无法连接 Jellyfin 服务器，请检查地址与账号';

  @override
  String get audioSourceStreaming => '网络';

  @override
  String get playerLiveBadge => '直播中';

  @override
  String get nowPlayingLiveStream => '直播流，没有固定时长';

  @override
  String get nowPlayingDetails => '曲目信息';

  @override
  String get nowPlayingDetailAlbum => '专辑';

  @override
  String get nowPlayingDetailYear => '年份';

  @override
  String get nowPlayingDetailGenre => '流派';

  @override
  String get nowPlayingDetailBitrate => '码率';

  @override
  String get nowPlayingDetailSampleRate => '采样率';

  @override
  String get nowPlayingDetailTrack => '音轨';

  @override
  String get nowPlayingDetailDisc => '碟片';

  @override
  String get nowPlayingDetailLicense => '许可';

  @override
  String get nowPlayingDetailSource => '来源';

  @override
  String get nowPlayingDetailNowPlaying => '正在播放';

  @override
  String get genreRock => '摇滚';

  @override
  String get genrePop => '流行';

  @override
  String get genreJazz => '爵士';

  @override
  String get genreClassical => '古典';

  @override
  String get genreElectronic => '电子';

  @override
  String get genreHipHop => '说唱';

  @override
  String get genreBlues => '蓝调';

  @override
  String get genreCountry => '乡村';

  @override
  String get genreFolk => '民谣';

  @override
  String get genreMetal => '金属';

  @override
  String get genrePunk => '朋克';

  @override
  String get genreReggae => '雷鬼';

  @override
  String get genreLatin => '拉丁';

  @override
  String get genreDance => '舞曲';

  @override
  String get genreAlternative => '另类';

  @override
  String get genreIndie => '独立';

  @override
  String get genreAmbient => '环境音乐';

  @override
  String get genreHouse => '浩室';

  @override
  String get genreFunk => '放克';

  @override
  String get genreGospel => '福音';

  @override
  String get genreWorld => '世界音乐';

  @override
  String get genreNewAge => '新世纪';

  @override
  String get genreSoundtrack => '原声';

  @override
  String get genreOpera => '歌剧';

  @override
  String get genreExperimental => '实验';

  @override
  String get genreMusicWord => '音乐';

  @override
  String get genreMusicWordShort => '乐';

  @override
  String get trackFactSource => '来源';

  @override
  String get trackFactStorage => '位置';

  @override
  String get trackFactStorageLocal => '本地';

  @override
  String get trackFactStorageRemote => '在线';

  @override
  String get trackFactFormat => '格式';

  @override
  String get trackFactQuality => '音质';

  @override
  String get trackFactQualityLossless => '无损';

  @override
  String get trackFactQualityHiRes => '高解析';

  @override
  String get trackFactSize => '大小';

  @override
  String get trackFactLyrics => '歌词';

  @override
  String get trackFactLyricsIncluded => '已包含';

  @override
  String get trackFactPerformers => '演奏者';

  @override
  String get trackFactAdded => '添加时间';

  @override
  String get trackFactDescription => '简介';

  @override
  String get trackFactLive => '直播';

  @override
  String get trackFactPath => '文件路径';

  @override
  String get trackFactAddress => '地址';

  @override
  String get trackDetailsTooltip => '查看详情';

  @override
  String get trackDetailsCopyPath => '复制路径';

  @override
  String get trackDetailsCopyAddress => '复制地址';

  @override
  String get trackDetailsCopied => '已复制到剪贴板';

  @override
  String get trackFactDuration => '时长';

  @override
  String get trackFactSourceId => '来源编号';

  @override
  String get trackFactMediaType => '媒体类型';

  @override
  String get trackFactCover => '封面';

  @override
  String get trackFactIdentity => '身份';

  @override
  String get trackFactHeaders => '请求头';

  @override
  String get trackFactRawData => '原始数据';

  @override
  String get trackDetailsCopyCover => '复制封面';

  @override
  String get trackDetailsCopyIdentity => '复制身份';

  @override
  String get sourceStatusEnabled => '已启用';

  @override
  String get sourceStatusOff => '已关闭';

  @override
  String get sourceStatusNeedsSetup => '待配置';

  @override
  String get sourceStatusFailed => '失败';

  @override
  String get sourceStatusSkipped => '已跳过';

  @override
  String get sourceStatusScanned => '已扫描';

  @override
  String get sourceStatusTracks => '曲目';

  @override
  String get sourceStatusLastScan => '上次扫描';

  @override
  String get sourceStatusUnsupported => '不支持';

  @override
  String get sourceStatusWaiting => '待扫描';

  @override
  String get jamendoFieldFormatHint => '默认 192 kbps';

  @override
  String get subsonicFieldFormatHint => '默认原始音质';

  @override
  String get subsonicFormatOriginal => '原始音质';

  @override
  String get sourceRadioName => '网络电台';

  @override
  String get settingsEyebrow => '偏好';

  @override
  String get settingsSectionInterface => '界面';

  @override
  String get settingsLocalFirst => '本地优先';

  @override
  String get libraryEyebrow => '收藏';

  @override
  String get sourcesEyebrow => '连接';

  @override
  String get sidebarCollect => '收藏';

  @override
  String get sidebarConnect => '连接';

  @override
  String get sidebarLocalOnline => '本地 + 在线';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name 桌面版 · $version';
  }

  @override
  String searchSourceError(String source, String message) {
    return '$source：$message';
  }

  @override
  String get radioNoChannelList => 'SomaFM 没有返回电台列表';

  @override
  String get trayPlayPause => '播放 / 暂停';

  @override
  String get trayPrevious => '上一首';

  @override
  String get trayNext => '下一首';

  @override
  String get trayShowWindow => '显示主窗口';

  @override
  String get trayQuit => '退出';

  @override
  String get settingsSectionDesktop => '桌面';

  @override
  String get settingsDesktopTitle => '桌面集成';

  @override
  String get settingsDesktopDescription => '让 Tune 在后台继续播放，并成为默认的音频播放器';

  @override
  String get settingsCloseToTray => '关闭窗口时最小化到托盘';

  @override
  String get settingsCloseToTrayHint => '关掉窗口后仍在托盘里继续播放';

  @override
  String get settingsMediaControls => '在系统媒体中心显示 Tune';

  @override
  String get settingsMediaControlsHint => '让媒体键和媒体菜单控制 Tune';

  @override
  String get settingsSetDefaultPlayer => '设为默认播放器';

  @override
  String get settingsDefaultPlayerActive => '已是默认播放器';

  @override
  String get settingsDefaultPlayerDone => 'Tune 已经是默认播放器了';

  @override
  String get settingsDefaultPlayerFailed => '设置失败，请先安装桌面项';

  @override
  String get settingsDefaultPlayerMissingEntry =>
      '还没有安装桌面项，先运行 linux/install-desktop-entry.sh';

  @override
  String get settingsSectionPlayback => '播放';

  @override
  String get settingsPlaybackTitle => '播放行为';

  @override
  String get settingsPlaybackDescription => '决定单击与双击歌曲时会发生什么';

  @override
  String get settingsReplaceQueueOnClick => '单击歌曲时替换播放队列';

  @override
  String get settingsReplaceQueueOnClickHint => '关掉时单击只把这首排进队列并立即播放，队列里的其余曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '双击时只标成喜欢';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '打开时双击只标成喜欢，不打断正在放的曲子；关掉时双击照常播放并标成喜欢';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => '本地优先的桌面音乐播放器';

  @override
  String get appStartFailed => 'Tune 启动失败';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get save => '保存';

  @override
  String get delete => '删除';

  @override
  String get remove => '移除';

  @override
  String get clear => '清空';

  @override
  String get close => '关闭';

  @override
  String get retry => '重试';

  @override
  String get chooseFile => '选择文件';

  @override
  String get unknownError => '未知错误';

  @override
  String get scanNow => '立即扫描';

  @override
  String get search => '搜索';

  @override
  String get scanning => '扫描中';

  @override
  String get about => '关于';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get lightMode => '浅色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get systemMode => '跟随系统';

  @override
  String get libraryTitle => '音乐库';

  @override
  String get librarySubtitle => '本地与在线音源的全部曲目';

  @override
  String get libraryClearSearch => '清除搜索';

  @override
  String get libraryFilterSources => '筛选来源';

  @override
  String get libraryAllSources => '全部来源';

  @override
  String get libraryScanAllSources => '扫描全部音源';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首';
  }

  @override
  String get libraryNoMatchTitle => '没有匹配的歌曲';

  @override
  String get libraryNoMatchSubtitle => '换个关键词，或清除搜索条件';

  @override
  String get librarySourceEmptyTitle => '该来源暂无歌曲';

  @override
  String get librarySourceEmptySubtitle => '切换到全部来源，或重新扫描该音源';

  @override
  String get libraryViewAllSources => '查看全部来源';

  @override
  String get libraryScanningTitle => '正在扫描音乐';

  @override
  String get libraryEmptyTitle => '还没有音乐';

  @override
  String get libraryEmptySubtitle => '扫描本地目录或已启用的在线音源，也可以在设置中调整音源。';

  @override
  String get libraryLoadFailedTitle => '音乐库加载失败';

  @override
  String get libraryAddedToQueue => '已加入播放队列';

  @override
  String libraryScanPaths(String paths) {
    return '扫描目录：$paths';
  }

  @override
  String get libraryAddToQueue => '加入播放队列';

  @override
  String get libraryAddAllToQueue => '将整个列表加入队列';

  @override
  String get queueTitle => '播放队列';

  @override
  String get queueSubtitle => '当前播放顺序';

  @override
  String get queueEmptyTitle => '播放队列是空的';

  @override
  String get queueEmptySubtitle => '从音乐库选择歌曲，或把歌曲加入队列';

  @override
  String get queueGoToLibrary => '去音乐库';

  @override
  String get queueClearTitle => '清空播放队列？';

  @override
  String get queueClearMessage => '当前播放会停止，队列中的歌曲不会从音乐库删除。';

  @override
  String get favoritesTitle => '喜欢';

  @override
  String get favoritesSubtitle => '标了心的曲子都在这里';

  @override
  String get favoritesEmptyTitle => '还没有喜欢的曲子';

  @override
  String get favoritesEmptySubtitle => '在音乐库里点一下红心，喜欢的曲子就会收在这里';

  @override
  String get favoritesGoToLibrary => '去音乐库';

  @override
  String get favoriteAdd => '加入收藏';

  @override
  String get favoriteRemove => '取消收藏';

  @override
  String get playerNowPlaying => '正在播放';

  @override
  String get playerExpandNowPlaying => '展开正在播放';

  @override
  String get playerCollapse => '收起';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暂停';

  @override
  String get playerMute => '静音';

  @override
  String get playerUnmute => '恢复音量';

  @override
  String get playerPlayModeSequential => '列表循环';

  @override
  String get playerPlayModeRepeatOne => '单曲循环';

  @override
  String get playerPlayModeShuffle => '随机播放';

  @override
  String get playerNoSongTitle => '选择一首歌开始';

  @override
  String get playerUnknownArtist => '未知艺术家';

  @override
  String get playerDockReady => 'Tune · 就绪';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '队列 $countString 首';
  }

  @override
  String playerQueuePosition(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return '队列第 $indexString 首';
  }

  @override
  String get nowPlayingEmptyTitle => '还没有播放的曲目';

  @override
  String get nowPlayingEmptySubtitle => '从音乐库里挑一首开始';

  @override
  String get nowPlayingUnnamedTrack => '未命名曲目';

  @override
  String get trackUnknownTitle => '未知歌曲';

  @override
  String playbackFailed(String error) {
    return '播放失败：$error';
  }

  @override
  String playbackPauseFailed(String error) {
    return '暂停失败：$error';
  }

  @override
  String playbackResumeFailed(String error) {
    return '继续播放失败：$error';
  }

  @override
  String playbackSeekFailed(String error) {
    return '跳转失败：$error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return '设置音量失败：$error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return '设置速度失败：$error';
  }

  @override
  String get audioSourceLocal => '本地文件';

  @override
  String audioSourceCaching(int percent) {
    return '缓存中 $percent%';
  }

  @override
  String get audioSourceCached => '已缓存';

  @override
  String get audioSourceFailed => '播放失败';

  @override
  String get routerNotFoundTitle => '页面不存在';

  @override
  String get routerBackToLibrary => '返回音乐库';

  @override
  String get sourcesTitle => '音源';

  @override
  String get sourcesSubtitle => '在线曲库、自建服务与扫描目录';

  @override
  String get sourcesGroupMore => '更多音源';

  @override
  String get sourcesGroupAdded => '我添加的';

  @override
  String get sourcesAdd => '添加音源';

  @override
  String get sourcesAddChooseType => '选择音源类型';

  @override
  String sourcesAddTitle(String name) {
    return '添加 $name';
  }

  @override
  String get sourcesFieldName => '名称';

  @override
  String get sourcesFieldNameHint => '留空则用类型名加序号';

  @override
  String get sourcesDelete => '删除';

  @override
  String sourcesDeleteTitle(String name) {
    return '删除「$name」？';
  }

  @override
  String get sourcesDeleteHint => '这个音源带来的曲目也会一并移除。';

  @override
  String get sourcesMenu => '更多操作';

  @override
  String get sourceDirectUrlName => '直链音频';

  @override
  String get sourceDirectUrlDescription => '一行一条地址，每条变成一首曲目';

  @override
  String get directUrlFieldUrls => '音频地址';

  @override
  String get directUrlFieldUrlsHint => '一行一条地址，例如 https://example.com/song.mp3';

  @override
  String get directUrlHint => '填写音频地址，一行一条';

  @override
  String get sourceM3uName => '播放列表';

  @override
  String get sourceM3uDescription => '读一个 .m3u 或 .pls 播放列表，条目变成曲目';

  @override
  String get m3uFieldPlaylist => '播放列表地址';

  @override
  String get m3uFieldPlaylistHint => '例如 https://example.com/list.m3u';

  @override
  String get m3uHint => '填写播放列表地址';

  @override
  String get m3uEmptyPlaylist => '播放列表是空的';

  @override
  String get m3uNoEntries => '播放列表里没有条目';

  @override
  String get jsonFieldListPath => '列表路径';

  @override
  String get jsonFieldIdPath => '曲目 id 路径';

  @override
  String get jsonFieldTitlePath => '标题路径';

  @override
  String get jsonFieldArtistPath => '歌手路径';

  @override
  String get jsonFieldAlbumPath => '专辑路径';

  @override
  String get jsonFieldCoverPath => '封面路径';

  @override
  String get jsonFieldUrlPath => '播放地址路径';

  @override
  String get jsonFieldDurationPath => '时长路径';

  @override
  String get jsonFieldGenrePath => '流派路径';

  @override
  String get jsonFieldUrlTemplate => '播放地址模板';

  @override
  String get jsonFieldPathHint => '响应里的路径，逐段用点分开，如 data.title';

  @override
  String get jsonFieldUrlTemplateHint => '播放地址的模板，曲目 id 会填进占位处';

  @override
  String get jsonFieldQueryHint => '搜索用的关键词，会替换请求里的占位符';

  @override
  String get jsonFieldUrl => '接口地址';

  @override
  String get jsonFieldUrlHint => '例如 https://example.com/api/search';

  @override
  String get jsonFieldHeaders => '请求头';

  @override
  String get jsonFieldHeadersHint => 'JSON 对象，一行一个键和值';

  @override
  String get jsonInvalidObject => '这段文字不是 JSON 对象';

  @override
  String get jsonInvalidResponse => '接口返回的不是 JSON';

  @override
  String get jsonNoTracks => '接口没有返回曲目';

  @override
  String get jsonNoAddressPath => '没有填写播放地址的路径或模板';

  @override
  String get sourceJsonApiName => 'JSON 接口';

  @override
  String get sourceJsonApiDescription => '把任意 JSON 接口映射成曲目';

  @override
  String get jsonApiHint => '填写接口地址与各字段的路径';

  @override
  String get jsonApiFieldMethod => '请求方式';

  @override
  String get jsonApiFieldMethodHint => '默认 GET；写了请求体就用 POST';

  @override
  String get jsonApiFieldBody => '请求体';

  @override
  String get jsonApiFieldBodyHint => 'POST 时的 JSON 对象；关键词会填进占位符';

  @override
  String get sourcesAutoScan => '启动时自动扫描';

  @override
  String get sourcesAutoScanDescription => '所有已启用音源都会在启动后自动刷新，失败不会影响本地库。';

  @override
  String get sourcesScanMayTakeSeconds => '含远程音源时可能需要数秒';

  @override
  String get sourcesScanCompleted => '扫描已完成';

  @override
  String get sourcesConfigure => '配置';

  @override
  String get sourcesUnsupported => '当前版本不支持该音源';

  @override
  String get sourcesDisabled => '已关闭';

  @override
  String get sourcesNeedsConfiguration => '需要配置';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return '需要配置：$hint';
  }

  @override
  String sourcesLastScan(String time) {
    return '上次扫描 $time';
  }

  @override
  String get sourcesAutoScanLocal => '启动后自动扫描本地目录';

  @override
  String get sourcesWaitingFirstScan => '等待首次扫描';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已扫描 $countString 首 · $time';
  }

  @override
  String get sourcesSkipped => '已跳过';

  @override
  String get sourcesScanFailed => '扫描失败';

  @override
  String sourcesDeleted(String name) {
    return '已删除 $name';
  }

  @override
  String get sourceKindLocal => '本地';

  @override
  String get sourceKindOpenCatalog => '开放曲库';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindCustom => '自定义';

  @override
  String sourcesConfigureTitle(String name) {
    return '配置 $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return '请填写$label';
  }

  @override
  String get sourcesFieldNumeric => '请输入数字';

  @override
  String get fieldQuery => '搜索关键词';

  @override
  String get fieldQueryOptional => '搜索关键词（可选）';

  @override
  String get fieldBrowse => '浏览流';

  @override
  String get fieldBrowseHint => '不填关键词时拉取的内容；填了关键词就按关键词搜';

  @override
  String get browseModeLatest => '最新';

  @override
  String get browseModeCharts => '排行';

  @override
  String get browseModeDaily => '每日推荐';

  @override
  String get fieldLimit => '每次扫描数量';

  @override
  String get fieldLimitFiles => '每次扫描文件数';

  @override
  String get fieldLimitEpisodes => '每次扫描集数';

  @override
  String get fieldLimitStations => '每次扫描电台数';

  @override
  String fieldLimitHint(int count, int max) {
    return '默认 $count，最大 $max';
  }

  @override
  String get fieldServer => '服务器地址';

  @override
  String get fieldUser => '用户名';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldFormat => '音质';

  @override
  String get sourcesNotLoaded => '音源列表尚未加载完成';

  @override
  String get playerLyrics => '歌词';

  @override
  String get lyricsLoading => '正在加载歌词';

  @override
  String get lyricsFailed => '歌词加载失败';

  @override
  String get lyricsMissing => '这首歌没有歌词';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '调整外观、语言和本地音乐库。';

  @override
  String get settingsThemeDescription => '选择界面的明暗气质和显示语言。';

  @override
  String get settingsLanguageDescription => '界面文字和系统菜单语言';

  @override
  String get settingsLibraryDescription => 'Tune 只会在这些目录中查找音频文件。';

  @override
  String get settingsDefaultPath => '默认';

  @override
  String get settingsNoDefaultFolder => '未找到默认音乐目录';

  @override
  String get settingsCustomPath => '自定义';

  @override
  String get settingsAddFolder => '添加文件夹';

  @override
  String get settingsClearLibrary => '清空音乐库';

  @override
  String get settingsScanSafetyNote => '扫描只读取音频文件，不会修改或删除磁盘内容。';

  @override
  String get settingsChooseFolder => '选择音乐文件夹';

  @override
  String get settingsFolderAdded => '已添加扫描目录';

  @override
  String get settingsLibraryFolder => '文件存放位置';

  @override
  String get settingsChangeLibraryFolder => '更换位置';

  @override
  String get settingsUseDefaultLibraryFolder => '用默认位置';

  @override
  String get settingsNoLibraryFolder => '这个平台没有音乐目录';

  @override
  String get settingsScanDone => '扫描完成';

  @override
  String get settingsClearLibraryTitle => '清空音乐库？';

  @override
  String get settingsClearLibraryMessage => '只会清除 Tune 的扫描记录，不会删除磁盘上的音乐文件。';

  @override
  String get settingsLibraryCleared => '音乐库已清空';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 个目录';
  }

  @override
  String get searchOnlineTitle => '在线搜索';

  @override
  String get searchOnlineHint => '搜索在线音源，例如 jazz、钢琴、lo-fi';

  @override
  String get searchOnlineDescription => '搜索已启用的在线音源；结果不会写入音乐库';

  @override
  String get searchOnlinePrompt => '搜索在线音源';

  @override
  String get searchOnlinePromptDescription => '输入关键词后按回车；所有已启用的在线音源会并行搜索。';

  @override
  String get searchNoResults => '没有结果';

  @override
  String get searchNoResultsDescription => '换个关键词再试一次。';

  @override
  String get searchNoMatch => '没有找到匹配的歌曲';

  @override
  String searchSearching(String query) {
    return '正在搜索「$query」';
  }

  @override
  String get searchPlayAll => '播放全部';

  @override
  String get searchAddToQueue => '加入队列';

  @override
  String searchAddedToQueue(String title) {
    return '已加入队列：$title';
  }

  @override
  String get searchNoSourcesEnabled => '没有启用在线音源，请先在设置中开启';

  @override
  String get searchFailedShort => '搜索失败';

  @override
  String searchFailed(String error) {
    return '在线搜索失败：$error';
  }

  @override
  String get scanPreparing => '准备扫描...';

  @override
  String get scanNoEnabledSources => '没有启用的音源';

  @override
  String get scanNoLocalFolders => '没有可扫描的音乐目录';

  @override
  String scanProgressPercent(int percent) {
    return '扫描中 $percent%';
  }

  @override
  String get scanAllSourcesFailed => '所有音源扫描失败';

  @override
  String scanFailed(String error) {
    return '扫描失败：$error';
  }

  @override
  String clearLibraryFailed(String error) {
    return '清空音乐库失败：$error';
  }

  @override
  String get scanNoAudioFiles => '未找到音频文件';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已扫描 $countString 首歌曲';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首歌曲';
  }

  @override
  String get scanSourceNotConfigured => '音源尚未配置';

  @override
  String get scanCachedTooSoon => '已保留缓存，距上次扫描不足间隔';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '已扫描 $sourcesString 个音源，共 $songsString 首歌曲';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '已更新 $songsString 首歌曲，$failedString 个音源失败';
  }

  @override
  String sourceErrorForbidden(int status) {
    return '访问被拒绝（HTTP $status）';
  }

  @override
  String get sourceErrorRateLimited => '请求过于频繁（HTTP 429），请稍后再试';

  @override
  String sourceErrorHttpStatus(int status) {
    return '接口返回 HTTP $status';
  }

  @override
  String get sourceErrorTimeout => '网络连接超时';

  @override
  String get sourceErrorConnection => '无法连接音源服务';

  @override
  String get sourceErrorCertificate => '证书校验失败';

  @override
  String get sourceErrorCancelled => '请求已取消';

  @override
  String sourceErrorNetwork(String message) {
    return '网络请求失败：$message';
  }

  @override
  String get sourceErrorUnsupported => '暂不支持该音源';

  @override
  String sourceErrorScanInterval(String interval) {
    return '距上次扫描不足 $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return '扫描超时（${seconds}s）';
  }

  @override
  String intervalHours(int count) {
    return '$count 小时';
  }

  @override
  String intervalMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get localSourceHint => '在音乐库设置中添加扫描目录';

  @override
  String get localSourceNotConfigured => '未配置本地音乐目录';

  @override
  String get neteaseHint =>
      '填写自建的 NeteaseCloudMusicApi 地址，例如 http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API 地址';

  @override
  String get neteaseFieldQueryHint => '例如 热门、周杰伦';

  @override
  String get neteaseHotKeyword => '热门';

  @override
  String get neteaseEmptyResponse => '网易云 API 返回了空响应';

  @override
  String get neteaseNoStream => '接口未返回可播放地址（可能需要在服务端登录或受版权限制）';

  @override
  String get openverseHint => '填写搜索关键词，例如 piano、ambient 或 jazz';

  @override
  String get openverseFieldQueryHint => '例如 piano、ambient、jazz';

  @override
  String get openverseEmptyResponse => 'Openverse 返回了空响应';

  @override
  String get openverseNoMatch => '没有找到匹配的开放音频';

  @override
  String get sourceLocalName => '本地音乐';

  @override
  String get sourceLocalDescription => '扫描设备上的音乐文件夹';

  @override
  String get sourceOpenverseDescription =>
      '开放版权音频聚合：Jamendo、Freesound、Wikimedia 等';

  @override
  String get sourceOpenverseName => '开放版权聚合';

  @override
  String get sourceJamendoDescription => '独立音乐开放曲库，需要免费 Client ID';

  @override
  String get sourceJamendoName => '独立音乐曲库';

  @override
  String get sourceInternetArchiveDescription => 'Internet Archive 的开放音频收藏';

  @override
  String get sourceInternetArchiveName => '公共领域音频';

  @override
  String get sourceNeteaseName => '网易云音乐 API';

  @override
  String get sourceNeteaseDescription => '连接自建的 NeteaseCloudMusicApi 服务';

  @override
  String get jamendoHint => '在 developer.jamendo.com 免费申请 Client ID 后填入';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint => '在 developer.jamendo.com 免费申请';

  @override
  String get jamendoFieldQueryHint => '例如 jazz、electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo 返回了空响应';

  @override
  String get jamendoNoMatch => '没有找到匹配的 Jamendo 曲目';

  @override
  String get internetArchiveHint =>
      '填写 Internet Archive 收录条件，例如 collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => '收录条件';

  @override
  String get internetArchiveInvalidResponse => 'Internet Archive 返回了无法识别的响应';

  @override
  String get internetArchiveNoMatch => '没有找到可播放的归档音频';

  @override
  String get downloadUnsupportedPlatform => '当前平台没有文件系统，无法缓存下载';

  @override
  String get audioLoadFailed => '音频加载失败';

  @override
  String get audioPathEmpty => '音频文件路径为空';

  @override
  String get ccmixterEmptyResponse => 'ccMixter 返回了空响应';

  @override
  String get ccmixterFieldQuery => '搜索标签';

  @override
  String get ccmixterFieldQueryHint => '例如 jazz、ambient、electro';

  @override
  String get ccmixterHint => '填写 ccMixter 标签，例如 jazz、ambient 或 electro';

  @override
  String get ccmixterNoMatch => '没有找到匹配的 ccMixter 曲目';

  @override
  String get itunesEmptyResponse => 'iTunes API 返回了空响应';

  @override
  String get itunesFieldQueryHint => '例如 jazz、piano、lo-fi';

  @override
  String get itunesHint => '填写搜索关键词，例如 jazz、piano 或 lo-fi';

  @override
  String get itunesNoMatch => '没有找到匹配的 iTunes 曲目';

  @override
  String get podcastRssEmptyFeed => '订阅地址返回了空内容';

  @override
  String get podcastRssFieldFeed => '订阅地址';

  @override
  String get podcastRssFieldFeedHint => '例如 https://example.com/podcast.xml';

  @override
  String get podcastRssHint => '填写播客订阅地址（RSS）';

  @override
  String podcastRssInvalidFeed(String error) {
    return '订阅地址返回了无法解析的 XML：$error';
  }

  @override
  String get podcastRssNoMatch => '订阅源里没有可播放的单集';

  @override
  String get sourceCcmixterDescription => 'Creative Commons 混音与开放音乐曲库';

  @override
  String get sourceCcmixterName => '共享混音素材';

  @override
  String get sourceItunesDescription => 'iTunes 目录的 30 秒试听片段';

  @override
  String get sourceItunesName => '商店试听片段';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS 播客订阅变成可播放的单集';

  @override
  String get sourcePodcastRssName => '播客订阅';

  @override
  String get sourceSubsonicDescription => '连接自建的 Navidrome / Subsonic 音乐库';

  @override
  String get sourceSubsonicName => '自建音乐库';

  @override
  String get subsonicAuthFailed => '无法连接音乐服务器，请检查地址与账号';

  @override
  String get subsonicEmptyResponse => '音乐服务器返回了空响应';

  @override
  String subsonicError(String error) {
    return '音乐服务器返回错误：$error';
  }

  @override
  String get subsonicFieldPasswordHint => '用于计算访问令牌，不会明文发送';

  @override
  String get subsonicFieldQueryHint => '例如 jazz、piano';

  @override
  String get subsonicFieldServerHint => '例如 http://localhost:4533';

  @override
  String get subsonicFieldUserHint => '自建音乐库的登录用户名';

  @override
  String get subsonicHint => '填写自建音乐库的地址与账号，例如 http://localhost:4533';

  @override
  String get subsonicNoMatch => '没有找到匹配的曲目';

  @override
  String get sourceAudiusDescription => 'Audius 上音乐人直发的完整曲目';

  @override
  String get sourceAudiusName => '音乐人直发';

  @override
  String get audiusHint => '填写搜索关键词，例如 jazz、ambient 或 electronic';

  @override
  String get audiusFieldQueryHint => '例如 jazz、ambient、electronic';

  @override
  String get audiusEmptyResponse => 'Audius 返回了空响应';

  @override
  String get audiusNoMatch => '没有找到匹配的 Audius 曲目';

  @override
  String get sourceRadioDescription => '公开网络电台的直播流';

  @override
  String get radioHint => '选择电台目录，关键词可进一步过滤';

  @override
  String get radioFieldProvider => '电台目录';

  @override
  String get radioFieldProviderHint =>
      '全部目录、Radio Browser、SomaFM 或 Radio Paradise';

  @override
  String get radioProviderAll => '全部目录';

  @override
  String get radioFieldQuery => '电台关键词';

  @override
  String get radioFieldQueryHint => '例如 jazz、ambient 或 SomaFM';

  @override
  String get radioNoMatch => '没有找到匹配的电台';

  @override
  String get sourceWikimediaDescription => 'Wikimedia Commons 的开放音频';

  @override
  String get sourceWikimediaName => '自由授权媒体';

  @override
  String get wikimediaHint => '填写搜索关键词，例如 piano、lecture 或 birdsong';

  @override
  String get wikimediaFieldQueryHint => '例如 piano、lecture、birdsong';

  @override
  String get wikimediaEmptyResponse => 'Wikimedia Commons 返回了空响应';

  @override
  String get wikimediaNoMatch => '没有找到可播放的共享音频';

  @override
  String get sourceJellyfinDescription => '连接自建的 Jellyfin 媒体库';

  @override
  String get sourceJellyfinName => '自建媒体库';

  @override
  String get jellyfinHint => '填写自建 Jellyfin 的地址与账号';

  @override
  String get jellyfinFieldServerHint => '例如 http://localhost:8096';

  @override
  String get jellyfinFieldUserHint => 'Jellyfin 的登录用户名';

  @override
  String get jellyfinFieldPasswordHint => '用于换取访问令牌';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin 返回了空响应';

  @override
  String get jellyfinAuthFailed => '无法连接 Jellyfin 服务器，请检查地址与账号';

  @override
  String get audioSourceStreaming => '网络';

  @override
  String get playerLiveBadge => '直播中';

  @override
  String get nowPlayingLiveStream => '直播流，没有固定时长';

  @override
  String get nowPlayingDetails => '曲目信息';

  @override
  String get nowPlayingDetailAlbum => '专辑';

  @override
  String get nowPlayingDetailYear => '年份';

  @override
  String get nowPlayingDetailGenre => '流派';

  @override
  String get nowPlayingDetailBitrate => '码率';

  @override
  String get nowPlayingDetailSampleRate => '采样率';

  @override
  String get nowPlayingDetailTrack => '音轨';

  @override
  String get nowPlayingDetailDisc => '碟片';

  @override
  String get nowPlayingDetailLicense => '许可';

  @override
  String get nowPlayingDetailSource => '来源';

  @override
  String get nowPlayingDetailNowPlaying => '正在播放';

  @override
  String get genreRock => '摇滚';

  @override
  String get genrePop => '流行';

  @override
  String get genreJazz => '爵士';

  @override
  String get genreClassical => '古典';

  @override
  String get genreElectronic => '电子';

  @override
  String get genreHipHop => '说唱';

  @override
  String get genreBlues => '蓝调';

  @override
  String get genreCountry => '乡村';

  @override
  String get genreFolk => '民谣';

  @override
  String get genreMetal => '金属';

  @override
  String get genrePunk => '朋克';

  @override
  String get genreReggae => '雷鬼';

  @override
  String get genreLatin => '拉丁';

  @override
  String get genreDance => '舞曲';

  @override
  String get genreAlternative => '另类';

  @override
  String get genreIndie => '独立';

  @override
  String get genreAmbient => '环境音乐';

  @override
  String get genreHouse => '浩室';

  @override
  String get genreFunk => '放克';

  @override
  String get genreGospel => '福音';

  @override
  String get genreWorld => '世界音乐';

  @override
  String get genreNewAge => '新世纪';

  @override
  String get genreSoundtrack => '原声';

  @override
  String get genreOpera => '歌剧';

  @override
  String get genreExperimental => '实验';

  @override
  String get genreMusicWord => '音乐';

  @override
  String get genreMusicWordShort => '乐';

  @override
  String get trackFactSource => '来源';

  @override
  String get trackFactStorage => '位置';

  @override
  String get trackFactStorageLocal => '本地';

  @override
  String get trackFactStorageRemote => '在线';

  @override
  String get trackFactFormat => '格式';

  @override
  String get trackFactQuality => '音质';

  @override
  String get trackFactQualityLossless => '无损';

  @override
  String get trackFactQualityHiRes => '高解析';

  @override
  String get trackFactSize => '大小';

  @override
  String get trackFactLyrics => '歌词';

  @override
  String get trackFactLyricsIncluded => '已包含';

  @override
  String get trackFactPerformers => '演奏者';

  @override
  String get trackFactAdded => '添加时间';

  @override
  String get trackFactDescription => '简介';

  @override
  String get trackFactLive => '直播';

  @override
  String get trackFactPath => '文件路径';

  @override
  String get trackFactAddress => '地址';

  @override
  String get trackDetailsTooltip => '查看详情';

  @override
  String get trackDetailsCopyPath => '复制路径';

  @override
  String get trackDetailsCopyAddress => '复制地址';

  @override
  String get trackDetailsCopied => '已复制到剪贴板';

  @override
  String get trackFactDuration => '时长';

  @override
  String get trackFactSourceId => '来源编号';

  @override
  String get trackFactMediaType => '媒体类型';

  @override
  String get trackFactCover => '封面';

  @override
  String get trackFactIdentity => '身份';

  @override
  String get trackFactHeaders => '请求头';

  @override
  String get trackFactRawData => '原始数据';

  @override
  String get trackDetailsCopyCover => '复制封面';

  @override
  String get trackDetailsCopyIdentity => '复制身份';

  @override
  String get sourceStatusEnabled => '已启用';

  @override
  String get sourceStatusOff => '已关闭';

  @override
  String get sourceStatusNeedsSetup => '待配置';

  @override
  String get sourceStatusFailed => '失败';

  @override
  String get sourceStatusSkipped => '已跳过';

  @override
  String get sourceStatusScanned => '已扫描';

  @override
  String get sourceStatusTracks => '曲目';

  @override
  String get sourceStatusLastScan => '上次扫描';

  @override
  String get sourceStatusUnsupported => '不支持';

  @override
  String get sourceStatusWaiting => '待扫描';

  @override
  String get jamendoFieldFormatHint => '默认 192 kbps';

  @override
  String get subsonicFieldFormatHint => '默认原始音质';

  @override
  String get subsonicFormatOriginal => '原始音质';

  @override
  String get sourceRadioName => '网络电台';

  @override
  String get settingsEyebrow => '偏好';

  @override
  String get settingsSectionInterface => '界面';

  @override
  String get settingsLocalFirst => '本地优先';

  @override
  String get libraryEyebrow => '收藏';

  @override
  String get sourcesEyebrow => '连接';

  @override
  String get sidebarCollect => '收藏';

  @override
  String get sidebarConnect => '连接';

  @override
  String get sidebarLocalOnline => '本地 + 在线';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name 桌面版 · $version';
  }

  @override
  String searchSourceError(String source, String message) {
    return '$source：$message';
  }

  @override
  String get radioNoChannelList => 'SomaFM 没有返回电台列表';

  @override
  String get trayPlayPause => '播放 / 暂停';

  @override
  String get trayPrevious => '上一首';

  @override
  String get trayNext => '下一首';

  @override
  String get trayShowWindow => '显示主窗口';

  @override
  String get trayQuit => '退出';

  @override
  String get settingsSectionDesktop => '桌面';

  @override
  String get settingsDesktopTitle => '桌面集成';

  @override
  String get settingsDesktopDescription => '让 Tune 在后台继续播放，并成为默认的音频播放器';

  @override
  String get settingsCloseToTray => '关闭窗口时最小化到托盘';

  @override
  String get settingsCloseToTrayHint => '关掉窗口后仍在托盘里继续播放';

  @override
  String get settingsMediaControls => '在系统媒体中心显示 Tune';

  @override
  String get settingsMediaControlsHint => '让媒体键和媒体菜单控制 Tune';

  @override
  String get settingsSetDefaultPlayer => '设为默认播放器';

  @override
  String get settingsDefaultPlayerActive => '已是默认播放器';

  @override
  String get settingsDefaultPlayerDone => 'Tune 已经是默认播放器了';

  @override
  String get settingsDefaultPlayerFailed => '设置失败，请先安装桌面项';

  @override
  String get settingsDefaultPlayerMissingEntry =>
      '还没有安装桌面项，先运行 linux/install-desktop-entry.sh';

  @override
  String get settingsSectionPlayback => '播放';

  @override
  String get settingsPlaybackTitle => '播放行为';

  @override
  String get settingsPlaybackDescription => '决定单击与双击歌曲时会发生什么';

  @override
  String get settingsReplaceQueueOnClick => '单击歌曲时替换播放队列';

  @override
  String get settingsReplaceQueueOnClickHint => '关掉时单击只把这首排进队列并立即播放，队列里的其余曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '双击时只标成喜欢';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '打开时双击只标成喜欢，不打断正在放的曲子；关掉时双击照常播放并标成喜欢';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appName => 'Tune';

  @override
  String get appTagline => '本機優先的桌面音樂播放器';

  @override
  String get appStartFailed => 'Tune 啟動失敗';

  @override
  String get cancel => '取消';

  @override
  String get ok => '確定';

  @override
  String get save => '儲存';

  @override
  String get delete => '刪除';

  @override
  String get remove => '移除';

  @override
  String get clear => '清空';

  @override
  String get close => '關閉';

  @override
  String get retry => '重試';

  @override
  String get chooseFile => '選擇檔案';

  @override
  String get unknownError => '未知錯誤';

  @override
  String get scanNow => '立即掃描';

  @override
  String get search => '搜尋';

  @override
  String get scanning => '掃描中';

  @override
  String get about => '關於';

  @override
  String get language => '語言';

  @override
  String get theme => '主題';

  @override
  String get lightMode => '淺色模式';

  @override
  String get darkMode => '深色模式';

  @override
  String get systemMode => '跟隨系統';

  @override
  String get libraryTitle => '音樂庫';

  @override
  String get librarySubtitle => '本地與線上音源的全部曲目';

  @override
  String get libraryClearSearch => '清除搜尋';

  @override
  String get libraryFilterSources => '篩選來源';

  @override
  String get libraryAllSources => '全部來源';

  @override
  String get libraryScanAllSources => '掃描全部音源';

  @override
  String libraryTrackCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首';
  }

  @override
  String get libraryNoMatchTitle => '沒有符合的歌曲';

  @override
  String get libraryNoMatchSubtitle => '換個關鍵字，或清除搜尋條件';

  @override
  String get librarySourceEmptyTitle => '該來源暫無歌曲';

  @override
  String get librarySourceEmptySubtitle => '切換到全部來源，或重新掃描該音源';

  @override
  String get libraryViewAllSources => '查看全部來源';

  @override
  String get libraryScanningTitle => '正在掃描音樂';

  @override
  String get libraryEmptyTitle => '還沒有音樂';

  @override
  String get libraryEmptySubtitle => '掃描本地目錄或已啟用的線上音源，也可以在設定中調整音源。';

  @override
  String get libraryLoadFailedTitle => '音樂庫載入失敗';

  @override
  String get libraryAddedToQueue => '已加入播放佇列';

  @override
  String libraryScanPaths(String paths) {
    return '掃描目錄：$paths';
  }

  @override
  String get libraryAddToQueue => '加入播放佇列';

  @override
  String get libraryAddAllToQueue => '將整個清單加入佇列';

  @override
  String get queueTitle => '播放佇列';

  @override
  String get queueSubtitle => '目前播放順序';

  @override
  String get queueEmptyTitle => '播放佇列是空的';

  @override
  String get queueEmptySubtitle => '從音樂庫選擇歌曲，或把歌曲加入佇列';

  @override
  String get queueGoToLibrary => '去音樂庫';

  @override
  String get queueClearTitle => '清空播放佇列？';

  @override
  String get queueClearMessage => '目前播放會停止，佇列中的歌曲不會從音樂庫刪除。';

  @override
  String get favoritesTitle => '喜歡';

  @override
  String get favoritesSubtitle => '標了心的曲子都在這裡';

  @override
  String get favoritesEmptyTitle => '還沒有喜歡的曲子';

  @override
  String get favoritesEmptySubtitle => '在音樂庫裡點一下紅心，喜歡的曲子就會收在這裡';

  @override
  String get favoritesGoToLibrary => '去音樂庫';

  @override
  String get favoriteAdd => '加入收藏';

  @override
  String get favoriteRemove => '取消收藏';

  @override
  String get playerNowPlaying => '正在播放';

  @override
  String get playerExpandNowPlaying => '展開正在播放';

  @override
  String get playerCollapse => '收起';

  @override
  String get playerPrevious => '上一首';

  @override
  String get playerNext => '下一首';

  @override
  String get playerPlay => '播放';

  @override
  String get playerPause => '暫停';

  @override
  String get playerMute => '靜音';

  @override
  String get playerUnmute => '恢復音量';

  @override
  String get playerPlayModeSequential => '清單循環';

  @override
  String get playerPlayModeRepeatOne => '單曲循環';

  @override
  String get playerPlayModeShuffle => '隨機播放';

  @override
  String get playerNoSongTitle => '選擇一首歌開始';

  @override
  String get playerUnknownArtist => '未知藝術家';

  @override
  String get playerDockReady => 'Tune · 就緒';

  @override
  String playerQueueSummary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '佇列 $countString 首';
  }

  @override
  String playerQueuePosition(int index) {
    final intl.NumberFormat indexNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String indexString = indexNumberFormat.format(index);

    return '佇列第 $indexString 首';
  }

  @override
  String get nowPlayingEmptyTitle => '還沒有播放的曲目';

  @override
  String get nowPlayingEmptySubtitle => '從音樂庫裡挑一首開始';

  @override
  String get nowPlayingUnnamedTrack => '未命名曲目';

  @override
  String get trackUnknownTitle => '未知歌曲';

  @override
  String playbackFailed(String error) {
    return '播放失敗：$error';
  }

  @override
  String playbackPauseFailed(String error) {
    return '暫停失敗：$error';
  }

  @override
  String playbackResumeFailed(String error) {
    return '繼續播放失敗：$error';
  }

  @override
  String playbackSeekFailed(String error) {
    return '跳轉失敗：$error';
  }

  @override
  String playbackVolumeFailed(String error) {
    return '設定音量失敗：$error';
  }

  @override
  String playbackSpeedFailed(String error) {
    return '設定速度失敗：$error';
  }

  @override
  String get audioSourceLocal => '本機檔案';

  @override
  String audioSourceCaching(int percent) {
    return '快取中 $percent%';
  }

  @override
  String get audioSourceCached => '已快取';

  @override
  String get audioSourceFailed => '播放失敗';

  @override
  String get routerNotFoundTitle => '頁面不存在';

  @override
  String get routerBackToLibrary => '返回音樂庫';

  @override
  String get sourcesTitle => '音源';

  @override
  String get sourcesSubtitle => '線上曲庫、自建服務與掃描目錄';

  @override
  String get sourcesGroupMore => '更多音源';

  @override
  String get sourcesGroupAdded => '我新增的';

  @override
  String get sourcesAdd => '新增音源';

  @override
  String get sourcesAddChooseType => '選擇音源類型';

  @override
  String sourcesAddTitle(String name) {
    return '新增 $name';
  }

  @override
  String get sourcesFieldName => '名稱';

  @override
  String get sourcesFieldNameHint => '留空則用類型名加序號';

  @override
  String get sourcesDelete => '刪除';

  @override
  String sourcesDeleteTitle(String name) {
    return '刪除「$name」？';
  }

  @override
  String get sourcesDeleteHint => '這個音源帶來的曲目也會一併移除。';

  @override
  String get sourcesMenu => '更多操作';

  @override
  String get sourceDirectUrlName => '直鏈音訊';

  @override
  String get sourceDirectUrlDescription => '一行一條位址，每條變成一首曲目';

  @override
  String get directUrlFieldUrls => '音訊位址';

  @override
  String get directUrlFieldUrlsHint => '一行一條位址，例如 https://example.com/song.mp3';

  @override
  String get directUrlHint => '填寫音訊位址，一行一條';

  @override
  String get sourceM3uName => '播放清單';

  @override
  String get sourceM3uDescription => '讀一個 .m3u 或 .pls 播放清單，條目變成曲目';

  @override
  String get m3uFieldPlaylist => '播放清單網址';

  @override
  String get m3uFieldPlaylistHint => '例如 https://example.com/list.m3u';

  @override
  String get m3uHint => '填寫播放清單網址';

  @override
  String get m3uEmptyPlaylist => '播放清單是空的';

  @override
  String get m3uNoEntries => '播放清單裡沒有條目';

  @override
  String get jsonFieldListPath => '清單路徑';

  @override
  String get jsonFieldIdPath => '曲目 id 路徑';

  @override
  String get jsonFieldTitlePath => '標題路徑';

  @override
  String get jsonFieldArtistPath => '歌手路徑';

  @override
  String get jsonFieldAlbumPath => '專輯路徑';

  @override
  String get jsonFieldCoverPath => '封面路徑';

  @override
  String get jsonFieldUrlPath => '播放網址路徑';

  @override
  String get jsonFieldDurationPath => '時長路徑';

  @override
  String get jsonFieldGenrePath => '類型路徑';

  @override
  String get jsonFieldUrlTemplate => '播放網址範本';

  @override
  String get jsonFieldPathHint => '回應裡的路徑，逐段用點分開，如 data.title';

  @override
  String get jsonFieldUrlTemplateHint => '播放網址的範本，曲目 id 會填進佔位處';

  @override
  String get jsonFieldQueryHint => '搜尋用的關鍵字，會替換請求裡的佔位符';

  @override
  String get jsonFieldUrl => '介面網址';

  @override
  String get jsonFieldUrlHint => '例如 https://example.com/api/search';

  @override
  String get jsonFieldHeaders => '請求標頭';

  @override
  String get jsonFieldHeadersHint => 'JSON 物件，一行一個鍵和值';

  @override
  String get jsonInvalidObject => '這段文字不是 JSON 物件';

  @override
  String get jsonInvalidResponse => '介面回應的不是 JSON';

  @override
  String get jsonNoTracks => '介面沒有回傳曲目';

  @override
  String get jsonNoAddressPath => '沒有填寫播放網址的路徑或範本';

  @override
  String get sourceJsonApiName => 'JSON 介面';

  @override
  String get sourceJsonApiDescription => '把任意 JSON 介面對應成曲目';

  @override
  String get jsonApiHint => '填寫介面網址與各欄位的路徑';

  @override
  String get jsonApiFieldMethod => '請求方式';

  @override
  String get jsonApiFieldMethodHint => '預設 GET；寫了請求體就用 POST';

  @override
  String get jsonApiFieldBody => '請求體';

  @override
  String get jsonApiFieldBodyHint => 'POST 時的 JSON 物件；關鍵字會填進佔位符';

  @override
  String get sourcesAutoScan => '啟動時自動掃描';

  @override
  String get sourcesAutoScanDescription => '所有已啟用音源都會在啟動後自動重新整理，失敗不會影響本機曲庫。';

  @override
  String get sourcesScanMayTakeSeconds => '含遠端音源時可能需要數秒';

  @override
  String get sourcesScanCompleted => '掃描已完成';

  @override
  String get sourcesConfigure => '設定';

  @override
  String get sourcesUnsupported => '目前版本不支援該音源';

  @override
  String get sourcesDisabled => '已關閉';

  @override
  String get sourcesNeedsConfiguration => '需要設定';

  @override
  String sourcesNeedsConfigurationHint(String hint) {
    return '需要設定：$hint';
  }

  @override
  String sourcesLastScan(String time) {
    return '上次掃描 $time';
  }

  @override
  String get sourcesAutoScanLocal => '啟動後自動掃描本機目錄';

  @override
  String get sourcesWaitingFirstScan => '等待首次掃描';

  @override
  String sourcesScannedCount(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已掃描 $countString 首 · $time';
  }

  @override
  String get sourcesSkipped => '已跳過';

  @override
  String get sourcesScanFailed => '掃描失敗';

  @override
  String sourcesDeleted(String name) {
    return '已刪除 $name';
  }

  @override
  String get sourceKindLocal => '本機';

  @override
  String get sourceKindOpenCatalog => '開放曲庫';

  @override
  String get sourceKindOpenApi => 'API';

  @override
  String get sourceKindCustom => '自訂';

  @override
  String sourcesConfigureTitle(String name) {
    return '設定 $name';
  }

  @override
  String sourcesFieldRequired(String label) {
    return '請填寫$label';
  }

  @override
  String get sourcesFieldNumeric => '請輸入數字';

  @override
  String get fieldQuery => '搜尋關鍵字';

  @override
  String get fieldQueryOptional => '搜尋關鍵字（可選）';

  @override
  String get fieldBrowse => '瀏覽流';

  @override
  String get fieldBrowseHint => '不填關鍵字時拉取的內容；填了關鍵字就按關鍵字搜';

  @override
  String get browseModeLatest => '最新';

  @override
  String get browseModeCharts => '排行';

  @override
  String get browseModeDaily => '每日推薦';

  @override
  String get fieldLimit => '每次掃描數量';

  @override
  String get fieldLimitFiles => '每次掃描檔案數';

  @override
  String get fieldLimitEpisodes => '每次掃描集數';

  @override
  String get fieldLimitStations => '每次掃描電台數';

  @override
  String fieldLimitHint(int count, int max) {
    return '預設 $count，最多 $max';
  }

  @override
  String get fieldServer => '伺服器位址';

  @override
  String get fieldUser => '使用者名稱';

  @override
  String get fieldPassword => '密碼';

  @override
  String get fieldFormat => '音質';

  @override
  String get sourcesNotLoaded => '音源列表尚未載入完成';

  @override
  String get playerLyrics => '歌詞';

  @override
  String get lyricsLoading => '正在載入歌詞';

  @override
  String get lyricsFailed => '歌詞載入失敗';

  @override
  String get lyricsMissing => '這首歌沒有歌詞';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '調整外觀、語言和本機音樂庫。';

  @override
  String get settingsThemeDescription => '選擇介面的明暗風格和顯示語言。';

  @override
  String get settingsLanguageDescription => '介面文字和系統選單語言';

  @override
  String get settingsLibraryDescription => 'Tune 只會在這些目錄中尋找音訊檔案。';

  @override
  String get settingsDefaultPath => '預設';

  @override
  String get settingsNoDefaultFolder => '找不到預設音樂目錄';

  @override
  String get settingsCustomPath => '自訂';

  @override
  String get settingsAddFolder => '新增資料夾';

  @override
  String get settingsClearLibrary => '清空音樂庫';

  @override
  String get settingsScanSafetyNote => '掃描只讀取音訊檔案，不會修改或刪除磁碟內容。';

  @override
  String get settingsChooseFolder => '選擇音樂資料夾';

  @override
  String get settingsFolderAdded => '已新增掃描目錄';

  @override
  String get settingsLibraryFolder => '檔案存放位置';

  @override
  String get settingsChangeLibraryFolder => '更換位置';

  @override
  String get settingsUseDefaultLibraryFolder => '用預設位置';

  @override
  String get settingsNoLibraryFolder => '這個平台沒有音樂目錄';

  @override
  String get settingsScanDone => '掃描完成';

  @override
  String get settingsClearLibraryTitle => '清空音樂庫？';

  @override
  String get settingsClearLibraryMessage => '只會清除 Tune 的掃描記錄，不會刪除磁碟上的音樂檔案。';

  @override
  String get settingsLibraryCleared => '音樂庫已清空';

  @override
  String settingsPathsCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 個目錄';
  }

  @override
  String get searchOnlineTitle => '線上搜尋';

  @override
  String get searchOnlineHint => '搜尋線上音源，例如 jazz、鋼琴、lo-fi';

  @override
  String get searchOnlineDescription => '搜尋已啟用的線上音源；結果不會寫入音樂庫';

  @override
  String get searchOnlinePrompt => '搜尋線上音源';

  @override
  String get searchOnlinePromptDescription => '輸入關鍵字後按 Enter；所有已啟用的線上音源會同時搜尋。';

  @override
  String get searchNoResults => '沒有結果';

  @override
  String get searchNoResultsDescription => '換個關鍵字再試一次。';

  @override
  String get searchNoMatch => '沒有找到符合的歌曲';

  @override
  String searchSearching(String query) {
    return '正在搜尋「$query」';
  }

  @override
  String get searchPlayAll => '播放全部';

  @override
  String get searchAddToQueue => '加入佇列';

  @override
  String searchAddedToQueue(String title) {
    return '已加入佇列：$title';
  }

  @override
  String get searchNoSourcesEnabled => '沒有啟用線上音源，請先在設定中開啟';

  @override
  String get searchFailedShort => '搜尋失敗';

  @override
  String searchFailed(String error) {
    return '線上搜尋失敗：$error';
  }

  @override
  String get scanPreparing => '準備掃描...';

  @override
  String get scanNoEnabledSources => '沒有啟用的音源';

  @override
  String get scanNoLocalFolders => '沒有可掃描的音樂目錄';

  @override
  String scanProgressPercent(int percent) {
    return '掃描中 $percent%';
  }

  @override
  String get scanAllSourcesFailed => '所有音源掃描失敗';

  @override
  String scanFailed(String error) {
    return '掃描失敗：$error';
  }

  @override
  String clearLibraryFailed(String error) {
    return '清空音樂庫失敗：$error';
  }

  @override
  String get scanNoAudioFiles => '找不到音訊檔案';

  @override
  String scanSongCount(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已掃描 $countString 首歌曲';
  }

  @override
  String scanSongCountShort(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString 首歌曲';
  }

  @override
  String get scanSourceNotConfigured => '音源尚未設定';

  @override
  String get scanCachedTooSoon => '已保留快取，距上次掃描不足間隔';

  @override
  String scanSummary(int songs, int sources) {
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '已掃描 $sourcesString 個音源，共 $songsString 首歌曲';
  }

  @override
  String scanUpdated(int failed, int songs) {
    final intl.NumberFormat failedNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String failedString = failedNumberFormat.format(failed);
    final intl.NumberFormat songsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String songsString = songsNumberFormat.format(songs);

    return '已更新 $songsString 首歌曲，$failedString 個音源失敗';
  }

  @override
  String sourceErrorForbidden(int status) {
    return '存取被拒絕（HTTP $status）';
  }

  @override
  String get sourceErrorRateLimited => '請求過於頻繁（HTTP 429），請稍後再試';

  @override
  String sourceErrorHttpStatus(int status) {
    return '介面回傳 HTTP $status';
  }

  @override
  String get sourceErrorTimeout => '網路連線逾時';

  @override
  String get sourceErrorConnection => '無法連線到音源服務';

  @override
  String get sourceErrorCertificate => '憑證驗證失敗';

  @override
  String get sourceErrorCancelled => '請求已取消';

  @override
  String sourceErrorNetwork(String message) {
    return '網路請求失敗：$message';
  }

  @override
  String get sourceErrorUnsupported => '暫不支援該音源';

  @override
  String sourceErrorScanInterval(String interval) {
    return '距上次掃描不足 $interval';
  }

  @override
  String sourceErrorScanTimeout(int seconds) {
    return '掃描逾時（${seconds}s）';
  }

  @override
  String intervalHours(int count) {
    return '$count 小時';
  }

  @override
  String intervalMinutes(int count) {
    return '$count 分鐘';
  }

  @override
  String get localSourceHint => '在音樂庫設定中新增掃描目錄';

  @override
  String get localSourceNotConfigured => '未設定本機音樂目錄';

  @override
  String get neteaseHint =>
      '填寫自建的 NeteaseCloudMusicApi 位址，例如 http://localhost:3000';

  @override
  String get neteaseFieldApi => 'API 位址';

  @override
  String get neteaseFieldQueryHint => '例如 熱門、周杰倫';

  @override
  String get neteaseHotKeyword => '熱門';

  @override
  String get neteaseEmptyResponse => '網易雲 API 回傳了空回應';

  @override
  String get neteaseNoStream => '介面未回傳可播放網址（可能需要在伺服器端登入或受版權限制）';

  @override
  String get openverseHint => '填寫搜尋關鍵字，例如 piano、ambient 或 jazz';

  @override
  String get openverseFieldQueryHint => '例如 piano、ambient、jazz';

  @override
  String get openverseEmptyResponse => 'Openverse 回傳了空回應';

  @override
  String get openverseNoMatch => '沒有找到符合的開放音訊';

  @override
  String get sourceLocalName => '本機音樂';

  @override
  String get sourceLocalDescription => '掃描裝置上的音樂檔案夾';

  @override
  String get sourceOpenverseDescription =>
      '開放版權音頻聚合：Jamendo、Freesound、Wikimedia 等';

  @override
  String get sourceOpenverseName => '開放版權聚合';

  @override
  String get sourceJamendoDescription => '獨立音樂開放曲庫，需要免費 Client ID';

  @override
  String get sourceJamendoName => '獨立音樂曲庫';

  @override
  String get sourceInternetArchiveDescription => 'Internet Archive 的開放音頻收藏';

  @override
  String get sourceInternetArchiveName => '公共領域音頻';

  @override
  String get sourceNeteaseName => '網易雲音樂 API';

  @override
  String get sourceNeteaseDescription => '連結自建的 NeteaseCloudMusicApi 服務';

  @override
  String get jamendoHint => '在 developer.jamendo.com 免費申請 Client ID 後填入';

  @override
  String get jamendoFieldClientId => 'Client ID';

  @override
  String get jamendoFieldClientIdHint => '在 developer.jamendo.com 免費申請';

  @override
  String get jamendoFieldQueryHint => '例如 jazz、electronic';

  @override
  String get jamendoEmptyResponse => 'Jamendo 回傳了空回應';

  @override
  String get jamendoNoMatch => '沒有找到符合的 Jamendo 曲目';

  @override
  String get internetArchiveHint =>
      '填寫 Internet Archive 收錄條件，例如 collection:netlabels AND mediatype:audio';

  @override
  String get internetArchiveFieldQuery => '收錄條件';

  @override
  String get internetArchiveInvalidResponse => 'Internet Archive 回傳了無法識別的回應';

  @override
  String get internetArchiveNoMatch => '沒有找到可播放的归檔音訊';

  @override
  String get downloadUnsupportedPlatform => '目前平台沒有檔案系統，無法待處下載';

  @override
  String get audioLoadFailed => '音訊載入失敗';

  @override
  String get audioPathEmpty => '音訊檔案路徑為空';

  @override
  String get ccmixterEmptyResponse => 'ccMixter 回傳了空回應';

  @override
  String get ccmixterFieldQuery => '搜尋標籤';

  @override
  String get ccmixterFieldQueryHint => '例如 jazz、ambient、electro';

  @override
  String get ccmixterHint => '填寫 ccMixter 標籤，例如 jazz、ambient 或 electro';

  @override
  String get ccmixterNoMatch => '找不到符合的 ccMixter 曲目';

  @override
  String get itunesEmptyResponse => 'iTunes API 回傳了空回應';

  @override
  String get itunesFieldQueryHint => '例如 jazz、piano、lo-fi';

  @override
  String get itunesHint => '填寫搜尋關鍵字，例如 jazz、piano 或 lo-fi';

  @override
  String get itunesNoMatch => '找不到符合的 iTunes 曲目';

  @override
  String get podcastRssEmptyFeed => '訂閱網址回傳了空內容';

  @override
  String get podcastRssFieldFeed => '訂閱網址';

  @override
  String get podcastRssFieldFeedHint => '例如 https://example.com/podcast.xml';

  @override
  String get podcastRssHint => '填寫 podcast 訂閱網址（RSS）';

  @override
  String podcastRssInvalidFeed(String error) {
    return '訂閱網址回傳了無法解析的 XML：$error';
  }

  @override
  String get podcastRssNoMatch => '訂閱來源裡沒有可播放的單集';

  @override
  String get sourceCcmixterDescription => 'Creative Commons 混音與開放音樂曲庫';

  @override
  String get sourceCcmixterName => '共享混音素材';

  @override
  String get sourceItunesDescription => 'iTunes 目錄的 30 秒試聽片段';

  @override
  String get sourceItunesName => '商店試聽片段';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS podcast 訂閱變成可播放的單集';

  @override
  String get sourcePodcastRssName => 'Podcast 訂閱';

  @override
  String get sourceSubsonicDescription => '連線自建的 Navidrome / Subsonic 音樂庫';

  @override
  String get sourceSubsonicName => '自建音樂庫';

  @override
  String get subsonicAuthFailed => '無法連線音樂伺服器，請檢查位址與帳號';

  @override
  String get subsonicEmptyResponse => '音樂伺服器回傳了空回應';

  @override
  String subsonicError(String error) {
    return '音樂伺服器回傳錯誤：$error';
  }

  @override
  String get subsonicFieldPasswordHint => '用於計算存取權杖，不會明文傳送';

  @override
  String get subsonicFieldQueryHint => '例如 jazz、piano';

  @override
  String get subsonicFieldServerHint => '例如 http://localhost:4533';

  @override
  String get subsonicFieldUserHint => '自建音樂庫的登入使用者名稱';

  @override
  String get subsonicHint => '填寫自建音樂庫的位址與帳號，例如 http://localhost:4533';

  @override
  String get subsonicNoMatch => '找不到符合的曲目';

  @override
  String get sourceAudiusDescription => 'Audius 上音樂人直發的完整曲目';

  @override
  String get sourceAudiusName => '音樂人直發';

  @override
  String get audiusHint => '填寫搜尋關鍵字，例如 jazz、ambient 或 electronic';

  @override
  String get audiusFieldQueryHint => '例如 jazz、ambient、electronic';

  @override
  String get audiusEmptyResponse => 'Audius 回傳了空回應';

  @override
  String get audiusNoMatch => '找不到符合的 Audius 曲目';

  @override
  String get sourceRadioDescription => '公開網路電台的直播串流';

  @override
  String get radioHint => '選擇電台目錄，關鍵字可進一步篩選';

  @override
  String get radioFieldProvider => '電台目錄';

  @override
  String get radioFieldProviderHint =>
      '全部目錄、Radio Browser、SomaFM 或 Radio Paradise';

  @override
  String get radioProviderAll => '全部目錄';

  @override
  String get radioFieldQuery => '電台關鍵字';

  @override
  String get radioFieldQueryHint => '例如 jazz、ambient 或 SomaFM';

  @override
  String get radioNoMatch => '找不到符合的電台';

  @override
  String get sourceWikimediaDescription => 'Wikimedia Commons 的開放音訊';

  @override
  String get sourceWikimediaName => '自由授權媒體';

  @override
  String get wikimediaHint => '填寫搜尋關鍵字，例如 piano、lecture 或 birdsong';

  @override
  String get wikimediaFieldQueryHint => '例如 piano、lecture、birdsong';

  @override
  String get wikimediaEmptyResponse => 'Wikimedia Commons 回傳了空回應';

  @override
  String get wikimediaNoMatch => '找不到可播放的共享音訊';

  @override
  String get sourceJellyfinDescription => '連接自建的 Jellyfin 媒體庫';

  @override
  String get sourceJellyfinName => '自建媒體庫';

  @override
  String get jellyfinHint => '填寫自建 Jellyfin 的位址與帳號';

  @override
  String get jellyfinFieldServerHint => '例如 http://localhost:8096';

  @override
  String get jellyfinFieldUserHint => 'Jellyfin 的登入使用者名稱';

  @override
  String get jellyfinFieldPasswordHint => '用於換取存取權杖';

  @override
  String get jellyfinEmptyResponse => 'Jellyfin 回傳了空回應';

  @override
  String get jellyfinAuthFailed => '無法連線 Jellyfin 伺服器，請檢查位址與帳號';

  @override
  String get audioSourceStreaming => '網路';

  @override
  String get playerLiveBadge => '直播中';

  @override
  String get nowPlayingLiveStream => '直播串流，沒有固定時長';

  @override
  String get nowPlayingDetails => '曲目資訊';

  @override
  String get nowPlayingDetailAlbum => '專輯';

  @override
  String get nowPlayingDetailYear => '年份';

  @override
  String get nowPlayingDetailGenre => '風格';

  @override
  String get nowPlayingDetailBitrate => '位元率';

  @override
  String get nowPlayingDetailSampleRate => '取樣率';

  @override
  String get nowPlayingDetailTrack => '音軌';

  @override
  String get nowPlayingDetailDisc => '光碟';

  @override
  String get nowPlayingDetailLicense => '授權';

  @override
  String get nowPlayingDetailSource => '來源';

  @override
  String get nowPlayingDetailNowPlaying => '正在播放';

  @override
  String get genreRock => '搖滾';

  @override
  String get genrePop => '流行';

  @override
  String get genreJazz => '爵士';

  @override
  String get genreClassical => '古典';

  @override
  String get genreElectronic => '電子';

  @override
  String get genreHipHop => '說唱';

  @override
  String get genreBlues => '藍調';

  @override
  String get genreCountry => '鄉村';

  @override
  String get genreFolk => '民謠';

  @override
  String get genreMetal => '金屬';

  @override
  String get genrePunk => '朋克';

  @override
  String get genreReggae => '雷鬼';

  @override
  String get genreLatin => '拉丁';

  @override
  String get genreDance => '舞曲';

  @override
  String get genreAlternative => '另類';

  @override
  String get genreIndie => '獨立';

  @override
  String get genreAmbient => '環境音樂';

  @override
  String get genreHouse => '浩室';

  @override
  String get genreFunk => '放克';

  @override
  String get genreGospel => '福音';

  @override
  String get genreWorld => '世界音樂';

  @override
  String get genreNewAge => '新世紀';

  @override
  String get genreSoundtrack => '原聲';

  @override
  String get genreOpera => '歌劇';

  @override
  String get genreExperimental => '實驗';

  @override
  String get genreMusicWord => '音樂';

  @override
  String get genreMusicWordShort => '樂';

  @override
  String get trackFactSource => '來源';

  @override
  String get trackFactStorage => '位置';

  @override
  String get trackFactStorageLocal => '本機';

  @override
  String get trackFactStorageRemote => '線上';

  @override
  String get trackFactFormat => '格式';

  @override
  String get trackFactQuality => '音質';

  @override
  String get trackFactQualityLossless => '無損';

  @override
  String get trackFactQualityHiRes => '高解析';

  @override
  String get trackFactSize => '大小';

  @override
  String get trackFactLyrics => '歌詞';

  @override
  String get trackFactLyricsIncluded => '已包含';

  @override
  String get trackFactPerformers => '演奏者';

  @override
  String get trackFactAdded => '加入時間';

  @override
  String get trackFactDescription => '簡介';

  @override
  String get trackFactLive => '直播';

  @override
  String get trackFactPath => '檔案路徑';

  @override
  String get trackFactAddress => '位址';

  @override
  String get trackDetailsTooltip => '查看詳情';

  @override
  String get trackDetailsCopyPath => '複製路徑';

  @override
  String get trackDetailsCopyAddress => '複製位址';

  @override
  String get trackDetailsCopied => '已複製到剪貼簿';

  @override
  String get trackFactDuration => '時長';

  @override
  String get trackFactSourceId => '來源編號';

  @override
  String get trackFactMediaType => '媒體類型';

  @override
  String get trackFactCover => '封面';

  @override
  String get trackFactIdentity => '身分';

  @override
  String get trackFactHeaders => '請求標頭';

  @override
  String get trackFactRawData => '原始資料';

  @override
  String get trackDetailsCopyCover => '複製封面';

  @override
  String get trackDetailsCopyIdentity => '複製身分';

  @override
  String get sourceStatusEnabled => '已啟用';

  @override
  String get sourceStatusOff => '已關閉';

  @override
  String get sourceStatusNeedsSetup => '待設定';

  @override
  String get sourceStatusFailed => '失敗';

  @override
  String get sourceStatusSkipped => '已略過';

  @override
  String get sourceStatusScanned => '已掃描';

  @override
  String get sourceStatusTracks => '曲目';

  @override
  String get sourceStatusLastScan => '上次掃描';

  @override
  String get sourceStatusUnsupported => '不支援';

  @override
  String get sourceStatusWaiting => '待掃描';

  @override
  String get jamendoFieldFormatHint => '預設 192 kbps';

  @override
  String get subsonicFieldFormatHint => '預設原始音質';

  @override
  String get subsonicFormatOriginal => '原始音質';

  @override
  String get sourceRadioName => '網路電台';

  @override
  String get settingsEyebrow => '偏好';

  @override
  String get settingsSectionInterface => '介面';

  @override
  String get settingsLocalFirst => '本機優先';

  @override
  String get libraryEyebrow => '收藏';

  @override
  String get sourcesEyebrow => '連線';

  @override
  String get sidebarCollect => '收藏';

  @override
  String get sidebarConnect => '連線';

  @override
  String get sidebarLocalOnline => '本機 + 線上';

  @override
  String sidebarVersionLine(String name, String version) {
    return '$name 桌面版 · $version';
  }

  @override
  String searchSourceError(String source, String message) {
    return '$source：$message';
  }

  @override
  String get radioNoChannelList => 'SomaFM 沒有回傳電台列表';

  @override
  String get trayPlayPause => '播放 / 暫停';

  @override
  String get trayPrevious => '上一首';

  @override
  String get trayNext => '下一首';

  @override
  String get trayShowWindow => '顯示主視窗';

  @override
  String get trayQuit => '結束';

  @override
  String get settingsSectionDesktop => '桌面';

  @override
  String get settingsDesktopTitle => '桌面整合';

  @override
  String get settingsDesktopDescription => '讓 Tune 在背景繼續播放，並成為預設的音訊播放器';

  @override
  String get settingsCloseToTray => '關閉視窗時縮到系統匣';

  @override
  String get settingsCloseToTrayHint => '關掉視窗後仍在系統匣裡繼續播放';

  @override
  String get settingsMediaControls => '在系統媒體中心顯示 Tune';

  @override
  String get settingsMediaControlsHint => '讓媒體鍵與媒體選單控制 Tune';

  @override
  String get settingsSetDefaultPlayer => '設為預設播放器';

  @override
  String get settingsDefaultPlayerActive => '已是預設播放器';

  @override
  String get settingsDefaultPlayerDone => 'Tune 已是預設播放器了';

  @override
  String get settingsDefaultPlayerFailed => '設定失敗，請先安裝桌面項目';

  @override
  String get settingsDefaultPlayerMissingEntry =>
      '還沒有安裝桌面項目，先執行 linux/install-desktop-entry.sh';

  @override
  String get settingsSectionPlayback => '播放';

  @override
  String get settingsPlaybackTitle => '播放行為';

  @override
  String get settingsPlaybackDescription => '決定單擊與雙擊歌曲時會發生什麼';

  @override
  String get settingsReplaceQueueOnClick => '單擊歌曲時取代播放佇列';

  @override
  String get settingsReplaceQueueOnClickHint => '關掉時單擊只把這首排進佇列並立即播放，佇列裡的其餘曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '雙擊時只標成喜歡';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '打開時雙擊只標成喜歡，不打斷正在放的曲子；關掉時雙擊照常播放並標成喜歡';
}

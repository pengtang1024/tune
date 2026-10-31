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
  String get updateEyebrow => '更新';

  @override
  String get updateTitle => '版本';

  @override
  String get updateDescription => '检查项目发布页是否有新版本，并直接安装';

  @override
  String updateCurrentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get updateIdle => '还没有检查过发布页';

  @override
  String get updateChecking => '正在检查发布页…';

  @override
  String get updateUpToDate => '已经是最新版本';

  @override
  String updateAvailable(String version) {
    return '新版本 $version 可用';
  }

  @override
  String get updateDownloading => '正在下载';

  @override
  String get updateInstalling => '正在安装…';

  @override
  String get updateReady => '更新已就绪，重启后生效';

  @override
  String updateFailed(String error) {
    return '检查失败：$error';
  }

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateInstall => '下载并安装';

  @override
  String get updateRetry => '重试';

  @override
  String get updateRestart => '立即重启';

  @override
  String get updateNoArchive => '这个平台不支持自动安装，请到发布页手动下载';

  @override
  String get songMayBeUnavailable => '可能已失效';

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
  String librarySummary(int tracks, int albums, int sources) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$tracksString 首歌曲 · $albumsString 张专辑 · $sourcesString 个来源';
  }

  @override
  String get libraryClearSearch => '清除搜索';

  @override
  String get libraryFilterSources => '筛选来源';

  @override
  String get libraryAllSources => '全部来源';

  @override
  String get libraryScanAllSources => '扫描全部音源';

  @override
  String get libraryLoadMore => '加载更多曲目';

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
  String get libraryViewSongs => '歌曲视图';

  @override
  String get libraryViewAlbums => '专辑视图';

  @override
  String get libraryUnknownAlbum => '未知专辑';

  @override
  String get libraryVariousArtists => '多位艺术家';

  @override
  String get libraryBackToAlbums => '返回专辑';

  @override
  String get queueTitle => '播放队列';

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
  String get queueReorderTooltip => '拖动排序';

  @override
  String get favoritesTitle => '喜欢';

  @override
  String get favoritesSubtitle => '标了心的曲子都在这里';

  @override
  String get favoritesEyebrow => '收藏';

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
  String favoritesOutsideLibrary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '另有 $countString 首标过，但不在音乐库里';
  }

  @override
  String get favoritesEmptyOutsideTitle => '标过的歌不在音乐库里';

  @override
  String get favoritesEmptyOutsideSubtitle => '音乐库里找不到它们，标记还留着';

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
  String get sourcesClearSongs => '清空曲目';

  @override
  String sourcesClearSongsTitle(String name) {
    return '清空「$name」的曲目？';
  }

  @override
  String get sourcesClearSongsHint => '只移除这个来源带来的曲目，来源本身保留';

  @override
  String sourcesSongsCleared(String name) {
    return '已清空「$name」的曲目';
  }

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
  String get sourcesMoveUp => '上移';

  @override
  String get sourcesMoveDown => '下移';

  @override
  String get sourcesMoveToMore => '移到更多音源';

  @override
  String get sourcesMoveToMain => '移回主列表';

  @override
  String get sourcesMovedToMore => '已移到更多音源';

  @override
  String get sourcesMovedToMain => '已移回主列表';

  @override
  String sourcesHealthScore(int score) {
    return '健康度 $score/100';
  }

  @override
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
  ) {
    return '可用 $availability% · 配置 $configuration% · 扫描 $scan% · 新鲜 $freshness% · 产出 $output% · 速度 $speed% · 可靠 $reliability% · 稳定 $stability% · 可播放 $playable% · 封面 $artwork% · 元数据 $metadata% · 活跃 $activity%';
  }

  @override
  String get sourcesHealthWeightsTitle => '健康度权重';

  @override
  String get sourcesHealthWeightsHint => '调高某个维度，它在健康度里的分量更大；总权重会自动归一化。';

  @override
  String sourcesHealthWeightsTotal(int total) {
    return '总权重 $total · 自动归一化';
  }

  @override
  String get settingsSourceHealthDescription =>
      '十二个维度当前的分量；调高一个维度，它在健康度里的占比就更大。';

  @override
  String get settingsAdjustSourceHealthWeights => '调整权重';

  @override
  String get sourcesHealthWeightsReset => '恢复默认';

  @override
  String get sourcesHealthAvailability => '可用';

  @override
  String get sourcesHealthConfiguration => '配置';

  @override
  String get sourcesHealthScan => '扫描';

  @override
  String get sourcesHealthFreshness => '新鲜';

  @override
  String get sourcesHealthOutput => '产出';

  @override
  String get sourcesHealthSpeed => '速度';

  @override
  String get sourcesHealthReliability => '可靠';

  @override
  String get sourcesHealthStability => '稳定';

  @override
  String get sourcesHealthPlayable => '可播放';

  @override
  String get sourcesHealthArtwork => '封面';

  @override
  String get sourcesHealthMetadata => '元数据';

  @override
  String get sourcesHealthActivity => '活跃';

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
  String get jsonFieldQueryHint => '搜索用的关键词，会替换请求里的占位符；留空就按地址原样问一次';

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
  String get jsonApiFieldMethodHint => 'GET 或 POST；只有 POST 带请求体';

  @override
  String get jsonApiFieldBody => '请求体';

  @override
  String get jsonApiFieldBodyHint => 'POST 时的 JSON 对象；关键词会填进占位符';

  @override
  String get sourceGraphqlName => 'GraphQL 接口';

  @override
  String get sourceGraphqlDescription => '用一份查询文档问接口，筛选条件写在文档里';

  @override
  String get graphqlHint => '填写接口地址、查询文档与各字段的路径';

  @override
  String get graphqlFieldQuery => '查询文档';

  @override
  String get graphqlFieldQueryHint =>
      'GraphQL 查询文档，筛选条件写在里面；模板只是个起点，字段要改成接口里有的';

  @override
  String get graphqlFieldVariables => '变量';

  @override
  String get graphqlFieldVariablesHint => 'JSON 对象；关键词会填进占位符';

  @override
  String get jsonPreviewNoTracks => '返回里没有认出曲目';

  @override
  String get sourcePreviewTry => '试一下';

  @override
  String get sourcePreviewRunning => '正在试…';

  @override
  String sourcePreviewTracks(int count) {
    return '认出 $count 首';
  }

  @override
  String get sourceFormShowAdvanced => '更多选项';

  @override
  String get sourceFormHideAdvanced => '收起选项';

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
  String get fieldLimitPodcasts => '每次扫描播客数';

  @override
  String get fieldLimitStations => '每次扫描电台数';

  @override
  String get fieldScanPages => '每次扫描页数';

  @override
  String get fieldScanPagesHint => '一次扫描翻几页，1–10；页数越多扫描越久';

  @override
  String fieldLimitHint(int count, int max) {
    return '默认 $count，最大 $max';
  }

  @override
  String get fieldLimitBooks => '每次扫描书数';

  @override
  String get fieldLanguage => '语言';

  @override
  String get fieldLanguageHint => '只保留一种语言的有声书';

  @override
  String get fieldLanguageAll => '不限制语言';

  @override
  String get fieldLanguageEnglish => '英语';

  @override
  String get fieldLanguageChinese => '中文';

  @override
  String get fieldLanguageFrench => '法语';

  @override
  String get fieldLanguageGerman => '德语';

  @override
  String get fieldLanguageSpanish => '西班牙语';

  @override
  String get fieldLanguageItalian => '意大利语';

  @override
  String get fieldLanguageJapanese => '日语';

  @override
  String get fieldLanguageRussian => '俄语';

  @override
  String get fieldLanguagePortuguese => '葡萄牙语';

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
  String get lyricsNothingPlaying => '还没有正在播放的曲目';

  @override
  String get lyricsInvalidFile => '这个文件里没有歌词';

  @override
  String get lyricsRetry => '重试';

  @override
  String get lyricsSearchAgain => '重新查找';

  @override
  String get lyricsChooseFile => '选择歌词文件';

  @override
  String get lyricsAttached => '歌词已关联';

  @override
  String get lyricsSubtitle => '正在播放的那首歌的词';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '调整外观、语言、音乐库与音源健康度。';

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
  String get settingsSourceCacheLimit => '每来源最多保留';

  @override
  String get settingsSourceCacheLimitHint => '优先保留收藏、最近播放与最近出现的曲目';

  @override
  String get settingsNoLimit => '不限';

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
  String get searchAddLibraryFailed => '加入音乐库失败';

  @override
  String get searchLoadMore => '加载更多';

  @override
  String get searchNoMore => '没有更多了';

  @override
  String get searchAutoSave => '搜索结果自动加入音乐库';

  @override
  String get searchAddToLibrary => '加入音乐库';

  @override
  String get searchAddAllToLibrary => '全部加入';

  @override
  String get searchAddedToLibrary => '已加入';

  @override
  String searchAddedManyToLibrary(int count) {
    return '已加入 $count 首到音乐库';
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
  String get sourceAddressNotHttp => '只支持 http(s) 地址';

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
  String get sourceLiveMusicArchiveDescription => 'Internet Archive 收藏的现场录音';

  @override
  String get sourceLiveMusicArchiveName => '现场音乐档案';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS 播客订阅变成可播放的单集';

  @override
  String get sourcePodcastRssName => '播客订阅';

  @override
  String get sourcePodcastCatalogName => '播客目录';

  @override
  String get sourcePodcastCatalogDescription => '搜索 gpodder 开放播客目录，取最新单集';

  @override
  String get podcastCatalogHint => '输入关键词找播客，留空则浏览目录';

  @override
  String get podcastCatalogFieldQueryHint => '例如爵士、历史、科技';

  @override
  String get podcastCatalogNoMatch => '没有找到播客';

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
  String get radioFieldCountry => '国家/地区';

  @override
  String get radioFieldCountryHint => '两位国家代码，例如 SG、MY、AU、JP；目录里有的国家都可以填';

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
  String get sourceFunkwhaleName => '联邦音乐';

  @override
  String get sourceFunkwhaleDescription => '联邦 Funkwhale 实例里的音乐';

  @override
  String get funkwhaleHint => '填写 Funkwhale 实例地址；只有私密库需要令牌';

  @override
  String get funkwhaleFieldServerHint => '例如 https://open.audio';

  @override
  String get funkwhaleFieldToken => '访问令牌';

  @override
  String get funkwhaleFieldTokenHint => '实例的库私密时才需要';

  @override
  String get funkwhaleFieldQueryHint => '例如爵士、民谣、电子';

  @override
  String get funkwhaleEmptyResponse => 'Funkwhale 返回了空响应';

  @override
  String get funkwhaleNoMatch => 'Funkwhale 上没有匹配的曲目';

  @override
  String get sourceAudiobookshelfName => '自建有声书';

  @override
  String get sourceAudiobookshelfDescription => '自建 Audiobookshelf 服务器里的有声书';

  @override
  String get audiobookshelfHint => '填写 Audiobookshelf 服务器的地址与令牌';

  @override
  String get audiobookshelfFieldServerHint => '例如 http://localhost:13378';

  @override
  String get audiobookshelfFieldToken => '访问令牌';

  @override
  String get audiobookshelfFieldTokenHint => 'Audiobookshelf 账号的 API 令牌';

  @override
  String get audiobookshelfFieldQueryHint => '例如历史、小说、科学';

  @override
  String get audiobookshelfEmptyResponse => 'Audiobookshelf 返回了空响应';

  @override
  String get audiobookshelfNoMatch => '没有找到有声书';

  @override
  String get sourcePlexName => '自建媒体库';

  @override
  String get sourcePlexDescription => '连接自建的 Plex 媒体库';

  @override
  String get plexHint => '填写 Plex 服务器的地址与访问令牌';

  @override
  String get plexFieldServerHint => '例如 http://localhost:32400';

  @override
  String get plexFieldToken => '访问令牌';

  @override
  String get plexFieldTokenHint => 'Plex 账号的 X-Plex-Token';

  @override
  String get plexNoMatch => 'Plex 上没有匹配的曲目';

  @override
  String plexInvalidAnswer(String error) {
    return '读不出 Plex 的回答：$error';
  }

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
  String get sourceLibrivoxName => '有声书';

  @override
  String get sourceLibrivoxDescription => 'LibriVox 志愿者朗读的公版有声书';

  @override
  String get librivoxHint => '输入书名或作者，留空则浏览最热门的有声书';

  @override
  String get librivoxFieldQueryHint => '例如爱丽丝梦游仙境、狄更斯、童话';

  @override
  String get librivoxNoMatch => '没有匹配的有声书';

  @override
  String get librivoxEmptyResponse => 'LibriVox 返回了空响应';

  @override
  String librivoxInvalidFeed(String error) {
    return '读不出一本书的章节列表：$error';
  }

  @override
  String get sourceEmbyName => 'Emby 媒体库';

  @override
  String get sourceEmbyDescription => '连接自建的 Emby 媒体库';

  @override
  String get embyHint => '填写自建 Emby 的地址与账号';

  @override
  String get embyFieldServerHint => '例如 http://localhost:8095';

  @override
  String get embyFieldUserHint => 'Emby 的登录用户名';

  @override
  String get embyFieldPasswordHint => '用于换取访问令牌';

  @override
  String get embyEmptyResponse => 'Emby 返回了空响应';

  @override
  String get embyAuthFailed => '无法连接 Emby 服务器，请检查地址与账号';

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
  String get trackFactAddress => '在线地址';

  @override
  String get trackDetailsTooltip => '查看详情';

  @override
  String get trackDetailsOpenPath => '打开文件';

  @override
  String get trackDetailsOpenFailed => '打不开这个文件';

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
  String get libraryEyebrow => '资料库';

  @override
  String get sourcesEyebrow => '连接';

  @override
  String get sidebarBrowse => '浏览';

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
  String get settingsPlaybackDescription => '决定启动时的播放行为，以及单击、双击歌曲时会发生什么';

  @override
  String get settingsResumePlaybackOnStartup => '启动时继续上次播放';

  @override
  String get settingsResumePlaybackOnStartupHint =>
      '打开 Tune 时总会恢复队列和播放进度；这个开关只决定当前这首是否自动继续播放，关掉则停在暂停状态';

  @override
  String get settingsReplaceQueueOnClick => '单击歌曲时替换播放队列';

  @override
  String get settingsReplaceQueueOnClickHint => '关掉时单击只把这首排进队列并立即播放，队列里的其余曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '双击时只标成喜欢';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '打开时双击只标成喜欢，不打断正在放的曲子；关掉时双击照常播放并标成喜欢';

  @override
  String get settingsFavoritesDoubleClickPlays => '双击喜欢的曲目时播放并替换队列';

  @override
  String get settingsFavoritesDoubleClickPlaysHint =>
      '打开时，双击喜欢列表里的曲目会播放它并把队列换成它；关掉时双击只标成喜欢';

  @override
  String get sidebarDiscover => '发现';

  @override
  String get discoverEyebrow => '发现';

  @override
  String get discoverTitle => '今天听什么';

  @override
  String get discoverSubtitle => '从你的音乐库和喜欢的曲目里挑的 · 只在本机计算';

  @override
  String get discoverRefresh => '换一批';

  @override
  String get discoverWhy => '怎么推荐';

  @override
  String get discoverWhyTitle => '推荐怎么来的';

  @override
  String get discoverWhyBody =>
      '发现页只用你的音乐库、标心的曲目、不感兴趣标记和可选的本地播放记录，在本机计算。不会上传，也不会替你搜索在线音源。';

  @override
  String get discoverWhyLibrary => '音乐库里的曲目和元数据';

  @override
  String get discoverWhyHearts => '你标了心的曲目';

  @override
  String get discoverWhyPrivacy => '只在你的电脑上计算，随时可以清除';

  @override
  String get discoverWhyClose => '知道了';

  @override
  String get discoverSectionDailyMix => '今日混音';

  @override
  String discoverSectionArtist(String artist) {
    return '因为你喜欢 $artist';
  }

  @override
  String discoverSectionExplore(String genre) {
    return '换个口味：$genre';
  }

  @override
  String discoverSectionExploreEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverSectionExploreEars => '换换耳朵';

  @override
  String get discoverSectionFresh => '刚入库';

  @override
  String discoverSectionSource(String source) {
    return '来自 $source';
  }

  @override
  String get discoverSectionFallback => '从你的音乐库挑的';

  @override
  String discoverDailyMixSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '熟悉的曲目 + 新发现 · $countString 首';
  }

  @override
  String get discoverPlay => '播放';

  @override
  String get discoverAddAllShort => '加入队列';

  @override
  String get discoverPlayAll => '播放全部';

  @override
  String get discoverAddAllToQueue => '全部加入队列';

  @override
  String get discoverShelfBack => '上一组';

  @override
  String get discoverShelfForward => '下一组';

  @override
  String get discoverMoreActions => '更多操作';

  @override
  String get discoverDismiss => '不感兴趣';

  @override
  String discoverDismissed(String title) {
    return '已减少「$title」的推荐';
  }

  @override
  String get discoverUndo => '撤销';

  @override
  String discoverAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首';
  }

  @override
  String get discoverAlreadyQueued => '这些歌已经在队列里了';

  @override
  String get discoverReasonFavorite => '你标了心';

  @override
  String discoverReasonArtist(String artist) {
    return '因为你喜欢 $artist';
  }

  @override
  String discoverReasonGenre(String genre) {
    return '你喜欢 $genre';
  }

  @override
  String discoverReasonEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverReasonFresh => '刚入库';

  @override
  String get discoverReasonUnheard => '还没听过';

  @override
  String discoverReasonSource(String source) {
    return '来自 $source';
  }

  @override
  String get discoverReasonFallback => '从你的音乐库挑的';

  @override
  String get discoverEmptyLibraryTitle => '音乐库还是空的';

  @override
  String get discoverEmptyLibrarySubtitle => '扫描本地音乐或连接一个音源，发现页才有东西可挑';

  @override
  String get discoverScanMusic => '扫描音乐';

  @override
  String get discoverConnectSources => '连接音源';

  @override
  String get discoverNoCandidatesTitle => '能推荐的都听过了';

  @override
  String get discoverNoCandidatesSubtitle => '去音乐库逛逛，或清掉不感兴趣标记';

  @override
  String get discoverGoToLibrary => '去音乐库';

  @override
  String get discoverLoadFailed => '发现页加载失败';

  @override
  String get discoverLoadFailedHint => '音乐库暂时读不出来，稍后再试';

  @override
  String get discoverClearTitle => '清除推荐记录？';

  @override
  String get discoverClearMessage => '会删除单曲与歌手的「少推荐」标记和本地播放记录；喜欢、音乐库和播放队列不受影响。';

  @override
  String get discoverCleared => '推荐记录已清除';

  @override
  String get settingsSectionDiscovery => '发现';

  @override
  String get settingsDiscoveryTitle => '发现页';

  @override
  String get settingsDiscoveryDescription => '推荐只在本机计算，不上传你的音乐库';

  @override
  String get settingsDiscoveryPrivacy => '推荐只使用音乐库、标心的曲目和不感兴趣标记。';

  @override
  String get discoverFavoriteHint => '标几首喜欢的歌，推荐会更准';

  @override
  String get settingsDiscoveryUseHistory => '本地播放记录';

  @override
  String get settingsDiscoveryUseHistoryHint => '只保存在本机，让推荐更贴近你；关闭后不再记录';

  @override
  String get discoverHistoryHint => '开启本地播放记录，推荐会更贴近你';

  @override
  String get discoverHistoryEnable => '开启';

  @override
  String get discoverClearAll => '清除推荐记录';

  @override
  String get discoverWhyHistory => '可选的本地播放记录（默认关闭）';

  @override
  String get settingsSectionSmartLyrics => '智能歌词';

  @override
  String get settingsSmartLyricsTitle => '歌词覆盖';

  @override
  String get settingsSmartLyricsDescription => '标签里的词和曲目旁的词稿都算；统计来自最近一次扫描';

  @override
  String get settingsSmartLyricsTotal => '曲目总数';

  @override
  String get settingsSmartLyricsResolved => '已知有词';

  @override
  String get settingsSmartLyricsMissing => '待补缺口';

  @override
  String get settingsSmartLyricsPreset => '接口模板';

  @override
  String get settingsSmartLyricsPresetCustom => '自定义';

  @override
  String get settingsSmartLyricsApiKey => '密钥';

  @override
  String get settingsSmartLyricsApiKeyHint => '粘贴你自己的 API 密钥';

  @override
  String get settingsSmartLyricsAdvanced => '高级';

  @override
  String get settingsSmartLyricsBaseUrl => '接口地址';

  @override
  String get settingsSmartLyricsAsrModels => '转写模型（逗号分隔）';

  @override
  String get settingsSmartLyricsChatModel => '文本模型';

  @override
  String get settingsSmartLyricsPrivacy => '生成会把整首歌的音频上传到你配置的端点；只发给你自己填的地址。';

  @override
  String get settingsSmartLyricsSampled => '抽样';

  @override
  String get settingsSmartLyricsChecked => '已核';

  @override
  String get settingsSmartLyricsAccuracy => '正确率';

  @override
  String get settingsSmartLyricsDrawSample => '开始抽样';

  @override
  String get settingsSmartLyricsAccuracyNote =>
      '正确率按已解决样本分层人工核对（直录棚 / Live / 说唱 / 非中文）；样本只增不减，改判以最后一笔为准。';

  @override
  String get settingsSmartLyricsLocal => '本地引擎';

  @override
  String get settingsSmartLyricsLocalOff => '关闭';

  @override
  String get settingsSmartLyricsLocalDownload => '下载模型';

  @override
  String get settingsSmartLyricsLocalBusy => '下载中……';

  @override
  String get settingsSmartLyricsLocalReady => '模型已就绪';

  @override
  String get settingsSmartLyricsLocalFailed => '下载失败：重试，或换个模型';

  @override
  String get settingsSmartLyricsBatch => '批量补齐';

  @override
  String get settingsSmartLyricsBatchStart => '补齐曲库';

  @override
  String get settingsSmartLyricsBatchStop => '停止';

  @override
  String get settingsSmartLyricsBatchRetry => '重查失败曲目';

  @override
  String get settingsSmartLyricsBudget => '云端预算（首/批，0 为不限）';

  @override
  String settingsSmartLyricsBatchIdle(int pending, int done, int failed) {
    return '待补 $pending · 已完成 $done · 失败 $failed';
  }

  @override
  String settingsSmartLyricsBatchRunning(int pending, int done) {
    return '正在补齐：待补 $pending · 已完成 $done';
  }

  @override
  String settingsSmartLyricsBudgetPaused(int budget) {
    return '已达云端预算（$budget 首），本批暂停——余下待补不丢';
  }

  @override
  String settingsSmartLyricsBatchFresh(int count) {
    return '新增 $count 首待补，按「补齐曲库」入队';
  }

  @override
  String get settingsSmartLyricsLeakCheck => '查漏长开：机器空闲时只重问人写票池，不花云端、不占 CPU';

  @override
  String get lyricsSmartGenerate => '智能生成';

  @override
  String get lyricsSmartGenerateNeedsKey => '还没有密钥——先到设置的「智能歌词」里贴一把';

  @override
  String get lyricsSmartGenerating => '正在生成歌词——先问人写稿，再开通道，一轮最多几分钟';

  @override
  String get lyricsSmartFailedAudio => '取音频失败：曲目没有本地副本，也没拉到流';

  @override
  String get lyricsSmartFailedUpload => '通道没有答上来：稍后再试，或到设置里检查钥匙与端点';

  @override
  String get lyricsSmartFailedEmpty => '没有识别出人声';

  @override
  String get lyricsSmartNote => '机器稿：票池生成，重新查找可以找更好的词';

  @override
  String get lyricsMarkLine => '这行不对';

  @override
  String get lyricsUnmarkLine => '撤销标记';

  @override
  String get lyricsMarkSong => '整首不对';

  @override
  String get lyricsMarkNotSung => '这不是唱的';

  @override
  String get lyricsMarksTitle => '标记管理';

  @override
  String get lyricsMarksEmpty => '还没有标记——听到不对的行，点行尾的小旗';

  @override
  String lyricsMarkLineNumber(int line) {
    return '第 $line 行';
  }

  @override
  String get lyricsMarkReword => '改词';

  @override
  String get lyricsMarkRewordTitle => '改这一行';

  @override
  String get lyricsMarkRewordSave => '保存改词';

  @override
  String get lyricsMarkRevoke => '撤销';

  @override
  String get lyricsMarkWaiting => '等复解';

  @override
  String get lyricsMarkResolved => '已复解';

  @override
  String get lyricsMarkReworded => '已改词';

  @override
  String get lyricsMarkRevoked => '已撤销';

  @override
  String get lyricsMarkSourceReader => '读者';

  @override
  String get lyricsMarkSourceSystem => '系统';

  @override
  String discoverSectionOnlineArtist(String artist) {
    return '在线找到的 $artist';
  }

  @override
  String get discoverFindMoreOnline => '在线找更多';

  @override
  String get discoverFindingMore => '正在找…';

  @override
  String get discoverNoOnlineSources => '没有启用的在线音源';

  @override
  String discoverOnlineNoResults(String artist) {
    return '没有找到更多 $artist 的歌';
  }

  @override
  String get discoverOnlineFailed => '在线查找失败，稍后再试';

  @override
  String discoverOnlineFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首在线结果';
  }

  @override
  String get discoverReasonAdjacent => '同一种口味，换个人';

  @override
  String get discoverLessArtist => '少推荐这位歌手';

  @override
  String discoverDismissedArtist(String artist) {
    return '已减少「$artist」的推荐';
  }

  @override
  String get discoverSectionFavoriteArtists => '更多来自你标心的歌手';

  @override
  String get discoverReasonCompleted => '你常把这首听完';

  @override
  String smartPromptCorrect(String title, String artist, String draft) {
    return '下面是一首歌的机器转写稿，可能有同音字或听错的词。歌名「$title」，歌手「$artist」。\n请修正错别字，行数与顺序必须与原稿完全一致。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$draft';
  }

  @override
  String smartPromptRebuild(String title, String artist) {
    return '请凭你对这首歌的了解，写出《$title》($artist) 的歌词，按演唱顺序拆成一行一句。\n只输出 JSON 字符串数组，不要输出其他内容。不确定的歌曲就输出空数组，不要编造：';
  }

  @override
  String smartPromptTranslate(String target, String lines) {
    return '把下面这首歌的歌词逐行译成$target，行数与顺序必须与原稿完全一致，不译标点风格差异。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$lines';
  }

  @override
  String smartPromptTransliterate(String lines) {
    return '把下面这首歌的歌词逐行转写成拉丁字母拼读（拼音或通行读音），行数与顺序必须与原稿完全一致。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$lines';
  }

  @override
  String get smartContrastTargetLanguage => '英文';

  @override
  String get lyricsContrastTranslate => '翻译';

  @override
  String get lyricsContrastTransliterate => '音译';

  @override
  String get lyricsContrastDone => '已对照';

  @override
  String get settingsSmartLyricsAutoFill => '自动补齐：开着就把库里所有没词的歌自动补到有词';

  @override
  String get librarySortTooltip => '排序';

  @override
  String get librarySortRecent => '最近加入';

  @override
  String get librarySortTitle => '标题';

  @override
  String get librarySortArtist => '艺术家';

  @override
  String get librarySortAlbum => '专辑';

  @override
  String get librarySortDuration => '时长';

  @override
  String get libraryColumnTitle => '标题';

  @override
  String get libraryColumnArtist => '艺术家';

  @override
  String get libraryColumnAlbum => '专辑';

  @override
  String get libraryColumnAdded => '加入';

  @override
  String get libraryColumnDuration => '时长';

  @override
  String get libraryMoreActions => '更多操作';

  @override
  String get libraryViewColumns => '双列视图';

  @override
  String get libraryFilter => '筛选';

  @override
  String get libraryFilterClearAll => '清除全部';

  @override
  String get libraryFilterStatus => '状态';

  @override
  String get libraryFilterStatusAll => '全部';

  @override
  String get libraryFilterStatusLiked => '喜欢';

  @override
  String get libraryFilterStatusWithLyrics => '有词';

  @override
  String get libraryFilterStatusWithoutLyrics => '缺词';

  @override
  String get libraryFilterStatusInstrumental => '纯音乐';

  @override
  String get libraryFilterGenres => '流派';

  @override
  String get libraryFilterDecades => '年代';

  @override
  String get libraryFilterArtists => '艺术家';

  @override
  String get libraryFilterLanguages => '语言';

  @override
  String get libraryFilterFormats => '格式';

  @override
  String get libraryFilterDurations => '时长';

  @override
  String get libraryFilterAdded => '加入时间';

  @override
  String get libraryFilterDurationShort => '<2 分钟';

  @override
  String get libraryFilterDurationMedium => '2–5 分钟';

  @override
  String get libraryFilterDurationLong => '5–10 分钟';

  @override
  String get libraryFilterDurationEpic => '>10 分钟';

  @override
  String get libraryFilterAddedWeek => '最近 7 天';

  @override
  String get libraryFilterAddedMonth => '最近 30 天';

  @override
  String get libraryFilterAddedYear => '最近一年';

  @override
  String get libraryFilterAddedOlder => '更早';
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
  String get updateEyebrow => '更新';

  @override
  String get updateTitle => '版本';

  @override
  String get updateDescription => '检查项目发布页是否有新版本，并直接安装';

  @override
  String updateCurrentVersion(String version) {
    return '当前版本 $version';
  }

  @override
  String get updateIdle => '还没有检查过发布页';

  @override
  String get updateChecking => '正在检查发布页…';

  @override
  String get updateUpToDate => '已经是最新版本';

  @override
  String updateAvailable(String version) {
    return '新版本 $version 可用';
  }

  @override
  String get updateDownloading => '正在下载';

  @override
  String get updateInstalling => '正在安装…';

  @override
  String get updateReady => '更新已就绪，重启后生效';

  @override
  String updateFailed(String error) {
    return '检查失败：$error';
  }

  @override
  String get updateCheck => '检查更新';

  @override
  String get updateInstall => '下载并安装';

  @override
  String get updateRetry => '重试';

  @override
  String get updateRestart => '立即重启';

  @override
  String get updateNoArchive => '这个平台不支持自动安装，请到发布页手动下载';

  @override
  String get songMayBeUnavailable => '可能已失效';

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
  String librarySummary(int tracks, int albums, int sources) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$tracksString 首歌曲 · $albumsString 张专辑 · $sourcesString 个来源';
  }

  @override
  String get libraryClearSearch => '清除搜索';

  @override
  String get libraryFilterSources => '筛选来源';

  @override
  String get libraryAllSources => '全部来源';

  @override
  String get libraryScanAllSources => '扫描全部音源';

  @override
  String get libraryLoadMore => '加载更多曲目';

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
  String get libraryViewSongs => '歌曲视图';

  @override
  String get libraryViewAlbums => '专辑视图';

  @override
  String get libraryUnknownAlbum => '未知专辑';

  @override
  String get libraryVariousArtists => '多位艺术家';

  @override
  String get libraryBackToAlbums => '返回专辑';

  @override
  String get queueTitle => '播放队列';

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
  String get queueReorderTooltip => '拖动排序';

  @override
  String get favoritesTitle => '喜欢';

  @override
  String get favoritesSubtitle => '标了心的曲子都在这里';

  @override
  String get favoritesEyebrow => '收藏';

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
  String favoritesOutsideLibrary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '另有 $countString 首标过，但不在音乐库里';
  }

  @override
  String get favoritesEmptyOutsideTitle => '标过的歌不在音乐库里';

  @override
  String get favoritesEmptyOutsideSubtitle => '音乐库里找不到它们，标记还留着';

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
  String get sourcesClearSongs => '清空曲目';

  @override
  String sourcesClearSongsTitle(String name) {
    return '清空「$name」的曲目？';
  }

  @override
  String get sourcesClearSongsHint => '只移除这个来源带来的曲目，来源本身保留';

  @override
  String sourcesSongsCleared(String name) {
    return '已清空「$name」的曲目';
  }

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
  String get sourcesMoveUp => '上移';

  @override
  String get sourcesMoveDown => '下移';

  @override
  String get sourcesMoveToMore => '移到更多音源';

  @override
  String get sourcesMoveToMain => '移回主列表';

  @override
  String get sourcesMovedToMore => '已移到更多音源';

  @override
  String get sourcesMovedToMain => '已移回主列表';

  @override
  String sourcesHealthScore(int score) {
    return '健康度 $score/100';
  }

  @override
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
  ) {
    return '可用 $availability% · 配置 $configuration% · 扫描 $scan% · 新鲜 $freshness% · 产出 $output% · 速度 $speed% · 可靠 $reliability% · 稳定 $stability% · 可播放 $playable% · 封面 $artwork% · 元数据 $metadata% · 活跃 $activity%';
  }

  @override
  String get sourcesHealthWeightsTitle => '健康度权重';

  @override
  String get sourcesHealthWeightsHint => '调高某个维度，它在健康度里的分量更大；总权重会自动归一化。';

  @override
  String sourcesHealthWeightsTotal(int total) {
    return '总权重 $total · 自动归一化';
  }

  @override
  String get settingsSourceHealthDescription =>
      '十二个维度当前的分量；调高一个维度，它在健康度里的占比就更大。';

  @override
  String get settingsAdjustSourceHealthWeights => '调整权重';

  @override
  String get sourcesHealthWeightsReset => '恢复默认';

  @override
  String get sourcesHealthAvailability => '可用';

  @override
  String get sourcesHealthConfiguration => '配置';

  @override
  String get sourcesHealthScan => '扫描';

  @override
  String get sourcesHealthFreshness => '新鲜';

  @override
  String get sourcesHealthOutput => '产出';

  @override
  String get sourcesHealthSpeed => '速度';

  @override
  String get sourcesHealthReliability => '可靠';

  @override
  String get sourcesHealthStability => '稳定';

  @override
  String get sourcesHealthPlayable => '可播放';

  @override
  String get sourcesHealthArtwork => '封面';

  @override
  String get sourcesHealthMetadata => '元数据';

  @override
  String get sourcesHealthActivity => '活跃';

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
  String get jsonFieldQueryHint => '搜索用的关键词，会替换请求里的占位符；留空就按地址原样问一次';

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
  String get jsonApiFieldMethodHint => 'GET 或 POST；只有 POST 带请求体';

  @override
  String get jsonApiFieldBody => '请求体';

  @override
  String get jsonApiFieldBodyHint => 'POST 时的 JSON 对象；关键词会填进占位符';

  @override
  String get sourceGraphqlName => 'GraphQL 接口';

  @override
  String get sourceGraphqlDescription => '用一份查询文档问接口，筛选条件写在文档里';

  @override
  String get graphqlHint => '填写接口地址、查询文档与各字段的路径';

  @override
  String get graphqlFieldQuery => '查询文档';

  @override
  String get graphqlFieldQueryHint =>
      'GraphQL 查询文档，筛选条件写在里面；模板只是个起点，字段要改成接口里有的';

  @override
  String get graphqlFieldVariables => '变量';

  @override
  String get graphqlFieldVariablesHint => 'JSON 对象；关键词会填进占位符';

  @override
  String get jsonPreviewNoTracks => '返回里没有认出曲目';

  @override
  String get sourcePreviewTry => '试一下';

  @override
  String get sourcePreviewRunning => '正在试…';

  @override
  String sourcePreviewTracks(int count) {
    return '认出 $count 首';
  }

  @override
  String get sourceFormShowAdvanced => '更多选项';

  @override
  String get sourceFormHideAdvanced => '收起选项';

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
  String get fieldLimitPodcasts => '每次扫描播客数';

  @override
  String get fieldLimitStations => '每次扫描电台数';

  @override
  String get fieldScanPages => '每次扫描页数';

  @override
  String get fieldScanPagesHint => '一次扫描翻几页，1–10；页数越多扫描越久';

  @override
  String fieldLimitHint(int count, int max) {
    return '默认 $count，最大 $max';
  }

  @override
  String get fieldLimitBooks => '每次扫描书数';

  @override
  String get fieldLanguage => '语言';

  @override
  String get fieldLanguageHint => '只保留一种语言的有声书';

  @override
  String get fieldLanguageAll => '不限制语言';

  @override
  String get fieldLanguageEnglish => '英语';

  @override
  String get fieldLanguageChinese => '中文';

  @override
  String get fieldLanguageFrench => '法语';

  @override
  String get fieldLanguageGerman => '德语';

  @override
  String get fieldLanguageSpanish => '西班牙语';

  @override
  String get fieldLanguageItalian => '意大利语';

  @override
  String get fieldLanguageJapanese => '日语';

  @override
  String get fieldLanguageRussian => '俄语';

  @override
  String get fieldLanguagePortuguese => '葡萄牙语';

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
  String get lyricsNothingPlaying => '还没有正在播放的曲目';

  @override
  String get lyricsInvalidFile => '这个文件里没有歌词';

  @override
  String get lyricsRetry => '重试';

  @override
  String get lyricsSearchAgain => '重新查找';

  @override
  String get lyricsChooseFile => '选择歌词文件';

  @override
  String get lyricsAttached => '歌词已关联';

  @override
  String get lyricsSubtitle => '正在播放的那首歌的词';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsSubtitle => '调整外观、语言、音乐库与音源健康度。';

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
  String get settingsSourceCacheLimit => '每来源最多保留';

  @override
  String get settingsSourceCacheLimitHint => '优先保留收藏、最近播放与最近出现的曲目';

  @override
  String get settingsNoLimit => '不限';

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
  String get searchAddLibraryFailed => '加入音乐库失败';

  @override
  String get searchLoadMore => '加载更多';

  @override
  String get searchNoMore => '没有更多了';

  @override
  String get searchAutoSave => '搜索结果自动加入音乐库';

  @override
  String get searchAddToLibrary => '加入音乐库';

  @override
  String get searchAddAllToLibrary => '全部加入';

  @override
  String get searchAddedToLibrary => '已加入';

  @override
  String searchAddedManyToLibrary(int count) {
    return '已加入 $count 首到音乐库';
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
  String get sourceAddressNotHttp => '只支持 http(s) 地址';

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
  String get sourceLiveMusicArchiveDescription => 'Internet Archive 收藏的现场录音';

  @override
  String get sourceLiveMusicArchiveName => '现场音乐档案';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS 播客订阅变成可播放的单集';

  @override
  String get sourcePodcastRssName => '播客订阅';

  @override
  String get sourcePodcastCatalogName => '播客目录';

  @override
  String get sourcePodcastCatalogDescription => '搜索 gpodder 开放播客目录，取最新单集';

  @override
  String get podcastCatalogHint => '输入关键词找播客，留空则浏览目录';

  @override
  String get podcastCatalogFieldQueryHint => '例如爵士、历史、科技';

  @override
  String get podcastCatalogNoMatch => '没有找到播客';

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
  String get radioFieldCountry => '国家/地区';

  @override
  String get radioFieldCountryHint => '两位国家代码，例如 SG、MY、AU、JP；目录里有的国家都可以填';

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
  String get sourceFunkwhaleName => '联邦音乐';

  @override
  String get sourceFunkwhaleDescription => '联邦 Funkwhale 实例里的音乐';

  @override
  String get funkwhaleHint => '填写 Funkwhale 实例地址；只有私密库需要令牌';

  @override
  String get funkwhaleFieldServerHint => '例如 https://open.audio';

  @override
  String get funkwhaleFieldToken => '访问令牌';

  @override
  String get funkwhaleFieldTokenHint => '实例的库私密时才需要';

  @override
  String get funkwhaleFieldQueryHint => '例如爵士、民谣、电子';

  @override
  String get funkwhaleEmptyResponse => 'Funkwhale 返回了空响应';

  @override
  String get funkwhaleNoMatch => 'Funkwhale 上没有匹配的曲目';

  @override
  String get sourceAudiobookshelfName => '自建有声书';

  @override
  String get sourceAudiobookshelfDescription => '自建 Audiobookshelf 服务器里的有声书';

  @override
  String get audiobookshelfHint => '填写 Audiobookshelf 服务器的地址与令牌';

  @override
  String get audiobookshelfFieldServerHint => '例如 http://localhost:13378';

  @override
  String get audiobookshelfFieldToken => '访问令牌';

  @override
  String get audiobookshelfFieldTokenHint => 'Audiobookshelf 账号的 API 令牌';

  @override
  String get audiobookshelfFieldQueryHint => '例如历史、小说、科学';

  @override
  String get audiobookshelfEmptyResponse => 'Audiobookshelf 返回了空响应';

  @override
  String get audiobookshelfNoMatch => '没有找到有声书';

  @override
  String get sourcePlexName => '自建媒体库';

  @override
  String get sourcePlexDescription => '连接自建的 Plex 媒体库';

  @override
  String get plexHint => '填写 Plex 服务器的地址与访问令牌';

  @override
  String get plexFieldServerHint => '例如 http://localhost:32400';

  @override
  String get plexFieldToken => '访问令牌';

  @override
  String get plexFieldTokenHint => 'Plex 账号的 X-Plex-Token';

  @override
  String get plexNoMatch => 'Plex 上没有匹配的曲目';

  @override
  String plexInvalidAnswer(String error) {
    return '读不出 Plex 的回答：$error';
  }

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
  String get sourceLibrivoxName => '有声书';

  @override
  String get sourceLibrivoxDescription => 'LibriVox 志愿者朗读的公版有声书';

  @override
  String get librivoxHint => '输入书名或作者，留空则浏览最热门的有声书';

  @override
  String get librivoxFieldQueryHint => '例如爱丽丝梦游仙境、狄更斯、童话';

  @override
  String get librivoxNoMatch => '没有匹配的有声书';

  @override
  String get librivoxEmptyResponse => 'LibriVox 返回了空响应';

  @override
  String librivoxInvalidFeed(String error) {
    return '读不出一本书的章节列表：$error';
  }

  @override
  String get sourceEmbyName => 'Emby 媒体库';

  @override
  String get sourceEmbyDescription => '连接自建的 Emby 媒体库';

  @override
  String get embyHint => '填写自建 Emby 的地址与账号';

  @override
  String get embyFieldServerHint => '例如 http://localhost:8095';

  @override
  String get embyFieldUserHint => 'Emby 的登录用户名';

  @override
  String get embyFieldPasswordHint => '用于换取访问令牌';

  @override
  String get embyEmptyResponse => 'Emby 返回了空响应';

  @override
  String get embyAuthFailed => '无法连接 Emby 服务器，请检查地址与账号';

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
  String get trackFactAddress => '在线地址';

  @override
  String get trackDetailsTooltip => '查看详情';

  @override
  String get trackDetailsOpenPath => '打开文件';

  @override
  String get trackDetailsOpenFailed => '打不开这个文件';

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
  String get libraryEyebrow => '资料库';

  @override
  String get sourcesEyebrow => '连接';

  @override
  String get sidebarBrowse => '浏览';

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
  String get settingsPlaybackDescription => '决定启动时的播放行为，以及单击、双击歌曲时会发生什么';

  @override
  String get settingsResumePlaybackOnStartup => '启动时继续上次播放';

  @override
  String get settingsResumePlaybackOnStartupHint =>
      '打开 Tune 时总会恢复队列和播放进度；这个开关只决定当前这首是否自动继续播放，关掉则停在暂停状态';

  @override
  String get settingsReplaceQueueOnClick => '单击歌曲时替换播放队列';

  @override
  String get settingsReplaceQueueOnClickHint => '关掉时单击只把这首排进队列并立即播放，队列里的其余曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '双击时只标成喜欢';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '打开时双击只标成喜欢，不打断正在放的曲子；关掉时双击照常播放并标成喜欢';

  @override
  String get settingsFavoritesDoubleClickPlays => '双击喜欢的曲目时播放并替换队列';

  @override
  String get settingsFavoritesDoubleClickPlaysHint =>
      '打开时，双击喜欢列表里的曲目会播放它并把队列换成它；关掉时双击只标成喜欢';

  @override
  String get sidebarDiscover => '发现';

  @override
  String get discoverEyebrow => '发现';

  @override
  String get discoverTitle => '今天听什么';

  @override
  String get discoverSubtitle => '从你的音乐库和喜欢的曲目里挑的 · 只在本机计算';

  @override
  String get discoverRefresh => '换一批';

  @override
  String get discoverWhy => '怎么推荐';

  @override
  String get discoverWhyTitle => '推荐怎么来的';

  @override
  String get discoverWhyBody =>
      '发现页只用你的音乐库、标心的曲目、不感兴趣标记和可选的本地播放记录，在本机计算。不会上传，也不会替你搜索在线音源。';

  @override
  String get discoverWhyLibrary => '音乐库里的曲目和元数据';

  @override
  String get discoverWhyHearts => '你标了心的曲目';

  @override
  String get discoverWhyPrivacy => '只在你的电脑上计算，随时可以清除';

  @override
  String get discoverWhyClose => '知道了';

  @override
  String get discoverSectionDailyMix => '今日混音';

  @override
  String discoverSectionArtist(String artist) {
    return '因为你喜欢 $artist';
  }

  @override
  String discoverSectionExplore(String genre) {
    return '换个口味：$genre';
  }

  @override
  String discoverSectionExploreEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverSectionExploreEars => '换换耳朵';

  @override
  String get discoverSectionFresh => '刚入库';

  @override
  String discoverSectionSource(String source) {
    return '来自 $source';
  }

  @override
  String get discoverSectionFallback => '从你的音乐库挑的';

  @override
  String discoverDailyMixSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '熟悉的曲目 + 新发现 · $countString 首';
  }

  @override
  String get discoverPlay => '播放';

  @override
  String get discoverAddAllShort => '加入队列';

  @override
  String get discoverPlayAll => '播放全部';

  @override
  String get discoverAddAllToQueue => '全部加入队列';

  @override
  String get discoverShelfBack => '上一组';

  @override
  String get discoverShelfForward => '下一组';

  @override
  String get discoverMoreActions => '更多操作';

  @override
  String get discoverDismiss => '不感兴趣';

  @override
  String discoverDismissed(String title) {
    return '已减少「$title」的推荐';
  }

  @override
  String get discoverUndo => '撤销';

  @override
  String discoverAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首';
  }

  @override
  String get discoverAlreadyQueued => '这些歌已经在队列里了';

  @override
  String get discoverReasonFavorite => '你标了心';

  @override
  String discoverReasonArtist(String artist) {
    return '因为你喜欢 $artist';
  }

  @override
  String discoverReasonGenre(String genre) {
    return '你喜欢 $genre';
  }

  @override
  String discoverReasonEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverReasonFresh => '刚入库';

  @override
  String get discoverReasonUnheard => '还没听过';

  @override
  String discoverReasonSource(String source) {
    return '来自 $source';
  }

  @override
  String get discoverReasonFallback => '从你的音乐库挑的';

  @override
  String get discoverEmptyLibraryTitle => '音乐库还是空的';

  @override
  String get discoverEmptyLibrarySubtitle => '扫描本地音乐或连接一个音源，发现页才有东西可挑';

  @override
  String get discoverScanMusic => '扫描音乐';

  @override
  String get discoverConnectSources => '连接音源';

  @override
  String get discoverNoCandidatesTitle => '能推荐的都听过了';

  @override
  String get discoverNoCandidatesSubtitle => '去音乐库逛逛，或清掉不感兴趣标记';

  @override
  String get discoverGoToLibrary => '去音乐库';

  @override
  String get discoverLoadFailed => '发现页加载失败';

  @override
  String get discoverLoadFailedHint => '音乐库暂时读不出来，稍后再试';

  @override
  String get discoverClearTitle => '清除推荐记录？';

  @override
  String get discoverClearMessage => '会删除单曲与歌手的「少推荐」标记和本地播放记录；喜欢、音乐库和播放队列不受影响。';

  @override
  String get discoverCleared => '推荐记录已清除';

  @override
  String get settingsSectionDiscovery => '发现';

  @override
  String get settingsDiscoveryTitle => '发现页';

  @override
  String get settingsDiscoveryDescription => '推荐只在本机计算，不上传你的音乐库';

  @override
  String get settingsDiscoveryPrivacy => '推荐只使用音乐库、标心的曲目和不感兴趣标记。';

  @override
  String get discoverFavoriteHint => '标几首喜欢的歌，推荐会更准';

  @override
  String get settingsDiscoveryUseHistory => '本地播放记录';

  @override
  String get settingsDiscoveryUseHistoryHint => '只保存在本机，让推荐更贴近你；关闭后不再记录';

  @override
  String get discoverHistoryHint => '开启本地播放记录，推荐会更贴近你';

  @override
  String get discoverHistoryEnable => '开启';

  @override
  String get discoverClearAll => '清除推荐记录';

  @override
  String get discoverWhyHistory => '可选的本地播放记录（默认关闭）';

  @override
  String get settingsSectionSmartLyrics => '智能歌词';

  @override
  String get settingsSmartLyricsTitle => '歌词覆盖';

  @override
  String get settingsSmartLyricsDescription => '标签里的词和曲目旁的词稿都算；统计来自最近一次扫描';

  @override
  String get settingsSmartLyricsTotal => '曲目总数';

  @override
  String get settingsSmartLyricsResolved => '已知有词';

  @override
  String get settingsSmartLyricsMissing => '待补缺口';

  @override
  String get settingsSmartLyricsPreset => '接口模板';

  @override
  String get settingsSmartLyricsPresetCustom => '自定义';

  @override
  String get settingsSmartLyricsApiKey => '密钥';

  @override
  String get settingsSmartLyricsApiKeyHint => '粘贴你自己的 API 密钥';

  @override
  String get settingsSmartLyricsAdvanced => '高级';

  @override
  String get settingsSmartLyricsBaseUrl => '接口地址';

  @override
  String get settingsSmartLyricsAsrModels => '转写模型（逗号分隔）';

  @override
  String get settingsSmartLyricsChatModel => '文本模型';

  @override
  String get settingsSmartLyricsPrivacy => '生成会把整首歌的音频上传到你配置的端点；只发给你自己填的地址。';

  @override
  String get settingsSmartLyricsSampled => '抽样';

  @override
  String get settingsSmartLyricsChecked => '已核';

  @override
  String get settingsSmartLyricsAccuracy => '正确率';

  @override
  String get settingsSmartLyricsDrawSample => '开始抽样';

  @override
  String get settingsSmartLyricsAccuracyNote =>
      '正确率按已解决样本分层人工核对（直录棚 / Live / 说唱 / 非中文）；样本只增不减，改判以最后一笔为准。';

  @override
  String get settingsSmartLyricsLocal => '本地引擎';

  @override
  String get settingsSmartLyricsLocalOff => '关闭';

  @override
  String get settingsSmartLyricsLocalDownload => '下载模型';

  @override
  String get settingsSmartLyricsLocalBusy => '下载中……';

  @override
  String get settingsSmartLyricsLocalReady => '模型已就绪';

  @override
  String get settingsSmartLyricsLocalFailed => '下载失败：重试，或换个模型';

  @override
  String get settingsSmartLyricsBatch => '批量补齐';

  @override
  String get settingsSmartLyricsBatchStart => '补齐曲库';

  @override
  String get settingsSmartLyricsBatchStop => '停止';

  @override
  String get settingsSmartLyricsBatchRetry => '重查失败曲目';

  @override
  String get settingsSmartLyricsBudget => '云端预算（首/批，0 为不限）';

  @override
  String settingsSmartLyricsBatchIdle(int pending, int done, int failed) {
    return '待补 $pending · 已完成 $done · 失败 $failed';
  }

  @override
  String settingsSmartLyricsBatchRunning(int pending, int done) {
    return '正在补齐：待补 $pending · 已完成 $done';
  }

  @override
  String settingsSmartLyricsBudgetPaused(int budget) {
    return '已达云端预算（$budget 首），本批暂停——余下待补不丢';
  }

  @override
  String settingsSmartLyricsBatchFresh(int count) {
    return '新增 $count 首待补，按「补齐曲库」入队';
  }

  @override
  String get settingsSmartLyricsLeakCheck => '查漏长开：机器空闲时只重问人写票池，不花云端、不占 CPU';

  @override
  String get lyricsSmartGenerate => '智能生成';

  @override
  String get lyricsSmartGenerateNeedsKey => '还没有密钥——先到设置的「智能歌词」里贴一把';

  @override
  String get lyricsSmartGenerating => '正在生成歌词——先问人写稿，再开通道，一轮最多几分钟';

  @override
  String get lyricsSmartFailedAudio => '取音频失败：曲目没有本地副本，也没拉到流';

  @override
  String get lyricsSmartFailedUpload => '通道没有答上来：稍后再试，或到设置里检查钥匙与端点';

  @override
  String get lyricsSmartFailedEmpty => '没有识别出人声';

  @override
  String get lyricsSmartNote => '机器稿：票池生成，重新查找可以找更好的词';

  @override
  String get lyricsMarkLine => '这行不对';

  @override
  String get lyricsUnmarkLine => '撤销标记';

  @override
  String get lyricsMarkSong => '整首不对';

  @override
  String get lyricsMarkNotSung => '这不是唱的';

  @override
  String get lyricsMarksTitle => '标记管理';

  @override
  String get lyricsMarksEmpty => '还没有标记——听到不对的行，点行尾的小旗';

  @override
  String lyricsMarkLineNumber(int line) {
    return '第 $line 行';
  }

  @override
  String get lyricsMarkReword => '改词';

  @override
  String get lyricsMarkRewordTitle => '改这一行';

  @override
  String get lyricsMarkRewordSave => '保存改词';

  @override
  String get lyricsMarkRevoke => '撤销';

  @override
  String get lyricsMarkWaiting => '等复解';

  @override
  String get lyricsMarkResolved => '已复解';

  @override
  String get lyricsMarkReworded => '已改词';

  @override
  String get lyricsMarkRevoked => '已撤销';

  @override
  String get lyricsMarkSourceReader => '读者';

  @override
  String get lyricsMarkSourceSystem => '系统';

  @override
  String discoverSectionOnlineArtist(String artist) {
    return '在线找到的 $artist';
  }

  @override
  String get discoverFindMoreOnline => '在线找更多';

  @override
  String get discoverFindingMore => '正在找…';

  @override
  String get discoverNoOnlineSources => '没有启用的在线音源';

  @override
  String discoverOnlineNoResults(String artist) {
    return '没有找到更多 $artist 的歌';
  }

  @override
  String get discoverOnlineFailed => '在线查找失败，稍后再试';

  @override
  String discoverOnlineFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首在线结果';
  }

  @override
  String get discoverReasonAdjacent => '同一种口味，换个人';

  @override
  String get discoverLessArtist => '少推荐这位歌手';

  @override
  String discoverDismissedArtist(String artist) {
    return '已减少「$artist」的推荐';
  }

  @override
  String get discoverSectionFavoriteArtists => '更多来自你标心的歌手';

  @override
  String get discoverReasonCompleted => '你常把这首听完';

  @override
  String smartPromptCorrect(String title, String artist, String draft) {
    return '下面是一首歌的机器转写稿，可能有同音字或听错的词。歌名「$title」，歌手「$artist」。\n请修正错别字，行数与顺序必须与原稿完全一致。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$draft';
  }

  @override
  String smartPromptRebuild(String title, String artist) {
    return '请凭你对这首歌的了解，写出《$title》($artist) 的歌词，按演唱顺序拆成一行一句。\n只输出 JSON 字符串数组，不要输出其他内容。不确定的歌曲就输出空数组，不要编造：';
  }

  @override
  String smartPromptTranslate(String target, String lines) {
    return '把下面这首歌的歌词逐行译成$target，行数与顺序必须与原稿完全一致，不译标点风格差异。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$lines';
  }

  @override
  String smartPromptTransliterate(String lines) {
    return '把下面这首歌的歌词逐行转写成拉丁字母拼读（拼音或通行读音），行数与顺序必须与原稿完全一致。\n只输出 JSON 字符串数组，每个元素一行，不要输出其他内容：\n$lines';
  }

  @override
  String get smartContrastTargetLanguage => '英文';

  @override
  String get lyricsContrastTranslate => '翻译';

  @override
  String get lyricsContrastTransliterate => '音译';

  @override
  String get lyricsContrastDone => '已对照';

  @override
  String get settingsSmartLyricsAutoFill => '自动补齐：开着就把库里所有没词的歌自动补到有词';

  @override
  String get librarySortTooltip => '排序';

  @override
  String get librarySortRecent => '最近加入';

  @override
  String get librarySortTitle => '标题';

  @override
  String get librarySortArtist => '艺术家';

  @override
  String get librarySortAlbum => '专辑';

  @override
  String get librarySortDuration => '时长';

  @override
  String get libraryColumnTitle => '标题';

  @override
  String get libraryColumnArtist => '艺术家';

  @override
  String get libraryColumnAlbum => '专辑';

  @override
  String get libraryColumnAdded => '加入';

  @override
  String get libraryColumnDuration => '时长';

  @override
  String get libraryMoreActions => '更多操作';

  @override
  String get libraryViewColumns => '双列视图';

  @override
  String get libraryFilter => '筛选';

  @override
  String get libraryFilterClearAll => '清除全部';

  @override
  String get libraryFilterStatus => '状态';

  @override
  String get libraryFilterStatusAll => '全部';

  @override
  String get libraryFilterStatusLiked => '喜欢';

  @override
  String get libraryFilterStatusWithLyrics => '有词';

  @override
  String get libraryFilterStatusWithoutLyrics => '缺词';

  @override
  String get libraryFilterStatusInstrumental => '纯音乐';

  @override
  String get libraryFilterGenres => '流派';

  @override
  String get libraryFilterDecades => '年代';

  @override
  String get libraryFilterArtists => '艺术家';

  @override
  String get libraryFilterLanguages => '语言';

  @override
  String get libraryFilterFormats => '格式';

  @override
  String get libraryFilterDurations => '时长';

  @override
  String get libraryFilterAdded => '加入时间';

  @override
  String get libraryFilterDurationShort => '<2 分钟';

  @override
  String get libraryFilterDurationMedium => '2–5 分钟';

  @override
  String get libraryFilterDurationLong => '5–10 分钟';

  @override
  String get libraryFilterDurationEpic => '>10 分钟';

  @override
  String get libraryFilterAddedWeek => '最近 7 天';

  @override
  String get libraryFilterAddedMonth => '最近 30 天';

  @override
  String get libraryFilterAddedYear => '最近一年';

  @override
  String get libraryFilterAddedOlder => '更早';
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
  String get updateEyebrow => '更新';

  @override
  String get updateTitle => '版本';

  @override
  String get updateDescription => '檢查專案發布頁是否有新版本，並直接安裝';

  @override
  String updateCurrentVersion(String version) {
    return '目前版本 $version';
  }

  @override
  String get updateIdle => '還沒檢查過發布頁';

  @override
  String get updateChecking => '正在檢查發布頁…';

  @override
  String get updateUpToDate => '已經是最新版本';

  @override
  String updateAvailable(String version) {
    return '新版本 $version 可用';
  }

  @override
  String get updateDownloading => '正在下載';

  @override
  String get updateInstalling => '正在安裝…';

  @override
  String get updateReady => '更新已就緒，重新啟動後生效';

  @override
  String updateFailed(String error) {
    return '檢查失敗：$error';
  }

  @override
  String get updateCheck => '檢查更新';

  @override
  String get updateInstall => '下載並安裝';

  @override
  String get updateRetry => '重試';

  @override
  String get updateRestart => '立即重新啟動';

  @override
  String get updateNoArchive => '這個平台不支援自動安裝，請到發布頁手動下載';

  @override
  String get songMayBeUnavailable => '可能已失效';

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
  String librarySummary(int tracks, int albums, int sources) {
    final intl.NumberFormat tracksNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String tracksString = tracksNumberFormat.format(tracks);
    final intl.NumberFormat albumsNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String albumsString = albumsNumberFormat.format(albums);
    final intl.NumberFormat sourcesNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String sourcesString = sourcesNumberFormat.format(sources);

    return '$tracksString 首歌曲 · $albumsString 張專輯 · $sourcesString 個來源';
  }

  @override
  String get libraryClearSearch => '清除搜尋';

  @override
  String get libraryFilterSources => '篩選來源';

  @override
  String get libraryAllSources => '全部來源';

  @override
  String get libraryScanAllSources => '掃描全部音源';

  @override
  String get libraryLoadMore => '載入更多曲目';

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
  String get libraryViewSongs => '歌曲檢視';

  @override
  String get libraryViewAlbums => '專輯檢視';

  @override
  String get libraryUnknownAlbum => '未知專輯';

  @override
  String get libraryVariousArtists => '多位藝術家';

  @override
  String get libraryBackToAlbums => '返回專輯';

  @override
  String get queueTitle => '播放佇列';

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
  String get queueReorderTooltip => '拖曳排序';

  @override
  String get favoritesTitle => '喜歡';

  @override
  String get favoritesSubtitle => '標了心的曲子都在這裡';

  @override
  String get favoritesEyebrow => '收藏';

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
  String favoritesOutsideLibrary(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '另有 $countString 首標過，但不在音樂庫裡';
  }

  @override
  String get favoritesEmptyOutsideTitle => '標過的歌不在音樂庫裡';

  @override
  String get favoritesEmptyOutsideSubtitle => '音樂庫裡找不到它們，標記還留著';

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
  String get sourcesClearSongs => '清空曲目';

  @override
  String sourcesClearSongsTitle(String name) {
    return '清空「$name」的曲目？';
  }

  @override
  String get sourcesClearSongsHint => '只移除這個來源帶來的曲目，來源本身保留';

  @override
  String sourcesSongsCleared(String name) {
    return '已清空「$name」的曲目';
  }

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
  String get sourcesMoveUp => '上移';

  @override
  String get sourcesMoveDown => '下移';

  @override
  String get sourcesMoveToMore => '移到更多音源';

  @override
  String get sourcesMoveToMain => '移回主清單';

  @override
  String get sourcesMovedToMore => '已移到更多音源';

  @override
  String get sourcesMovedToMain => '已移回主清單';

  @override
  String sourcesHealthScore(int score) {
    return '健康度 $score/100';
  }

  @override
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
  ) {
    return '可用 $availability% · 設定 $configuration% · 掃描 $scan% · 新鮮 $freshness% · 產出 $output% · 速度 $speed% · 可靠 $reliability% · 穩定 $stability% · 可播放 $playable% · 封面 $artwork% · 中繼資料 $metadata% · 活躍 $activity%';
  }

  @override
  String get sourcesHealthWeightsTitle => '健康度權重';

  @override
  String get sourcesHealthWeightsHint => '調高某個維度，它在健康度裡的分量更大；總權重會自動歸一化。';

  @override
  String sourcesHealthWeightsTotal(int total) {
    return '總權重 $total · 自動歸一化';
  }

  @override
  String get settingsSourceHealthDescription =>
      '十二個維度目前的分量；調高一個維度，它在健康度裡的佔比就更大。';

  @override
  String get settingsAdjustSourceHealthWeights => '調整權重';

  @override
  String get sourcesHealthWeightsReset => '恢復預設';

  @override
  String get sourcesHealthAvailability => '可用';

  @override
  String get sourcesHealthConfiguration => '設定';

  @override
  String get sourcesHealthScan => '掃描';

  @override
  String get sourcesHealthFreshness => '新鮮';

  @override
  String get sourcesHealthOutput => '產出';

  @override
  String get sourcesHealthSpeed => '速度';

  @override
  String get sourcesHealthReliability => '可靠';

  @override
  String get sourcesHealthStability => '穩定';

  @override
  String get sourcesHealthPlayable => '可播放';

  @override
  String get sourcesHealthArtwork => '封面';

  @override
  String get sourcesHealthMetadata => '中繼資料';

  @override
  String get sourcesHealthActivity => '活躍';

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
  String get jsonFieldQueryHint => '搜尋用的關鍵字，會替換請求裡的佔位符；留空就按網址原樣問一次';

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
  String get jsonApiFieldMethodHint => 'GET 或 POST；只有 POST 帶請求體';

  @override
  String get jsonApiFieldBody => '請求體';

  @override
  String get jsonApiFieldBodyHint => 'POST 時的 JSON 物件；關鍵字會填進佔位符';

  @override
  String get sourceGraphqlName => 'GraphQL 介面';

  @override
  String get sourceGraphqlDescription => '用一份查詢文件問介面，篩選條件寫在文件裡';

  @override
  String get graphqlHint => '填寫介面網址、查詢文件與各欄位的路徑';

  @override
  String get graphqlFieldQuery => '查詢文件';

  @override
  String get graphqlFieldQueryHint =>
      'GraphQL 查詢文件，篩選條件寫在裡面；模板只是個起點，欄位要改成介面裡有的';

  @override
  String get graphqlFieldVariables => '變數';

  @override
  String get graphqlFieldVariablesHint => 'JSON 物件；關鍵字會填進佔位符';

  @override
  String get jsonPreviewNoTracks => '回傳裡沒有認出曲目';

  @override
  String get sourcePreviewTry => '試一下';

  @override
  String get sourcePreviewRunning => '正在試…';

  @override
  String sourcePreviewTracks(int count) {
    return '認出 $count 首';
  }

  @override
  String get sourceFormShowAdvanced => '更多選項';

  @override
  String get sourceFormHideAdvanced => '收起選項';

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
  String get fieldLimitPodcasts => '每次掃描播客數';

  @override
  String get fieldLimitStations => '每次掃描電台數';

  @override
  String get fieldScanPages => '每次掃描頁數';

  @override
  String get fieldScanPagesHint => '一次掃描翻幾頁，1–10；頁數越多掃描越久';

  @override
  String fieldLimitHint(int count, int max) {
    return '預設 $count，最多 $max';
  }

  @override
  String get fieldLimitBooks => '每次掃描書數';

  @override
  String get fieldLanguage => '語言';

  @override
  String get fieldLanguageHint => '只保留一種語言的有聲書';

  @override
  String get fieldLanguageAll => '不限制語言';

  @override
  String get fieldLanguageEnglish => '英語';

  @override
  String get fieldLanguageChinese => '中文';

  @override
  String get fieldLanguageFrench => '法語';

  @override
  String get fieldLanguageGerman => '德語';

  @override
  String get fieldLanguageSpanish => '西班牙語';

  @override
  String get fieldLanguageItalian => '義大利語';

  @override
  String get fieldLanguageJapanese => '日語';

  @override
  String get fieldLanguageRussian => '俄語';

  @override
  String get fieldLanguagePortuguese => '葡萄牙語';

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
  String get lyricsNothingPlaying => '還沒有正在播放的曲目';

  @override
  String get lyricsInvalidFile => '這個檔案裡沒有歌詞';

  @override
  String get lyricsRetry => '重試';

  @override
  String get lyricsSearchAgain => '重新尋找';

  @override
  String get lyricsChooseFile => '選擇歌詞檔案';

  @override
  String get lyricsAttached => '歌詞已連結';

  @override
  String get lyricsSubtitle => '正在播放的那首歌的詞';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsSubtitle => '調整外觀、語言、音樂庫與音源健康度。';

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
  String get settingsSourceCacheLimit => '每來源最多保留';

  @override
  String get settingsSourceCacheLimitHint => '優先保留收藏、最近播放與最近出現的曲目';

  @override
  String get settingsNoLimit => '不限';

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
  String get searchAddLibraryFailed => '加入音樂庫失敗';

  @override
  String get searchLoadMore => '載入更多';

  @override
  String get searchNoMore => '沒有更多了';

  @override
  String get searchAutoSave => '搜尋結果自動加入音樂庫';

  @override
  String get searchAddToLibrary => '加入音樂庫';

  @override
  String get searchAddAllToLibrary => '全部加入';

  @override
  String get searchAddedToLibrary => '已加入';

  @override
  String searchAddedManyToLibrary(int count) {
    return '已加入 $count 首到音樂庫';
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
  String get sourceAddressNotHttp => '只支援 http(s) 網址';

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
  String get sourceLiveMusicArchiveDescription => 'Internet Archive 收藏的現場錄音';

  @override
  String get sourceLiveMusicArchiveName => '現場音樂檔案';

  @override
  String get sourcePodcastRssDescription => '把任意 RSS podcast 訂閱變成可播放的單集';

  @override
  String get sourcePodcastRssName => 'Podcast 訂閱';

  @override
  String get sourcePodcastCatalogName => '播客目錄';

  @override
  String get sourcePodcastCatalogDescription => '搜尋 gpodder 開放播客目錄，取最新單集';

  @override
  String get podcastCatalogHint => '輸入關鍵字找播客，留空則瀏覽目錄';

  @override
  String get podcastCatalogFieldQueryHint => '例如爵士、歷史、科技';

  @override
  String get podcastCatalogNoMatch => '沒有找到播客';

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
  String get radioFieldCountry => '國家／地區';

  @override
  String get radioFieldCountryHint => '兩位國家代碼，例如 SG、MY、AU、JP；目錄裡有的國家都可以填';

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
  String get sourceFunkwhaleName => '聯邦音樂';

  @override
  String get sourceFunkwhaleDescription => '聯邦 Funkwhale 實例裡的音樂';

  @override
  String get funkwhaleHint => '填寫 Funkwhale 實例位址；只有私密庫需要權杖';

  @override
  String get funkwhaleFieldServerHint => '例如 https://open.audio';

  @override
  String get funkwhaleFieldToken => '存取權杖';

  @override
  String get funkwhaleFieldTokenHint => '實例的庫私密時才需要';

  @override
  String get funkwhaleFieldQueryHint => '例如爵士、民謠、電子';

  @override
  String get funkwhaleEmptyResponse => 'Funkwhale 回傳了空回應';

  @override
  String get funkwhaleNoMatch => 'Funkwhale 上沒有符合的曲目';

  @override
  String get sourceAudiobookshelfName => '自架有聲書';

  @override
  String get sourceAudiobookshelfDescription => '自架 Audiobookshelf 伺服器裡的有聲書';

  @override
  String get audiobookshelfHint => '填寫 Audiobookshelf 伺服器的位址與權杖';

  @override
  String get audiobookshelfFieldServerHint => '例如 http://localhost:13378';

  @override
  String get audiobookshelfFieldToken => '存取權杖';

  @override
  String get audiobookshelfFieldTokenHint => 'Audiobookshelf 帳號的 API 權杖';

  @override
  String get audiobookshelfFieldQueryHint => '例如歷史、小說、科學';

  @override
  String get audiobookshelfEmptyResponse => 'Audiobookshelf 回傳了空回應';

  @override
  String get audiobookshelfNoMatch => '沒有找到有聲書';

  @override
  String get sourcePlexName => '自架媒體庫';

  @override
  String get sourcePlexDescription => '連結自架的 Plex 媒體庫';

  @override
  String get plexHint => '填寫 Plex 伺服器的位址與存取權杖';

  @override
  String get plexFieldServerHint => '例如 http://localhost:32400';

  @override
  String get plexFieldToken => '存取權杖';

  @override
  String get plexFieldTokenHint => 'Plex 帳號的 X-Plex-Token';

  @override
  String get plexNoMatch => 'Plex 上沒有符合的曲目';

  @override
  String plexInvalidAnswer(String error) {
    return '讀不出 Plex 的回應：$error';
  }

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
  String get sourceLibrivoxName => '有聲書';

  @override
  String get sourceLibrivoxDescription => 'LibriVox 志工朗讀的公版有聲書';

  @override
  String get librivoxHint => '輸入書名或作者，留空白則瀏覽最熱門的有聲書';

  @override
  String get librivoxFieldQueryHint => '例如愛麗絲夢遊仙境、狄更斯、童話';

  @override
  String get librivoxNoMatch => '沒有符合的有聲書';

  @override
  String get librivoxEmptyResponse => 'LibriVox 回傳了空回應';

  @override
  String librivoxInvalidFeed(String error) {
    return '讀不出一本書的章節列表：$error';
  }

  @override
  String get sourceEmbyName => 'Emby 媒體庫';

  @override
  String get sourceEmbyDescription => '連接自建的 Emby 媒體庫';

  @override
  String get embyHint => '填寫自建 Emby 的位址與帳號';

  @override
  String get embyFieldServerHint => '例如 http://localhost:8095';

  @override
  String get embyFieldUserHint => 'Emby 的登入使用者名稱';

  @override
  String get embyFieldPasswordHint => '用於換取存取權杖';

  @override
  String get embyEmptyResponse => 'Emby 回傳了空回應';

  @override
  String get embyAuthFailed => '無法連線 Emby 伺服器，請檢查位址與帳號';

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
  String get trackFactAddress => '線上位址';

  @override
  String get trackDetailsTooltip => '查看詳情';

  @override
  String get trackDetailsOpenPath => '打開檔案';

  @override
  String get trackDetailsOpenFailed => '打不開這個檔案';

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
  String get libraryEyebrow => '資料庫';

  @override
  String get sourcesEyebrow => '連線';

  @override
  String get sidebarBrowse => '瀏覽';

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
  String get settingsPlaybackDescription => '決定啟動時的播放行為，以及單擊、雙擊歌曲時會發生什麼';

  @override
  String get settingsResumePlaybackOnStartup => '啟動時繼續上次播放';

  @override
  String get settingsResumePlaybackOnStartupHint =>
      '開啟 Tune 時總會恢復佇列和播放進度；這個開關只決定當前這首是否自動繼續播放，關掉則停在暫停狀態';

  @override
  String get settingsReplaceQueueOnClick => '單擊歌曲時取代播放佇列';

  @override
  String get settingsReplaceQueueOnClickHint => '關掉時單擊只把這首排進佇列並立即播放，佇列裡的其餘曲目保留';

  @override
  String get settingsOnlyLikeOnDoubleClick => '雙擊時只標成喜歡';

  @override
  String get settingsOnlyLikeOnDoubleClickHint =>
      '開啟時雙擊只標成喜歡，不打斷正在播放的曲子；關閉時雙擊照常播放並標成喜歡';

  @override
  String get settingsFavoritesDoubleClickPlays => '雙擊喜歡的曲目時播放並替換佇列';

  @override
  String get settingsFavoritesDoubleClickPlaysHint =>
      '開啟時，雙擊喜歡列表裡的曲目會播放它並把佇列換成它；關閉時雙擊只標成喜歡';

  @override
  String get sidebarDiscover => '發現';

  @override
  String get discoverEyebrow => '發現';

  @override
  String get discoverTitle => '今天聽什麼';

  @override
  String get discoverSubtitle => '從你的音樂庫和喜歡的曲目裡挑的 · 只在本機計算';

  @override
  String get discoverRefresh => '換一批';

  @override
  String get discoverWhy => '怎麼推薦';

  @override
  String get discoverWhyTitle => '推薦怎麼來的';

  @override
  String get discoverWhyBody =>
      '發現頁只用你的音樂庫、標心的曲目、不感興趣標記和可選的本機播放記錄，在本機計算。不會上傳，也不會替你搜尋線上音源。';

  @override
  String get discoverWhyLibrary => '音樂庫裡的曲目和中繼資料';

  @override
  String get discoverWhyHearts => '你標了心的曲目';

  @override
  String get discoverWhyPrivacy => '只在你的電腦上計算，隨時可以清除';

  @override
  String get discoverWhyClose => '知道了';

  @override
  String get discoverSectionDailyMix => '今日混音';

  @override
  String discoverSectionArtist(String artist) {
    return '因為你喜歡 $artist';
  }

  @override
  String discoverSectionExplore(String genre) {
    return '換個口味：$genre';
  }

  @override
  String discoverSectionExploreEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverSectionExploreEars => '換換耳朵';

  @override
  String get discoverSectionFresh => '剛入庫';

  @override
  String discoverSectionSource(String source) {
    return '來自 $source';
  }

  @override
  String get discoverSectionFallback => '從你的音樂庫挑的';

  @override
  String discoverDailyMixSubtitle(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '熟悉的曲目 + 新發現 · $countString 首';
  }

  @override
  String get discoverPlay => '播放';

  @override
  String get discoverAddAllShort => '加入佇列';

  @override
  String get discoverPlayAll => '播放全部';

  @override
  String get discoverAddAllToQueue => '全部加入佇列';

  @override
  String get discoverShelfBack => '上一組';

  @override
  String get discoverShelfForward => '下一組';

  @override
  String get discoverMoreActions => '更多操作';

  @override
  String get discoverDismiss => '不感興趣';

  @override
  String discoverDismissed(String title) {
    return '已減少「$title」的推薦';
  }

  @override
  String get discoverUndo => '復原';

  @override
  String discoverAddedToQueue(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首';
  }

  @override
  String get discoverAlreadyQueued => '這些歌已經在佇列裡了';

  @override
  String get discoverReasonFavorite => '你標了心';

  @override
  String discoverReasonArtist(String artist) {
    return '因為你喜歡 $artist';
  }

  @override
  String discoverReasonGenre(String genre) {
    return '你喜歡 $genre';
  }

  @override
  String discoverReasonEra(int decade) {
    return '回到 $decade 年代';
  }

  @override
  String get discoverReasonFresh => '剛入庫';

  @override
  String get discoverReasonUnheard => '還沒聽過';

  @override
  String discoverReasonSource(String source) {
    return '來自 $source';
  }

  @override
  String get discoverReasonFallback => '從你的音樂庫挑的';

  @override
  String get discoverEmptyLibraryTitle => '音樂庫還是空的';

  @override
  String get discoverEmptyLibrarySubtitle => '掃描本機音樂或連接一個音源，發現頁才有東西可挑';

  @override
  String get discoverScanMusic => '掃描音樂';

  @override
  String get discoverConnectSources => '連接音源';

  @override
  String get discoverNoCandidatesTitle => '能推薦的都聽過了';

  @override
  String get discoverNoCandidatesSubtitle => '去音樂庫逛逛，或清掉不感興趣標記';

  @override
  String get discoverGoToLibrary => '去音樂庫';

  @override
  String get discoverLoadFailed => '發現頁載入失敗';

  @override
  String get discoverLoadFailedHint => '音樂庫暫時讀不出來，稍後再試';

  @override
  String get discoverClearTitle => '清除推薦記錄？';

  @override
  String get discoverClearMessage => '會刪除單曲與歌手的「少推薦」標記和本機播放記錄；喜歡、音樂庫和播放佇列不受影響。';

  @override
  String get discoverCleared => '推薦記錄已清除';

  @override
  String get settingsSectionDiscovery => '發現';

  @override
  String get settingsDiscoveryTitle => '發現頁';

  @override
  String get settingsDiscoveryDescription => '推薦只在本機計算，不上傳你的音樂庫';

  @override
  String get settingsDiscoveryPrivacy => '推薦只使用音樂庫、標心的曲目和不感興趣標記。';

  @override
  String get discoverFavoriteHint => '標幾首喜歡的歌，推薦會更準';

  @override
  String get settingsDiscoveryUseHistory => '本機播放記錄';

  @override
  String get settingsDiscoveryUseHistoryHint => '只保存在本機，讓推薦更貼近你；關閉後不再記錄';

  @override
  String get discoverHistoryHint => '開啟本機播放記錄，推薦會更貼近你';

  @override
  String get discoverHistoryEnable => '開啟';

  @override
  String get discoverClearAll => '清除推薦記錄';

  @override
  String get discoverWhyHistory => '可選的本機播放記錄（預設關閉）';

  @override
  String get settingsSectionSmartLyrics => '智慧歌詞';

  @override
  String get settingsSmartLyricsTitle => '歌詞覆蓋';

  @override
  String get settingsSmartLyricsDescription => '標籤裡的詞和曲目旁的詞稿都算；統計來自最近一次掃描';

  @override
  String get settingsSmartLyricsTotal => '曲目總數';

  @override
  String get settingsSmartLyricsResolved => '已知有詞';

  @override
  String get settingsSmartLyricsMissing => '待補缺口';

  @override
  String get settingsSmartLyricsPreset => '介面範本';

  @override
  String get settingsSmartLyricsPresetCustom => '自訂';

  @override
  String get settingsSmartLyricsApiKey => '金鑰';

  @override
  String get settingsSmartLyricsApiKeyHint => '貼上你自己的 API 金鑰';

  @override
  String get settingsSmartLyricsAdvanced => '進階';

  @override
  String get settingsSmartLyricsBaseUrl => '介面位址';

  @override
  String get settingsSmartLyricsAsrModels => '轉寫模型（逗號分隔）';

  @override
  String get settingsSmartLyricsChatModel => '文字模型';

  @override
  String get settingsSmartLyricsPrivacy => '生成會把整首歌的音訊上傳到你設定的端點；只發給你自己填的位址。';

  @override
  String get settingsSmartLyricsSampled => '抽樣';

  @override
  String get settingsSmartLyricsChecked => '已核';

  @override
  String get settingsSmartLyricsAccuracy => '正確率';

  @override
  String get settingsSmartLyricsDrawSample => '開始抽樣';

  @override
  String get settingsSmartLyricsAccuracyNote =>
      '正確率按已解決樣本分層人工核對（直錄棚 / Live / 說唱 / 非中文）；樣本只增不減，改判以最後一筆為準。';

  @override
  String get settingsSmartLyricsLocal => '本機引擎';

  @override
  String get settingsSmartLyricsLocalOff => '關閉';

  @override
  String get settingsSmartLyricsLocalDownload => '下載模型';

  @override
  String get settingsSmartLyricsLocalBusy => '下載中……';

  @override
  String get settingsSmartLyricsLocalReady => '模型已就緒';

  @override
  String get settingsSmartLyricsLocalFailed => '下載失敗：重試，或換個模型';

  @override
  String get settingsSmartLyricsBatch => '批次補齊';

  @override
  String get settingsSmartLyricsBatchStart => '補齊曲庫';

  @override
  String get settingsSmartLyricsBatchStop => '停止';

  @override
  String get settingsSmartLyricsBatchRetry => '重查失敗曲目';

  @override
  String get settingsSmartLyricsBudget => '雲端預算（首/批，0 為不限）';

  @override
  String settingsSmartLyricsBatchIdle(int pending, int done, int failed) {
    return '待補 $pending · 已完成 $done · 失敗 $failed';
  }

  @override
  String settingsSmartLyricsBatchRunning(int pending, int done) {
    return '正在補齊：待補 $pending · 已完成 $done';
  }

  @override
  String settingsSmartLyricsBudgetPaused(int budget) {
    return '已達雲端預算（$budget 首），本批暫停——餘下待補不丟';
  }

  @override
  String settingsSmartLyricsBatchFresh(int count) {
    return '新增 $count 首待補，按「補齊曲庫」入隊';
  }

  @override
  String get settingsSmartLyricsLeakCheck => '查漏長開：機器閒置時只重問人寫票池，不花雲端、不佔 CPU';

  @override
  String get lyricsSmartGenerate => '智慧生成';

  @override
  String get lyricsSmartGenerateNeedsKey => '還沒有金鑰——先到設定的「智慧歌詞」裡貼一把';

  @override
  String get lyricsSmartGenerating => '正在生成歌詞——先問人寫稿，再開通道，一輪最多幾分鐘';

  @override
  String get lyricsSmartFailedAudio => '取音訊失敗：曲目沒有本機副本，也沒拉到串流';

  @override
  String get lyricsSmartFailedUpload => '通道沒有答上來：稍後再試，或到設定裡檢查金鑰與端點';

  @override
  String get lyricsSmartFailedEmpty => '沒有識別出人聲';

  @override
  String get lyricsSmartNote => '機器稿：票池生成，重新查找可以找更好的詞';

  @override
  String get lyricsMarkLine => '這行不對';

  @override
  String get lyricsUnmarkLine => '撤銷標記';

  @override
  String get lyricsMarkSong => '整首不對';

  @override
  String get lyricsMarkNotSung => '這不是唱的';

  @override
  String get lyricsMarksTitle => '標記管理';

  @override
  String get lyricsMarksEmpty => '還沒有標記——聽到不對的行，點行尾的小旗';

  @override
  String lyricsMarkLineNumber(int line) {
    return '第 $line 行';
  }

  @override
  String get lyricsMarkReword => '改詞';

  @override
  String get lyricsMarkRewordTitle => '改這一行';

  @override
  String get lyricsMarkRewordSave => '保存改詞';

  @override
  String get lyricsMarkRevoke => '撤銷';

  @override
  String get lyricsMarkWaiting => '等復解';

  @override
  String get lyricsMarkResolved => '已復解';

  @override
  String get lyricsMarkReworded => '已改詞';

  @override
  String get lyricsMarkRevoked => '已撤銷';

  @override
  String get lyricsMarkSourceReader => '讀者';

  @override
  String get lyricsMarkSourceSystem => '系統';

  @override
  String discoverSectionOnlineArtist(String artist) {
    return '線上找到的 $artist';
  }

  @override
  String get discoverFindMoreOnline => '線上找更多';

  @override
  String get discoverFindingMore => '正在找…';

  @override
  String get discoverNoOnlineSources => '沒有啟用的線上音源';

  @override
  String discoverOnlineNoResults(String artist) {
    return '沒有找到更多 $artist 的歌';
  }

  @override
  String get discoverOnlineFailed => '線上查找失敗，稍後再試';

  @override
  String discoverOnlineFound(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '已加入 $countString 首線上結果';
  }

  @override
  String get discoverReasonAdjacent => '同一種口味，換個人';

  @override
  String get discoverLessArtist => '少推薦這位歌手';

  @override
  String discoverDismissedArtist(String artist) {
    return '已減少「$artist」的推薦';
  }

  @override
  String get discoverSectionFavoriteArtists => '更多來自你標心的歌手';

  @override
  String get discoverReasonCompleted => '你常把這首聽完';

  @override
  String smartPromptCorrect(String title, String artist, String draft) {
    return '下面是一首歌的機器轉寫稿，可能有同音字或聽錯的詞。歌名「$title」，歌手「$artist」。\n請修正錯別字，行數與順序必須與原稿完全一致。\n只輸出 JSON 字串陣列，每個元素一行，不要輸出其他內容：\n$draft';
  }

  @override
  String smartPromptRebuild(String title, String artist) {
    return '請憑你對這首歌的了解，寫出《$title》($artist) 的歌詞，按演唱順序拆成一行一句。\n只輸出 JSON 字串陣列，不要輸出其他內容。不確定的歌曲就輸出空陣列，不要編造：';
  }

  @override
  String smartPromptTranslate(String target, String lines) {
    return '把下面這首歌的歌詞逐行譯成$target，行數與順序必須與原稿完全一致，不譯標點風格差異。\n只輸出 JSON 字串陣列，每個元素一行，不要輸出其他內容：\n$lines';
  }

  @override
  String smartPromptTransliterate(String lines) {
    return '把下面這首歌的歌詞逐行轉寫成拉丁字母拼讀（拼音或通行讀音），行數與順序必須與原稿完全一致。\n只輸出 JSON 字串陣列，每個元素一行，不要輸出其他內容：\n$lines';
  }

  @override
  String get smartContrastTargetLanguage => '英文';

  @override
  String get lyricsContrastTranslate => '翻譯';

  @override
  String get lyricsContrastTransliterate => '音譯';

  @override
  String get lyricsContrastDone => '已對照';

  @override
  String get settingsSmartLyricsAutoFill => '自動補齊：開著就把庫裡所有沒詞的歌自動補到有詞';

  @override
  String get librarySortTooltip => '排序';

  @override
  String get librarySortRecent => '最近加入';

  @override
  String get librarySortTitle => '標題';

  @override
  String get librarySortArtist => '藝術家';

  @override
  String get librarySortAlbum => '專輯';

  @override
  String get librarySortDuration => '時長';

  @override
  String get libraryColumnTitle => '標題';

  @override
  String get libraryColumnArtist => '藝術家';

  @override
  String get libraryColumnAlbum => '專輯';

  @override
  String get libraryColumnAdded => '加入';

  @override
  String get libraryColumnDuration => '時長';

  @override
  String get libraryMoreActions => '更多操作';

  @override
  String get libraryViewColumns => '雙欄檢視';

  @override
  String get libraryFilter => '篩選';

  @override
  String get libraryFilterClearAll => '清除全部';

  @override
  String get libraryFilterStatus => '状态';

  @override
  String get libraryFilterStatusAll => '全部';

  @override
  String get libraryFilterStatusLiked => '喜歡';

  @override
  String get libraryFilterStatusWithLyrics => '有詞';

  @override
  String get libraryFilterStatusWithoutLyrics => '缺詞';

  @override
  String get libraryFilterStatusInstrumental => '純音樂';

  @override
  String get libraryFilterGenres => '流派';

  @override
  String get libraryFilterDecades => '年代';

  @override
  String get libraryFilterArtists => '藝術家';

  @override
  String get libraryFilterLanguages => '語言';

  @override
  String get libraryFilterFormats => '格式';

  @override
  String get libraryFilterDurations => '時長';

  @override
  String get libraryFilterAdded => '加入時間';

  @override
  String get libraryFilterDurationShort => '<2 分钟';

  @override
  String get libraryFilterDurationMedium => '2–5 分钟';

  @override
  String get libraryFilterDurationLong => '5–10 分钟';

  @override
  String get libraryFilterDurationEpic => '>10 分钟';

  @override
  String get libraryFilterAddedWeek => '最近 7 天';

  @override
  String get libraryFilterAddedMonth => '最近 30 天';

  @override
  String get libraryFilterAddedYear => '最近一年';

  @override
  String get libraryFilterAddedOlder => '更早';
}

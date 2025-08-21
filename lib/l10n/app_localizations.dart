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
  ];

  /// No description provided for @app_name.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune'**
  String get app_name;

  /// No description provided for @welcome_message.
  ///
  /// In zh_CN, this message translates to:
  /// **'欢迎使用 Tune'**
  String get welcome_message;

  /// No description provided for @no_songs_found.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到歌曲'**
  String get no_songs_found;

  /// No description provided for @settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @retry.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @home.
  ///
  /// In zh_CN, this message translates to:
  /// **'首页'**
  String get home;

  /// No description provided for @home_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'首页'**
  String get home_title;

  /// No description provided for @recommend.
  ///
  /// In zh_CN, this message translates to:
  /// **'推荐'**
  String get recommend;

  /// No description provided for @featured.
  ///
  /// In zh_CN, this message translates to:
  /// **'精选'**
  String get featured;

  /// No description provided for @library.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库'**
  String get library;

  /// No description provided for @library_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库'**
  String get library_title;

  /// No description provided for @search.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @search_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索'**
  String get search_title;

  /// No description provided for @player.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器'**
  String get player;

  /// No description provided for @player_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放器'**
  String get player_title;

  /// No description provided for @playlist.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get playlist;

  /// No description provided for @about.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @custom_scan_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义扫描路径'**
  String get custom_scan_paths;

  /// No description provided for @add_custom_directory.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义音乐扫描目录'**
  String get add_custom_directory;

  /// No description provided for @no_custom_scan_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂无自定义扫描路径'**
  String get no_custom_scan_paths;

  /// No description provided for @full_platform_scan_note.
  ///
  /// In zh_CN, this message translates to:
  /// **'注意：如需全平台扫描，请使用侧边栏中的\"音乐扫描\"功能'**
  String get full_platform_scan_note;

  /// No description provided for @library_info.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库信息'**
  String get library_info;

  /// No description provided for @songs_count.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前音乐库包含 0 首歌曲'**
  String get songs_count;

  /// No description provided for @library_features.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库功能'**
  String get library_features;

  /// No description provided for @auto_extract_metadata.
  ///
  /// In zh_CN, this message translates to:
  /// **'• 音乐库会自动提取歌曲元数据（标题、艺术家、专辑等）'**
  String get auto_extract_metadata;

  /// No description provided for @how_to_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'如何使用音乐扫描：'**
  String get how_to_scan;

  /// No description provided for @scan_step1.
  ///
  /// In zh_CN, this message translates to:
  /// **'1. 点击左侧边栏中的\"音乐扫描\"菜单项'**
  String get scan_step1;

  /// No description provided for @scan_step2.
  ///
  /// In zh_CN, this message translates to:
  /// **'2. 在扫描页面点击\"开始扫描\"按钮'**
  String get scan_step2;

  /// No description provided for @scan_step3.
  ///
  /// In zh_CN, this message translates to:
  /// **'3. 等待扫描完成并查看结果'**
  String get scan_step3;

  /// No description provided for @scan_step4.
  ///
  /// In zh_CN, this message translates to:
  /// **'4. 扫描的音乐将自动出现在\"音乐库\"中'**
  String get scan_step4;

  /// No description provided for @faq.
  ///
  /// In zh_CN, this message translates to:
  /// **'常见问题'**
  String get faq;

  /// No description provided for @faq_scan_issue.
  ///
  /// In zh_CN, this message translates to:
  /// **'问：为什么找不到音乐文件？'**
  String get faq_scan_issue;

  /// No description provided for @faq_scan_issue_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'答：请确保设备上存在音乐文件，并且应用具有存储访问权限。'**
  String get faq_scan_issue_answer;

  /// No description provided for @faq_slow_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'问：为什么扫描很慢？'**
  String get faq_slow_scan;

  /// No description provided for @faq_slow_scan_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'答：首次扫描可能会较慢，后续扫描会更快。请耐心等待。'**
  String get faq_slow_scan_answer;

  /// No description provided for @faq_not_showing.
  ///
  /// In zh_CN, this message translates to:
  /// **'问：为什么扫描的歌曲没有显示在音乐库中？'**
  String get faq_not_showing;

  /// No description provided for @faq_not_showing_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'答：请确保扫描已完成，并尝试刷新音乐库页面。'**
  String get faq_not_showing_answer;

  /// No description provided for @contact_us.
  ///
  /// In zh_CN, this message translates to:
  /// **'如果您有任何问题或建议，请联系我们：'**
  String get contact_us;

  /// No description provided for @email.
  ///
  /// In zh_CN, this message translates to:
  /// **'📧 邮箱: support@tune-music.com'**
  String get email;

  /// No description provided for @website.
  ///
  /// In zh_CN, this message translates to:
  /// **'🌐 网站: https://tune-music.com'**
  String get website;

  /// No description provided for @unknown_artist.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知艺术家'**
  String get unknown_artist;

  /// No description provided for @unknown_album.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知专辑'**
  String get unknown_album;

  /// No description provided for @enable_desktop_lyrics.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用桌面歌词'**
  String get enable_desktop_lyrics;

  /// No description provided for @tag_vip.
  ///
  /// In zh_CN, this message translates to:
  /// **'VIP'**
  String get tag_vip;

  /// No description provided for @tag_singer.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌手'**
  String get tag_singer;

  /// No description provided for @tag_elite.
  ///
  /// In zh_CN, this message translates to:
  /// **'精英'**
  String get tag_elite;

  /// No description provided for @general_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'通用设置'**
  String get general_settings;

  /// No description provided for @auto_start.
  ///
  /// In zh_CN, this message translates to:
  /// **'开机自启'**
  String get auto_start;

  /// No description provided for @auto_start_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统启动时自动启动应用程序'**
  String get auto_start_description;

  /// No description provided for @window_size.
  ///
  /// In zh_CN, this message translates to:
  /// **'窗口大小'**
  String get window_size;

  /// No description provided for @window_size_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置应用程序启动时的默认窗口大小'**
  String get window_size_description;

  /// No description provided for @default_player.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认播放器'**
  String get default_player;

  /// No description provided for @default_player_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'将此应用程序设置为默认音频播放器'**
  String get default_player_description;

  /// No description provided for @desktop_lyrics.
  ///
  /// In zh_CN, this message translates to:
  /// **'桌面歌词'**
  String get desktop_lyrics;

  /// No description provided for @desktop_lyrics_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'在桌面上以浮动窗口形式显示歌词'**
  String get desktop_lyrics_description;

  /// No description provided for @small.
  ///
  /// In zh_CN, this message translates to:
  /// **'小'**
  String get small;

  /// No description provided for @medium.
  ///
  /// In zh_CN, this message translates to:
  /// **'中'**
  String get medium;

  /// No description provided for @large.
  ///
  /// In zh_CN, this message translates to:
  /// **'大'**
  String get large;

  /// No description provided for @version.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本: 1.0.0'**
  String get version;

  /// No description provided for @platform.
  ///
  /// In zh_CN, this message translates to:
  /// **'平台'**
  String get platform;

  /// No description provided for @about_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune 是一款现代音乐播放器，让您可以轻松管理和播放本地音乐收藏。凭借简洁直观的界面，Tune 提供了无缝的音乐体验。'**
  String get about_description;

  /// No description provided for @features.
  ///
  /// In zh_CN, this message translates to:
  /// **'功能'**
  String get features;

  /// No description provided for @high_quality_audio_playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'高品质音频播放'**
  String get high_quality_audio_playback;

  /// No description provided for @supports_multiple_audio_formats.
  ///
  /// In zh_CN, this message translates to:
  /// **'支持多种音频格式，包括 MP3、FLAC、WAV 等'**
  String get supports_multiple_audio_formats;

  /// No description provided for @local_music_management.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地音乐管理'**
  String get local_music_management;

  /// No description provided for @automatically_scans_and_organizes_local_music_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动扫描和整理您的本地音乐库'**
  String get automatically_scans_and_organizes_local_music_library;

  /// No description provided for @multi_language_support.
  ///
  /// In zh_CN, this message translates to:
  /// **'多语言支持'**
  String get multi_language_support;

  /// No description provided for @supports_chinese_english_japanese_korean_russian_and_more.
  ///
  /// In zh_CN, this message translates to:
  /// **'支持中文、英文、日文、韩文、俄文等多种语言'**
  String get supports_chinese_english_japanese_korean_russian_and_more;

  /// No description provided for @multiple_themes.
  ///
  /// In zh_CN, this message translates to:
  /// **'多种主题'**
  String get multiple_themes;

  /// No description provided for @eight_theme_colors_with_dark_light_mode_switching.
  ///
  /// In zh_CN, this message translates to:
  /// **'八种主题颜色，支持深色/浅色模式切换'**
  String get eight_theme_colors_with_dark_light_mode_switching;

  /// No description provided for @lyrics_synchronization.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词同步'**
  String get lyrics_synchronization;

  /// No description provided for @lrc_format_lyrics_real_time_synchronization_display.
  ///
  /// In zh_CN, this message translates to:
  /// **'LRC 格式歌词实时同步显示'**
  String get lrc_format_lyrics_real_time_synchronization_display;

  /// No description provided for @smart_search.
  ///
  /// In zh_CN, this message translates to:
  /// **'智能搜索'**
  String get smart_search;

  /// No description provided for @supports_searching_by_song_title_artist_album_and_other_metadata.
  ///
  /// In zh_CN, this message translates to:
  /// **'支持按歌曲标题、艺术家、专辑和其他元数据搜索'**
  String get supports_searching_by_song_title_artist_album_and_other_metadata;

  /// No description provided for @open_source_license.
  ///
  /// In zh_CN, this message translates to:
  /// **'开源许可'**
  String get open_source_license;

  /// No description provided for @opensource_license_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'该项目根据 MIT 许可证授权 - 有关详细信息，请参阅 LICENSE 文件。'**
  String get opensource_license_description;

  /// No description provided for @github_project_address.
  ///
  /// In zh_CN, this message translates to:
  /// **'GitHub 项目地址'**
  String get github_project_address;

  /// No description provided for @contact_us_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'如果您有任何问题、建议或反馈，请随时通过以下渠道与我们联系。'**
  String get contact_us_description;

  /// No description provided for @official_website.
  ///
  /// In zh_CN, this message translates to:
  /// **'官方网站'**
  String get official_website;

  /// No description provided for @access_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'• 可随时访问和管理音乐库'**
  String get access_library;

  /// No description provided for @add_custom_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'• 可添加自定义扫描路径'**
  String get add_custom_paths;

  /// No description provided for @scan_completion.
  ///
  /// In zh_CN, this message translates to:
  /// **'• 扫描完成后可在音乐库查看结果'**
  String get scan_completion;

  /// No description provided for @auto_metadata_extraction.
  ///
  /// In zh_CN, this message translates to:
  /// **'• 自动从音乐文件中提取元数据'**
  String get auto_metadata_extraction;

  /// No description provided for @scan_instructions.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描说明'**
  String get scan_instructions;

  /// No description provided for @music_library_management.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库管理'**
  String get music_library_management;

  /// No description provided for @failed_to_save_custom_path.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存自定义路径失败'**
  String get failed_to_save_custom_path;

  /// No description provided for @custom_path_scanning_will_be_implemented.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义路径扫描将在未来版本中实现'**
  String get custom_path_scanning_will_be_implemented;

  /// No description provided for @error.
  ///
  /// In zh_CN, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @featured_playlists.
  ///
  /// In zh_CN, this message translates to:
  /// **'精选播放列表'**
  String get featured_playlists;

  /// No description provided for @featured_artists.
  ///
  /// In zh_CN, this message translates to:
  /// **'精选艺术家'**
  String get featured_artists;

  /// No description provided for @featured_albums.
  ///
  /// In zh_CN, this message translates to:
  /// **'精选专辑'**
  String get featured_albums;

  /// No description provided for @songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'首歌曲'**
  String get songs;

  /// No description provided for @music_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐扫描'**
  String get music_scan;

  /// No description provided for @scan_local_music.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描本地音乐'**
  String get scan_local_music;

  /// No description provided for @search_error.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索错误'**
  String get search_error;

  /// No description provided for @no_matching_songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到匹配的歌曲'**
  String get no_matching_songs;

  /// No description provided for @playback_error.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放错误'**
  String get playback_error;

  /// No description provided for @no_song_playing.
  ///
  /// In zh_CN, this message translates to:
  /// **'当前无歌曲播放'**
  String get no_song_playing;

  /// No description provided for @select_a_song_to_play.
  ///
  /// In zh_CN, this message translates to:
  /// **'请选择一首歌曲进行播放'**
  String get select_a_song_to_play;

  /// No description provided for @unknown_user.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知用户'**
  String get unknown_user;

  /// No description provided for @my_account.
  ///
  /// In zh_CN, this message translates to:
  /// **'我的账户'**
  String get my_account;

  /// No description provided for @select_language.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择语言'**
  String get select_language;

  /// No description provided for @cancel.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @failed_to_open_github.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开 GitHub 页面'**
  String get failed_to_open_github;

  /// No description provided for @theme_light.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色'**
  String get theme_dark;

  /// No description provided for @theme_system.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统'**
  String get theme_system;

  /// No description provided for @bottom_player_bar_now_playing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放'**
  String get bottom_player_bar_now_playing;

  /// No description provided for @bottom_player_bar_no_song.
  ///
  /// In zh_CN, this message translates to:
  /// **'未选择歌曲'**
  String get bottom_player_bar_no_song;

  /// No description provided for @song_list_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌曲'**
  String get song_list_title;

  /// No description provided for @song_list_no_songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到歌曲'**
  String get song_list_no_songs;

  /// No description provided for @settings_page_language.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言'**
  String get settings_page_language;

  /// No description provided for @settings_page_theme.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题'**
  String get settings_page_theme;

  /// No description provided for @theme_name_trendy_electro.
  ///
  /// In zh_CN, this message translates to:
  /// **'潮流电音'**
  String get theme_name_trendy_electro;

  /// No description provided for @theme_name_minimal_gray.
  ///
  /// In zh_CN, this message translates to:
  /// **'极简灰'**
  String get theme_name_minimal_gray;

  /// No description provided for @theme_name_nature_forest.
  ///
  /// In zh_CN, this message translates to:
  /// **'自然森林'**
  String get theme_name_nature_forest;

  /// No description provided for @theme_name_cyber_neon.
  ///
  /// In zh_CN, this message translates to:
  /// **'赛博霓虹'**
  String get theme_name_cyber_neon;

  /// No description provided for @theme_name_warm_healing.
  ///
  /// In zh_CN, this message translates to:
  /// **'温暖治愈'**
  String get theme_name_warm_healing;

  /// No description provided for @theme_name_dark_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式'**
  String get theme_name_dark_mode;

  /// No description provided for @theme_name_light_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色模式'**
  String get theme_name_light_mode;

  /// No description provided for @theme_name_system_theme.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统主题'**
  String get theme_name_system_theme;

  /// No description provided for @library_page_artists.
  ///
  /// In zh_CN, this message translates to:
  /// **'艺术家'**
  String get library_page_artists;

  /// No description provided for @library_page_albums.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑'**
  String get library_page_albums;

  /// No description provided for @library_page_genres.
  ///
  /// In zh_CN, this message translates to:
  /// **'流派'**
  String get library_page_genres;

  /// No description provided for @play_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get play_button;

  /// No description provided for @pause_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停'**
  String get pause_button;

  /// No description provided for @next_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一首'**
  String get next_button;

  /// No description provided for @previous_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一首'**
  String get previous_button;

  /// No description provided for @favorite_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get favorite_button;

  /// No description provided for @font_family.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体'**
  String get font_family;

  /// No description provided for @theme_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题模式'**
  String get theme_mode;

  /// No description provided for @light_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'浅色模式'**
  String get light_mode;

  /// No description provided for @dark_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'深色模式'**
  String get dark_mode;

  /// No description provided for @system_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统模式'**
  String get system_mode;

  /// No description provided for @artist_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'艺术家'**
  String get artist_title;

  /// No description provided for @search_hint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索歌曲...'**
  String get search_hint;

  /// No description provided for @artist_hint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索艺术家...'**
  String get artist_hint;

  /// No description provided for @album_hint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索专辑...'**
  String get album_hint;

  /// No description provided for @now_playing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放'**
  String get now_playing;

  /// No description provided for @no_things_players.
  ///
  /// In zh_CN, this message translates to:
  /// **'无播放器'**
  String get no_things_players;

  /// No description provided for @no_selected_song.
  ///
  /// In zh_CN, this message translates to:
  /// **'未选择歌曲'**
  String get no_selected_song;

  /// No description provided for @player_duration.
  ///
  /// In zh_CN, this message translates to:
  /// **'时长'**
  String get player_duration;

  /// No description provided for @player_artist.
  ///
  /// In zh_CN, this message translates to:
  /// **'艺术家'**
  String get player_artist;

  /// No description provided for @player_album.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑'**
  String get player_album;

  /// No description provided for @search_empty.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入搜索词以查找歌曲'**
  String get search_empty;

  /// No description provided for @search_no_results.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到与您的搜索匹配的歌曲'**
  String get search_no_results;

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

  /// No description provided for @font.
  ///
  /// In zh_CN, this message translates to:
  /// **'字体'**
  String get font;

  /// No description provided for @library_artists.
  ///
  /// In zh_CN, this message translates to:
  /// **'艺术家'**
  String get library_artists;

  /// No description provided for @library_albums.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑'**
  String get library_albums;

  /// No description provided for @library_genres.
  ///
  /// In zh_CN, this message translates to:
  /// **'流派'**
  String get library_genres;

  /// No description provided for @profile_title.
  ///
  /// In zh_CN, this message translates to:
  /// **'个人资料'**
  String get profile_title;

  /// No description provided for @username_default.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户'**
  String get username_default;

  /// No description provided for @user_email_default.
  ///
  /// In zh_CN, this message translates to:
  /// **'user@example.com'**
  String get user_email_default;

  /// No description provided for @search_hint_text.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索...'**
  String get search_hint_text;

  /// No description provided for @search_page_hint.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索歌曲...'**
  String get search_page_hint;

  /// No description provided for @search_page_empty.
  ///
  /// In zh_CN, this message translates to:
  /// **'输入搜索词以查找歌曲'**
  String get search_page_empty;

  /// No description provided for @search_page_no_results.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到与您的搜索匹配的歌曲'**
  String get search_page_no_results;

  /// No description provided for @settings_page_about.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get settings_page_about;

  /// No description provided for @language_name_en.
  ///
  /// In zh_CN, this message translates to:
  /// **'英语'**
  String get language_name_en;

  /// No description provided for @language_name_zh.
  ///
  /// In zh_CN, this message translates to:
  /// **'中文'**
  String get language_name_zh;

  /// No description provided for @english.
  ///
  /// In zh_CN, this message translates to:
  /// **'英语'**
  String get english;

  /// No description provided for @chinese_simplified.
  ///
  /// In zh_CN, this message translates to:
  /// **'中文 (简体)'**
  String get chinese_simplified;

  /// No description provided for @chinese_traditional.
  ///
  /// In zh_CN, this message translates to:
  /// **'中文 (繁体)'**
  String get chinese_traditional;

  /// No description provided for @chinese.
  ///
  /// In zh_CN, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @japanese.
  ///
  /// In zh_CN, this message translates to:
  /// **'日语'**
  String get japanese;

  /// No description provided for @korean.
  ///
  /// In zh_CN, this message translates to:
  /// **'韩语'**
  String get korean;

  /// No description provided for @russian.
  ///
  /// In zh_CN, this message translates to:
  /// **'俄语'**
  String get russian;

  /// No description provided for @german.
  ///
  /// In zh_CN, this message translates to:
  /// **'德语'**
  String get german;

  /// No description provided for @french.
  ///
  /// In zh_CN, this message translates to:
  /// **'法语'**
  String get french;

  /// No description provided for @spanish.
  ///
  /// In zh_CN, this message translates to:
  /// **'西班牙语'**
  String get spanish;

  /// No description provided for @playback_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放模式'**
  String get playback_mode;

  /// No description provided for @repeat_all.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部重复'**
  String get repeat_all;

  /// No description provided for @repeat_one.
  ///
  /// In zh_CN, this message translates to:
  /// **'单曲重复'**
  String get repeat_one;

  /// No description provided for @shuffle.
  ///
  /// In zh_CN, this message translates to:
  /// **'随机播放'**
  String get shuffle;

  /// No description provided for @audio_effects.
  ///
  /// In zh_CN, this message translates to:
  /// **'音频效果'**
  String get audio_effects;

  /// No description provided for @enable_equalizer.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用均衡器'**
  String get enable_equalizer;

  /// No description provided for @bass_boost.
  ///
  /// In zh_CN, this message translates to:
  /// **'低音增强'**
  String get bass_boost;

  /// No description provided for @spatial_audio.
  ///
  /// In zh_CN, this message translates to:
  /// **'空间音频'**
  String get spatial_audio;

  /// No description provided for @account_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户设置'**
  String get account_settings;

  /// No description provided for @general_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规'**
  String get general_tab;

  /// No description provided for @library_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库'**
  String get library_tab;

  /// No description provided for @account_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户'**
  String get account_tab;

  /// No description provided for @playback_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get playback_tab;

  /// No description provided for @about_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get about_tab;

  /// No description provided for @animations_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'动画'**
  String get animations_tab;

  /// No description provided for @username.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @auto_login.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动登录'**
  String get auto_login;

  /// No description provided for @save_password.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存密码'**
  String get save_password;

  /// No description provided for @account_settings_saved.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户设置已保存'**
  String get account_settings_saved;

  /// No description provided for @save.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @search_songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索歌曲...'**
  String get search_songs;

  /// No description provided for @artists.
  ///
  /// In zh_CN, this message translates to:
  /// **'艺术家'**
  String get artists;

  /// No description provided for @albums.
  ///
  /// In zh_CN, this message translates to:
  /// **'专辑'**
  String get albums;

  /// No description provided for @load_stats_failed.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载统计信息失败'**
  String get load_stats_failed;

  /// No description provided for @load_songs_failed.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载歌曲失败'**
  String get load_songs_failed;
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

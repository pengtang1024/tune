import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ru.dart';
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
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
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

  /// No description provided for @settings_saved.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置已保存'**
  String get settings_saved;

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

  /// No description provided for @playback_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放设置'**
  String get playback_settings;

  /// No description provided for @account_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'账户设置'**
  String get account_settings;

  /// No description provided for @general_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'常规设置'**
  String get general_settings;

  /// No description provided for @music_library_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库设置'**
  String get music_library_settings;

  /// No description provided for @about_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'关于'**
  String get about_settings;

  /// No description provided for @play_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放模式'**
  String get play_mode;

  /// No description provided for @sequence_playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'顺序播放'**
  String get sequence_playback;

  /// No description provided for @repeat_one.
  ///
  /// In zh_CN, this message translates to:
  /// **'单曲重复'**
  String get repeat_one;

  /// No description provided for @shuffle_playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'随机播放'**
  String get shuffle_playback;

  /// No description provided for @audio_quality.
  ///
  /// In zh_CN, this message translates to:
  /// **'音质'**
  String get audio_quality;

  /// No description provided for @low_quality.
  ///
  /// In zh_CN, this message translates to:
  /// **'低质量'**
  String get low_quality;

  /// No description provided for @medium_quality.
  ///
  /// In zh_CN, this message translates to:
  /// **'中等质量'**
  String get medium_quality;

  /// No description provided for @high_quality.
  ///
  /// In zh_CN, this message translates to:
  /// **'高质量'**
  String get high_quality;

  /// No description provided for @pause_when_headset_disconnected.
  ///
  /// In zh_CN, this message translates to:
  /// **'耳机断开时暂停'**
  String get pause_when_headset_disconnected;

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

  /// No description provided for @username.
  ///
  /// In zh_CN, this message translates to:
  /// **'用户名'**
  String get username;

  /// No description provided for @email.
  ///
  /// In zh_CN, this message translates to:
  /// **'邮箱'**
  String get email;

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

  /// No description provided for @save.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存'**
  String get save;

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

  /// No description provided for @add.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In zh_CN, this message translates to:
  /// **'移除'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In zh_CN, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh_CN, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @add_custom_path.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义路径'**
  String get add_custom_path;

  /// No description provided for @no_custom_scan_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'未设置自定义扫描路径'**
  String get no_custom_scan_paths;

  /// No description provided for @no_custom_scan_paths_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义文件夹路径以扫描特定位置的音乐文件'**
  String get no_custom_scan_paths_description;

  /// No description provided for @scan_local_music.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描本地音乐'**
  String get scan_local_music;

  /// No description provided for @scanning.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描中...'**
  String get scanning;

  /// No description provided for @scan_completed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描完成'**
  String get scan_completed;

  /// No description provided for @scan_failed.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描失败'**
  String get scan_failed;

  /// No description provided for @failed_to_load_songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'加载歌曲失败'**
  String get failed_to_load_songs;

  /// No description provided for @failed_to_load_songs_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法从您的音乐库加载歌曲。请检查您的网络连接或重新扫描音乐库。'**
  String get failed_to_load_songs_description;

  /// No description provided for @try_again.
  ///
  /// In zh_CN, this message translates to:
  /// **'重试'**
  String get try_again;

  /// No description provided for @scan_progress.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描进度'**
  String get scan_progress;

  /// No description provided for @scanning_path.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在扫描路径:'**
  String get scanning_path;

  /// No description provided for @no_songs_found_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'在您的设备上未找到任何音乐文件。'**
  String get no_songs_found_description;

  /// No description provided for @scan_again.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新扫描'**
  String get scan_again;

  /// No description provided for @scan_local_music_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描您的设备以查找音乐文件'**
  String get scan_local_music_description;

  /// No description provided for @custom_scan_paths_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义文件夹路径以扫描特定位置的音乐文件'**
  String get custom_scan_paths_description;

  /// No description provided for @scan_button.
  ///
  /// In zh_CN, this message translates to:
  /// **'开始扫描'**
  String get scan_button;

  /// No description provided for @cancel_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'取消扫描'**
  String get cancel_scan;

  /// No description provided for @failed_to_save_custom_scan_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'保存自定义扫描路径失败'**
  String get failed_to_save_custom_scan_paths;

  /// No description provided for @failed_to_add_custom_scan_path.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义扫描路径失败'**
  String get failed_to_add_custom_scan_path;

  /// No description provided for @failed_to_scan_music.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描音乐失败'**
  String get failed_to_scan_music;

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

  /// No description provided for @songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌曲'**
  String get songs;

  /// No description provided for @playlists.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放列表'**
  String get playlists;

  /// No description provided for @music_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库'**
  String get music_library;

  /// No description provided for @favorites.
  ///
  /// In zh_CN, this message translates to:
  /// **'收藏'**
  String get favorites;

  /// No description provided for @recently_played.
  ///
  /// In zh_CN, this message translates to:
  /// **'最近播放'**
  String get recently_played;

  /// No description provided for @top_charts.
  ///
  /// In zh_CN, this message translates to:
  /// **'排行榜'**
  String get top_charts;

  /// No description provided for @new_releases.
  ///
  /// In zh_CN, this message translates to:
  /// **'新歌发布'**
  String get new_releases;

  /// No description provided for @genres.
  ///
  /// In zh_CN, this message translates to:
  /// **'流派'**
  String get genres;

  /// No description provided for @now_playing.
  ///
  /// In zh_CN, this message translates to:
  /// **'正在播放'**
  String get now_playing;

  /// No description provided for @previous.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一首'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一首'**
  String get next;

  /// No description provided for @play.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放'**
  String get play;

  /// No description provided for @pause.
  ///
  /// In zh_CN, this message translates to:
  /// **'暂停'**
  String get pause;

  /// No description provided for @sequence.
  ///
  /// In zh_CN, this message translates to:
  /// **'顺序播放'**
  String get sequence;

  /// No description provided for @shuffle.
  ///
  /// In zh_CN, this message translates to:
  /// **'随机播放'**
  String get shuffle;

  /// No description provided for @scan_completed_no_new_songs.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描完成，未找到新歌曲'**
  String get scan_completed_no_new_songs;

  /// No description provided for @added_scanned_songs_to_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'已将扫描的歌曲添加到音乐库'**
  String get added_scanned_songs_to_library;

  /// No description provided for @rescan.
  ///
  /// In zh_CN, this message translates to:
  /// **'重新扫描'**
  String get rescan;

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

  /// No description provided for @add_to_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加到音乐库'**
  String get add_to_library;

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

  /// No description provided for @version.
  ///
  /// In zh_CN, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @platform.
  ///
  /// In zh_CN, this message translates to:
  /// **'平台'**
  String get platform;

  /// No description provided for @about_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'Tune 是一款现代化的音乐播放器，专为音乐爱好者设计。它支持多种音频格式，提供高质量的音频播放体验。'**
  String get about_description;

  /// No description provided for @features.
  ///
  /// In zh_CN, this message translates to:
  /// **'功能特性'**
  String get features;

  /// No description provided for @high_quality_audio_playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'高质量音频播放'**
  String get high_quality_audio_playback;

  /// No description provided for @supports_multiple_audio_formats.
  ///
  /// In zh_CN, this message translates to:
  /// **'支持多种音频格式（MP3、FLAC、WAV、AAC等）'**
  String get supports_multiple_audio_formats;

  /// No description provided for @local_music_management.
  ///
  /// In zh_CN, this message translates to:
  /// **'本地音乐管理'**
  String get local_music_management;

  /// No description provided for @automatically_scans_and_organizes_local_music_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动扫描并整理本地音乐库'**
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
  /// **'8种主题颜色，支持深色/浅色模式切换'**
  String get eight_theme_colors_with_dark_light_mode_switching;

  /// No description provided for @lyrics_synchronization.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌词同步'**
  String get lyrics_synchronization;

  /// No description provided for @lrc_format_lyrics_real_time_synchronization_display.
  ///
  /// In zh_CN, this message translates to:
  /// **'LRC格式歌词实时同步显示'**
  String get lrc_format_lyrics_real_time_synchronization_display;

  /// No description provided for @smart_search.
  ///
  /// In zh_CN, this message translates to:
  /// **'智能搜索'**
  String get smart_search;

  /// No description provided for @supports_searching_by_song_title_artist_album_and_other_metadata.
  ///
  /// In zh_CN, this message translates to:
  /// **'支持按歌曲名、艺术家、专辑等元数据搜索'**
  String get supports_searching_by_song_title_artist_album_and_other_metadata;

  /// No description provided for @open_source_license.
  ///
  /// In zh_CN, this message translates to:
  /// **'开源许可'**
  String get open_source_license;

  /// No description provided for @opensource_license_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'本项目使用开源许可证发布，源代码可在GitHub上获取。'**
  String get opensource_license_description;

  /// No description provided for @github_project_address.
  ///
  /// In zh_CN, this message translates to:
  /// **'GitHub项目地址'**
  String get github_project_address;

  /// No description provided for @contact_us.
  ///
  /// In zh_CN, this message translates to:
  /// **'联系我们'**
  String get contact_us;

  /// No description provided for @contact_us_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'如有任何问题，请通过以下方式联系我们：\n邮箱：support@tune.com'**
  String get contact_us_description;

  /// No description provided for @official_website.
  ///
  /// In zh_CN, this message translates to:
  /// **'官方网站'**
  String get official_website;

  /// No description provided for @auto_start.
  ///
  /// In zh_CN, this message translates to:
  /// **'开机自启'**
  String get auto_start;

  /// No description provided for @auto_start_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'系统启动时自动运行Tune'**
  String get auto_start_description;

  /// No description provided for @window_size.
  ///
  /// In zh_CN, this message translates to:
  /// **'窗口大小'**
  String get window_size;

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

  /// No description provided for @window_size_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置应用窗口的默认大小'**
  String get window_size_description;

  /// No description provided for @default_player.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认播放器'**
  String get default_player;

  /// No description provided for @default_player_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'将Tune设置为系统默认音频播放器'**
  String get default_player_description;

  /// No description provided for @desktop_lyrics.
  ///
  /// In zh_CN, this message translates to:
  /// **'桌面歌词'**
  String get desktop_lyrics;

  /// No description provided for @desktop_lyrics_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'在桌面上显示实时歌词'**
  String get desktop_lyrics_description;

  /// No description provided for @music_library_management.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库管理'**
  String get music_library_management;

  /// No description provided for @add_custom_directory.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义目录'**
  String get add_custom_directory;

  /// No description provided for @full_platform_scan_note.
  ///
  /// In zh_CN, this message translates to:
  /// **'全平台扫描说明：默认扫描系统音乐目录，可通过添加自定义路径扩展扫描范围。'**
  String get full_platform_scan_note;

  /// No description provided for @library_info.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库信息'**
  String get library_info;

  /// No description provided for @songs_count.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌曲总数'**
  String get songs_count;

  /// No description provided for @library_features.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐库功能'**
  String get library_features;

  /// No description provided for @access_library.
  ///
  /// In zh_CN, this message translates to:
  /// **'访问音乐库'**
  String get access_library;

  /// No description provided for @scan_instructions.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描说明'**
  String get scan_instructions;

  /// No description provided for @auto_extract_metadata.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动提取元数据'**
  String get auto_extract_metadata;

  /// No description provided for @add_custom_paths.
  ///
  /// In zh_CN, this message translates to:
  /// **'添加自定义路径'**
  String get add_custom_paths;

  /// No description provided for @scan_completion.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描完成'**
  String get scan_completion;

  /// No description provided for @auto_metadata_extraction.
  ///
  /// In zh_CN, this message translates to:
  /// **'自动元数据提取'**
  String get auto_metadata_extraction;

  /// No description provided for @how_to_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'如何扫描'**
  String get how_to_scan;

  /// No description provided for @scan_step1.
  ///
  /// In zh_CN, this message translates to:
  /// **'1. 点击扫描按钮开始扫描'**
  String get scan_step1;

  /// No description provided for @scan_step2.
  ///
  /// In zh_CN, this message translates to:
  /// **'2. 系统会自动扫描默认音乐目录'**
  String get scan_step2;

  /// No description provided for @scan_step3.
  ///
  /// In zh_CN, this message translates to:
  /// **'3. 可添加自定义目录扩展扫描范围'**
  String get scan_step3;

  /// No description provided for @scan_step4.
  ///
  /// In zh_CN, this message translates to:
  /// **'4. 扫描完成后歌曲会自动添加到音乐库'**
  String get scan_step4;

  /// No description provided for @faq.
  ///
  /// In zh_CN, this message translates to:
  /// **'常见问题'**
  String get faq;

  /// No description provided for @faq_scan_issue.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描问题'**
  String get faq_scan_issue;

  /// No description provided for @faq_scan_issue_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'如果扫描失败，请检查文件权限和路径是否正确。'**
  String get faq_scan_issue_answer;

  /// No description provided for @faq_slow_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描缓慢'**
  String get faq_slow_scan;

  /// No description provided for @faq_slow_scan_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'扫描速度取决于音乐库大小和硬盘性能，大库扫描可能需要较长时间。'**
  String get faq_slow_scan_answer;

  /// No description provided for @faq_not_showing.
  ///
  /// In zh_CN, this message translates to:
  /// **'歌曲未显示'**
  String get faq_not_showing;

  /// No description provided for @faq_not_showing_answer.
  ///
  /// In zh_CN, this message translates to:
  /// **'确保音乐文件格式受支持，并检查文件是否损坏。'**
  String get faq_not_showing_answer;

  /// No description provided for @music_scan.
  ///
  /// In zh_CN, this message translates to:
  /// **'音乐扫描'**
  String get music_scan;

  /// No description provided for @failed_to_open_github.
  ///
  /// In zh_CN, this message translates to:
  /// **'无法打开GitHub页面'**
  String get failed_to_open_github;

  /// No description provided for @select_language.
  ///
  /// In zh_CN, this message translates to:
  /// **'选择语言'**
  String get select_language;

  /// No description provided for @unknown_user.
  ///
  /// In zh_CN, this message translates to:
  /// **'未知用户'**
  String get unknown_user;

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

  /// No description provided for @settings_page_theme.
  ///
  /// In zh_CN, this message translates to:
  /// **'主题设置'**
  String get settings_page_theme;

  /// No description provided for @settings_page_language.
  ///
  /// In zh_CN, this message translates to:
  /// **'语言设置'**
  String get settings_page_language;

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

  /// No description provided for @system_mode.
  ///
  /// In zh_CN, this message translates to:
  /// **'跟随系统'**
  String get system_mode;

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

  /// No description provided for @english.
  ///
  /// In zh_CN, this message translates to:
  /// **'英语'**
  String get english;

  /// No description provided for @chinese_simplified.
  ///
  /// In zh_CN, this message translates to:
  /// **'简体中文'**
  String get chinese_simplified;

  /// No description provided for @chinese_traditional.
  ///
  /// In zh_CN, this message translates to:
  /// **'繁体中文'**
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

  /// No description provided for @search_error.
  ///
  /// In zh_CN, this message translates to:
  /// **'搜索错误'**
  String get search_error;

  /// No description provided for @error.
  ///
  /// In zh_CN, this message translates to:
  /// **'错误'**
  String get error;

  /// No description provided for @network_error.
  ///
  /// In zh_CN, this message translates to:
  /// **'网络错误'**
  String get network_error;

  /// No description provided for @permission_denied.
  ///
  /// In zh_CN, this message translates to:
  /// **'权限被拒绝'**
  String get permission_denied;

  /// No description provided for @invalid_input.
  ///
  /// In zh_CN, this message translates to:
  /// **'无效输入'**
  String get invalid_input;

  /// No description provided for @search_no_results.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到搜索结果'**
  String get search_no_results;

  /// No description provided for @skipToPrevious.
  ///
  /// In zh_CN, this message translates to:
  /// **'上一首'**
  String get skipToPrevious;

  /// No description provided for @skipToNext.
  ///
  /// In zh_CN, this message translates to:
  /// **'下一首'**
  String get skipToNext;

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
  /// **'请选择一首歌曲播放'**
  String get select_a_song_to_play;

  /// No description provided for @repeat_all.
  ///
  /// In zh_CN, this message translates to:
  /// **'全部循环'**
  String get repeat_all;

  /// No description provided for @playback_speed.
  ///
  /// In zh_CN, this message translates to:
  /// **'播放速度'**
  String get playback_speed;

  /// No description provided for @default_playback_speed.
  ///
  /// In zh_CN, this message translates to:
  /// **'默认播放速度'**
  String get default_playback_speed;

  /// No description provided for @default_playback_speed_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置所有歌曲的默认播放速度'**
  String get default_playback_speed_description;

  /// No description provided for @crossfade.
  ///
  /// In zh_CN, this message translates to:
  /// **'交叉淡入淡出'**
  String get crossfade;

  /// No description provided for @crossfade_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用歌曲间的交叉淡入淡出'**
  String get crossfade_description;

  /// No description provided for @crossfade_duration.
  ///
  /// In zh_CN, this message translates to:
  /// **'交叉淡入淡出时长'**
  String get crossfade_duration;

  /// No description provided for @gapless_playback.
  ///
  /// In zh_CN, this message translates to:
  /// **'无缝播放'**
  String get gapless_playback;

  /// No description provided for @gapless_playback_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用无缝播放以实现平滑过渡'**
  String get gapless_playback_description;

  /// No description provided for @equalizer.
  ///
  /// In zh_CN, this message translates to:
  /// **'均衡器'**
  String get equalizer;

  /// No description provided for @equalizer_tab.
  ///
  /// In zh_CN, this message translates to:
  /// **'均衡器'**
  String get equalizer_tab;

  /// No description provided for @presets.
  ///
  /// In zh_CN, this message translates to:
  /// **'预设'**
  String get presets;

  /// No description provided for @flat.
  ///
  /// In zh_CN, this message translates to:
  /// **'平直'**
  String get flat;

  /// No description provided for @pop.
  ///
  /// In zh_CN, this message translates to:
  /// **'流行'**
  String get pop;

  /// No description provided for @rock.
  ///
  /// In zh_CN, this message translates to:
  /// **'摇滚'**
  String get rock;

  /// No description provided for @jazz.
  ///
  /// In zh_CN, this message translates to:
  /// **'爵士'**
  String get jazz;

  /// No description provided for @classical.
  ///
  /// In zh_CN, this message translates to:
  /// **'古典'**
  String get classical;

  /// No description provided for @hip_hop.
  ///
  /// In zh_CN, this message translates to:
  /// **'嘻哈'**
  String get hip_hop;

  /// No description provided for @custom_equalizer.
  ///
  /// In zh_CN, this message translates to:
  /// **'自定义均衡器'**
  String get custom_equalizer;

  /// No description provided for @animations_settings.
  ///
  /// In zh_CN, this message translates to:
  /// **'动画设置'**
  String get animations_settings;

  /// No description provided for @enable_animations.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用动画'**
  String get enable_animations;

  /// No description provided for @enable_animations_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'启用或禁用UI动画'**
  String get enable_animations_description;

  /// No description provided for @animation_speed.
  ///
  /// In zh_CN, this message translates to:
  /// **'动画速度'**
  String get animation_speed;

  /// No description provided for @animation_speed_description.
  ///
  /// In zh_CN, this message translates to:
  /// **'设置UI动画的速度'**
  String get animation_speed_description;

  /// No description provided for @very_slow.
  ///
  /// In zh_CN, this message translates to:
  /// **'非常慢'**
  String get very_slow;

  /// No description provided for @slow.
  ///
  /// In zh_CN, this message translates to:
  /// **'慢'**
  String get slow;

  /// No description provided for @normal.
  ///
  /// In zh_CN, this message translates to:
  /// **'正常'**
  String get normal;

  /// No description provided for @fast.
  ///
  /// In zh_CN, this message translates to:
  /// **'快'**
  String get fast;

  /// No description provided for @very_fast.
  ///
  /// In zh_CN, this message translates to:
  /// **'非常快'**
  String get very_fast;

  /// No description provided for @no_scan_results.
  ///
  /// In zh_CN, this message translates to:
  /// **'未找到扫描结果'**
  String get no_scan_results;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'ja',
    'ko',
    'ru',
    'zh',
  ].contains(locale.languageCode);

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
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ru':
      return AppLocalizationsRu();
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

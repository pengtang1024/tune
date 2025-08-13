// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get app_name => 'Tune';

  @override
  String get home_title => '主页';

  @override
  String get font_family => '字体系列';

  @override
  String get theme_mode => '主题模式';

  @override
  String get light_mode => '浅色模式';

  @override
  String get dark_mode => '深色模式';

  @override
  String get system_mode => '系统模式';

  @override
  String get library_title => '音乐库';

  @override
  String get artist_title => '艺术家';

  @override
  String get search_hint => '搜索歌曲...';

  @override
  String get artist_hint => '搜索艺术家...';

  @override
  String get album_hint => '搜索专辑...';

  @override
  String get settings_title => '设置';

  @override
  String get play_button => '播放';

  @override
  String get pause_button => '暂停';

  @override
  String get previous_button => '上一首';

  @override
  String get next_button => '下一首';

  @override
  String get stop_button => '停止';

  @override
  String get player_title => '播放器';

  @override
  String get now_playing => '正在播放';

  @override
  String get no_song_playing => '没有正在播放的歌曲';

  @override
  String get no_songs_found => '未找到歌曲';

  @override
  String get search_title => '搜索';

  @override
  String get search_no_results => '未找到结果';

  @override
  String get quick_actions => '快速操作';

  @override
  String get favorites => '收藏';

  @override
  String get playlists => '播放列表';

  @override
  String get recently_played => '最近播放';

  @override
  String get recommendations => '推荐';

  @override
  String get no_recent_songs => '无最近播放歌曲';

  @override
  String get no_recommendations => '无推荐内容';

  @override
  String get failed_to_load_songs => '加载歌曲失败';

  @override
  String get scan_local_music => '扫描本地音乐';

  @override
  String get no_scan_performed => '没有执行扫描';

  @override
  String get scanning => '扫描中';

  @override
  String get cancel => '取消';

  @override
  String get scan_completed => '扫描完成';

  @override
  String get scan_again => '再次扫描';

  @override
  String found_songs(Object count) {
    return '找到了$count首歌曲';
  }

  @override
  String get scan_failed => '扫描失败';

  @override
  String get try_again => '再试一次';

  @override
  String get scan_cancelled => '扫描已取消';

  @override
  String get toggle_sidebar => '切换侧边栏';

  @override
  String get no_things_players => '播放器中没有歌曲';

  @override
  String get song_list_title => '歌曲列表';

  @override
  String get profile_title => '个人资料';

  @override
  String get username_default => '用户';

  @override
  String get user_email_default => 'user@example.com';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';
}

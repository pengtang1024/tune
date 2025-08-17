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
  String get welcome_message => '欢迎使用 Tune';

  @override
  String get no_songs_found => '未找到歌曲';

  @override
  String get settings => '设置';

  @override
  String get retry => '重试';

  @override
  String get home => '首页';

  @override
  String get recommend => '推荐';

  @override
  String get featured => '精选';

  @override
  String get library => '音乐库';

  @override
  String get search => '搜索';

  @override
  String get player => '播放器';

  @override
  String get playlist => '播放列表';

  @override
  String get about => '关于';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get app_name => 'Tune';

  @override
  String get welcome_message => '欢迎使用 Tune';

  @override
  String get no_songs_found => '未找到歌曲';

  @override
  String get settings => '设置';

  @override
  String get retry => '重试';

  @override
  String get home => '首页';

  @override
  String get recommend => '推荐';

  @override
  String get featured => '精选';

  @override
  String get library => '音乐库';

  @override
  String get search => '搜索';

  @override
  String get player => '播放器';

  @override
  String get playlist => '播放列表';

  @override
  String get about => '关于';
}

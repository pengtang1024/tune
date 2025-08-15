// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Tune';

  @override
  String get welcome_message => 'Welcome to Tune';

  @override
  String get no_songs_found => 'No songs found';

  @override
  String get settings => 'Settings';

  @override
  String get retry => 'Retry';

  @override
  String get home => 'Home';

  @override
  String get recommend => 'Recommend';

  @override
  String get featured => 'Featured';

  @override
  String get library => 'Library';

  @override
  String get search => '搜索';

  @override
  String get player => '播放器';

  @override
  String get playlist => '播放列表';

  @override
  String get about => '关于';
}

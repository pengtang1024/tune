// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get app_name => 'Tune';

  @override
  String get home_title => 'Главная';

  @override
  String get font_family => 'Семейство шрифтов';

  @override
  String get theme_mode => 'Режим темы';

  @override
  String get light_mode => 'Светлый режим';

  @override
  String get dark_mode => 'Темный режим';

  @override
  String get system_mode => 'Системный режим';

  @override
  String get library_title => 'Библиотека';

  @override
  String get artist_title => 'Исполнитель';

  @override
  String get search_hint => 'Поиск песен...';

  @override
  String get artist_hint => 'Поиск исполнителей...';

  @override
  String get album_hint => 'Поиск альбомов...';

  @override
  String get settings_title => 'Настройки';

  @override
  String get play_button => 'Воспроизвести';

  @override
  String get pause_button => 'Пауза';

  @override
  String get next_button => 'Следующая';

  @override
  String get previous_button => 'Предыдущая';

  @override
  String get favorite_button => 'Избранное';

  @override
  String get now_playing => 'Сейчас играет';

  @override
  String get no_things_players => 'Нет плееров';

  @override
  String get no_selected_song => 'Песня не выбрана';

  @override
  String get song_list_title => 'Песни';

  @override
  String get no_songs_found => 'Песны не найдены';

  @override
  String get player_duration => 'Длительность';

  @override
  String get player_artist => 'Исполнитель';

  @override
  String get player_album => 'Альбом';

  @override
  String get search_empty => 'Введите поисковый запрос для поиска песен';

  @override
  String get search_no_results => 'Песны не найдены по вашему запросу';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get font => 'Шрифт';

  @override
  String get theme_trendy_electro => 'Модный Электро';

  @override
  String get theme_minimal_gray => 'Минималистичный Серый';

  @override
  String get theme_nature_forest => 'Лес Природы';

  @override
  String get theme_cyber_neon => 'Кибер Нeon';

  @override
  String get theme_warm_healing => 'Теплое Исцеление';

  @override
  String get about => 'О приложении';

  @override
  String get library_artists => 'Исполнители';

  @override
  String get library_albums => 'Альбомы';

  @override
  String get library_genres => 'Жанры';

  @override
  String get player_title => 'Плеер';

  @override
  String get profile_title => 'Профиль';

  @override
  String get username_default => 'Пользователь';

  @override
  String get user_email_default => 'user@example.com';

  @override
  String get locale => 'Русский';

  @override
  String get search_title => 'Поиск';

  @override
  String get no_song_playing => 'Нет воспроизводимой песни';

  @override
  String get quick_actions => 'Быстрые действия';

  @override
  String get favorites => 'Избранное';

  @override
  String get playlists => 'Плейлисты';

  @override
  String get recently_played => 'Недавно воспроизведенные';

  @override
  String get recommendations => 'Рекомендации';

  @override
  String get no_recent_songs => 'Нет недавних песен';

  @override
  String get no_recommendations => 'Нет рекомендаций';

  @override
  String get failed_to_load_songs => 'Не удалось загрузить песни';

  @override
  String get scan_local_music => 'Scan Local Music';

  @override
  String get no_scan_performed => 'No scan performed';

  @override
  String get scanning => 'Scanning';

  @override
  String get cancel => 'Cancel';

  @override
  String get scan_completed => 'Scan Completed';

  @override
  String get scan_again => 'Scan Again';

  @override
  String found_songs(Object count) {
    return 'Found $count songs';
  }

  @override
  String get scan_failed => 'Scan Failed';

  @override
  String get try_again => 'Try Again';

  @override
  String get scan_cancelled => 'Scan Cancelled';
}

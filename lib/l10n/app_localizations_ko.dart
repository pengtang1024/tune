// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get app_name => 'Tune';

  @override
  String get home_title => '홈';

  @override
  String get font_family => '폰트 패밀리';

  @override
  String get theme_mode => '테마 모드';

  @override
  String get light_mode => '라이트 모드';

  @override
  String get dark_mode => '다크 모드';

  @override
  String get system_mode => '시스템 모드';

  @override
  String get library_title => '라이브러리';

  @override
  String get artist_title => '아티스트';

  @override
  String get search_hint => '노래 검색...';

  @override
  String get artist_hint => '아티스트 검색...';

  @override
  String get album_hint => '앨범 검색...';

  @override
  String get settings_title => '설정';

  @override
  String get play_button => '재생';

  @override
  String get pause_button => '일시정지';

  @override
  String get next_button => '다음';

  @override
  String get previous_button => '이전';

  @override
  String get favorite_button => '즐겨찾기';

  @override
  String get now_playing => '지금 재생 중';

  @override
  String get no_things_players => '플레이어 없음';

  @override
  String get no_selected_song => '선택된 노래 없음';

  @override
  String get song_list_title => '노래';

  @override
  String get no_songs_found => '노래를 찾을 수 없음';

  @override
  String get player_duration => '길이';

  @override
  String get player_artist => '아티스트';

  @override
  String get player_album => '앨범';

  @override
  String get search_empty => '노래를 찾기 위해 검색어를 입력하세요';

  @override
  String get search_no_results => '검색 결과가 없습니다';

  @override
  String get language => '언어';

  @override
  String get theme => '테마';

  @override
  String get font => '폰트';

  @override
  String get theme_trendy_electro => '트렌디 일렉트로';

  @override
  String get theme_minimal_gray => '미니멀 그레이';

  @override
  String get theme_nature_forest => '자연 숲';

  @override
  String get theme_cyber_neon => '사이버 네온';

  @override
  String get theme_warm_healing => '따뜻한 힐링';

  @override
  String get about => '앱 정보';

  @override
  String get library_artists => '아티스트';

  @override
  String get library_albums => '앨범';

  @override
  String get library_genres => '장르';

  @override
  String get player_title => '플레이어';

  @override
  String get profile_title => '프로필';

  @override
  String get username_default => '사용자';

  @override
  String get user_email_default => 'user@example.com';

  @override
  String get locale => '한국어';

  @override
  String get search_title => '검색';

  @override
  String get no_song_playing => '재생 중인 노래가 없습니다';

  @override
  String get quick_actions => '빠른 작업';

  @override
  String get favorites => '즐겨찾기';

  @override
  String get playlists => '재생목록';

  @override
  String get recently_played => '최근 재생';

  @override
  String get recommendations => '추천';

  @override
  String get no_recent_songs => '최근 재생한 노래가 없습니다';

  @override
  String get no_recommendations => '추천 항목이 없습니다';

  @override
  String get failed_to_load_songs => '노래 로드 실패';

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

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
  String get home_title => 'Home';

  @override
  String get font_family => 'Font Family';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get light_mode => 'Light Mode';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get system_mode => 'System Mode';

  @override
  String get library_title => 'Library';

  @override
  String get artist_title => 'Artist';

  @override
  String get search_hint => 'Search songs...';

  @override
  String get artist_hint => 'Search artists...';

  @override
  String get album_hint => 'Search albums...';

  @override
  String get settings_title => 'Settings';

  @override
  String get play_button => 'Play';

  @override
  String get pause_button => 'Pause';

  @override
  String get previous_button => 'Previous';

  @override
  String get next_button => 'Next';

  @override
  String get stop_button => 'Stop';

  @override
  String get player_title => 'Player';

  @override
  String get now_playing => 'Now Playing';

  @override
  String get no_song_playing => 'No song playing';

  @override
  String get no_songs_found => 'No songs found';

  @override
  String get search_title => 'Search';

  @override
  String get search_no_results => 'No results found';

  @override
  String get quick_actions => 'Quick Actions';

  @override
  String get favorites => 'Favorites';

  @override
  String get playlists => 'Playlists';

  @override
  String get recently_played => 'Recently Played';

  @override
  String get recommendations => 'Recommendations';

  @override
  String get no_recent_songs => 'No recent songs';

  @override
  String get no_recommendations => 'No recommendations';

  @override
  String get failed_to_load_songs => 'Failed to load songs';

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

  @override
  String get toggle_sidebar => 'Toggle Sidebar';

  @override
  String get no_things_players => 'No songs in the player';

  @override
  String get song_list_title => 'Song List';

  @override
  String get profile_title => 'Profile';

  @override
  String get username_default => 'User';

  @override
  String get user_email_default => 'user@example.com';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';
}

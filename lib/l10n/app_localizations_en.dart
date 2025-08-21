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
  String get home_title => 'Home';

  @override
  String get recommend => 'Recommend';

  @override
  String get featured => 'Featured';

  @override
  String get library => 'Library';

  @override
  String get library_title => 'Library';

  @override
  String get search => 'Search';

  @override
  String get search_title => 'Search';

  @override
  String get player => 'Player';

  @override
  String get player_title => 'Player';

  @override
  String get playlist => 'Playlist';

  @override
  String get about => 'About';

  @override
  String get custom_scan_paths => 'Custom Scan Paths';

  @override
  String get add_custom_directory => 'Add custom directory for music scanning';

  @override
  String get no_custom_scan_paths => 'No custom scan paths';

  @override
  String get full_platform_scan_note =>
      'Note: Please use the \"Music Scan\" function in the sidebar for full platform scanning';

  @override
  String get library_info => 'Library Info';

  @override
  String get songs_count => 'Current library contains 0 songs';

  @override
  String get library_features => 'Library Features';

  @override
  String get auto_extract_metadata =>
      '• The library will automatically extract song metadata (title, artist, album, etc.)';

  @override
  String get how_to_scan => 'How to use music scanning:';

  @override
  String get scan_step1 =>
      '1. Click the \"Music Scan\" menu item in the left sidebar';

  @override
  String get scan_step2 =>
      '2. Click the \"Start Scan\" button on the scan page';

  @override
  String get scan_step3 =>
      '3. Wait for the scan to complete and view the results';

  @override
  String get scan_step4 =>
      '4. Scanned music will automatically appear in the \"Library\"';

  @override
  String get faq => 'FAQ';

  @override
  String get faq_scan_issue => 'Q: Why can\'t I find music files?';

  @override
  String get faq_scan_issue_answer =>
      'A: Please ensure music files exist on your device and the app has storage access permissions.';

  @override
  String get faq_slow_scan => 'Q: Why is scanning slow?';

  @override
  String get faq_slow_scan_answer =>
      'A: First scan may be slow, subsequent scans will be faster. Please be patient.';

  @override
  String get faq_not_showing =>
      'Q: Why aren\'t scanned songs showing in the library?';

  @override
  String get faq_not_showing_answer =>
      'A: Please ensure scanning is complete and try refreshing the library page.';

  @override
  String get contact_us =>
      'If you have any questions or suggestions, please contact us:';

  @override
  String get email => '📧 Email: support@tune-music.com';

  @override
  String get website => '🌐 Website: https://tune-music.com';

  @override
  String get unknown_artist => 'Unknown Artist';

  @override
  String get unknown_album => 'Unknown Album';

  @override
  String get enable_desktop_lyrics => 'Enable Desktop Lyrics';

  @override
  String get tag_vip => 'VIP';

  @override
  String get tag_singer => 'Singer';

  @override
  String get tag_elite => 'Elite';

  @override
  String get general_settings => 'General Settings';

  @override
  String get auto_start => 'Auto Start';

  @override
  String get auto_start_description =>
      'Automatically start the application on system startup';

  @override
  String get window_size => 'Window Size';

  @override
  String get window_size_description =>
      'Set the default window size when the application starts';

  @override
  String get default_player => 'Default Player';

  @override
  String get default_player_description =>
      'Set this application as the default audio player';

  @override
  String get desktop_lyrics => 'Desktop Lyrics';

  @override
  String get desktop_lyrics_description =>
      'Display lyrics in a floating window on the desktop';

  @override
  String get small => 'Small';

  @override
  String get medium => 'Medium';

  @override
  String get large => 'Large';

  @override
  String get version => 'Version: 1.0.0';

  @override
  String get platform => 'Platform';

  @override
  String get about_description =>
      'Tune is a modern music player that allows you to easily manage and play your local music collection. With a clean and intuitive interface, Tune provides a seamless music experience.';

  @override
  String get features => 'Features';

  @override
  String get high_quality_audio_playback => 'High-quality audio playback';

  @override
  String get supports_multiple_audio_formats =>
      'Supports multiple audio formats including MP3, FLAC, WAV, etc.';

  @override
  String get local_music_management => 'Local music management';

  @override
  String get automatically_scans_and_organizes_local_music_library =>
      'Automatically scans and organizes your local music library';

  @override
  String get multi_language_support => 'Multi-language support';

  @override
  String get supports_chinese_english_japanese_korean_russian_and_more =>
      'Supports Chinese, English, Japanese, Korean, Russian and more languages';

  @override
  String get multiple_themes => 'Multiple themes';

  @override
  String get eight_theme_colors_with_dark_light_mode_switching =>
      'Eight theme colors with dark/light mode switching';

  @override
  String get lyrics_synchronization => 'Lyrics synchronization';

  @override
  String get lrc_format_lyrics_real_time_synchronization_display =>
      'LRC format lyrics real-time synchronization display';

  @override
  String get smart_search => 'Smart search';

  @override
  String get supports_searching_by_song_title_artist_album_and_other_metadata =>
      'Supports searching by song title, artist, album and other metadata';

  @override
  String get open_source_license => 'Open Source License';

  @override
  String get opensource_license_description =>
      'This project is licensed under the MIT License - see the LICENSE file for details.';

  @override
  String get github_project_address => 'GitHub Project Address';

  @override
  String get contact_us_description =>
      'If you have any questions, suggestions or feedback, please feel free to contact us through the following channels.';

  @override
  String get official_website => 'Official Website';

  @override
  String get access_library =>
      '• Can access and manage music library at any time';

  @override
  String get add_custom_paths => '• Can add custom scan paths';

  @override
  String get scan_completion =>
      '• Results can be viewed in the library after scanning is complete';

  @override
  String get auto_metadata_extraction =>
      '• Automatically extract metadata from music files';

  @override
  String get scan_instructions => 'Scan Instructions';

  @override
  String get music_library_management => 'Music Library Management';

  @override
  String get failed_to_save_custom_path => 'Failed to save custom path';

  @override
  String get custom_path_scanning_will_be_implemented =>
      'Custom path scanning will be implemented in future versions';

  @override
  String get error => 'Error';

  @override
  String get featured_playlists => 'Featured Playlists';

  @override
  String get featured_artists => 'Featured Artists';

  @override
  String get featured_albums => 'Featured Albums';

  @override
  String get songs => 'Songs';

  @override
  String get music_scan => 'Music Scan';

  @override
  String get scan_local_music => 'Scan Local Music';

  @override
  String get search_error => 'Search Error';

  @override
  String get no_matching_songs => 'No matching songs found';

  @override
  String get playback_error => 'Playback Error';

  @override
  String get no_song_playing => 'No song is currently playing';

  @override
  String get select_a_song_to_play => 'Please select a song to play';

  @override
  String get unknown_user => 'Unknown User';

  @override
  String get my_account => 'My Account';

  @override
  String get select_language => 'Select Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get failed_to_open_github => 'Failed to open GitHub page';

  @override
  String get theme_light => 'Light';

  @override
  String get theme_dark => 'Dark';

  @override
  String get theme_system => 'System';

  @override
  String get bottom_player_bar_now_playing => 'Now Playing';

  @override
  String get bottom_player_bar_no_song => 'No Song Selected';

  @override
  String get song_list_title => 'Songs';

  @override
  String get song_list_no_songs => 'No songs found';

  @override
  String get settings_page_language => 'Language';

  @override
  String get settings_page_theme => 'Theme';

  @override
  String get theme_name_trendy_electro => 'Trendy Electro';

  @override
  String get theme_name_minimal_gray => 'Minimal Gray';

  @override
  String get theme_name_nature_forest => 'Nature Forest';

  @override
  String get theme_name_cyber_neon => 'Cyber Neon';

  @override
  String get theme_name_warm_healing => 'Warm Healing';

  @override
  String get theme_name_dark_mode => 'Dark Mode';

  @override
  String get theme_name_light_mode => 'Light Mode';

  @override
  String get theme_name_system_theme => 'System Theme';

  @override
  String get library_page_artists => 'Artists';

  @override
  String get library_page_albums => 'Albums';

  @override
  String get library_page_genres => 'Genres';

  @override
  String get play_button => 'Play';

  @override
  String get pause_button => 'Pause';

  @override
  String get next_button => 'Next';

  @override
  String get previous_button => 'Previous';

  @override
  String get favorite_button => 'Favorite';

  @override
  String get font_family => 'Font';

  @override
  String get theme_mode => 'Theme Mode';

  @override
  String get light_mode => 'Light Mode';

  @override
  String get dark_mode => 'Dark Mode';

  @override
  String get system_mode => 'System Mode';

  @override
  String get artist_title => 'Artist';

  @override
  String get search_hint => 'Search songs...';

  @override
  String get artist_hint => 'Search artists...';

  @override
  String get album_hint => 'Search albums...';

  @override
  String get now_playing => 'Now Playing';

  @override
  String get no_things_players => 'No Players';

  @override
  String get no_selected_song => 'No Song Selected';

  @override
  String get player_duration => 'Duration';

  @override
  String get player_artist => 'Artist';

  @override
  String get player_album => 'Album';

  @override
  String get search_empty => 'Enter search terms to find songs';

  @override
  String get search_no_results => 'No songs found matching your search';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get font => 'Font';

  @override
  String get library_artists => 'Artists';

  @override
  String get library_albums => 'Albums';

  @override
  String get library_genres => 'Genres';

  @override
  String get profile_title => 'Profile';

  @override
  String get username_default => 'User';

  @override
  String get user_email_default => 'user@example.com';

  @override
  String get search_hint_text => 'Search...';

  @override
  String get search_page_hint => 'Search songs...';

  @override
  String get search_page_empty => 'Enter search terms to find songs';

  @override
  String get search_page_no_results => 'No songs found matching your search';

  @override
  String get settings_page_about => 'About';

  @override
  String get language_name_en => 'English';

  @override
  String get language_name_zh => 'Chinese';

  @override
  String get english => 'English';

  @override
  String get chinese_simplified => 'Chinese (Simplified)';

  @override
  String get chinese_traditional => 'Chinese (Traditional)';

  @override
  String get chinese => 'Chinese';

  @override
  String get japanese => 'Japanese';

  @override
  String get korean => 'Korean';

  @override
  String get russian => 'Russian';

  @override
  String get german => 'German';

  @override
  String get french => 'French';

  @override
  String get spanish => 'Spanish';

  @override
  String get playback_mode => 'Playback Mode';

  @override
  String get repeat_all => 'Repeat All';

  @override
  String get repeat_one => 'Repeat One';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get audio_effects => 'Audio Effects';

  @override
  String get enable_equalizer => 'Enable Equalizer';

  @override
  String get bass_boost => 'Bass Boost';

  @override
  String get spatial_audio => 'Spatial Audio';

  @override
  String get account_settings => 'Account Settings';

  @override
  String get general_tab => 'General';

  @override
  String get library_tab => 'Library';

  @override
  String get account_tab => 'Account';

  @override
  String get playback_tab => 'Playback';

  @override
  String get about_tab => 'About';

  @override
  String get animations_tab => 'Animations';

  @override
  String get username => 'Username';

  @override
  String get auto_login => 'Auto Login';

  @override
  String get save_password => 'Save Password';

  @override
  String get account_settings_saved => 'Account settings saved';

  @override
  String get save => 'Save';

  @override
  String get search_songs => 'Search songs...';

  @override
  String get artists => 'Artists';

  @override
  String get albums => 'Albums';

  @override
  String get load_stats_failed => 'Failed to load statistics';

  @override
  String get load_songs_failed => 'Failed to load songs';
}

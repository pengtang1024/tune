import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('ru'),
    Locale('zh'),
  ];

  /// No description provided for @locale.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get locale;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get app_name;

  /// No description provided for @home_title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// No description provided for @font_family.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get font_family;

  /// No description provided for @theme_mode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// No description provided for @light_mode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get light_mode;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @system_mode.
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get system_mode;

  /// No description provided for @library_title.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library_title;

  /// No description provided for @artist_title.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist_title;

  /// No description provided for @search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get search_hint;

  /// No description provided for @artist_hint.
  ///
  /// In en, this message translates to:
  /// **'Search artists...'**
  String get artist_hint;

  /// No description provided for @album_hint.
  ///
  /// In en, this message translates to:
  /// **'Search albums...'**
  String get album_hint;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Search Suggestions'**
  String get search_suggestions;

  /// No description provided for @search_history.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get search_history;

  /// No description provided for @clear_history.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// No description provided for @play_button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play_button;

  /// No description provided for @pause_button.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_button;

  /// No description provided for @next_button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_button;

  /// No description provided for @previous_button.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous_button;

  /// No description provided for @favorite_button.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite_button;

  /// No description provided for @now_playing.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get now_playing;

  /// No description provided for @no_things_players.
  ///
  /// In en, this message translates to:
  /// **'No things players'**
  String get no_things_players;

  /// No description provided for @no_selected_song.
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get no_selected_song;

  /// No description provided for @song_list_title.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get song_list_title;

  /// No description provided for @no_songs_found.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get no_songs_found;

  /// No description provided for @player_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get player_duration;

  /// No description provided for @player_artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get player_artist;

  /// No description provided for @player_album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get player_album;

  /// No description provided for @search_empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term to find songs'**
  String get search_empty;

  /// No description provided for @search_no_results.
  ///
  /// In en, this message translates to:
  /// **'No songs found matching your search'**
  String get search_no_results;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @font.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// No description provided for @theme_trendy_electro.
  ///
  /// In en, this message translates to:
  /// **'Trendy Electro'**
  String get theme_trendy_electro;

  /// No description provided for @theme_minimal_gray.
  ///
  /// In en, this message translates to:
  /// **'Minimal Gray'**
  String get theme_minimal_gray;

  /// No description provided for @theme_nature_forest.
  ///
  /// In en, this message translates to:
  /// **'Nature Forest'**
  String get theme_nature_forest;

  /// No description provided for @theme_cyber_neon.
  ///
  /// In en, this message translates to:
  /// **'Cyber Neon'**
  String get theme_cyber_neon;

  /// No description provided for @theme_warm_healing.
  ///
  /// In en, this message translates to:
  /// **'Warm Healing'**
  String get theme_warm_healing;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @library_artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get library_artists;

  /// No description provided for @library_albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get library_albums;

  /// No description provided for @library_genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get library_genres;

  /// No description provided for @player_title.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player_title;

  /// No description provided for @profile_title.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// No description provided for @username_default.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get username_default;

  /// No description provided for @user_email_default.
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get user_email_default;

  /// No description provided for @failed_to_load_songs.
  ///
  /// In en, this message translates to:
  /// **'Failed to load songs'**
  String get failed_to_load_songs;

  /// No description provided for @found_songs.
  ///
  /// In en, this message translates to:
  /// **'Found Songs'**
  String get found_songs;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @no_song_playing.
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get no_song_playing;

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @playlists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// No description provided for @recently_played.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recently_played;

  /// No description provided for @scan_local_music.
  ///
  /// In en, this message translates to:
  /// **'Scan Local Music'**
  String get scan_local_music;

  /// No description provided for @recommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// No description provided for @scan_completed.
  ///
  /// In en, this message translates to:
  /// **'Scan Completed'**
  String get scan_completed;

  /// No description provided for @scan_again.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scan_again;

  /// No description provided for @scan_failed.
  ///
  /// In en, this message translates to:
  /// **'Scan Failed'**
  String get scan_failed;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @scan_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan Cancelled'**
  String get scan_cancelled;

  /// No description provided for @toggle_sidebar.
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get toggle_sidebar;

  /// No description provided for @sort_by_title.
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get sort_by_title;

  /// No description provided for @sort_by_artist.
  ///
  /// In en, this message translates to:
  /// **'Sort by Artist'**
  String get sort_by_artist;

  /// No description provided for @sort_by_album.
  ///
  /// In en, this message translates to:
  /// **'Sort by Album'**
  String get sort_by_album;

  /// No description provided for @sort_by_date_added.
  ///
  /// In en, this message translates to:
  /// **'Sort by Date Added'**
  String get sort_by_date_added;

  /// No description provided for @sort_by_duration.
  ///
  /// In en, this message translates to:
  /// **'Sort by Duration'**
  String get sort_by_duration;

  /// No description provided for @group_by_none.
  ///
  /// In en, this message translates to:
  /// **'Group by None'**
  String get group_by_none;

  /// No description provided for @search_songs.
  ///
  /// In en, this message translates to:
  /// **'Search songs'**
  String get search_songs;
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
      <String>['en', 'ja', 'ko', 'ru', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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

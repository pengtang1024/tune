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

  /// this is the name of the app
  ///
  /// In en, this message translates to:
  /// **'Tune'**
  String get app_name;

  /// this is the title of the home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_title;

  /// this is the font family
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get font_family;

  /// this is the theme mode
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get theme_mode;

  /// this is the light mode
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get light_mode;

  /// this is the dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// this is the system mode
  ///
  /// In en, this message translates to:
  /// **'System Mode'**
  String get system_mode;

  /// this is the title of the library page
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library_title;

  /// this is the title of the artist page
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get artist_title;

  /// this is the hint text for the search bar
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get search_hint;

  /// this is the hint text for the search bar
  ///
  /// In en, this message translates to:
  /// **'Search artists...'**
  String get artist_hint;

  /// this is the hint text for the search bar
  ///
  /// In en, this message translates to:
  /// **'Search albums...'**
  String get album_hint;

  /// this is the title of the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// Retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Search suggestions title
  ///
  /// In en, this message translates to:
  /// **'Search Suggestions'**
  String get search_suggestions;

  /// Search history title
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get search_history;

  /// Clear history action
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clear_history;

  /// this is the text for the play button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play_button;

  /// this is the text for the pause button
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_button;

  /// this is the text for the next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_button;

  /// this is the text for the previous button
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous_button;

  /// this is the text for the favorite button
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite_button;

  /// this is the text for the now playing
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get now_playing;

  /// this is the text for the no things players
  ///
  /// In en, this message translates to:
  /// **'No things players'**
  String get no_things_players;

  /// this is the text for the no selected song
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get no_selected_song;

  /// this is the title of the song list
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get song_list_title;

  /// this is the text for the no songs found
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get no_songs_found;

  /// this is the duration of the player
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get player_duration;

  /// this is the artist of the player
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get player_artist;

  /// this is the album of the player
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get player_album;

  /// this is the text for the search empty
  ///
  /// In en, this message translates to:
  /// **'Enter a search term to find songs'**
  String get search_empty;

  /// this is the text for the search no results
  ///
  /// In en, this message translates to:
  /// **'No songs found matching your search'**
  String get search_no_results;

  /// this is the language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// this is the theme
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// this is the font
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// this is the trendy electro theme
  ///
  /// In en, this message translates to:
  /// **'Trendy Electro'**
  String get theme_trendy_electro;

  /// this is the minimal gray theme
  ///
  /// In en, this message translates to:
  /// **'Minimal Gray'**
  String get theme_minimal_gray;

  /// this is the nature forest theme
  ///
  /// In en, this message translates to:
  /// **'Nature Forest'**
  String get theme_nature_forest;

  /// this is the cyber neon theme
  ///
  /// In en, this message translates to:
  /// **'Cyber Neon'**
  String get theme_cyber_neon;

  /// this is the warm healing theme
  ///
  /// In en, this message translates to:
  /// **'Warm Healing'**
  String get theme_warm_healing;

  /// this is the about
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// this is the library artists
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get library_artists;

  /// this is the library albums
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get library_albums;

  /// this is the library genres
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get library_genres;

  /// this is the title of the player page
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player_title;

  /// this is the title of the profile page
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_title;

  /// this is the default username
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get username_default;

  /// this is the default user email
  ///
  /// In en, this message translates to:
  /// **'user@example.com'**
  String get user_email_default;

  /// Error message when failing to load songs
  ///
  /// In en, this message translates to:
  /// **'Failed to load songs'**
  String get failed_to_load_songs;

  /// Title for the found songs section
  ///
  /// In en, this message translates to:
  /// **'Found Songs'**
  String get found_songs;

  /// Cancel action text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Text displayed when no song is playing
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get no_song_playing;

  /// Title for quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// Title for favorites section
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Title for playlists section
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// Title for recently played section
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recently_played;

  /// Action to scan local music
  ///
  /// In en, this message translates to:
  /// **'Scan Local Music'**
  String get scan_local_music;

  /// Title for recommendations section
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// Text displayed during scanning process
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get scanning;

  /// Text displayed when scan is completed
  ///
  /// In en, this message translates to:
  /// **'Scan Completed'**
  String get scan_completed;

  /// Action to scan again
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scan_again;

  /// Text displayed when scan fails
  ///
  /// In en, this message translates to:
  /// **'Scan Failed'**
  String get scan_failed;

  /// Action to try again
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// Text displayed when scan is cancelled
  ///
  /// In en, this message translates to:
  /// **'Scan Cancelled'**
  String get scan_cancelled;
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

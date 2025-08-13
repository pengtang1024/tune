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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
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

  /// this is the hint text for the artist search bar
  ///
  /// In en, this message translates to:
  /// **'Search artists...'**
  String get artist_hint;

  /// this is the hint text for the album search bar
  ///
  /// In en, this message translates to:
  /// **'Search albums...'**
  String get album_hint;

  /// this is the title of the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// this is the play button text
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play_button;

  /// this is the pause button text
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause_button;

  /// this is the previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous_button;

  /// this is the next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next_button;

  /// this is the stop button text
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop_button;

  /// this is the title of the player page
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get player_title;

  /// this is the now playing text
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get now_playing;

  /// this is the text for the no song playing indicator
  ///
  /// In en, this message translates to:
  /// **'No song playing'**
  String get no_song_playing;

  /// this is the text for the no songs found indicator
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get no_songs_found;

  /// this is the title of the search page
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// this is the text for the no search results indicator
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get search_no_results;

  /// this is the title for the quick actions section
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// this is the title for the favorites section
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// this is the title for the playlists section
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get playlists;

  /// this is the title for the recently played section
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recently_played;

  /// this is the title for the recommendations section
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get recommendations;

  /// this is the text for the no recent songs indicator
  ///
  /// In en, this message translates to:
  /// **'No recent songs'**
  String get no_recent_songs;

  /// this is the text for the no recommendations indicator
  ///
  /// In en, this message translates to:
  /// **'No recommendations'**
  String get no_recommendations;

  /// this is the text for the failed to load songs error
  ///
  /// In en, this message translates to:
  /// **'Failed to load songs'**
  String get failed_to_load_songs;

  /// No description provided for @scan_local_music.
  ///
  /// In en, this message translates to:
  /// **'Scan Local Music'**
  String get scan_local_music;

  /// No description provided for @no_scan_performed.
  ///
  /// In en, this message translates to:
  /// **'No scan performed'**
  String get no_scan_performed;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get scanning;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

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

  /// No description provided for @found_songs.
  ///
  /// In en, this message translates to:
  /// **'Found {count} songs'**
  String found_songs(Object count);

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

  /// this is the text for the toggle sidebar button
  ///
  /// In en, this message translates to:
  /// **'Toggle Sidebar'**
  String get toggle_sidebar;

  /// this is the text for the no songs in player indicator
  ///
  /// In en, this message translates to:
  /// **'No songs in the player'**
  String get no_things_players;

  /// this is the title for the song list section
  ///
  /// In en, this message translates to:
  /// **'Song List'**
  String get song_list_title;

  /// this is the title for the profile page
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

  /// this is the language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// this is the theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}

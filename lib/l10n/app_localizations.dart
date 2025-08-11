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

  /// this is the text for the now playing indicator
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get now_playing;

  /// this is the text for the no things players indicator
  ///
  /// In en, this message translates to:
  /// **'No things players'**
  String get no_things_players;

  /// this is the text for the no song selected indicator
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get no_selected_song;

  /// this is the title for the song list
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get song_list_title;

  /// this is the text for the no songs found indicator
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get no_songs_found;

  /// this is the text for the duration indicator
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get player_duration;

  /// this is the text for the artist indicator
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get player_artist;

  /// this is the text for the album indicator
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get player_album;

  /// this is the text for the empty search indicator
  ///
  /// In en, this message translates to:
  /// **'Enter a search term to find songs'**
  String get search_empty;

  /// this is the text for the no results indicator
  ///
  /// In en, this message translates to:
  /// **'No songs found matching your search'**
  String get search_no_results;

  /// this is the text for the language indicator
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// this is the text for the theme indicator
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// this is the text for the font indicator
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get font;

  /// this is the name of the theme
  ///
  /// In en, this message translates to:
  /// **'Trendy Electro'**
  String get theme_trendy_electro;

  /// this is the name of the theme
  ///
  /// In en, this message translates to:
  /// **'Minimal Gray'**
  String get theme_minimal_gray;

  /// this is the name of the theme
  ///
  /// In en, this message translates to:
  /// **'Nature Forest'**
  String get theme_nature_forest;

  /// this is the name of the theme
  ///
  /// In en, this message translates to:
  /// **'Cyber Neon'**
  String get theme_cyber_neon;

  /// this is the name of the theme
  ///
  /// In en, this message translates to:
  /// **'Warm Healing'**
  String get theme_warm_healing;

  /// this is the text for the about indicator
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// this is the text for the artists indicator
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get library_artists;

  /// this is the text for the albums indicator
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get library_albums;

  /// this is the text for the genres indicator
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

  /// this is the name of the English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get locale;

  /// this is the title of the search page
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// this is the message shown when there is no song playing
  ///
  /// In en, this message translates to:
  /// **'No song is playing'**
  String get no_song_playing;

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

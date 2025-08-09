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
  ];

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

  /// No description provided for @library_title.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library_title;

  /// No description provided for @search_title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search_title;

  /// No description provided for @search_hint_text.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search_hint_text;

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

  /// No description provided for @theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get theme_dark;

  /// No description provided for @theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get theme_system;

  /// No description provided for @bottom_player_bar_now_playing.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get bottom_player_bar_now_playing;

  /// No description provided for @bottom_player_bar_no_song.
  ///
  /// In en, this message translates to:
  /// **'No song selected'**
  String get bottom_player_bar_no_song;

  /// No description provided for @song_list_title.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get song_list_title;

  /// No description provided for @song_list_no_songs.
  ///
  /// In en, this message translates to:
  /// **'No songs found'**
  String get song_list_no_songs;

  /// No description provided for @player_page_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get player_page_duration;

  /// No description provided for @player_page_artist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get player_page_artist;

  /// No description provided for @player_page_album.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get player_page_album;

  /// No description provided for @search_page_hint.
  ///
  /// In en, this message translates to:
  /// **'Search songs...'**
  String get search_page_hint;

  /// No description provided for @search_page_empty.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term to find songs'**
  String get search_page_empty;

  /// No description provided for @search_page_no_results.
  ///
  /// In en, this message translates to:
  /// **'No songs found matching your search'**
  String get search_page_no_results;

  /// No description provided for @settings_page_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_page_language;

  /// No description provided for @settings_page_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_page_theme;

  /// No description provided for @theme_name_trendy_electro.
  ///
  /// In en, this message translates to:
  /// **'Trendy Electro'**
  String get theme_name_trendy_electro;

  /// No description provided for @theme_name_minimal_gray.
  ///
  /// In en, this message translates to:
  /// **'Minimal Gray'**
  String get theme_name_minimal_gray;

  /// No description provided for @theme_name_nature_forest.
  ///
  /// In en, this message translates to:
  /// **'Nature Forest'**
  String get theme_name_nature_forest;

  /// No description provided for @theme_name_cyber_neon.
  ///
  /// In en, this message translates to:
  /// **'Cyber Neon'**
  String get theme_name_cyber_neon;

  /// No description provided for @theme_name_warm_healing.
  ///
  /// In en, this message translates to:
  /// **'Warm Healing'**
  String get theme_name_warm_healing;

  /// No description provided for @theme_name_dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get theme_name_dark_mode;

  /// No description provided for @theme_name_light_mode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get theme_name_light_mode;

  /// No description provided for @theme_name_system_theme.
  ///
  /// In en, this message translates to:
  /// **'System Theme'**
  String get theme_name_system_theme;

  /// No description provided for @settings_page_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_page_about;

  /// No description provided for @library_page_artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get library_page_artists;

  /// No description provided for @library_page_albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get library_page_albums;

  /// No description provided for @library_page_genres.
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get library_page_genres;
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

import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/library/domain/library_filter.dart';

String filterStatusLabel(BuildContext context, LibraryStatusFilter status) =>
    switch (status) {
      LibraryStatusFilter.all => context.loc.libraryFilterStatusAll,
      LibraryStatusFilter.liked => context.loc.libraryFilterStatusLiked,
      LibraryStatusFilter.withLyrics =>
        context.loc.libraryFilterStatusWithLyrics,
      LibraryStatusFilter.withoutLyrics =>
        context.loc.libraryFilterStatusWithoutLyrics,
      LibraryStatusFilter.instrumental =>
        context.loc.libraryFilterStatusInstrumental,
    };

String filterDurationLabel(
  BuildContext context,
  LibraryDurationBucket bucket,
) => switch (bucket) {
  LibraryDurationBucket.short => context.loc.libraryFilterDurationShort,
  LibraryDurationBucket.medium => context.loc.libraryFilterDurationMedium,
  LibraryDurationBucket.long => context.loc.libraryFilterDurationLong,
  LibraryDurationBucket.epic => context.loc.libraryFilterDurationEpic,
};

String filterAddedLabel(BuildContext context, LibraryAddedWindow window) =>
    switch (window) {
      LibraryAddedWindow.lastWeek => context.loc.libraryFilterAddedWeek,
      LibraryAddedWindow.lastMonth => context.loc.libraryFilterAddedMonth,
      LibraryAddedWindow.lastYear => context.loc.libraryFilterAddedYear,
      LibraryAddedWindow.older => context.loc.libraryFilterAddedOlder,
    };

String filterDecadeLabel(int decade) => '${decade}s';

/// Formats are technical names: MP3 stays MP3 in every language.
String filterFormatLabel(String format) => format.toUpperCase();

/// The name of a language in the reader's language; an unknown code keeps
/// its own spelling so the filter still says what it holds.
String filterLanguageLabel(BuildContext context, String language) =>
    switch (language.toLowerCase()) {
      'zh' => context.loc.languageZh,
      'en' => context.loc.languageEn,
      'ja' => context.loc.languageJa,
      'ko' => context.loc.languageKo,
      'fr' => context.loc.languageFr,
      'de' => context.loc.languageDe,
      'es' => context.loc.languageEs,
      'ru' => context.loc.languageRu,
      _ => language.toUpperCase(),
    };

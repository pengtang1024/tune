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

/// The language codes are shown as codes for now; the localized names are
/// the next polish step (docs/library-browse.md §4.3).
String filterLanguageLabel(String language) => language.toUpperCase();

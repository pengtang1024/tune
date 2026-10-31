import 'package:flutter/foundation.dart';
import 'package:tune/features/library/domain/library_filter.dart';

/// The counts the filter panel and the category cards read.
///
/// Every map is keyed by the value the filter accepts: genre and language
/// keys are lower-case, artist and source names are the stored spelling,
/// formats are the normalized enum names.
@immutable
class LibraryFacets {
  final Map<String, int> genres;
  final Map<int, int> decades;
  final Map<String, int> artists;
  final Map<String, int> sources;
  final Map<String, int> languages;
  final Map<String, int> formats;
  final Map<LibraryDurationBucket, int> durations;
  final Map<LibraryAddedWindow, int> added;
  final Map<LibraryStatusFilter, int> statuses;

  const LibraryFacets({
    this.genres = const {},
    this.decades = const {},
    this.artists = const {},
    this.sources = const {},
    this.languages = const {},
    this.formats = const {},
    this.durations = const {},
    this.added = const {},
    this.statuses = const {},
  });

  static const LibraryFacets empty = LibraryFacets();
}

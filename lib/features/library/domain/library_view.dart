import 'package:flutter/foundation.dart';
import 'package:tune/features/library/domain/library_filter.dart';
import 'package:tune/features/library/domain/library_sort.dart';

/// What the reader left the library looking like: the order and the filters.
///
/// It lives in `<support>/library/view.json`; the search word and the view
/// mode are session state and stay out of it.
@immutable
class LibraryView {
  final LibrarySort sort;
  final LibraryFilter filter;

  const LibraryView({
    this.sort = LibrarySort.recent,
    this.filter = LibraryFilter.empty,
  });

  Map<String, dynamic> toJson() => {
    'sort': {'field': sort.field.name, 'ascending': sort.ascending},
    'filter': {
      'status': filter.status.name,
      'genres': filter.genres.toList(),
      'decades': filter.decades.toList(),
      'artists': filter.artists.toList(),
      'sources': filter.sources.toList(),
      'formats': filter.formats.toList(),
      'durations': [for (final value in filter.durations) value.name],
      'added': [for (final value in filter.added) value.name],
      'languages': filter.languages.toList(),
    },
  };

  factory LibraryView.fromJson(Map<String, dynamic> json) {
    final sort = json['sort'];
    final filter = json['filter'];
    return LibraryView(
      sort: sort is Map
          ? LibrarySort(
              field: LibrarySortField.values.asNameMap()[sort['field']] ??
                  LibrarySortField.title,
              ascending: sort['ascending'] == true,
            )
          : LibrarySort.recent,
      filter: filter is Map
          ? LibraryFilter(
              status: LibraryStatusFilter.values
                      .asNameMap()[filter['status']] ??
                  LibraryStatusFilter.all,
              genres: _strings(filter['genres']),
              decades: _ints(filter['decades']),
              artists: _strings(filter['artists']),
              sources: _strings(filter['sources']),
              formats: _strings(filter['formats']),
              durations: {
                for (final name in _strings(filter['durations']))
                  if (LibraryDurationBucket.values.asNameMap()[name] != null)
                    LibraryDurationBucket.values.asNameMap()[name]!,
              },
              added: {
                for (final name in _strings(filter['added']))
                  if (LibraryAddedWindow.values.asNameMap()[name] != null)
                    LibraryAddedWindow.values.asNameMap()[name]!,
              },
              languages: _strings(filter['languages']),
            )
          : LibraryFilter.empty,
    );
  }

  static Set<String> _strings(Object? value) =>
      value is List ? {for (final item in value) if (item is String) item} : {};

  static Set<int> _ints(Object? value) =>
      value is List ? {for (final item in value) if (item is int) item} : {};
}

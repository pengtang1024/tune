import 'package:tune/features/discovery/domain/discovery_section.dart';

enum DiscoveryFailure { libraryUnavailable, computationFailed }

/// What one explicit online lookup for an artist produced.
enum DiscoveryOnlineResult { added, noSources, noResults, failed }

/// What the discover page shows right now.
///
/// The sections are a projection of the library and the favorites. They are
/// kept in memory while the page is open and are never written to the disk.
class DiscoveryState {
  final bool isLoading;
  final List<DiscoverySection> sections;
  final DiscoveryFailure? failure;
  final DateTime? generatedAt;
  final String? dateKey;

  /// Artists whose online lookup is running right now.
  final Set<String> findingArtists;

  const DiscoveryState({
    this.isLoading = false,
    this.sections = const [],
    this.failure,
    this.generatedAt,
    this.dateKey,
    this.findingArtists = const {},
  });

  bool get hasSections => sections.isNotEmpty;

  DiscoveryState copyWith({
    bool? isLoading,
    List<DiscoverySection>? sections,
    Object? failure = _unset,
    DateTime? generatedAt,
    String? dateKey,
    Set<String>? findingArtists,
  }) {
    return DiscoveryState(
      isLoading: isLoading ?? this.isLoading,
      sections: sections ?? this.sections,
      failure: identical(failure, _unset)
          ? this.failure
          : failure as DiscoveryFailure?,
      generatedAt: generatedAt ?? this.generatedAt,
      dateKey: dateKey ?? this.dateKey,
      findingArtists: findingArtists ?? this.findingArtists,
    );
  }
}

const Object _unset = Object();

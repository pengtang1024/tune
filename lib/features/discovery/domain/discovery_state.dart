import 'package:tune/features/discovery/domain/discovery_section.dart';

enum DiscoveryFailure { libraryUnavailable, computationFailed }

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

  const DiscoveryState({
    this.isLoading = false,
    this.sections = const [],
    this.failure,
    this.generatedAt,
    this.dateKey,
  });

  bool get hasSections => sections.isNotEmpty;
}

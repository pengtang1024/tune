import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/genre_label.dart';
import 'package:tune/domain/models/music_source.dart';
import 'package:tune/features/discovery/domain/discovery_section.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';

/// The words of a recommendation reason.
String discoveryReasonText(
  BuildContext context,
  RecommendationReason reason,
  Map<String, SourceLabel> sourceLabels,
) {
  return switch (reason.kind) {
    RecommendationReasonKind.favorite => context.loc.discoverReasonFavorite,
    RecommendationReasonKind.artist => context.loc.discoverReasonArtist(
      _nonEmpty(reason.artist, context.loc.discoverReasonFallback),
    ),
    RecommendationReasonKind.genre => context.loc.discoverReasonGenre(
      genreLabel(_nonEmpty(reason.genre, ''), context.loc),
    ),
    RecommendationReasonKind.era => context.loc.discoverReasonEra(
      reason.decade ?? 0,
    ),
    RecommendationReasonKind.adjacent => context.loc.discoverReasonAdjacent,
    RecommendationReasonKind.fresh => context.loc.discoverReasonFresh,
    RecommendationReasonKind.unheard => context.loc.discoverReasonUnheard,
    RecommendationReasonKind.source => context.loc.discoverReasonSource(
      _sourceName(reason.sourceId, sourceLabels, context),
    ),
    RecommendationReasonKind.fallback => context.loc.discoverReasonFallback,
  };
}

/// The title of a section, written in the language of the reader.
String discoverySectionTitle(
  BuildContext context,
  DiscoverySection section,
  Map<String, SourceLabel> sourceLabels,
) {
  final reason = section.reason;
  return switch (section.kind) {
    DiscoverySectionKind.dailyMix => context.loc.discoverSectionDailyMix,
    DiscoverySectionKind.artist => context.loc.discoverSectionArtist(
      _nonEmpty(reason.artist, context.loc.discoverReasonFallback),
    ),
    DiscoverySectionKind.explore => switch (reason.kind) {
      RecommendationReasonKind.genre => context.loc.discoverSectionExplore(
        genreLabel(_nonEmpty(reason.genre, ''), context.loc),
      ),
      RecommendationReasonKind.era => context.loc.discoverSectionExploreEra(
        reason.decade ?? 0,
      ),
      RecommendationReasonKind.adjacent =>
        context.loc.discoverSectionExploreEars,
      _ => context.loc.discoverSectionExploreEars,
    },
    DiscoverySectionKind.fresh => context.loc.discoverSectionFresh,
    DiscoverySectionKind.onlineArtist =>
      context.loc.discoverSectionOnlineArtist(
        _nonEmpty(reason.artist, context.loc.discoverReasonFallback),
      ),
    DiscoverySectionKind.source => context.loc.discoverSectionSource(
      _sourceName(reason.sourceId, sourceLabels, context),
    ),
    DiscoverySectionKind.fallback => context.loc.discoverSectionFallback,
  };
}

String _sourceName(
  String? sourceId,
  Map<String, SourceLabel> sourceLabels,
  BuildContext context,
) {
  if (sourceId == null || sourceId.isEmpty) {
    return context.loc.discoverReasonFallback;
  }
  return sourceLabels[sourceId]?.name ?? sourceId;
}

String _nonEmpty(String? value, String fallback) {
  if (value == null || value.trim().isEmpty) return fallback;
  return value.trim();
}

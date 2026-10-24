import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/domain/recommendation_reason.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The actions of a recommendation card.
enum RecommendationCardAction { queue, dismiss, details }

class RoundCardControl extends StatelessWidget {
  final Widget child;

  const RoundCardControl({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        shape: BoxShape.circle,
      ),
      child: child,
    );
  }
}

class RecommendationCardMenu extends StatelessWidget {
  final bool canDismiss;
  final ValueChanged<RecommendationCardAction> onSelected;

  const RecommendationCardMenu({
    super.key,
    required this.canDismiss,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TuneTooltip(
      message: context.loc.discoverMoreActions,
      child: PopupMenuButton<RecommendationCardAction>(
        icon: const Icon(Icons.more_horiz_rounded, size: CompactTokens.icon16),
        iconSize: CompactTokens.icon16,
        padding: EdgeInsets.zero,
        onSelected: onSelected,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: RecommendationCardAction.queue,
            child: Text(context.loc.libraryAddToQueue),
          ),
          if (canDismiss)
            PopupMenuItem(
              value: RecommendationCardAction.dismiss,
              child: Text(context.loc.discoverDismiss),
            ),
          PopupMenuItem(
            value: RecommendationCardAction.details,
            child: Text(context.loc.trackDetailsTooltip),
          ),
        ],
      ),
    );
  }
}

IconData recommendationReasonIcon(RecommendationReasonKind kind) {
  return switch (kind) {
    RecommendationReasonKind.favorite => Icons.favorite_rounded,
    RecommendationReasonKind.artist => Icons.person_rounded,
    RecommendationReasonKind.genre => Icons.category_rounded,
    RecommendationReasonKind.era => Icons.history_rounded,
    RecommendationReasonKind.fresh => Icons.new_releases_rounded,
    RecommendationReasonKind.unheard => Icons.hearing_rounded,
    RecommendationReasonKind.source => Icons.podcasts_rounded,
    RecommendationReasonKind.fallback => Icons.auto_awesome_rounded,
  };
}

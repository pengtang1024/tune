import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/discovery/presentation/discovery_empty_state.dart';

Widget discoveryEmptyLibrary(BuildContext context) {
  return DiscoveryEmptyState(
    icon: Icons.auto_awesome_rounded,
    title: context.loc.discoverEmptyLibraryTitle,
    subtitle: context.loc.discoverEmptyLibrarySubtitle,
    actions: [
      FilledButton.icon(
        key: const ValueKey('discovery-scan'),
        onPressed: () => context.go('/library'),
        icon: const Icon(Icons.search_rounded),
        label: Text(context.loc.discoverScanMusic),
      ),
      OutlinedButton.icon(
        key: const ValueKey('discovery-sources'),
        onPressed: () => context.go('/sources'),
        icon: const Icon(Icons.podcasts_rounded),
        label: Text(context.loc.discoverConnectSources),
      ),
    ],
  );
}

Widget discoveryNoCandidates(BuildContext context, VoidCallback onClear) {
  return DiscoveryEmptyState(
    icon: Icons.check_circle_outline_rounded,
    title: context.loc.discoverNoCandidatesTitle,
    subtitle: context.loc.discoverNoCandidatesSubtitle,
    actions: [
      FilledButton(
        onPressed: () => context.go('/library'),
        child: Text(context.loc.discoverGoToLibrary),
      ),
      OutlinedButton(
        onPressed: onClear,
        child: Text(context.loc.discoverClearAll),
      ),
    ],
  );
}

Widget discoveryFailure(BuildContext context, VoidCallback onRetry) {
  return DiscoveryEmptyState(
    icon: Icons.error_outline_rounded,
    title: context.loc.discoverLoadFailed,
    subtitle: context.loc.discoverLoadFailedHint,
    actions: [FilledButton(onPressed: onRetry, child: Text(context.loc.retry))],
  );
}

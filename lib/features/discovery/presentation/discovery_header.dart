import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/shared/ui/page_heading.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The heading of the discover page.
class DiscoveryHeader extends StatelessWidget {
  final VoidCallback onRefresh;
  final VoidCallback onInfo;

  const DiscoveryHeader({
    super.key,
    required this.onRefresh,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        CompactTokens.pageTopPadding,
        CompactTokens.pageGutter,
        CompactTokens.pageHeadingGap,
      ),
      child: PageHeading(
        eyebrow: context.loc.discoverEyebrow,
        title: context.loc.discoverTitle,
        subtitle: context.loc.discoverSubtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TuneTooltip(
              message: context.loc.discoverRefresh,
              child: IconButton(
                key: const ValueKey('discovery-refresh'),
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: CompactTokens.icon18,
                ),
              ),
            ),
            TuneTooltip(
              message: context.loc.discoverWhy,
              child: IconButton(
                key: const ValueKey('discovery-why'),
                onPressed: onInfo,
                icon: const Icon(
                  Icons.info_outline_rounded,
                  size: CompactTokens.icon18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

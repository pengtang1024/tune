import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';
import 'package:tune/shared/ui/page_heading.dart';

/// The sources page.
///
/// The page lists the configured music sources; the list itself is owned by
/// [MusicSourcesSection].
class SourcesPane extends StatelessWidget {
  const SourcesPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          CompactTokens.pageTopPadding,
          CompactTokens.pageGutter,
          CompactTokens.pageGutter,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              eyebrow: context.loc.sourcesEyebrow,
              title: context.loc.sourcesTitle,
              subtitle: context.loc.sourcesSubtitle,
            ),
            const SizedBox(height: 24),
            const MusicSourcesSection(),
          ],
        ),
      ),
    );
  }
}

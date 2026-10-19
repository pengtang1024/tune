import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeading(
              eyebrow: 'CONNECTIONS',
              title: '音源',
              subtitle: '在线曲库与扫描目录',
            ),
            const SizedBox(height: 24),
            const MusicSourcesSection(),
          ],
        ),
      ),
    );
  }
}

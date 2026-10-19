import 'package:flutter/material.dart';
import 'package:tune/features/sources/presentation/music_sources_section.dart';

class SourcesPane extends StatelessWidget {
  const SourcesPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PageHeading(
              eyebrow: 'CONNECTIONS',
              title: 'Sources',
              subtitle: '音源与在线曲库',
            ),
            const SizedBox(height: 28),
            const MusicSourcesSection(),
          ],
        ),
      ),
    );
  }
}

class _PageHeading extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  const _PageHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 9,
            letterSpacing: 2,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: theme.textTheme.displayMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontSize: 38,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

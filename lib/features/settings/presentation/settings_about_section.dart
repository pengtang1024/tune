import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';
import 'package:tune/features/settings/presentation/settings_update_card.dart';

/// The about block, with the update card beside it when this build ships one.
class SettingsAboutSection extends StatelessWidget {
  /// Whether this build updates itself.
  final bool autoUpdate;

  const SettingsAboutSection({super.key, required this.autoUpdate});

  @override
  Widget build(BuildContext context) {
    final about = SettingsAboutCard(version: AppVersion.version);
    if (!autoUpdate) return about;
    const update = SettingsUpdateCard();
    return LayoutBuilder(
      builder: (context, constraints) {
        // Side by side needs room for the longest action label ("Check for
        // updates") beside the title; below that the cards stack full width.
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              about,
              const SizedBox(height: CompactTokens.space8),
              update,
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: about),
              const SizedBox(width: CompactTokens.space8),
              const Expanded(child: update),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/localization/application/localization_providers.dart';

/// Why translation is paused right now.
class SettingsLocalizationAvailabilityNotice extends StatelessWidget {
  final TranslationAvailability availability;

  const SettingsLocalizationAvailabilityNotice({
    super.key,
    required this.availability,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final text = switch (availability) {
      TranslationAvailability.needsProvider =>
        strings.settingsLocalizationAvailabilityNeedsProvider,
      TranslationAvailability.needsKey =>
        strings.settingsLocalizationAvailabilityNeedsKey,
      TranslationAvailability.needsModel =>
        strings.settingsLocalizationAvailabilityNeedsModel,
      TranslationAvailability.localNotInstalled =>
        strings.settingsLocalizationAvailabilityLocalMissing,
      TranslationAvailability.available => '',
    };
    return Padding(
      padding: const EdgeInsets.only(top: CompactTokens.space8),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

/// What leaves the device, and what stays.
class SettingsLocalizationPrivacyNotice extends StatelessWidget {
  const SettingsLocalizationPrivacyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.loc;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(strings.settingsLocalizationPrivacyTitle, style: muted),
        const SizedBox(height: CompactTokens.space4),
        Text(strings.settingsLocalizationPrivacySend, style: muted),
        Text(strings.settingsLocalizationPrivacyKeep, style: muted),
      ],
    );
  }
}

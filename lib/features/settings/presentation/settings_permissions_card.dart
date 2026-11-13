import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/mobile_permissions_service.dart';
import 'package:tune/features/settings/application/mobile_permissions_controller.dart';

/// The permissions Android asks for while the app runs.
///
/// The card shows what the system answered, offers the dialog again while it
/// may still be shown, and sends the reader to the system settings once the
/// permission was refused for good. A refusal never hides the app: the rows
/// simply say that the matching feature is off.
class SettingsPermissionsCard extends ConsumerWidget {
  /// Whether the card is drawn inside the sheet of its section.
  final bool embedded;

  const SettingsPermissionsCard({super.key, this.embedded = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(mobilePermissionsControllerProvider);
    final controller = ref.read(mobilePermissionsControllerProvider.notifier);

    final value = state.valueOrNull;
    if (value == null) {
      return Text(
        context.loc.settingsPermissionsDescription,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.settingsPermissionsDescription,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: CompactTokens.space12),
        _PermissionRow(
          key: const ValueKey('settings-permission-notifications'),
          title: context.loc.settingsPermissionNotifications,
          description: context.loc.settingsPermissionNotificationsHint,
          deniedHint: context.loc.settingsPermissionDeniedHint,
          status: value.notifications,
          onRequest: () => controller.request(MobilePermission.notifications),
          onOpenSettings: controller.openSettings,
        ),
        const SizedBox(height: CompactTokens.space12),
        _PermissionRow(
          key: const ValueKey('settings-permission-media'),
          title: context.loc.settingsPermissionMedia,
          description: context.loc.settingsPermissionMediaHint,
          deniedHint: context.loc.settingsPermissionDeniedHint,
          status: value.mediaAudio,
          onRequest: () => controller.request(MobilePermission.mediaAudio),
          onOpenSettings: controller.openSettings,
        ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    super.key,
    required this.title,
    required this.description,
    required this.deniedHint,
    required this.status,
    required this.onRequest,
    required this.onOpenSettings,
  });

  final String title;
  final String description;
  final String deniedHint;
  final MobilePermissionStatus status;
  final VoidCallback onRequest;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final granted = status == MobilePermissionStatus.granted;
    final refusedForGood = status == MobilePermissionStatus.permanentlyDenied;
    final hint = refusedForGood ? deniedHint : description;

    return Row(
      children: [
        Icon(
          granted ? Icons.check_circle_rounded : Icons.error_outline_rounded,
          size: CompactTokens.icon18,
          color: granted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: CompactTokens.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: CompactTokens.space12),
        if (granted)
          Text(
            context.loc.settingsPermissionGranted,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          )
        else
          OutlinedButton(
            onPressed: refusedForGood ? onOpenSettings : onRequest,
            child: Text(
              refusedForGood
                  ? context.loc.settingsPermissionOpenSettings
                  : context.loc.settingsPermissionAllow,
            ),
          ),
      ],
    );
  }
}

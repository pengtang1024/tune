import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/player/widgets/player_speed.dart';
import 'package:tune/ui/player/widgets/player_volume.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class PlayerOptions extends ConsumerWidget {
  const PlayerOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      decoration: BoxDecoration(
        color: isDark
            ? AppDesignSystem.neutral900.withValues(alpha: 0.5)
            : AppDesignSystem.neutral100.withValues(alpha: 0.5),
        borderRadius: AppDesignSystem.borderRadius16,
        border: Border.all(
          color: isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral200,
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: AppDesignSystem.spacing16,
        runSpacing: AppDesignSystem.spacing12,
        alignment: WrapAlignment.center,
        children: const [
          PlayerVolume(),
          PlayerSpeed(),
        ],
      ),
    );
  }
}

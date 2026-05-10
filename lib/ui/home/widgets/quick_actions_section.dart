import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.quick_actions,
          style: AppDesignSystem.textTheme.titleLarge?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing16),
        ModernCard(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(icon: Icons.music_note_outlined, label: loc.my_songs, onTap: () => context.go('/library/songs')),
              _ActionButton(icon: Icons.favorite_border, label: loc.favorites, onTap: () => context.go('/library/favorites')),
              _ActionButton(icon: Icons.playlist_play, label: loc.playlists, onTap: () => context.go('/library/playlists')),
              _ActionButton(icon: Icons.radio, label: loc.radio, onTap: () => context.go('/radio')),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppInteractions.pressableScale(
          scaleValue: 0.92,
          onTap: onTap,
          child: Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppDesignSystem.primary.withValues(alpha: 0.08),
              borderRadius: AppDesignSystem.borderRadius28,
            ),
            child: Icon(icon, size: AppDesignSystem.iconSize28, color: AppDesignSystem.primary),
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(label, style: AppDesignSystem.textTheme.labelSmall),
      ],
    );
  }
}

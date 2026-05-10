import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class LogoSectionWidget extends StatelessWidget {
  final bool isExpanded;

  const LogoSectionWidget({super.key, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: AnimatedSwitcher(
        duration: AppDesignSystem.duration300,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: isExpanded
            ? Row(
                key: const ValueKey('expanded'),
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppDesignSystem.primaryGradient,
                      borderRadius: AppDesignSystem.borderRadius12,
                    ),
                    child: const Icon(Icons.music_note_rounded, color: Colors.white, size: AppDesignSystem.iconSize24),
                  ),
                  const SizedBox(width: AppDesignSystem.spacing12),
                  Text(
                    'Tune',
                    style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                      fontWeight: AppDesignSystem.fontWeightBold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              )
            : Center(
                key: const ValueKey('collapsed'),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppDesignSystem.primaryGradient,
                    borderRadius: AppDesignSystem.borderRadius12,
                  ),
                  child: const Icon(Icons.music_note_rounded, color: Colors.white, size: AppDesignSystem.iconSize24),
                ),
              ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/home/widgets/hero_header.dart';
import 'package:tune/ui/home/widgets/library_overview_section.dart';
import 'package:tune/ui/home/widgets/quick_actions_section.dart';
import 'package:tune/ui/home/widgets/recent_section.dart';
import 'package:tune/ui/home/widgets/welcome_section.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/theme/app_interactions.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < AppDesignSystem.breakpointMobile;
    final playerState = ref.watch(playerStateNotifierProvider);

    final pad = isCompact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing24;
    final gap = isCompact ? AppDesignSystem.spacing32 : AppDesignSystem.spacing40;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppDesignSystem.backgroundGradientDark
            : AppDesignSystem.backgroundGradientLight,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeroHeader().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
              ),
              SizedBox(height: gap),
              WelcomeSection(playerState: playerState).withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
                delay: const Duration(milliseconds: 80),
              ),
              SizedBox(height: gap),
              LibraryOverviewSection().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
                delay: const Duration(milliseconds: 160),
              ),
              SizedBox(height: gap),
              QuickActionsSection().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
                delay: const Duration(milliseconds: 240),
              ),
              SizedBox(height: gap),
              RecentSection().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
                delay: const Duration(milliseconds: 320),
              ),
              SizedBox(height: isCompact ? AppDesignSystem.spacing32 : AppDesignSystem.spacing48),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/home/widgets/hero_header.dart';
import 'package:tune/ui/home/widgets/quick_actions.dart';
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

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppDesignSystem.backgroundGradientDark
            : AppDesignSystem.backgroundGradientLight,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(isCompact ? AppDesignSystem.spacing16 : AppDesignSystem.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroHeader().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
              ),
              SizedBox(height: isCompact ? AppDesignSystem.spacing32 : AppDesignSystem.spacing40),
              const QuickActions().withSlideIn(
                begin: const Offset(0.0, 0.2),
                duration: AppDesignSystem.duration400,
                delay: const Duration(milliseconds: 100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

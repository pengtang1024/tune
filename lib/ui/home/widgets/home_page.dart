import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/home/widgets/hero_header.dart';
import 'package:tune/ui/home/widgets/quick_actions.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppDesignSystem.backgroundGradientDark
              : AppDesignSystem.backgroundGradientLight,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: Column(
              children: const [
                HeroHeader(),
                SizedBox(height: AppDesignSystem.spacing40),
                QuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

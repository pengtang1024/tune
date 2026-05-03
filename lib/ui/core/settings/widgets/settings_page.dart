import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/settings/widgets/tabs/about_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/general_tab.dart';
import 'package:tune/ui/core/settings/widgets/tabs/music_library_tab.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SettingsTabView();
  }
}

class SettingsTabView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const SettingsTabView({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends ConsumerState<SettingsTabView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? AppDesignSystem.backgroundGradientDark
            : AppDesignSystem.backgroundGradientLight,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: AppDesignSystem.spacing24),
              _buildTabBar(),
              const SizedBox(height: AppDesignSystem.spacing16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: const [
                    GeneralTab(),
                    MusicLibraryTab(),
                    AboutTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing8),
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            borderRadius: AppDesignSystem.borderRadius12,
          ),
          child: const Icon(
            Icons.settings_rounded,
            color: Colors.white,
            size: AppDesignSystem.iconSize24,
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Text(
          '设置',
          style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral100,
        borderRadius: AppDesignSystem.borderRadius16,
      ),
      child: TabBar(
        controller: _tabController,
        padding: const EdgeInsets.all(AppDesignSystem.spacing4),
        tabs: [
          Tab(text: context.loc.general_tab),
          Tab(text: context.loc.library_tab),
          Tab(text: context.loc.about_tab),
        ],
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          gradient: AppDesignSystem.primaryGradient,
          borderRadius: AppDesignSystem.borderRadius12,
        ),
        labelColor: Colors.white,
        labelStyle: AppDesignSystem.textTheme.labelLarge?.copyWith(
          fontWeight: AppDesignSystem.fontWeightSemiBold,
        ),
        unselectedLabelColor: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
        unselectedLabelStyle: AppDesignSystem.textTheme.labelLarge,
      ),
    );
  }
}

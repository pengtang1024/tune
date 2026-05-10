import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/ui/core/layout/widgets/desktop_layout.dart';
import 'package:tune/ui/core/layout/widgets/mobile_layout.dart';
import 'package:tune/ui/core/layout/widgets/tablet_layout.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/keyboard_shortcut_handler.dart';

enum ResponsiveLayoutType { mobile, tablet, desktop }

final responsiveLayoutTypeProvider = Provider<ResponsiveLayoutType>((ref) {
  final context = ref.watch(responsiveContextProvider);
  if (context == null) return ResponsiveLayoutType.desktop;
  final width = MediaQuery.of(context).size.width;
  if (width < AppDesignSystem.breakpointMobile) {
    return ResponsiveLayoutType.mobile;
  } else if (width < AppDesignSystem.breakpointTablet) {
    return ResponsiveLayoutType.tablet;
  }
  return ResponsiveLayoutType.desktop;
});

final responsiveContextProvider = StateProvider<BuildContext?>((ref) => null);

final showMiniPlayerProvider = Provider<bool>((ref) {
  final playerState = ref.watch(playerStateNotifierProvider);
  return playerState.currentSong != null;
});

class ResponsiveShell extends ConsumerWidget {
  final Widget child;

  const ResponsiveShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(responsiveContextProvider);
    if (contextState == null) {
      ref.read(responsiveContextProvider.notifier).state = context;
    }

    final layoutType = ref.watch(responsiveLayoutTypeProvider);
    final playerState = ref.watch(playerStateNotifierProvider);
    final showMini = playerState.currentSong != null;

    return KeyboardShortcutHandler(
      child: _ResponsiveScaffold(
      layoutType: layoutType,
      mainContent: child,
      showMiniPlayer: showMini,
    ),
    );
  }
}

class _ResponsiveScaffold extends StatelessWidget {
  final ResponsiveLayoutType layoutType;
  final Widget mainContent;
  final bool showMiniPlayer;

  const _ResponsiveScaffold({
    required this.layoutType,
    required this.mainContent,
    required this.showMiniPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final useSafeArea = layoutType != ResponsiveLayoutType.desktop;

    Widget content = AnimatedSwitcher(
      duration: AppDesignSystem.duration300,
      child: _buildLayout(context),
    );

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Scaffold(body: content);
  }

  Widget _buildLayout(BuildContext context) {
    switch (layoutType) {
      case ResponsiveLayoutType.mobile:
        return MobileLayout(
          key: const ValueKey('mobile'),
          child: mainContent,
          showMiniPlayer: showMiniPlayer,
        );
      case ResponsiveLayoutType.tablet:
        return TabletLayout(
          key: const ValueKey('tablet'),
          child: mainContent,
          showMiniPlayer: showMiniPlayer,
        );
      case ResponsiveLayoutType.desktop:
        return DesktopLayout(
          key: const ValueKey('desktop'),
          child: mainContent,
          showMiniPlayer: showMiniPlayer,
        );
    }
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveLayoutType get responsiveLayoutType {
    final width = MediaQuery.of(this).size.width;
    if (width < AppDesignSystem.breakpointMobile) {
      return ResponsiveLayoutType.mobile;
    } else if (width < AppDesignSystem.breakpointTablet) {
      return ResponsiveLayoutType.tablet;
    }
    return ResponsiveLayoutType.desktop;
  }
}

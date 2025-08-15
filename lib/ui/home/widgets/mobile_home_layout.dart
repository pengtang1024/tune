import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/providers/router_providers.dart';
import 'package:tune/l10n/app_localizations.dart';

class MobileHomeLayout extends ConsumerWidget {
  final Widget child;

  const MobileHomeLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routerState = ref.watch(routerProvider);
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: routerState.getSelectedIndex(),
        onDestinationSelected: (int index) {
          _navigateTo(context, ref, index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: localizations?.home ?? 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.music_note_outlined),
            selectedIcon: const Icon(Icons.music_note),
            label: localizations?.recommend ?? 'Recommend',
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline),
            selectedIcon: const Icon(Icons.star),
            label: localizations?.featured ?? 'Featured',
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            selectedIcon: const Icon(Icons.library_music),
            label: localizations?.library ?? 'Library',
          ),
        ],
      ),
    );
  }

  /// 导航到指定页面
  void _navigateTo(BuildContext context, WidgetRef ref, int index) {
    switch (index) {
      case 0:
        context.go('/');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/');
        break;
      case 1:
        context.go('/recommend');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/recommend');
        break;
      case 2:
        context.go('/featured');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/featured');
        break;
      case 3:
        context.go('/library');
        ref.read(routerProvider.notifier).updateSelectedMenuItem('/library');
        break;
    }
  }
}
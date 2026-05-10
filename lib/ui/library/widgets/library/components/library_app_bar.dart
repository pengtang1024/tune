import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/route_observer_provider.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class LibraryAppBar extends ConsumerWidget {
  const LibraryAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RouteObserverState>(routeObserverProvider, (previous, next) {
      if (next.route == '/library') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
          appBarNotifier.clearDynamicActions();
          final libraryState = ref.read(libraryStateNotifierProvider);
          appBarNotifier.addDynamicAction(
            IconButton(
              icon: const Icon(Icons.music_note, size: AppDesignSystem.iconSize24),
              onPressed: libraryState.scanStatus == ScanStatus.scanning
                  ? null
                  : () => context.push('/music-scan'),
              tooltip: context.loc.scan_local_music,
            ),
          );
        });
      } else {
        ref.read(appBarStateNotifierProvider.notifier).clearDynamicActions();
      }
    });

    return const SizedBox.shrink();
  }
}

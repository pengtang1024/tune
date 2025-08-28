import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/route_observer_provider.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';

class LibraryAppBar extends ConsumerWidget {
  const LibraryAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听路由变化，在进入音乐库页面时添加扫描按钮
    ref.listen<RouteObserverState>(routeObserverProvider, (previous, next) {
      if (next.route == '/library') {
        // 延迟执行以确保在widget构建完成后执行
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
          appBarNotifier.clearDynamicActions(); // 清除之前的动态按钮

          final libraryState = ref.read(libraryStateNotifierProvider);
          appBarNotifier.addDynamicAction(
            IconButton(
              icon: const Icon(Icons.music_note),
              onPressed: libraryState.scanStatus == ScanStatus.scanning
                  ? null
                  : () {
                      context.push('/music-scan');
                    },
              tooltip: context.loc.scan_local_music,
            ),
          );
        });
      } else {
        // 当页面被移除时清除动态按钮
        final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
        appBarNotifier.clearDynamicActions();
      }
    });

    return const SizedBox.shrink();
  }
}
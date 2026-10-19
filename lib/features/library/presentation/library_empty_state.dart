import 'package:flutter/material.dart';
import 'package:tune/features/library/domain/library_state.dart';
import 'package:tune/shared/ui/empty_state_view.dart';

/// Empty state of the library page.
///
/// The state names the reason the list is empty and offers the action that
/// resolves it.
class LibraryEmptyState extends StatelessWidget {
  final LibraryState state;
  final VoidCallback onClearQuery;
  final VoidCallback onClearSourceFilter;
  final VoidCallback onScan;

  const LibraryEmptyState({
    super.key,
    required this.state,
    required this.onClearQuery,
    required this.onClearSourceFilter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    if (state.query.trim().isNotEmpty && state.hasSongs) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: '没有匹配的歌曲',
        subtitle: '换个关键词，或清除搜索条件',
        action: TextButton(
          onPressed: onClearQuery,
          child: const Text('清除搜索'),
        ),
      );
    }

    if (state.sourceFilter != null && state.hasSongs) {
      return EmptyStateView(
        icon: Icons.filter_alt_off_rounded,
        title: '该来源暂无歌曲',
        subtitle: '切换到全部来源，或重新扫描该音源',
        action: TextButton(
          onPressed: onClearSourceFilter,
          child: const Text('查看全部来源'),
        ),
      );
    }

    return EmptyStateView(
      icon: Icons.library_music_outlined,
      title: state.isScanning ? '正在扫描音乐' : '还没有音乐',
      subtitle: state.isScanning
          ? state.statusMessage
          : '扫描本地目录或已启用的在线音源，也可以在设置中调整音源。',
      action: state.isScanning
          ? null
          : FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('扫描全部音源'),
            ),
    );
  }
}

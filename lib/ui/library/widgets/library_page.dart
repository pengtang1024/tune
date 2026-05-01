import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/app_bar_providers.dart';
import 'package:tune/providers/route_observer_provider.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/library/song_grid_widget.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    // 初始化时加载音乐库
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(libraryStateNotifierProvider.notifier);
      notifier.loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      } else if (next.route != '/music-scan') {
        // 当页面被移除时清除动态按钮（除了跳转到音乐扫描页面的情况）
        final appBarNotifier = ref.read(appBarStateNotifierProvider.notifier);
        appBarNotifier.clearDynamicActions();
      }
    });

    final state = ref.watch(libraryStateNotifierProvider);

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
          child: Padding(
            padding: const EdgeInsets.all(AppDesignSystem.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 页面标题
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                      decoration: BoxDecoration(
                        gradient: AppDesignSystem.primaryGradient,
                        borderRadius: AppDesignSystem.borderRadius12,
                      ),
                      child: Icon(
                        Icons.library_music_rounded,
                        color: Colors.white,
                        size: AppDesignSystem.iconSize24,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing12),
                    Text(
                      '音乐库',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: AppDesignSystem.fontWeightBold,
                        color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
                      ),
                    ),
                    const Spacer(),
                    if (state.songs.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDesignSystem.spacing12,
                          vertical: AppDesignSystem.spacing6,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primary.withValues(alpha: 0.1),
                          borderRadius: AppDesignSystem.borderRadius20,
                        ),
                        child: Text(
                          '${state.songs.length} 首歌曲',
                          style: TextStyle(
                            color: AppDesignSystem.primary,
                            fontSize: AppDesignSystem.fontSize12,
                            fontWeight: AppDesignSystem.fontWeightMedium,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppDesignSystem.spacing24),
                
                // 搜索框
                _buildSearchBar(),
                const SizedBox(height: AppDesignSystem.spacing16),

                // 扫描状态显示
                _buildScanStatusDisplay(state),

                // 歌曲列表
                Expanded(
                  child: SongGridWidget(
                    songs: state.songs,
                    searchQuery: _searchQuery,
                    localizedNoSongsFound: context.loc.no_songs_found,
                    style: SongGridStyle.list,
                    onSongTap: (song) {
                      // TODO: 播放歌曲或显示详情
                    },
                    onSongPlay: (song) {
                      // TODO: 播放歌曲
                    },
                    onSongMore: (song) {
                      // TODO: 显示更多操作
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.loc.search,
          hintStyle: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppDesignSystem.neutral500
                : AppDesignSystem.neutral400,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppDesignSystem.neutral500
                : AppDesignSystem.neutral400,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDesignSystem.spacing16,
            vertical: AppDesignSystem.spacing12,
          ),
        ),
        style: const TextStyle(
          fontSize: AppDesignSystem.fontSize16,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          _performSearch();
        },
      ),
    );
  }

  Widget _buildScanStatusDisplay(LibraryState state) {
    if (state.scanStatus == ScanStatus.idle || state.scanStatus == ScanStatus.completed) {
      return const SizedBox.shrink();
    }

    Color statusColor;
    IconData statusIcon;
    String statusType;

    switch (state.scanStatus) {
      case ScanStatus.scanning:
        statusColor = AppDesignSystem.primary;
        statusIcon = Icons.refresh_rounded;
        statusType = '扫描中';
        break;
      case ScanStatus.error:
        statusColor = AppDesignSystem.error;
        statusIcon = Icons.error_rounded;
        statusType = '错误';
        break;
      default:
        return const SizedBox.shrink();
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing16),
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      backgroundColor: statusColor.withValues(alpha: 0.1),
      borderSide: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      child: Row(
        children: [
          if (state.scanStatus == ScanStatus.scanning) ...[
            SizedBox(
              width: AppDesignSystem.iconSize20,
              height: AppDesignSystem.iconSize20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ] else if (state.scanStatus == ScanStatus.error) ...[
            Icon(
              statusIcon,
              color: statusColor,
              size: AppDesignSystem.iconSize20,
            ),
          ],
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusType,
                  style: TextStyle(
                    fontWeight: AppDesignSystem.fontWeightMedium,
                    color: statusColor,
                    fontSize: AppDesignSystem.fontSize14,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing2),
                Text(
                  state.statusMessage,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppDesignSystem.neutral300
                        : AppDesignSystem.neutral700,
                    fontSize: AppDesignSystem.fontSize12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 执行搜索的方法
  void _performSearch() {
    final notifier = ref.read(libraryStateNotifierProvider.notifier);
    notifier.updateSearchQuery(_searchQuery);
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/category_tabs.dart';
import 'package:tune/ui/library/widgets/library/song_grid_widget.dart';
import 'package:tune/ui/player/providers/player_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/empty_state.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  LibraryCategory _selectedCategory = LibraryCategory.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(libraryStateNotifierProvider.notifier).loadLibrary();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _buildHeader(state, isDark),
                const SizedBox(height: AppDesignSystem.spacing24),
                CategoryTabs(
                  selectedCategory: _selectedCategory,
                  onCategoryChanged: (category) {
                    setState(() => _selectedCategory = category);
                  },
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                _buildSearchBar(),
                const SizedBox(height: AppDesignSystem.spacing16),
                _buildScanStatusDisplay(state),
                Expanded(
                  child: state.songs.isEmpty
                      ? _buildEmptyState()
                      : SongGridWidget(
                          songs: state.songs,
                          searchQuery: _searchQuery,
                          localizedNoSongsFound: context.loc.no_songs_found,
                          style: SongGridStyle.list,
                          onSongTap: (song) => _playSong(song),
                          onSongPlay: (song) => _playSong(song),
                          onSongMore: (song) => _showSongOptions(context, song),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LibraryState state, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing8),
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            borderRadius: AppDesignSystem.borderRadius12,
          ),
          child: const Icon(
            Icons.library_music_rounded,
            color: Colors.white,
            size: AppDesignSystem.iconSize24,
          ),
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '音乐库',
                style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightBold,
                  color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
                ),
              ),
              if (state.songs.isNotEmpty) ...[
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  '${state.songs.length} 首歌曲',
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: AppDesignSystem.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索歌曲...',
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
                    setState(() => _searchQuery = '');
                    _performSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: AppDesignSystem.spacing14,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
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
                  style: AppDesignSystem.textTheme.labelLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightSemiBold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  state.statusMessage,
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppDesignSystem.neutral300
                        : AppDesignSystem.neutral700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.library_music_outlined,
      title: '暂无音乐',
      subtitle: '开始扫描本地音乐文件',
    );
  }

  void _performSearch() {
    ref.read(libraryStateNotifierProvider.notifier).updateSearchQuery(_searchQuery);
  }

  void _playSong(Song song) {
    ref.read(playerStateNotifierProvider.notifier).playSong(song);
    context.go('/player');
  }

  void _showSongOptions(BuildContext context, Song song) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('播放'),
                onTap: () {
                  Navigator.pop(context);
                  _playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('添加到播放列表'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('分享'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

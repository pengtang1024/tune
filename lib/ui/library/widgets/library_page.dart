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
import 'package:tune/ui/theme/app_interactions.dart';
import 'package:tune/ui/widgets/empty_state.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/widgets/skeleton_loader.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              _buildHeader(state, isDark).withSlideIn(),
              const SizedBox(height: AppDesignSystem.spacing20),
              CategoryTabs(
                selectedCategory: _selectedCategory,
                onCategoryChanged: (category) {
                  setState(() => _selectedCategory = category);
                },
              ),
              const SizedBox(height: AppDesignSystem.spacing16),
              _buildSearchBar().withFadeIn(),
              const SizedBox(height: AppDesignSystem.spacing12),
              _buildScanStatusDisplay(state),
              Expanded(
                child: state.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(AppDesignSystem.spacing8),
                        child: SkeletonLoader.songList(),
                      )
                    : state.songs.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.read(libraryStateNotifierProvider.notifier).loadLibrary();
                        },
                        child: SongGridWidget(
                        songs: state.songs,
                        searchQuery: _searchQuery,
                        localizedNoSongsFound: context.loc.no_songs_found,
                        style: SongGridStyle.list,
                        onSongTap: (song) => _playSong(song),
                        onSongPlay: (song) => _playSong(song),
                          onSongMore: (song) => _showSongOptions(context, song),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(LibraryState state, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppDesignSystem.spacing10),
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            borderRadius: AppDesignSystem.borderRadius12,
            boxShadow: [AppDesignSystem.shadowColored.first],
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
                context.loc.library_title,
                style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightBold,
                  color: isDark ? AppDesignSystem.neutral100 : AppDesignSystem.neutral900,
                ),
              ),
              if (state.songs.isNotEmpty) ...[
                const SizedBox(height: AppDesignSystem.spacing4),
                Text(
                  '${state.songs.length} tracks',
                  style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                    color: AppDesignSystem.primary,
                    fontWeight: AppDesignSystem.fontWeightMedium,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search tracks...',
          hintStyle: TextStyle(
            color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral400,
            fontSize: AppDesignSystem.fontSize14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral400,
            size: AppDesignSystem.iconSize20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? AppInteractions.pressableScale(
                  scaleValue: 0.9,
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _performSearch();
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: isDark ? AppDesignSystem.neutral500 : AppDesignSystem.neutral400,
                    size: AppDesignSystem.iconSize20,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing14),
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
    String statusType;
    IconData statusIcon;

    switch (state.scanStatus) {
      case ScanStatus.scanning:
        statusColor = AppDesignSystem.primary;
        statusType = context.loc.scanning;
        statusIcon = Icons.refresh_rounded;
        break;
      case ScanStatus.error:
        statusColor = AppDesignSystem.error;
        statusType = 'Error';
        statusIcon = Icons.error_rounded;
        break;
      default:
        return const SizedBox.shrink();
    }

    return ModernCard(
      margin: const EdgeInsets.only(bottom: AppDesignSystem.spacing12),
      padding: const EdgeInsets.all(AppDesignSystem.spacing12),
      backgroundColor: statusColor.withValues(alpha: 0.08),
      borderSide: BorderSide(color: statusColor.withValues(alpha: 0.2)),
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
          ] else ...[
            Icon(statusIcon, color: statusColor, size: AppDesignSystem.iconSize20),
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
                const SizedBox(height: 2),
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
    return EmptyState(
      icon: Icons.library_music_outlined,
      title: context.loc.no_songs_found,
      subtitle: 'Please scan local music files',
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDesignSystem.spacing16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Play'),
                onTap: () {
                  Navigator.pop(context);
                  _playSong(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to playlist'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded),
                title: const Text('Share'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

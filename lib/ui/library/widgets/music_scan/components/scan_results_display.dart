import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/library/states/library_state.dart';
import 'package:tune/ui/library/widgets/music_scan/scan_results_header_widget.dart';
import 'package:tune/ui/library/widgets/music_scan/song_list_item_widget.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_button.dart';

class ScanResultsDisplay extends StatelessWidget {
  final LibraryState state;
  final VoidCallback onAddToLibrary;
  final VoidCallback onResetScan;
  final Function(Song) onPlaySong;

  const ScanResultsDisplay({
    super.key,
    required this.state,
    required this.onAddToLibrary,
    required this.onResetScan,
    required this.onPlaySong,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDesignSystem.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScanResultsHeaderWidget(scannedCount: state.foundSongs.length),
          const SizedBox(height: AppDesignSystem.spacing24),
          if (state.scanStatus == ScanStatus.completed && state.foundSongs.isNotEmpty) ...[
            Text(
              'Found ${state.foundSongs.length} songs',
              style: AppDesignSystem.textTheme.titleMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightBold),
            ),
            const SizedBox(height: AppDesignSystem.spacing16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.foundSongs.length,
                itemBuilder: (context, index) {
                  final song = state.foundSongs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDesignSystem.spacing8),
                    child: SongListItemWidget(
                      song: song,
                      durationText: _fmtDuration(Duration(milliseconds: song.duration)),
                      onPlay: () => onPlaySong(song),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing24),
            Row(
              children: [
                Expanded(child: ModernButton.primary(text: 'Add to Library', onPressed: onAddToLibrary)),
                const SizedBox(width: AppDesignSystem.spacing16),
                ModernButton.outline(text: 'Rescan', onPressed: onResetScan),
              ],
            ),
          ] else if (state.scanStatus == ScanStatus.completed) ...[
            Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: AppDesignSystem.neutral400),
                  const SizedBox(height: AppDesignSystem.spacing16),
                  Text(
                    'No songs found',
                    style: AppDesignSystem.textTheme.titleMedium?.copyWith(fontWeight: AppDesignSystem.fontWeightBold),
                  ),
                  const SizedBox(height: AppDesignSystem.spacing8),
                  Text(
                    'Please check if the scan paths contain music files',
                    style: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: AppDesignSystem.neutral500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDesignSystem.spacing24),
            Center(child: ModernButton.outline(text: 'Rescan', onPressed: onResetScan)),
          ],
        ],
      ),
    );
  }

  String _fmtDuration(Duration duration) {
    return '${duration.inMinutes}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
  }
}

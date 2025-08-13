import 'package:flutter/material.dart';
import 'package:tune/features/home/presentation/bloc/home_state.dart';
import 'package:tune/l10n/app_localizations.dart';

class RecentlyPlayedSection extends StatelessWidget {
  final HomeState homeState;
  final AppLocalizations localizations;

  const RecentlyPlayedSection({
    super.key,
    required this.homeState,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    if (homeState is HomeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (homeState is HomeLoaded) {
      final homeLoaded = homeState as HomeLoaded;
      if (homeLoaded.recentlyPlayedSongs.isEmpty) {
        return Container(
          height: 100,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            localizations.no_songs_found,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }

      return SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: homeLoaded.recentlyPlayedSongs.length,
          itemBuilder: (context, index) {
            final song = homeLoaded.recentlyPlayedSongs[index];
            return Container(
              width: 100,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.history,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      song.title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      song.artist,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    // 错误或初始状态
    return Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        localizations.no_songs_found,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
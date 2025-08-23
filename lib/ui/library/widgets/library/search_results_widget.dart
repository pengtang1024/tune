import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/library/providers/library_providers.dart';
import 'package:tune/ui/library/widgets/library/song_grid_widget.dart';

class SearchResultsWidget extends ConsumerWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(libraryStateNotifierProvider);
    final localizations = context.loc;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage?.isNotEmpty ?? false) {
      String getLocalizedErrorMessage(String? errorMessage) {
        if (errorMessage == null || errorMessage.isEmpty) {
          return localizations.error;
        }

        // 常见错误消息的本地化映射
        if (errorMessage.contains('network')) {
          return localizations.network_error;
        } else if (errorMessage.contains('permission')) {
          return localizations.permission_denied;
        } else if (errorMessage.contains('invalid')) {
          return localizations.invalid_input;
        }

        // 默认返回原始错误消息
        return errorMessage;
      }

      return Center(
        child: Text(
          '${localizations.search_error}: ${getLocalizedErrorMessage(state.errorMessage)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
        ),
      );
    }

    return SongGridWidget(
      songs: state.searchResults,
      searchQuery: state.searchQuery,
      localizedNoSongsFound: localizations.search_no_results,
    );
  }
}

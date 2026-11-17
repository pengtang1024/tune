import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';

/// 音源页底部的入口卡。
///
/// 分享不是一级导航：它不进侧栏，只在这里给一条路，免得把一个还没成熟的
/// 局域网功能提到和「音乐库」「发现」一样的位置。
class ShareEntryCard extends StatelessWidget {
  const ShareEntryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(CompactTokens.radius12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_tethering, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.shareEntryTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  context.loc.shareEntryBody,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => context.push('/share'),
            child: Text(context.loc.shareTitle),
          ),
        ],
      ),
    );
  }
}

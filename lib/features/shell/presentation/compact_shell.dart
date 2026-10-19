import 'package:flutter/material.dart';
import 'package:tune/features/player/presentation/player_pane.dart';
import 'package:tune/features/shell/presentation/app_header.dart';
import 'package:tune/features/shell/presentation/pane_tabs.dart';

class CompactShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const CompactShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showTabs = currentPath == '/library' || currentPath == '/queue';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          AppHeader(currentPath: currentPath),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final leftWidth = (constraints.maxWidth * 0.38)
                    .clamp(300.0, 360.0)
                    .toDouble();

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: leftWidth, child: const PlayerPane()),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (showTabs) PaneTabs(currentPath: currentPath),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tune/features/player/presentation/player_dock.dart';
import 'package:tune/features/shell/presentation/app_sidebar.dart';

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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSidebar(currentPath: currentPath, compact: compact),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.9, -1.0),
                              radius: 1.2,
                              colors: [
                                theme.colorScheme.primary.withValues(
                                  alpha: 0.05,
                                ),
                                Colors.transparent,
                              ],
                              stops: const [0, 0.7],
                            ),
                          ),
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const PlayerDock(),
          ],
        ),
      ),
    );
  }
}

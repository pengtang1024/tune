import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';

class AppSidebar extends StatelessWidget {
  final String currentPath;
  final bool compact;

  const AppSidebar({
    super.key,
    required this.currentPath,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = compact ? 76.0 : 196.0;
    final short = MediaQuery.sizeOf(context).height < 560;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        right: false,
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 20,
            22,
            compact ? 12 : 16,
            16,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: compact
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      _Brand(compact: compact),
                      SizedBox(height: short ? 24 : 34),
                      _SectionLabel(
                        context.loc.sidebarCollect,
                        compact: compact,
                      ),
                      const SizedBox(height: 8),
                      _NavItem(
                        icon: Icons.library_music_rounded,
                        label: context.loc.navLibrary,
                        path: '/library',
                        currentPath: currentPath,
                        compact: compact,
                      ),
                      const SizedBox(height: 4),
                      _NavItem(
                        icon: Icons.queue_music_rounded,
                        label: context.loc.navQueue,
                        path: '/queue',
                        currentPath: currentPath,
                        compact: compact,
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        context.loc.sidebarConnect,
                        compact: compact,
                      ),
                      const SizedBox(height: 8),
                      _NavItem(
                        icon: Icons.podcasts_rounded,
                        label: context.loc.navSources,
                        path: '/sources',
                        currentPath: currentPath,
                        compact: compact,
                      ),
                      const Spacer(),
                      _NavItem(
                        icon: Icons.tune_rounded,
                        label: context.loc.navSettings,
                        path: '/settings',
                        currentPath: currentPath,
                        compact: compact,
                      ),
                      if (!compact && !short) ...[
                        const SizedBox(height: 18),
                        Text(
                          context.loc.sidebarLocalOnline,
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 8,
                            letterSpacing: 1.1,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          context.loc.sidebarVersionLine(
                            context.loc.appName,
                            AppVersion.version,
                          ),
                          style: TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontSize: 8,
                            letterSpacing: 0.8,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final bool compact;
  const _Brand({required this.compact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mark = Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        Icons.graphic_eq_rounded,
        size: 19,
        color: theme.colorScheme.onPrimary,
      ),
    );

    if (compact) return mark;

    return Row(
      children: [
        mark,
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            context.loc.appName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Fraunces',
              fontSize: 25,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool compact;
  const _SectionLabel(this.text, {required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: 20,
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'JetBrains Mono',
          fontSize: 8.5,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w500,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String path;
  final String currentPath;
  final bool compact;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.currentPath,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = currentPath == path;

    return Tooltip(
      message: compact ? label : '',
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: CompactTokens.fastMotion,
          height: 40,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: compact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (!compact) ...[
                const SizedBox(width: 11),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

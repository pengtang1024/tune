import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The rail on the left of the settings page.
class SettingsNavRail extends StatelessWidget {
  /// The sections the reader can go to, in order.
  final List<SettingsSection> sections;

  /// The section the page is showing.
  final SettingsSection selected;

  /// Whether the rail shows the labels beside the icons.
  final bool wide;

  final ValueChanged<SettingsSection> onSelected;

  const SettingsNavRail({
    super.key,
    required this.sections,
    required this.selected,
    required this.wide,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: wide ? 176 : 56,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.space8,
          CompactTokens.space12,
          CompactTokens.space8,
          CompactTokens.space12,
        ),
        children: [
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CompactTokens.space8),
              child: Text(
                context.loc.settingsSearchNoMatch,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final section in sections) ...[
            _tile(context, section),
            const SizedBox(height: CompactTokens.space4),
          ],
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, SettingsSection section) {
    final theme = Theme.of(context);
    final isSelected = selected == section;
    final tile = Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: CompactTokens.borderRadius8,
      child: InkWell(
        key: ValueKey('settings-nav-${section.name}'),
        onTap: () => onSelected(section),
        borderRadius: CompactTokens.borderRadius8,
        child: Container(
          height: 36,
          padding: EdgeInsets.symmetric(
            horizontal: wide ? CompactTokens.space8 : 0,
          ),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 2,
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: wide
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                settingsSectionIcon(section),
                size: CompactTokens.icon18,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (wide) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  child: Text(
                    settingsSectionLabel(context, section),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected ? theme.colorScheme.primary : null,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (wide) return tile;
    return TuneTooltip(
      message: settingsSectionLabel(context, section),
      child: tile,
    );
  }
}

/// The switch that replaces the rail on a phone: one row of chips that walks
/// sideways.
///
/// 左边那条 56 px 的图标栏是桌面窗口的窄态：它按「两侧都要有边」的桌面布局
/// 摆，在手机上就把正文挤到 342 px。手机里同一件事只需要一行横着走的 chip——
/// 换的还是「这一页看哪一组设置」，但正文拿回整条宽度。
class SettingsNavStrip extends StatelessWidget {
  /// The sections the reader can go to, in order.
  final List<SettingsSection> sections;

  /// The section the page is showing.
  final SettingsSection selected;

  final ValueChanged<SettingsSection> onSelected;

  /// Chips the page highlights as it scrolls, so the row follows the body.
  ///
  /// 正文滚到哪一组，这一行就把它推到看得见的位置——否则高亮跑出视野，
  /// 读的人会以为哪一档都没选中。
  final ScrollController? controller;

  /// The key of each chip, so the page can walk one of them into sight.
  final Map<SettingsSection, GlobalKey>? itemKeys;

  const SettingsNavStrip({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelected,
    this.controller,
    this.itemKeys,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          0,
          CompactTokens.pageGutter,
          CompactTokens.space8,
        ),
        child: Text(
          context.loc.settingsSearchNoMatch,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    // 用 ListView 而不是 SingleChildScrollView：设置页正文那个滚动视图是按
    // 类型找的，截图与滚动测试都按类型点它，这里再堆一个同名类型会撞车。
    // 横滑的 ListView 在 Column 里拿不到高度，得自己给一条。
    return SizedBox(
      height: CompactTokens.controlDefault + CompactTokens.space8,
      child: ListView(
        key: const ValueKey('settings-nav-strip'),
        controller: controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          CompactTokens.pageGutter,
          CompactTokens.space4,
          CompactTokens.pageGutter,
          CompactTokens.space4,
        ),
        children: [
          for (final section in sections)
            Padding(
              padding: const EdgeInsets.only(right: CompactTokens.space8),
              child: KeyedSubtree(
                key: itemKeys?[section],
                child: _chip(context, section),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, SettingsSection section) {
    final theme = Theme.of(context);
    final isSelected = selected == section;
    return Material(
      color: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : theme.colorScheme.surfaceContainer,
      borderRadius: CompactTokens.borderRadius8,
      child: InkWell(
        key: ValueKey('settings-nav-${section.name}'),
        onTap: () => onSelected(section),
        borderRadius: CompactTokens.borderRadius8,
        child: Container(
          height: CompactTokens.controlDefault,
          padding: const EdgeInsets.symmetric(
            horizontal: CompactTokens.space12,
          ),
          decoration: BoxDecoration(
            borderRadius: CompactTokens.borderRadius8,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.40)
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                settingsSectionIcon(section),
                size: CompactTokens.icon16,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: CompactTokens.space8),
              Text(
                settingsSectionLabel(context, section),
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? theme.colorScheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

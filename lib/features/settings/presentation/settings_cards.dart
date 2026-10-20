import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/core/l10n/locale_labels.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/shared/ui/compact_spinner.dart';

class SettingsPageHeader extends StatelessWidget {
  final String version;

  const SettingsPageHeader({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.loc.settingsEyebrow,
                style: CompactTypography.mono(
                  theme.colorScheme.primary,
                  size: CompactTypeScale.mark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.loc.settingsTitle,
                style: CompactTypography.asDisplay(
                  theme.textTheme.displayMedium,
                  size: CompactTypeScale.displayLarge,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.loc.settingsSubtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'v$version',
                style: CompactTypography.mono(
                  theme.colorScheme.onSurfaceVariant,
                  size: CompactTypeScale.mark,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsInterfaceCard extends StatelessWidget {
  final ThemeMode themeMode;
  final Locale locale;
  final ValueChanged<ThemeMode> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;

  const SettingsInterfaceCard({
    super.key,
    required this.themeMode,
    required this.locale,
    required this.onThemeChanged,
    required this.onLocaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCard(
      index: '01',
      eyebrow: context.loc.settingsSectionInterface,
      title: context.loc.theme,
      description: context.loc.settingsThemeDescription,
      child: Column(
        children: [
          Row(
            children: [
              for (final mode in ThemeMode.values) ...[
                Expanded(
                  child: _ThemePreview(
                    mode: mode,
                    label: switch (mode) {
                      ThemeMode.system => context.loc.systemMode,
                      ThemeMode.light => context.loc.lightMode,
                      ThemeMode.dark => context.loc.darkMode,
                    },
                    selected: themeMode == mode,
                    onTap: () => onThemeChanged(mode),
                  ),
                ),
                if (mode != ThemeMode.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.translate_rounded,
                size: CompactTokens.icon18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.loc.language,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.loc.settingsLanguageDescription,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _LanguageDropdown(locale: locale, onChanged: onLocaleChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsLibraryCard extends StatelessWidget {
  final SettingsState settings;
  final bool scanning;
  final bool canScan;
  final VoidCallback onAddFolder;
  final ValueChanged<String> onRemoveFolder;
  final VoidCallback onScan;
  final VoidCallback? onClear;

  const SettingsLibraryCard({
    super.key,
    required this.settings,
    required this.scanning,
    required this.canScan,
    required this.onAddFolder,
    required this.onRemoveFolder,
    required this.onScan,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pathCount =
        settings.defaultScanPaths.length + settings.customScanPaths.length;

    return SettingsCard(
      index: '02',
      // The eyebrow names the section, the title names the card.
      eyebrow: context.loc.libraryEyebrow,
      title: context.loc.libraryTitle,
      description: context.loc.settingsLibraryDescription,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          context.loc.settingsPathsCount(pathCount),
          style: CompactTypography.mono(
            theme.colorScheme.onSurfaceVariant,
            size: CompactTypeScale.mark,
            letterSpacing: 0.6,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final path in settings.defaultScanPaths)
            _PathRow(path: path, label: context.loc.settingsDefaultPath),
          if (settings.defaultScanPaths.isEmpty)
            _EmptyPath(
              icon: Icons.folder_off_outlined,
              text: context.loc.settingsNoDefaultFolder,
            ),
          if (settings.customScanPaths.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final path in settings.customScanPaths)
              _PathRow(
                path: path,
                label: context.loc.settingsCustomPath,
                onRemove: () => onRemoveFolder(path),
              ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: onAddFolder,
                icon: const Icon(Icons.create_new_folder_outlined, size: CompactTokens.icon16),
                label: Text(context.loc.settingsAddFolder),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                ),
              ),
              OutlinedButton.icon(
                onPressed: canScan ? onScan : null,
                icon: scanning
                    ? const CompactSpinner.small()
                    : const Icon(Icons.refresh_rounded, size: CompactTokens.icon16),
                label: Text(
                  scanning ? context.loc.scanning : context.loc.scanNow,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                ),
              ),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.delete_sweep_outlined, size: CompactTokens.icon16),
                label: Text(context.loc.settingsClearLibrary),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, CompactTokens.controlDefault),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: CompactTokens.icon14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  context.loc.settingsScanSafetyNote,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsAboutCard extends StatelessWidget {
  final String version;

  const SettingsAboutCard({super.key, required this.version});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SettingsCard(
      index: '04',
      eyebrow: context.loc.about,
      title: context.loc.appName,
      description: context.loc.appTagline,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              size: CompactTokens.icon28,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              'v$version',
              style: CompactTypography.mono(
                theme.colorScheme.onSurfaceVariant,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              context.loc.settingsLocalFirst,
              style: CompactTypography.mono(
                theme.colorScheme.primary,
                size: CompactTypeScale.mark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  final ThemeMode mode;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreview({
    required this.mode,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 108,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary.withValues(alpha: 0.07)
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _MiniPreview(mode: mode)),
              const SizedBox(height: 7),
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: CompactTypeScale.mark,
                            color: theme.colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: selected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPreview extends StatelessWidget {
  final ThemeMode mode;

  const _MiniPreview({required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == ThemeMode.system) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(child: _MiniCanvas(dark: false)),
            Container(width: 1, color: const Color(0xFF6B6256)),
            Expanded(child: _MiniCanvas(dark: true)),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: _MiniCanvas(dark: mode == ThemeMode.dark),
    );
  }
}

class _MiniCanvas extends StatelessWidget {
  final bool dark;

  const _MiniCanvas({required this.dark});

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF11100E) : const Color(0xFFF1ECE2);
    final panel = dark ? const Color(0xFF211E19) : const Color(0xFFFBF7F0);
    final border = dark ? const Color(0xFF3A342C) : const Color(0xFFD9D0C2);
    final line = dark ? const Color(0xFF514A40) : const Color(0xFFC8BDAD);
    final accent = dark ? const Color(0xFFFF6B48) : const Color(0xFFE6532F);

    return Container(
      color: background,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 20,
                  color: panel,
                  child: Column(
                    children: [
                      // The picture of a window keeps its shape, but the
                      // gaps in it give way when the room is short: the
                      // desktop raises the text scale, the label of the
                      // preview grows, and the picture has less height.
                      const Flexible(child: SizedBox(height: 5)),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Flexible(child: SizedBox(height: 7)),
                      for (var i = 0; i < 3; i++) ...[
                        Container(
                          width: 9,
                          height: 2,
                          decoration: BoxDecoration(
                            color: i == 0 ? accent : line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Flexible(child: SizedBox(height: 4)),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Flexible(child: SizedBox(height: 5)),
                        for (var i = 0; i < 2; i++) ...[
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: panel,
                              borderRadius: BorderRadius.circular(2),
                              border: Border.all(color: border, width: 0.5),
                            ),
                          ),
                          const Flexible(child: SizedBox(height: 3)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 12,
            margin: const EdgeInsets.fromLTRB(5, 0, 5, 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: panel,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 2,
                    color: line,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                ),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: line,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  final Locale locale;
  final ValueChanged<Locale> onChanged;

  const _LanguageDropdown({required this.locale, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locales = offerableLocales();

    return Container(
      width: 150,
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Locale>(
          value: _selected(locales),
          isDense: true,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more_rounded,
            size: CompactTokens.icon16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          menuMaxHeight: 250,
          items: locales
              .map(
                (item) => DropdownMenuItem<Locale>(
                  value: item,
                  child: Text(localeEndonym(item)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }

  /// The entry that shows the locale of the app.
  ///
  /// A locale outside of the catalogue falls back to the first entry of its
  /// language, so the dropdown always shows where the app stands.
  Locale? _selected(List<Locale> locales) {
    for (final item in locales) {
      if (item == locale) return item;
    }
    for (final item in locales) {
      if (item.languageCode == locale.languageCode) return item;
    }
    return null;
  }
}

class _PathRow extends StatelessWidget {
  final String path;
  final String label;
  final VoidCallback? onRemove;

  const _PathRow({required this.path, required this.label, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDefault = label == context.loc.settingsDefaultPath;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 6, 5, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder_outlined,
            size: CompactTokens.icon16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              path,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CompactTypography.mono(
                theme.colorScheme.onSurface,
                size: CompactTypeScale.mark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: isDefault
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              label,
              style: CompactTypography.mono(
                isDefault
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: CompactTypeScale.mark,
                letterSpacing: 0.3,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 3),
            SizedBox(
              width: 26,
              height: 26,
              child: IconButton(
                tooltip: context.loc.remove,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: CompactTokens.icon14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
                style: IconButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyPath extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyPath({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: CompactTokens.icon16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

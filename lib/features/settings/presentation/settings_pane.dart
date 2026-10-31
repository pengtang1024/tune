import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/app/theme/compact_type_scale.dart';
import 'package:tune/app/theme/compact_typography.dart';
import 'package:tune/config/app_version.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/data/services/desktop/audio_mime_types.dart';
import 'package:tune/data/services/providers/desktop_service_providers.dart';
import 'package:tune/features/library/application/library_cache_limit_provider.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/settings/presentation/settings_card_shell.dart';
import 'package:tune/features/settings/presentation/settings_cards.dart';
import 'package:tune/features/settings/presentation/settings_desktop_card.dart';
import 'package:tune/features/settings/presentation/settings_discovery_card.dart';
import 'package:tune/features/settings/presentation/settings_playback_card.dart';
import 'package:tune/features/settings/presentation/settings_source_health_card.dart';
import 'package:tune/features/settings/presentation/settings_update_card.dart';
import 'package:tune/features/smart_lyrics/domain/smart_lyrics_config.dart';
import 'package:tune/features/smart_lyrics/presentation/settings_smart_lyrics_card.dart';
import 'package:tune/shared/ui/tune_tooltip.dart';

/// The sections of the settings page.
enum _SettingsSection {
  overview,
  appearance,
  library,
  playback,
  lyrics,
  discovery,
  desktop,
  sourceHealth,
  about,
}

class SettingsPane extends ConsumerStatefulWidget {
  const SettingsPane({super.key});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane> {
  var _section = _SettingsSection.overview;
  final _search = TextEditingController();
  var _query = '';

  bool? _isDefaultPlayer;
  bool _desktopEntryInstalled = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDefaultPlayerState();
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.isLoading ?? false,
        ),
      ),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _nav(context, wide, settings),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, controller),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    CompactTokens.pageGutter,
                    CompactTokens.space8,
                    CompactTokens.pageGutter,
                    CompactTokens.pageGutter,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _body(
                        context,
                        settings,
                        controller,
                        libraryReady: library.$1,
                        scanning: library.$2,
                        clearing: library.$3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Navigation

  static const _sections = _SettingsSection.values;

  Widget _nav(BuildContext context, bool wide, SettingsState settings) {
    final theme = Theme.of(context);
    final items = _sections.where((section) => _matches(section)).toList();
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
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(CompactTokens.space8),
              child: Text(
                context.loc.settingsSearchNoMatch,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (final section in items) ...[
            _navTile(context, section, wide),
            const SizedBox(height: CompactTokens.space4),
          ],
        ],
      ),
    );
  }

  Widget _navTile(BuildContext context, _SettingsSection section, bool wide) {
    final theme = Theme.of(context);
    final selected = _section == section;
    final tile = Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: CompactTokens.borderRadius8,
      child: InkWell(
        key: ValueKey('settings-nav-${section.name}'),
        onTap: () => setState(() => _section = section),
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
                color: selected ? theme.colorScheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: wide
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                _iconOf(section),
                size: CompactTokens.icon18,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              if (wide) ...[
                const SizedBox(width: CompactTokens.space8),
                Expanded(
                  child: Text(
                    _labelOf(context, section),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? theme.colorScheme.primary : null,
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
    return TuneTooltip(message: _labelOf(context, section), child: tile);
  }

  // ---------------------------------------------------------------------
  // Header

  Widget _header(BuildContext context, SettingsController controller) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CompactTokens.pageGutter,
        CompactTokens.space12,
        CompactTokens.pageGutter,
        CompactTokens.space4,
      ),
      child: Row(
        children: [
          Text(
            context.loc.settingsTitle,
            style: CompactTypography.asDisplay(
              theme.textTheme.displayMedium,
              size: CompactTypeScale.displayMedium,
              height: 0.95,
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          Text(
            'v${AppVersion.version}',
            style: CompactTypography.mono(
              theme.colorScheme.onSurfaceVariant,
              size: CompactTypeScale.mark,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: wide ? 220 : 150,
            child: TextField(
              controller: _search,
              onChanged: _onSearchChanged,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainer,
                hintText: context.loc.settingsSearchHint,
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: CompactTokens.icon16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 30,
                  minHeight: 30,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          _onSearchChanged('');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: CompactTokens.icon14,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 26,
                          height: 26,
                        ),
                      ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: CompactTokens.space8,
                  vertical: CompactTokens.space8,
                ),
                border: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: CompactTokens.borderRadius8,
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: CompactTokens.space8),
          TuneTooltip(
            message: context.loc.libraryMoreActions,
            child: PopupMenuButton<String>(
              key: const ValueKey('settings-more'),
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                if (value == 'resetSection') _confirmReset(all: false);
                if (value == 'resetAll') _confirmReset(all: true);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'resetSection',
                  enabled: _section != _SettingsSection.overview,
                  child: Text(context.loc.settingsResetSection),
                ),
                PopupMenuItem(
                  value: 'resetAll',
                  child: Text(context.loc.settingsResetAll),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) return;
      if (_matches(_section)) return;
      final first = _sections.where(_matches).firstOrNull;
      if (first != null) _section = first;
    });
  }

  bool _matches(_SettingsSection section) {
    if (_query.isEmpty) return true;
    final text =
        '${_labelOf(context, section)} ${_descriptionOf(context, section)} '
        '${_keywordsOf(context, section)}'
            .toLowerCase();
    return text.contains(_query);
  }

  // ---------------------------------------------------------------------
  // Body

  Widget _body(
    BuildContext context,
    SettingsState settings,
    SettingsController controller, {
    required bool libraryReady,
    required bool scanning,
    required bool clearing,
  }) {
    if (_section == _SettingsSection.overview) {
      return _overview(context, settings);
    }
    if (_section == _SettingsSection.sourceHealth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context),
          const SizedBox(height: CompactTokens.space12),
          const SettingsSourceHealthCard(),
        ],
      );
    }
    if (_section == _SettingsSection.about) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeading(context),
          const SizedBox(height: CompactTokens.space12),
          SettingsAboutCard(version: AppVersion.version),
          if (!kIsWeb) ...[
            const SizedBox(height: CompactTokens.space12),
            const SettingsUpdateCard(),
          ],
        ],
      );
    }
    final presets = _presets(settings, controller);
    final selected = _selectedPreset(settings);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(context),
        const SizedBox(height: CompactTokens.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 700
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: CompactTokens.space12,
              runSpacing: CompactTokens.space12,
              children: [
                for (final preset in presets)
                  SizedBox(
                    width: width,
                    child: _PresetCard(
                      preset: preset,
                      selected: preset.id == selected,
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: CompactTokens.space12),
        Row(
          children: [
            OutlinedButton.icon(
              key: const ValueKey('settings-customize'),
              onPressed: () => _openCustom(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, CompactTokens.controlDefault),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              icon: const Icon(
                Icons.tune_rounded,
                size: CompactTokens.icon16,
              ),
              label: Text(context.loc.settingsCustomize),
            ),
            const SizedBox(width: CompactTokens.space8),
            ..._quickActions(
              context,
              controller,
              libraryReady: libraryReady,
              scanning: scanning,
              clearing: clearing,
            ),
          ],
        ),
      ],
    );
  }

  Widget _overview(BuildContext context, SettingsState settings) {
    final sections = [
      _SettingsSection.appearance,
      _SettingsSection.library,
      _SettingsSection.playback,
      _SettingsSection.lyrics,
      _SettingsSection.discovery,
      _SettingsSection.desktop,
      _SettingsSection.sourceHealth,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeading(context),
        const SizedBox(height: CompactTokens.space12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth >= 700
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: CompactTokens.space12,
              runSpacing: CompactTokens.space12,
              children: [
                for (final section in sections)
                  SizedBox(
                    width: width,
                    child: _OverviewCard(
                      section: section,
                      label: _labelOf(context, section),
                      description: _descriptionOf(context, section),
                      status: _presetLabel(context, _selectedPreset(settings)),
                      onTap: () => setState(() => _section = section),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _sectionHeading(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _labelOf(context, _section),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: CompactTokens.space4),
        Text(
          _descriptionOf(context, _section),
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Presets

  List<_Preset> _presets(SettingsState settings, SettingsController controller) {
    switch (_section) {
      case _SettingsSection.appearance:
        return [
          _Preset(
            id: ThemeMode.system.name,
            title: context.loc.systemMode,
            description: context.loc.settingsThemeDescription,
            icon: Icons.brightness_auto_rounded,
            apply: () => controller.setThemeMode(ThemeMode.system),
          ),
          _Preset(
            id: ThemeMode.light.name,
            title: context.loc.lightMode,
            description: context.loc.settingsThemeDescription,
            icon: Icons.light_mode_rounded,
            apply: () => controller.setThemeMode(ThemeMode.light),
          ),
          _Preset(
            id: ThemeMode.dark.name,
            title: context.loc.darkMode,
            description: context.loc.settingsThemeDescription,
            icon: Icons.dark_mode_rounded,
            apply: () => controller.setThemeMode(ThemeMode.dark),
          ),
        ];
      case _SettingsSection.library:
        return [
          _Preset(
            id: 'auto',
            title: context.loc.settingsPresetAutoScan,
            description: context.loc.settingsPresetAutoScanHint,
            icon: Icons.autorenew_rounded,
            apply: () => controller.setAutoScanOnStartup(true),
          ),
          _Preset(
            id: 'manual',
            title: context.loc.settingsPresetManualScan,
            description: context.loc.settingsPresetManualScanHint,
            icon: Icons.touch_app_rounded,
            apply: () => controller.setAutoScanOnStartup(false),
          ),
        ];
      case _SettingsSection.playback:
        return [
          _Preset(
            id: 'queue',
            title: context.loc.settingsPresetQueueFirst,
            description: context.loc.settingsPresetQueueFirstHint,
            icon: Icons.queue_music_rounded,
            apply: () => _applyPlayback(
              controller,
              replaceQueue: false,
              favoritesDoubleClick: true,
              onlyLike: false,
            ),
          ),
          _Preset(
            id: 'single',
            title: context.loc.settingsPresetSingleFirst,
            description: context.loc.settingsPresetSingleFirstHint,
            icon: Icons.play_circle_outline_rounded,
            apply: () => _applyPlayback(
              controller,
              replaceQueue: true,
              favoritesDoubleClick: true,
              onlyLike: false,
            ),
          ),
          _Preset(
            id: 'favorite',
            title: context.loc.settingsPresetFavoriteFirst,
            description: context.loc.settingsPresetFavoriteFirstHint,
            icon: Icons.favorite_border_rounded,
            apply: () => _applyPlayback(
              controller,
              replaceQueue: false,
              favoritesDoubleClick: false,
              onlyLike: true,
            ),
          ),
        ];
      case _SettingsSection.lyrics:
        return [
          _Preset(
            id: 'manual',
            title: context.loc.settingsPresetLyricsManual,
            description: context.loc.settingsPresetLyricsManualHint,
            icon: Icons.edit_off_rounded,
            apply: () => _applyLyrics(
              settings,
              controller,
              autoFill: false,
              gapCheck: false,
            ),
          ),
          _Preset(
            id: 'balanced',
            title: context.loc.settingsPresetLyricsBalanced,
            description: context.loc.settingsPresetLyricsBalancedHint,
            icon: Icons.balance_rounded,
            apply: () => _applyLyrics(
              settings,
              controller,
              autoFill: true,
              gapCheck: true,
            ),
          ),
          _Preset(
            id: 'saver',
            title: context.loc.settingsPresetLyricsSaver,
            description: context.loc.settingsPresetLyricsSaverHint,
            icon: Icons.battery_saver_rounded,
            apply: () => _applyLyrics(
              settings,
              controller,
              autoFill: true,
              gapCheck: false,
            ),
          ),
        ];
      case _SettingsSection.discovery:
        return [
          _Preset(
            id: 'on',
            title: context.loc.settingsPresetLearnOn,
            description: context.loc.settingsPresetLearnOnHint,
            icon: Icons.auto_awesome_rounded,
            apply: () => controller.setUseListeningHistory(true),
          ),
          _Preset(
            id: 'off',
            title: context.loc.settingsPresetLearnOff,
            description: context.loc.settingsPresetLearnOffHint,
            icon: Icons.shield_outlined,
            apply: () => controller.setUseListeningHistory(false),
          ),
        ];
      case _SettingsSection.desktop:
        return [
          _Preset(
            id: 'tray',
            title: context.loc.settingsPresetTray,
            description: context.loc.settingsPresetTrayHint,
            icon: Icons.minimize_rounded,
            apply: () => controller.setCloseToTray(true),
          ),
          _Preset(
            id: 'quit',
            title: context.loc.settingsPresetQuit,
            description: context.loc.settingsPresetQuitHint,
            icon: Icons.power_settings_new_rounded,
            apply: () => controller.setCloseToTray(false),
          ),
        ];
      case _SettingsSection.overview:
      case _SettingsSection.sourceHealth:
      case _SettingsSection.about:
        return const [];
    }
  }

  String _selectedPreset(SettingsState settings) {
    switch (_section) {
      case _SettingsSection.appearance:
        return settings.themeMode.name;
      case _SettingsSection.library:
        return settings.autoScanOnStartup ? 'auto' : 'manual';
      case _SettingsSection.playback:
        if (!settings.autoResumeOnStartup) return 'custom';
        if (settings.replaceQueueOnClick &&
            settings.favoritesDoubleClickPlays &&
            !settings.onlyLikeOnDoubleClick) {
          return 'single';
        }
        if (!settings.replaceQueueOnClick &&
            settings.favoritesDoubleClickPlays &&
            !settings.onlyLikeOnDoubleClick) {
          return 'queue';
        }
        if (!settings.replaceQueueOnClick &&
            !settings.favoritesDoubleClickPlays &&
            settings.onlyLikeOnDoubleClick) {
          return 'favorite';
        }
        return 'custom';
      case _SettingsSection.lyrics:
        final config = settings.smartLyrics;
        if (!config.autoFill && !config.gapCheckEnabled) return 'manual';
        if (config.autoFill && config.gapCheckEnabled) return 'balanced';
        if (config.autoFill && !config.gapCheckEnabled) return 'saver';
        return 'custom';
      case _SettingsSection.discovery:
        return settings.useListeningHistory ? 'on' : 'off';
      case _SettingsSection.desktop:
        return settings.closeToTray ? 'tray' : 'quit';
      case _SettingsSection.overview:
      case _SettingsSection.sourceHealth:
      case _SettingsSection.about:
        return 'custom';
    }
  }

  String _presetLabel(BuildContext context, String id) => switch (id) {
    'system' => context.loc.systemMode,
    'light' => context.loc.lightMode,
    'dark' => context.loc.darkMode,
    'auto' => context.loc.settingsPresetAutoScan,
    'manual' => context.loc.settingsPresetManualScan,
    'queue' => context.loc.settingsPresetQueueFirst,
    'single' => context.loc.settingsPresetSingleFirst,
    'favorite' => context.loc.settingsPresetFavoriteFirst,
    'balanced' => context.loc.settingsPresetLyricsBalanced,
    'saver' => context.loc.settingsPresetLyricsSaver,
    'on' => context.loc.settingsPresetLearnOn,
    'off' => context.loc.settingsPresetLearnOff,
    'tray' => context.loc.settingsPresetTray,
    'quit' => context.loc.settingsPresetQuit,
    _ => context.loc.settingsCustomize,
  };

  void _applyPlayback(
    SettingsController controller, {
    required bool replaceQueue,
    required bool favoritesDoubleClick,
    required bool onlyLike,
  }) {
    controller.setReplaceQueueOnClick(replaceQueue);
    controller.setFavoritesDoubleClickPlays(favoritesDoubleClick);
    controller.setOnlyLikeOnDoubleClick(onlyLike);
    controller.setAutoResumeOnStartup(true);
  }

  void _applyLyrics(
    SettingsState settings,
    SettingsController controller, {
    required bool autoFill,
    required bool gapCheck,
  }) {
    controller.setSmartLyrics(
      settings.smartLyrics.copyWith(
        autoFill: autoFill,
        gapCheckEnabled: gapCheck,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Custom sheet and quick actions

  List<Widget> _quickActions(
    BuildContext context,
    SettingsController controller, {
    required bool libraryReady,
    required bool scanning,
    required bool clearing,
  }) {
    switch (_section) {
      case _SettingsSection.library:
        return [
          OutlinedButton.icon(
            onPressed: libraryReady && !scanning && !clearing ? _scan : null,
            style: _actionStyle(context),
            icon: const Icon(Icons.refresh_rounded, size: CompactTokens.icon16),
            label: Text(context.loc.libraryScanAllSources),
          ),
          const SizedBox(width: CompactTokens.space8),
          OutlinedButton.icon(
            onPressed: _pickDirectory,
            style: _actionStyle(context),
            icon: const Icon(
              Icons.create_new_folder_outlined,
              size: CompactTokens.icon16,
            ),
            label: Text(context.loc.settingsAddFolder),
          ),
        ];
      case _SettingsSection.desktop:
        if (!_canSetDefaultPlayer) return const [];
        return [
          OutlinedButton.icon(
            onPressed: _isDefaultPlayer == true ? null : _setDefaultPlayer,
            style: _actionStyle(context),
            icon: const Icon(
              Icons.audiotrack_rounded,
              size: CompactTokens.icon16,
            ),
            label: Text(
              _isDefaultPlayer == true
                  ? context.loc.settingsDefaultPlayerActive
                  : context.loc.settingsSetDefaultPlayer,
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  ButtonStyle _actionStyle(BuildContext context) => OutlinedButton.styleFrom(
    minimumSize: const Size(0, CompactTokens.controlDefault),
    side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
  );

  void _openCustom(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        alignment: Alignment.centerRight,
        insetPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: math.min(640, width),
          height: MediaQuery.sizeOf(context).height,
          child: Material(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    CompactTokens.space16,
                    CompactTokens.space12,
                    CompactTokens.space8,
                    CompactTokens.space8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _labelOf(context, _section),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TuneTooltip(
                        message: context.loc.cancel,
                        child: IconButton(
                          key: const ValueKey('settings-custom-close'),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(CompactTokens.space16),
                    child: SettingsSheetScope(
                      inSheet: true,
                      child: _customCard(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _customCard(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.valueOrNull?.isScanning ?? false,
          value.valueOrNull?.isLoading ?? false,
        ),
      ),
    );
    return switch (_section) {
      _SettingsSection.appearance => SettingsInterfaceCard(
        themeMode: settings.themeMode,
        locale: settings.locale,
        onThemeChanged: controller.setThemeMode,
        onLocaleChanged: controller.setLocale,
      ),
      _SettingsSection.library => SettingsLibraryCard(
        settings: settings,
        scanning: library.$2,
        canScan: library.$1 && !library.$2 && !library.$3,
        onAddFolder: _pickDirectory,
        onRemoveFolder: controller.removeScanPath,
        onScan: _scan,
        onClear: library.$1 && !library.$2 && !library.$3
            ? _clearLibrary
            : null,
        onChooseLibraryFolder: _pickLibraryFolder,
        onResetLibraryFolder: _resetLibraryFolder,
        cacheLimit: ref.watch(libraryCacheLimitProvider),
        onCacheLimitChanged: ref.read(libraryCacheLimitProvider.notifier).set,
      ),
      _SettingsSection.playback => SettingsPlaybackCard(
        autoResumeOnStartup: settings.autoResumeOnStartup,
        replaceQueueOnClick: settings.replaceQueueOnClick,
        onlyLikeOnDoubleClick: settings.onlyLikeOnDoubleClick,
        favoritesDoubleClickPlays: settings.favoritesDoubleClickPlays,
        onAutoResumeOnStartup: controller.setAutoResumeOnStartup,
        onReplaceQueueOnClick: controller.setReplaceQueueOnClick,
        onOnlyLikeOnDoubleClick: controller.setOnlyLikeOnDoubleClick,
        onFavoritesDoubleClickPlays:
            controller.setFavoritesDoubleClickPlays,
      ),
      _SettingsSection.lyrics => const SettingsSmartLyricsCard(),
      _SettingsSection.discovery => const SettingsDiscoveryCard(),
      _SettingsSection.desktop => SettingsDesktopCard(
        closeToTray: settings.closeToTray,
        mediaControlsEnabled: settings.mediaControlsEnabled,
        isDefaultPlayer: _isDefaultPlayer ?? false,
        desktopEntryInstalled: _desktopEntryInstalled,
        onCloseToTrayChanged: controller.setCloseToTray,
        onMediaControlsChanged: controller.setMediaControlsEnabled,
        onSetDefaultPlayer: _canSetDefaultPlayer ? _setDefaultPlayer : null,
      ),
      _SettingsSection.sourceHealth => const SettingsSourceHealthCard(),
      _SettingsSection.overview ||
      _SettingsSection.about => const SizedBox.shrink(),
    };
  }

  // ---------------------------------------------------------------------
  // Reset

  Future<void> _confirmReset({required bool all}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.settingsResetTitle),
        content: Text(
          all
              ? context.loc.settingsResetAllMessage
              : context.loc.settingsResetMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final controller = ref.read(settingsControllerProvider.notifier);
    if (all) {
      await _resetAll(controller);
    } else {
      await _resetSection(_section, controller);
    }
  }

  Future<void> _resetAll(SettingsController controller) async {
    for (final section in _sections) {
      await _resetSection(section, controller);
    }
  }

  Future<void> _resetSection(
    _SettingsSection section,
    SettingsController controller,
  ) async {
    switch (section) {
      case _SettingsSection.appearance:
        await controller.setThemeMode(ThemeMode.system);
        await controller.setLocale(const Locale('en'));
      case _SettingsSection.library:
        await controller.setAutoScanOnStartup(true);
      case _SettingsSection.playback:
        await controller.setReplaceQueueOnClick(false);
        await controller.setOnlyLikeOnDoubleClick(false);
        await controller.setFavoritesDoubleClickPlays(true);
        await controller.setAutoResumeOnStartup(true);
      case _SettingsSection.lyrics:
        await controller.setSmartLyrics(const SmartLyricsConfig());
      case _SettingsSection.discovery:
        await controller.setUseListeningHistory(false);
      case _SettingsSection.desktop:
        await controller.setCloseToTray(true);
        await controller.setMediaControlsEnabled(true);
      case _SettingsSection.overview:
      case _SettingsSection.sourceHealth:
      case _SettingsSection.about:
        break;
    }
  }

  // ---------------------------------------------------------------------
  // Labels and icons

  String _labelOf(BuildContext context, _SettingsSection section) =>
      switch (section) {
        _SettingsSection.overview => context.loc.settingsOverview,
        _SettingsSection.appearance => context.loc.settingsSectionInterface,
        _SettingsSection.library => context.loc.libraryTitle,
        _SettingsSection.playback => context.loc.settingsSectionPlayback,
        _SettingsSection.lyrics => context.loc.settingsSectionSmartLyrics,
        _SettingsSection.discovery => context.loc.settingsSectionDiscovery,
        _SettingsSection.desktop => context.loc.settingsSectionDesktop,
        _SettingsSection.sourceHealth => context.loc.sourcesTitle,
        _SettingsSection.about => context.loc.about,
      };

  String _descriptionOf(BuildContext context, _SettingsSection section) =>
      switch (section) {
        _SettingsSection.overview => context.loc.settingsSubtitle,
        _SettingsSection.appearance => context.loc.settingsThemeDescription,
        _SettingsSection.library => context.loc.settingsLibraryDescription,
        _SettingsSection.playback => context.loc.settingsPlaybackDescription,
        _SettingsSection.lyrics => context.loc.settingsSmartLyricsDescription,
        _SettingsSection.discovery => context.loc.settingsDiscoveryDescription,
        _SettingsSection.desktop => context.loc.settingsDesktopDescription,
        _SettingsSection.sourceHealth =>
          context.loc.settingsSourceHealthDescription,
        _SettingsSection.about => context.loc.appTagline,
      };

  String _keywordsOf(BuildContext context, _SettingsSection section) =>
      switch (section) {
        _SettingsSection.appearance =>
          context.loc.settingsSearchKeywordsAppearance,
        _SettingsSection.library => context.loc.settingsSearchKeywordsLibrary,
        _SettingsSection.playback =>
          context.loc.settingsSearchKeywordsPlayback,
        _SettingsSection.lyrics => context.loc.settingsSearchKeywordsLyrics,
        _SettingsSection.discovery =>
          context.loc.settingsSearchKeywordsDiscovery,
        _SettingsSection.desktop => context.loc.settingsSearchKeywordsDesktop,
        _SettingsSection.sourceHealth =>
          context.loc.settingsSearchKeywordsSourceHealth,
        _SettingsSection.overview || _SettingsSection.about => '',
      };

  IconData _iconOf(_SettingsSection section) => switch (section) {
    _SettingsSection.overview => Icons.dashboard_customize_rounded,
    _SettingsSection.appearance => Icons.palette_outlined,
    _SettingsSection.library => Icons.library_music_rounded,
    _SettingsSection.playback => Icons.play_circle_outline_rounded,
    _SettingsSection.lyrics => Icons.lyrics_outlined,
    _SettingsSection.discovery => Icons.explore_rounded,
    _SettingsSection.desktop => Icons.desktop_windows_outlined,
    _SettingsSection.sourceHealth => Icons.monitor_heart_outlined,
    _SettingsSection.about => Icons.info_outline_rounded,
  };

  // ---------------------------------------------------------------------
  // Existing actions of the page

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChooseFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).addScanPath(path);
    if (!mounted) return;
    _showMessage(context.loc.settingsFolderAdded);
  }

  Future<void> _pickLibraryFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: context.loc.settingsChangeLibraryFolder,
    );
    if (path == null || !mounted) return;

    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(path);
  }

  Future<void> _resetLibraryFolder() async {
    await ref.read(settingsControllerProvider.notifier).setLibraryFolder(null);
  }

  Future<void> _scan() async {
    final settings = ref.read(settingsControllerProvider);
    await ref
        .read(libraryControllerProvider.notifier)
        .scan(settings.effectiveScanPaths);
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    _showMessage(
      state?.errorMessage ??
          state?.statusMessage ??
          context.loc.settingsScanDone,
    );
  }

  Future<void> _clearLibrary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.loc.settingsClearLibraryTitle),
        content: Text(context.loc.settingsClearLibraryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.loc.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.loc.clear),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(libraryControllerProvider.notifier).clearLibrary();
    if (!mounted) return;
    final state = ref.read(libraryControllerProvider).valueOrNull;
    _showMessage(state?.errorMessage ?? context.loc.settingsLibraryCleared);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  bool get _canSetDefaultPlayer {
    return ref.read(defaultPlayerServiceProvider).isSupported;
  }

  Future<void> _loadDefaultPlayerState() async {
    final service = ref.read(defaultPlayerServiceProvider);
    if (!service.isSupported) return;

    final installed = await service.isDesktopEntryInstalled();
    if (!mounted) return;
    setState(() => _desktopEntryInstalled = installed);
    if (!installed) return;

    final isDefault = await service.isDefaultHandler('audio/mpeg');
    if (!mounted) return;
    setState(() => _isDefaultPlayer = isDefault);
  }

  Future<void> _setDefaultPlayer() async {
    final service = ref.read(defaultPlayerServiceProvider);

    final installed = await service.isDesktopEntryInstalled();
    if (!installed) {
      if (!mounted) return;
      _showMessage(context.loc.settingsDefaultPlayerFailed);
      return;
    }

    var succeeded = true;
    for (final mimeType in supportedAudioMimeTypes) {
      succeeded = await service.makeDefaultHandler(mimeType) && succeeded;
    }
    if (!mounted) return;

    setState(() => _isDefaultPlayer = succeeded);
    _showMessage(
      succeeded
          ? context.loc.settingsDefaultPlayerDone
          : context.loc.settingsDefaultPlayerFailed,
    );
  }
}

class _Preset {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback apply;

  const _Preset({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.apply,
  });
}

class _PresetCard extends StatelessWidget {
  final _Preset preset;
  final bool selected;

  const _PresetCard({required this.preset, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainer,
      borderRadius: CompactTokens.borderRadius12,
      child: InkWell(
        onTap: () => preset.apply(),
        borderRadius: CompactTokens.borderRadius12,
        child: Container(
          height: 84,
          padding: const EdgeInsets.all(CompactTokens.space12),
          decoration: BoxDecoration(
            borderRadius: CompactTokens.borderRadius12,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(
                preset.icon,
                size: CompactTokens.icon20,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: CompactTokens.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      preset.title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: selected ? theme.colorScheme.primary : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: CompactTokens.icon16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final _SettingsSection section;
  final String label;
  final String description;
  final String status;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.section,
    required this.label,
    required this.description,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: CompactTokens.borderRadius12,
      child: InkWell(
        onTap: onTap,
        borderRadius: CompactTokens.borderRadius12,
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(CompactTokens.space12),
          decoration: BoxDecoration(
            borderRadius: CompactTokens.borderRadius12,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                switch (section) {
                  _SettingsSection.appearance => Icons.palette_outlined,
                  _SettingsSection.library => Icons.library_music_rounded,
                  _SettingsSection.playback =>
                    Icons.play_circle_outline_rounded,
                  _SettingsSection.lyrics => Icons.lyrics_outlined,
                  _SettingsSection.discovery => Icons.explore_rounded,
                  _SettingsSection.desktop => Icons.desktop_windows_outlined,
                  _SettingsSection.sourceHealth => Icons.monitor_heart_outlined,
                  _ => Icons.tune_rounded,
                },
                size: CompactTokens.icon20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: CompactTokens.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: CompactTypography.mono(
                        theme.colorScheme.primary,
                        size: CompactTypeScale.mark,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: CompactTokens.icon16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

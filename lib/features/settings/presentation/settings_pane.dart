import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/app/layout/layout_metrics.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/core/config/app_capabilities.dart';
import 'package:tune/features/library/application/library_controller.dart';
import 'package:tune/features/settings/application/settings_controller.dart';
import 'package:tune/features/settings/domain/settings_state.dart';
import 'package:tune/features/settings/presentation/settings_about_section.dart';
import 'package:tune/features/settings/presentation/settings_customize_sheet.dart';
import 'package:tune/features/settings/presentation/settings_pane_actions.dart';
import 'package:tune/features/settings/presentation/settings_pane_body.dart';
import 'package:tune/features/settings/presentation/settings_pane_header.dart';
import 'package:tune/features/settings/presentation/settings_pane_nav.dart';
import 'package:tune/features/settings/presentation/settings_presets.dart';
import 'package:tune/features/settings/presentation/settings_quick_actions.dart';
import 'package:tune/features/settings/presentation/settings_scroll.dart';
import 'package:tune/features/settings/presentation/settings_section_card.dart';
import 'package:tune/features/settings/presentation/settings_section_catalog.dart';

class SettingsPane extends ConsumerStatefulWidget {
  /// The capabilities of the build being drawn.
  ///
  /// Tests pass a table of another platform; the app leaves it null and the
  /// page reads the build it runs in.
  final AppCapabilities? capabilities;

  const SettingsPane({super.key, this.capabilities});

  @override
  ConsumerState<SettingsPane> createState() => _SettingsPaneState();
}

class _SettingsPaneState extends ConsumerState<SettingsPane>
    with SettingsPaneActions<SettingsPane> {
  @override
  AppCapabilities get capabilities =>
      widget.capabilities ?? AppCapabilities.current;

  var _section = SettingsSection.overview;
  final _search = TextEditingController();
  var _query = '';

  @override
  bool? isDefaultPlayer;

  @override
  bool desktopEntryInstalled = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();

  /// The phone's section chips scroll sideways; these keep the chosen one in
  /// sight while the body scrolls.
  final ScrollController _navScrollController = ScrollController();
  final Map<SettingsSection, GlobalKey> _navKeys = {
    for (final section in SettingsSection.values) section: GlobalKey(),
  };

  /// Set while a nav click animates the page; the scroll spy must not
  /// fight the animation and land on a section it passes on the way.
  var _programmaticScroll = false;

  final Map<SettingsSection, GlobalKey> _sectionKeys = {
    for (final section in SettingsSection.values) section: GlobalKey(),
  };

  static const _sections = SettingsSection.values;

  @override
  void initState() {
    super.initState();
    loadDefaultPlayerState();
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.dispose();
    _navScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final library = ref.watch(
      libraryControllerProvider.select(
        (value) => (
          value.hasValue,
          value.value?.isScanning ?? false,
          value.value?.isLoading ?? false,
        ),
      ),
    );
    final controller = ref.read(settingsControllerProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final visible = _sections.where(_visible).toList();

    final header = SettingsPaneHeader(
      searchController: _search,
      query: _query,
      section: _section,
      onQueryChanged: _onSearchChanged,
      onResetSection: () => confirmReset(all: false, currentSection: _section),
      onResetAll: () => confirmReset(all: true, currentSection: _section),
    );
    final body = Expanded(
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _syncSectionWithScroll();
          }
          return false;
        },
        child: SingleChildScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            CompactTokens.pageGutter,
            CompactTokens.space8,
            CompactTokens.pageGutter,
            CompactTokens.pageGutter,
          ),
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 手机形态（页宽 < 600）：左边那条图标栏换成一排横着走的 chip，
        // 正文拿回整条宽度；桌面窗口再窄也还是左侧栏。
        final phone = constraints.maxWidth < LayoutBreakpoints.phoneMaxWidth;
        if (phone) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              SettingsNavStrip(
                sections: visible,
                selected: _section,
                onSelected: _goTo,
                controller: _navScrollController,
                itemKeys: _navKeys,
              ),
              body,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsNavRail(
              sections: visible,
              selected: _section,
              wide: wide,
              onSelected: _goTo,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [header, body],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _visible(SettingsSection section) =>
      settingsSectionSupported(section, capabilities) &&
      settingsSectionMatches(context, section, _query);

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) return;
      if (settingsSectionMatches(context, _section, _query)) return;
      final first = _sections
          .where((section) => settingsSectionMatches(context, section, _query))
          .firstOrNull;
      if (first != null) _section = first;
    });
  }

  Widget _body(
    BuildContext context,
    SettingsState settings,
    SettingsController controller, {
    required bool libraryReady,
    required bool scanning,
    required bool clearing,
  }) {
    final sections = [
      SettingsSection.appearance,
      SettingsSection.library,
      SettingsSection.playback,
      SettingsSection.lyrics,
      SettingsSection.localization,
      SettingsSection.components,
      SettingsSection.discovery,
      SettingsSection.desktop,
      SettingsSection.permissions,
      SettingsSection.sourceHealth,
      SettingsSection.about,
    ].where(_visible).toList();
    return SettingsSectionsBody(
      sections: sections,
      sectionKeys: _sectionKeys,
      cardBuilder: (section) => _sectionCard(
        context,
        section,
        settings,
        controller,
        libraryReady: libraryReady,
        scanning: scanning,
        clearing: clearing,
      ),
      about: _aboutCard(),
    );
  }

  void _goTo(SettingsSection section) {
    setState(() => _section = section);
    _revealSection(section);
    _programmaticScroll = true;
    final done = settingsScrollToSection(
      controller: _scrollController,
      sectionKeys: _sectionKeys,
      section: section,
    );
    if (done == null) {
      _programmaticScroll = false;
      return;
    }
    done.whenComplete(() {
      if (mounted) _programmaticScroll = false;
    });
  }

  /// Walks the phone's chip row to the section the body settled on.
  ///
  /// 这只是让高亮留在视野里：等这一帧画完再滚动，按的是新的宽度与位置。
  void _revealSection(SettingsSection section) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _navKeys[section]?.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
      );
    });
  }

  /// Makes the left rail follow the section under the top of the page.
  void _syncSectionWithScroll() {
    if (!mounted || _programmaticScroll || _query.isNotEmpty) return;
    final next = settingsSectionAtTop(
      controller: _scrollController,
      scrollViewKey: _scrollViewKey,
      sectionKeys: _sectionKeys,
      visible: _visible,
    );
    if (next != null && next != _section) {
      setState(() => _section = next);
      _revealSection(next);
    }
  }

  Widget _sectionCard(
    BuildContext context,
    SettingsSection section,
    SettingsState settings,
    SettingsController controller, {
    required bool libraryReady,
    required bool scanning,
    required bool clearing,
  }) {
    return SettingsSectionCard(
      section: section,
      presets: settingsPresetsFor(
        context: context,
        section: section,
        settings: settings,
        controller: controller,
      ),
      selectedPresetId: settingsSelectedPreset(section, settings),
      actions: settingsQuickActions(
        context,
        section,
        libraryReady: libraryReady,
        scanning: scanning,
        clearing: clearing,
        onScan: scan,
        onAddFolder: pickDirectory,
        canSetDefaultPlayer: canSetDefaultPlayer,
        isDefaultPlayer: isDefaultPlayer,
        onSetDefaultPlayer: setDefaultPlayer,
      ),
      onCustomize: () => section == SettingsSection.sourceHealth
          ? openHealthSheet(context)
          : _openCustom(context, section),
    );
  }

  Widget _aboutCard() =>
      SettingsAboutSection(autoUpdate: capabilities.autoUpdate);

  void _openCustom(BuildContext context, SettingsSection section) {
    showSettingsCustomizeSheet(
      context: context,
      section: section,
      child: SettingsCustomizeCard(
        section: section,
        capabilities: capabilities,
        isDefaultPlayer: isDefaultPlayer,
        desktopEntryInstalled: desktopEntryInstalled,
        onPickDirectory: pickDirectory,
        onScan: scan,
        onClear: clearLibrary,
        onChooseLibraryFolder: pickLibraryFolder,
        onResetLibraryFolder: resetLibraryFolder,
        onSetDefaultPlayer: canSetDefaultPlayer ? setDefaultPlayer : null,
      ),
    );
  }

  @override
  void showSettingsMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}

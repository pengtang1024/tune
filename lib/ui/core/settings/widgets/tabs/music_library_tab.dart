import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/persistence_providers.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:tune/ui/widgets/settings_item.dart';

class MusicLibraryTab extends ConsumerStatefulWidget {
  const MusicLibraryTab({super.key});

  @override
  ConsumerState<MusicLibraryTab> createState() => _MusicLibraryTabState();
}

class _MusicLibraryTabState extends ConsumerState<MusicLibraryTab> {
  List<String> _customScanPaths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    setState(() {
      _customScanPaths = persistenceService.getStringList('custom_scan_paths') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final persistenceService = ref.read(sharedPreferencesServiceProvider);
    if (value is List<String>) {
      await persistenceService.setStringList(key, value);
    }
  }

  Future<void> _addCustomScanPath() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      setState(() {
        if (!_customScanPaths.contains(result)) {
          _customScanPaths.add(result);
          _saveSetting('custom_scan_paths', _customScanPaths);
        }
      });
    }
  }

  void _removeCustomScanPath(int index) {
    setState(() {
      _customScanPaths.removeAt(index);
      _saveSetting('custom_scan_paths', _customScanPaths);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sharedPreferencesServiceProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.music_library_management,
            style: AppDesignSystem.textTheme.headlineSmall?.copyWith(
              fontWeight: AppDesignSystem.fontWeightBold,
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing24),

          // 自定义扫描路径
          _CustomPathsSection(
            paths: _customScanPaths,
            onAddPath: _addCustomScanPath,
            onRemovePath: _removeCustomScanPath,
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 说明区域
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.scan_instructions,
                  style: AppDesignSystem.textTheme.titleMedium?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                _InstructionItem(text: context.loc.auto_extract_metadata),
                const SizedBox(height: AppDesignSystem.spacing8),
                _InstructionItem(text: context.loc.add_custom_paths),
                const SizedBox(height: AppDesignSystem.spacing8),
                _InstructionItem(text: context.loc.scan_completion),
                const SizedBox(height: AppDesignSystem.spacing8),
                _InstructionItem(text: context.loc.auto_metadata_extraction),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing16),

          // 常见问题
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.faq,
                  style: AppDesignSystem.textTheme.titleMedium?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                _FaqItem(
                  question: context.loc.faq_scan_issue,
                  answer: context.loc.faq_scan_issue_answer,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FaqItem(
                  question: context.loc.faq_slow_scan,
                  answer: context.loc.faq_slow_scan_answer,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FaqItem(
                  question: context.loc.faq_not_showing,
                  answer: context.loc.faq_not_showing_answer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomPathsSection extends StatelessWidget {
  final List<String> paths;
  final VoidCallback onAddPath;
  final ValueChanged<int> onRemovePath;

  const _CustomPathsSection({
    required this.paths,
    required this.onAddPath,
    required this.onRemovePath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsItem(
          icon: Icons.folder_open,
          title: context.loc.custom_scan_paths,
          subtitle: context.loc.add_custom_directory,
          iconColor: AppDesignSystem.primary,
          trailing: IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppDesignSystem.primary,
            onPressed: onAddPath,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing12),
        if (paths.isEmpty)
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing24),
            child: Center(
              child: Text(
                context.loc.no_custom_scan_paths,
                style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                  color: AppDesignSystem.neutral500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...paths.asMap().entries.map((entry) {
            final index = entry.key;
            final path = entry.value;
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppDesignSystem.spacing8,
              ),
              child: ModernCard(
                padding: const EdgeInsets.all(AppDesignSystem.spacing16),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      color: AppDesignSystem.neutral500,
                      size: AppDesignSystem.iconSize24,
                    ),
                    const SizedBox(width: AppDesignSystem.spacing12),
                    Expanded(
                      child: Text(
                        path,
                        style: AppDesignSystem.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppDesignSystem.error,
                      onPressed: () => onRemovePath(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppDesignSystem.spacing8),
        Padding(
          padding: EdgeInsets.only(left: AppDesignSystem.spacing56),
          child: Text(
            context.loc.full_platform_scan_note,
            style: AppDesignSystem.textTheme.bodySmall?.copyWith(
              color: AppDesignSystem.warning,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String text;

  const _InstructionItem({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppDesignSystem.success,
          size: AppDesignSystem.iconSize20,
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Text(
            text,
            style: AppDesignSystem.textTheme.bodySmall?.copyWith(
              color: isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral600,
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: AppDesignSystem.textTheme.titleSmall?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing4),
        Text(
          answer,
          style: AppDesignSystem.textTheme.bodySmall?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
        ),
      ],
    );
  }
}

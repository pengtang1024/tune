import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/providers/persistence_providers.dart';

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
    setState(() {
      _isLoading = true;
    });

    // 使用全局的sharedPreferencesServiceProvider
    final persistenceService = ref.read(sharedPreferencesServiceProvider);

    setState(() {
      _customScanPaths = persistenceService.getStringList('custom_scan_paths') ?? [];
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    // 使用全局的sharedPreferencesServiceProvider
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
    // 监听持久化服务的变化，当设置改变时刷新UI
    ref.watch(sharedPreferencesServiceProvider);
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.music_library_management,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // 添加自定义扫描目录
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.loc.custom_scan_paths,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addCustomScanPath,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.add_custom_directory,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (_customScanPaths.isEmpty)
                    Center(
                      child: Text(
                        context.loc.no_custom_scan_paths,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _customScanPaths.length,
                      itemBuilder: (context, index) {
                        final path = _customScanPaths[index];
                        return Material(
                          color: Colors.transparent,
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                path,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeCustomScanPath(index),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 16),
                  Text(
                    context.loc.full_platform_scan_note,
                    style: const TextStyle(color: Colors.orange, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 音乐库信息
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.library_info,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.songs_count,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.loc.library_features,
                    style: const TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.access_library,
                    style: const TextStyle(color: Colors.green, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 扫描说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.scan_instructions,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.auto_extract_metadata,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.add_custom_paths,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.scan_completion,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.auto_metadata_extraction,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.loc.how_to_scan,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.scan_step1,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.scan_step2,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.scan_step3,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.scan_step4,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 常见问题
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.faq,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.faq_scan_issue,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.faq_scan_issue_answer,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.faq_slow_scan,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.faq_slow_scan_answer,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.loc.faq_not_showing,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.loc.faq_not_showing_answer,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
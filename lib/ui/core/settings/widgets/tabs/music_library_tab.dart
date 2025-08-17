import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '音乐库管理',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                      const Text(
                        '自定义扫描目录',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addCustomScanPath,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '添加自定义目录进行音乐扫描',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),

                  if (_customScanPaths.isEmpty)
                    const Center(
                      child: Text(
                        '暂无自定义扫描路径',
                        style: TextStyle(color: Colors.grey),
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
                  const Text(
                    '注意：请通过侧边栏的"音乐扫描"功能进行全平台扫描',
                    style: TextStyle(color: Colors.orange, fontSize: 14),
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
                  const Text(
                    '音乐库信息',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '当前音乐库包含 0 首歌曲',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '提示：音乐库信息将在专门的音乐库页面中显示和管理',
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '提示：您可以通过侧边栏访问"音乐库"和"音乐扫描"功能',
                    style: TextStyle(color: Colors.green, fontSize: 14),
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
                  const Text(
                    '音乐扫描说明',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• 通过侧边栏的"音乐扫描"功能可以扫描设备上的所有音乐文件',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 可以在扫描页面添加自定义扫描路径',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 扫描完成后，音乐将自动显示在音乐库中',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '• 音乐库会自动提取歌曲的元数据（标题、艺术家、专辑等）',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '如何使用音乐扫描功能：',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. 点击左侧边栏的"音乐扫描"菜单项',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '2. 在扫描页面点击"开始扫描"按钮',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '3. 等待扫描完成，查看扫描结果',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '4. 扫描到的音乐将自动显示在"音乐库"中',
                    style: TextStyle(color: Colors.grey),
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
                  const Text(
                    '常见问题',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Q: 为什么扫描不到音乐文件？',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A: 请确保设备上存在音乐文件，并且应用具有访问存储的权限。',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Q: 扫描很慢怎么办？',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A: 首次扫描可能会比较慢，后续扫描会更快。请耐心等待。',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Q: 扫描后音乐没有显示在音乐库中？',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'A: 请确保扫描已完成，并尝试刷新音乐库页面。',
                    style: TextStyle(color: Colors.grey),
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

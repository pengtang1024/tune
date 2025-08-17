import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  // 打开URL的函数
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取平台信息
    String platform;
    if (kIsWeb) {
      platform = 'Web';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          platform = 'Android';
          break;
        case TargetPlatform.iOS:
          platform = 'iOS';
          break;
        case TargetPlatform.windows:
          platform = 'Windows';
          break;
        case TargetPlatform.macOS:
          platform = 'macOS';
          break;
        case TargetPlatform.linux:
          platform = 'Linux';
          break;
        case TargetPlatform.fuchsia:
          platform = 'Fuchsia';
          break;
      }
    }

    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 应用Logo和名称
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note,
              size: 80,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // 应用名称和版本
          const Text(
            'Tune 音乐播放器',
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '版本 1.0.0',
            style: TextStyle(
              fontSize: 16, 
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '运行平台: $platform',
            style: const TextStyle(
              fontSize: 16, 
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          
          // 简介卡片
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '简介',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tune 是一款简洁、美观的跨平台音乐播放器，专注于为用户提供优质的音乐播放体验。'
                    '支持多种音频格式，具备丰富的播放功能和个性化设置选项。',
                    style: TextStyle(fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 功能特点
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '功能特点',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.music_note,
                    title: '高质量音频播放',
                    description: '支持 MP3、FLAC、WAV、AAC 等多种音频格式',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.folder,
                    title: '本地音乐管理',
                    description: '自动扫描并整理本地音乐库',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.translate,
                    title: '多语言支持',
                    description: '支持中文、英文、日文、韩文、俄文等多种语言',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.color_lens,
                    title: '多主题支持',
                    description: '8 种主题配色，支持深色/浅色模式切换',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.sync,
                    title: '歌词同步',
                    description: 'LRC 格式歌词实时同步显示',
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.search,
                    title: '智能搜索',
                    description: '支持按歌曲名、艺术家、专辑等元数据快速搜索',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 开源许可
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '开源许可',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '本项目使用 MIT 许可证开源，源代码可在 GitHub 上获取。',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchUrl('https://github.com/your-username/tune'),
                    child: const Text(
                      'GitHub 项目地址',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 联系我们
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '联系我们',
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '如有任何问题或建议，请通过以下方式联系我们:',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '📧 邮箱: support@tune-music.com',
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl('https://tune-music.com'),
                    child: const Text(
                      '🌐 官方网站: https://tune-music.com',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// 功能特点项组件
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:url_launcher/url_launcher.dart';

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
              color: theme.primaryColor.withValues(alpha:0.1),
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
          Text(
            context.loc.app_name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.loc.version,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${context.loc.platform}: $platform',
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
                    context.loc.about,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.loc.about_description,
                    style: const TextStyle(fontSize: 15),
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
                    context.loc.features,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FeatureItem(
                    icon: Icons.music_note,
                    title: context.loc.high_quality_audio_playback,
                    description: context.loc.supports_multiple_audio_formats,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.folder,
                    title: context.loc.local_music_management,
                    description: context.loc.automatically_scans_and_organizes_local_music_library,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.translate,
                    title: context.loc.multi_language_support,
                    description: context.loc.supports_chinese_english_japanese_korean_russian_and_more,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.color_lens,
                    title: context.loc.multiple_themes,
                    description: context.loc.eight_theme_colors_with_dark_light_mode_switching,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.sync,
                    title: context.loc.lyrics_synchronization,
                    description: context.loc.lrc_format_lyrics_real_time_synchronization_display,
                  ),
                  const SizedBox(height: 12),
                  _FeatureItem(
                    icon: Icons.search,
                    title: context.loc.smart_search,
                    description: context.loc.supports_searching_by_song_title_artist_album_and_other_metadata,
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
                    context.loc.open_source_license,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.loc.opensource_license_description,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchUrl('https://github.com/your-username/tune'),
                    child: Text(
                      context.loc.github_project_address,
                      style: const TextStyle(
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
                    context.loc.contact_us,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.loc.contact_us_description,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.loc.email,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _launchUrl('https://tune-music.com'),
                    child: Text(
                      context.loc.official_website,
                      style: const TextStyle(
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

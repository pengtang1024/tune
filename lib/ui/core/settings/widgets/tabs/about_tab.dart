import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutTab extends ConsumerWidget {
  const AboutTab({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 应用 Logo 和信息
          _AppInfoSection(platform: platform),
          const SizedBox(height: AppDesignSystem.spacing32),

          // 关于应用
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.about,
                  style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                    color: AppDesignSystem.primary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                Text(
                  context.loc.about_description,
                  style: AppDesignSystem.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing20),

          // 功能特点
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.features,
                  style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                    color: AppDesignSystem.primary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing16),
                _FeatureItem(
                  icon: Icons.music_note,
                  title: context.loc.high_quality_audio_playback,
                  description: context.loc.supports_multiple_audio_formats,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FeatureItem(
                  icon: Icons.folder,
                  title: context.loc.local_music_management,
                  description: context.loc.automatically_scans_and_organizes_local_music_library,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FeatureItem(
                  icon: Icons.translate,
                  title: context.loc.multi_language_support,
                  description: context.loc.supports_chinese_english_japanese_korean_russian_and_more,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FeatureItem(
                  icon: Icons.color_lens,
                  title: context.loc.multiple_themes,
                  description: context.loc.eight_theme_colors_with_dark_light_mode_switching,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FeatureItem(
                  icon: Icons.sync,
                  title: context.loc.lyrics_synchronization,
                  description: context.loc.lrc_format_lyrics_real_time_synchronization_display,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _FeatureItem(
                  icon: Icons.search,
                  title: context.loc.smart_search,
                  description: context.loc.supports_searching_by_song_title_artist_album_and_other_metadata,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing20),

          // 开源许可
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.open_source_license,
                  style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                    color: AppDesignSystem.primary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                Text(
                  context.loc.opensource_license_description,
                  style: AppDesignSystem.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                _LinkButton(
                  text: context.loc.github_project_address,
                  url: 'https://github.com/your-username/tune',
                  onTap: () => _launchUrl('https://github.com/your-username/tune'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing20),

          // 联系我们
          ModernCard(
            padding: const EdgeInsets.all(AppDesignSystem.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.contact_us,
                  style: AppDesignSystem.textTheme.titleLarge?.copyWith(
                    fontWeight: AppDesignSystem.fontWeightBold,
                    color: AppDesignSystem.primary,
                  ),
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                Text(
                  context.loc.contact_us_description,
                  style: AppDesignSystem.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDesignSystem.spacing12),
                Text(
                  context.loc.email,
                  style: AppDesignSystem.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppDesignSystem.spacing8),
                _LinkButton(
                  text: context.loc.official_website,
                  url: 'https://tune-music.com',
                  onTap: () => _launchUrl('https://tune-music.com'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacing20),
        ],
      ),
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  final String platform;

  const _AppInfoSection({required this.platform});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: AppDesignSystem.albumCoverSize120,
          height: AppDesignSystem.albumCoverSize120,
          decoration: BoxDecoration(
            gradient: AppDesignSystem.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppDesignSystem.shadowColored,
          ),
          child: const Icon(
            Icons.music_note,
            size: AppDesignSystem.iconSize64,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing20),
        Text(
          context.loc.app_name,
          style: AppDesignSystem.textTheme.headlineMedium?.copyWith(
            fontWeight: AppDesignSystem.fontWeightBold,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing8),
        Text(
          context.loc.version,
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
        ),
        const SizedBox(height: AppDesignSystem.spacing4),
        Text(
          '${context.loc.platform}: $platform',
          style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
            color: isDark ? AppDesignSystem.neutral400 : AppDesignSystem.neutral600,
          ),
        ),
      ],
    );
  }
}

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
        Icon(
          icon,
          color: AppDesignSystem.primary,
          size: AppDesignSystem.iconSize28,
        ),
        const SizedBox(width: AppDesignSystem.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppDesignSystem.textTheme.titleSmall?.copyWith(
                  fontWeight: AppDesignSystem.fontWeightBold,
                ),
              ),
              const SizedBox(height: AppDesignSystem.spacing4),
              Text(
                description,
                style: AppDesignSystem.textTheme.bodySmall?.copyWith(
                  color: AppDesignSystem.neutral500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String text;
  final String url;
  final VoidCallback onTap;

  const _LinkButton({
    required this.text,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
          color: AppDesignSystem.accent,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}

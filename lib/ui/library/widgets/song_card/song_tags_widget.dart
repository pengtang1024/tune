import 'package:flutter/material.dart';
import 'package:tune/domain/models/song.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class SongTagsWidget extends StatelessWidget {
  final Song song;
  const SongTagsWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags();
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppDesignSystem.spacing4,
      runSpacing: 2,
      children: tags,
    );
  }

  List<Widget> _buildTags() {
    final List<Widget> tags = [];

    if (song.year != null && song.year != 0) {
      tags.add(_tag(song.year.toString(), AppDesignSystem.success));
    }
    if (song.genre != null && song.genre!.isNotEmpty) {
      tags.add(_tag(song.genre!, AppDesignSystem.primary));
    }
    if (song.bitrate != null && song.bitrate != 0) {
      tags.add(_tag('${song.bitrate}kbps', AppDesignSystem.accent));
    }
    if (song.sampleRate != null && song.sampleRate != 0) {
      tags.add(_tag('${song.sampleRate}Hz', AppDesignSystem.warning));
    }
    if (song.trackNumber != null && song.trackNumber != 0) {
      tags.add(_tag('#${song.trackNumber}', AppDesignSystem.secondary));
    }
    if (song.discNumber != null && song.discNumber != 0) {
      tags.add(_tag('Disc ${song.discNumber}', AppDesignSystem.tertiary));
    }
    if (song.size != null && song.size != 0) {
      tags.add(_tag(_fmtSize(song.size!), AppDesignSystem.info));
    }
    if (song.isFavorite) {
      tags.add(_tag('Fav', AppDesignSystem.error));
    }

    return tags;
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppDesignSystem.borderRadius4,
      ),
      child: Text(
        text,
        style: AppDesignSystem.textTheme.labelSmall?.copyWith(
          fontSize: 9,
          color: color,
        ),
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

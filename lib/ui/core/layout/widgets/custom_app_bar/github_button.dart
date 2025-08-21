import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:url_launcher/url_launcher.dart';

class GitHubButton extends StatelessWidget {
  const GitHubButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.code),
      onPressed: () async {
        final Uri url = Uri.parse('https://github.com/ByteForge-Studio/Tune');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.loc.failed_to_open_github)), // 使用本地化字符串
            );
          }
        }
      },
    );
  }
}

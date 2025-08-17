import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// GitHub 按钮组件
/// 负责跳转到 GitHub 仓库
class GitHubButton extends StatelessWidget {
  const GitHubButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.code),
      tooltip: '访问 GitHub',
      onPressed: () async {
        final Uri url = Uri.parse('https://github.com');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        } else {
          // 添加错误提示
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法打开 GitHub 链接')),
            );
          }
        }
      },
    );
  }
}
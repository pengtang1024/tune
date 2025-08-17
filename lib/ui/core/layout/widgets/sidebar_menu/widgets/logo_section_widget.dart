import 'package:flutter/material.dart';

/// Logo区域组件
/// 仅负责显示应用Logo和名称
class LogoSectionWidget extends StatelessWidget {
  final bool isExpanded;

  const LogoSectionWidget({
    super.key,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        child: isExpanded
            ? Row(
                children: [
                  Icon(
                    Icons.music_note,
                    size: 48, // 增大图标尺寸
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tune',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Center(
                // 收起状态下Logo居中显示
                child: Icon(
                  Icons.music_note,
                  size: 48, // 增大图标尺寸
                  color: Theme.of(context).primaryColor,
                ),
              ),
      ),
    );
  }
}

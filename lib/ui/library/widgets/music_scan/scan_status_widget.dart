import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

/// 扫描状态消息组件
/// 显示扫描过程中的状态信息
class ScanStatusWidget extends StatelessWidget {
  final String statusMessage;
  final String errorMessage;

  const ScanStatusWidget({
    super.key,
    required this.statusMessage,
    this.errorMessage = '',
  });

  @override
  Widget build(BuildContext context) {
    if (statusMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasError = errorMessage.isNotEmpty;
    final iconColor = hasError ? AppDesignSystem.error : AppDesignSystem.primary;
    final icon = hasError ? Icons.error_outline : Icons.info_outline;

    return ModernCard(
      padding: const EdgeInsets.all(AppDesignSystem.spacing16),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: AppDesignSystem.iconSize24),
          const SizedBox(width: AppDesignSystem.spacing12),
          Expanded(
            child: Text(
              statusMessage,
              style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                color: hasError ? AppDesignSystem.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
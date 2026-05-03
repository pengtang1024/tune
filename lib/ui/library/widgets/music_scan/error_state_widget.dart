import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_button.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignSystem.spacing16),
        child: ModernCard(
          padding: const EdgeInsets.all(AppDesignSystem.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: AppDesignSystem.error,
                size: AppDesignSystem.iconSize64,
              ),
              const SizedBox(height: AppDesignSystem.spacing16),
              Text(
                errorMessage,
                style: AppDesignSystem.textTheme.bodyMedium?.copyWith(
                  color: AppDesignSystem.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesignSystem.spacing24),
              ModernButton(
                onPressed: onRetry,
                icon: Icons.refresh,
                text: context.loc.retry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
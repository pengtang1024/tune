import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/widgets/modern_button.dart';
import 'package:tune/ui/widgets/modern_button_config.dart';

class CustomPathsScanButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  const CustomPathsScanButtonWidget({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ModernButton(
            text: context.loc.add_custom_directory,
            icon: Icons.folder_open_rounded,
            onPressed: onPressed,
            type: ModernButtonType.primary,
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}

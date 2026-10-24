import 'package:flutter/material.dart';
import 'package:tune/app/theme/compact_tokens.dart';
import 'package:tune/shared/ui/empty_state_view.dart';

/// An empty screen of the discover page.
class DiscoveryEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> actions;

  const DiscoveryEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: icon,
      title: title,
      subtitle: subtitle,
      action: actions.isEmpty
          ? null
          : Wrap(
              spacing: CompactTokens.space8,
              runSpacing: CompactTokens.space8,
              alignment: WrapAlignment.center,
              children: actions,
            ),
    );
  }
}

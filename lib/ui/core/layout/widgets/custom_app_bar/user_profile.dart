import 'package:flutter/material.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/core/layout/states/app_bar_state.dart';
import 'package:tune/ui/theme/app_design_system.dart';

class UserProfile extends StatelessWidget {
  final AppBarState state;
  const UserProfile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: state.userAvatarUrl != null ? NetworkImage(state.userAvatarUrl!) : null,
            child: state.userAvatarUrl == null ? const Icon(Icons.person, size: 20) : null,
          ),
          const SizedBox(width: AppDesignSystem.spacing10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      state.username ?? context.loc.unknown_user,
                      style: AppDesignSystem.textTheme.titleMedium?.copyWith(
                        fontWeight: AppDesignSystem.fontWeightBold,
                      ),
                    ),
                    const SizedBox(width: AppDesignSystem.spacing6),
                    if (state.userLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.primary,
                          borderRadius: AppDesignSystem.borderRadius12,
                        ),
                        child: Text(
                          'Lv.${state.userLevel}',
                          style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                if (state.userTags.isNotEmpty)
                  Wrap(
                    spacing: AppDesignSystem.spacing4,
                    runSpacing: 2,
                    children: state.userTags.map<Widget>((tag) {
                      Color tagColor = AppDesignSystem.neutral500;
                      if (tag == 'vip' || tag == context.loc.tag_vip) tagColor = AppDesignSystem.error;
                      else if (tag == context.loc.tag_singer) tagColor = AppDesignSystem.success;
                      else if (tag == context.loc.tag_elite) tagColor = AppDesignSystem.primary;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: tagColor, borderRadius: AppDesignSystem.borderRadius8),
                        child: Text(tag, style: AppDesignSystem.textTheme.labelSmall?.copyWith(color: Colors.white)),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

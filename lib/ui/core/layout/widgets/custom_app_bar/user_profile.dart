import 'package:flutter/material.dart';
import 'package:tune/ui/core/layout/states/app_bar_state.dart';

/// 用户信息组件
/// 负责显示用户头像、用户名、等级和标签
class UserProfile extends StatelessWidget {
  final AppBarState state;

  const UserProfile({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 居中对齐
        children: [
          // 用户头像
          CircleAvatar(
            radius: 20,
            backgroundImage: state.userAvatarUrl != null
                ? NetworkImage(state.userAvatarUrl!)
                : null,
            child: state.userAvatarUrl == null
                ? const Icon(Icons.person, size: 20)
                : null,
          ),
          const SizedBox(width: 10),
          // 用户信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 用户名和等级
                Row(
                  children: [
                    Text(
                      state.username ?? '未知用户',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 5),
                    if (state.userLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Lv.${state.userLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // 用户标签
                if (state.userTags.isNotEmpty)
                  Wrap(
                    spacing: 5,
                    runSpacing: 3,
                    children: state.userTags.map<Widget>((tag) {
                      Color tagColor = Colors.grey;
                      if (tag == 'vip') {
                        tagColor = Colors.red;
                      } else if (tag == '歌手') {
                        tagColor = Colors.green;
                      } else if (tag == '精英') {
                        tagColor = Colors.purple;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
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
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tune/domain/models/menu_item.dart';

class SidebarMenu extends StatefulWidget {
  final bool isExpanded;
  final Function(bool) onExpandChanged;
  final Function(MenuItem) onMenuItemSelected;
  final MenuItem? selectedMenuItem;

  const SidebarMenu({
    super.key,
    required this.isExpanded,
    required this.onExpandChanged,
    required this.onMenuItemSelected,
    this.selectedMenuItem,
  });

  @override
  State<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends State<SidebarMenu> {
  late List<MenuItem> menuItems;

  @override
  void initState() {
    super.initState();
    menuItems = [
      MenuItem(
        title: '主页',
        icon: Icons.home_outlined,
        route: '/',
      ),
      MenuItem(
        title: '推荐',
        icon: Icons.recommend_outlined,
        route: '/recommend',
      ),
      MenuItem(
        title: '精选',
        icon: Icons.star_outline,
        route: '/featured',
      ),
      MenuItem(
        title: '音乐库',
        icon: Icons.library_music_outlined,
        route: '/library',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.isExpanded ? 250 : 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 应用标题栏
          _buildAppHeader(),
          // 菜单展开/收缩按钮
          _buildExpandButton(),
          // 菜单项目列表
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: menuItems.map((item) => _buildMenuItem(item)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, // 始终居中对齐
        children: [
          // 应用图标
          Image(
            image: AssetImage('assets/icons/app_icon.png'),
            width: 32,
            height: 32,
            fit: BoxFit.contain, // 防止图标变形
          ),
          // 应用名称
          if (widget.isExpanded) ...[
            const SizedBox(width: 12),
            const Text(
              'Tune',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        icon: Icon(
          widget.isExpanded ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
        ),
        onPressed: () {
          widget.onExpandChanged(!widget.isExpanded);
        },
      ),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    final isSelected = widget.selectedMenuItem?.route == item.route;

    return Material(
      color: isSelected 
          ? Theme.of(context).primaryColor.withValues(alpha: 0.1) 
          : Colors.transparent,
      child: InkWell(
        onTap: () {
          // 使用路由导航到对应页面
          context.push(item.route);
          // 通知父组件菜单项被选中
          widget.onMenuItemSelected(item);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: widget.isExpanded 
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? _getSelectedIcon(item.icon) : item.icon,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? Theme.of(context).primaryColor : null,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Icon(
                  isSelected ? _getSelectedIcon(item.icon) : item.icon,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
        ),
      ),
    );
  }
  
  IconData _getSelectedIcon(IconData originalIcon) {
    switch (originalIcon) {
      case Icons.home_outlined:
        return Icons.home;
      case Icons.recommend_outlined:
        return Icons.recommend;
      case Icons.star_outline:
        return Icons.star;
      case Icons.library_music_outlined:
        return Icons.library_music;
      default:
        return originalIcon;
    }
  }
}
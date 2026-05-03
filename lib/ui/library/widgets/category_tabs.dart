import 'package:flutter/material.dart';
import 'package:tune/ui/theme/app_design_system.dart';

enum LibraryCategory {
  all,
  artists,
  albums,
  folders,
}

class CategoryTabs extends StatelessWidget {
  final LibraryCategory selectedCategory;
  final ValueChanged<LibraryCategory> onCategoryChanged;

  const CategoryTabs({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LibraryCategory.values.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: EdgeInsets.only(
              right: category != LibraryCategory.values.last 
                  ? AppDesignSystem.spacing12 
                  : 0,
            ),
            child: _buildCategoryTab(context, category, isSelected, isDark),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryTab(
    BuildContext context,
    LibraryCategory category,
    bool isSelected,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => onCategoryChanged(category),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppDesignSystem.spacing20,
          vertical: AppDesignSystem.spacing10,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppDesignSystem.primary
              : (isDark ? AppDesignSystem.neutral800 : AppDesignSystem.neutral100),
          borderRadius: AppDesignSystem.borderRadius20,
        ),
        child: Text(
          _getCategoryLabel(category),
          style: AppDesignSystem.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? Colors.white
                : (isDark ? AppDesignSystem.neutral300 : AppDesignSystem.neutral700),
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(LibraryCategory category) {
    switch (category) {
      case LibraryCategory.all:
        return '全部';
      case LibraryCategory.artists:
        return '艺术家';
      case LibraryCategory.albums:
        return '专辑';
      case LibraryCategory.folders:
        return '文件夹';
    }
  }
}

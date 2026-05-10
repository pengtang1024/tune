import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tune/core/extension/localizations_extension.dart';
import 'package:tune/ui/theme/app_design_system.dart';
import 'package:tune/ui/widgets/modern_card.dart';

class LibrarySearchBar extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;

  const LibrarySearchBar({super.key, required this.controller, required this.onSearchChanged});

  @override
  ConsumerState<LibrarySearchBar> createState() => _LibrarySearchBarState();
}

class _LibrarySearchBarState extends ConsumerState<LibrarySearchBar> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(horizontal: AppDesignSystem.spacing16),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: context.loc.search,
          hintStyle: AppDesignSystem.textTheme.bodyMedium?.copyWith(color: AppDesignSystem.neutral400),
          prefixIcon: const Icon(Icons.search, size: AppDesignSystem.iconSize20, color: AppDesignSystem.neutral400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: AppDesignSystem.iconSize20),
                  onPressed: () {
                    widget.controller.clear();
                    setState(() => _searchQuery = '');
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: AppDesignSystem.spacing14),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          widget.onSearchChanged(value);
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class CategorySelector extends StatelessWidget {
  /// Category names in display order. The first entry is expected to be
  /// the "All" pseudo-category.
  final List<String> categories;

  /// Currently selected category name. An empty string means "All".
  final String selected;

  /// Called with the tapped category name, or an empty string for "All".
  final ValueChanged<String> onSelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selected == category;
          return ChoiceChip(
            showCheckmark: false,
            label: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(category == 'All' ? '' : category),
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.textSecondary.withValues(alpha: 0.3),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}

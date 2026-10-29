import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';

/// Horizontal category filter selector for the POS cashier screen.
class PosCategorySelector extends StatelessWidget {
  const PosCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    this.totalActiveProductsCount = 0,
  });

  /// List of available active categories.
  final List<Category> categories;

  /// Currently selected category ID (null if all are selected).
  final String? selectedCategoryId;

  /// Callback when a category is selected (passes null when "Semua" is tapped).
  final ValueChanged<String?> onSelectCategory;

  /// Total count of active products across all categories.
  final int totalActiveProductsCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          // "Semua" Chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              avatar: const Icon(
                Icons.grid_view_rounded,
                size: 16,
              ),
              label: Text(
                totalActiveProductsCount > 0
                    ? 'Semua ($totalActiveProductsCount)'
                    : 'Semua',
              ),
              selected: selectedCategoryId == null,
              onSelected: (_) => onSelectCategory(null),
            ),
          ),

          // Categories Chips
          ...categories.where((c) => c.isActive).map((cat) {
            final isSelected = selectedCategoryId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                avatar: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: cat.color,
                    shape: BoxShape.circle,
                  ),
                ),
                label: Text(cat.name),
                selected: isSelected,
                onSelected: (_) {
                  onSelectCategory(isSelected ? null : cat.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}

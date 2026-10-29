import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/category_provider.dart';
import 'package:kas_usaha/features/catalog/presentation/widgets/category_card.dart';
import 'package:kas_usaha/features/catalog/presentation/widgets/category_form_sheet.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';
import 'package:kas_usaha/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_empty_state.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_loading.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';

/// Screen for managing product categories (Task T1.2).
///
/// Provides responsive list display, search filtering, status toggling,
/// category creation, editing, and safe deletion.
class CategoryListScreen extends ConsumerStatefulWidget {
  const CategoryListScreen({super.key});

  @override
  ConsumerState<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends ConsumerState<CategoryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(categoryProvider).status == CategoryStatus.initial) {
        ref.read(categoryProvider.notifier).loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddCategorySheet() {
    CategoryFormSheet.show(
      context,
      onSave: ({
        required String name,
        required String description,
        required String colorHex,
        required int iconCodePoint,
        required bool isActive,
      }) {
        return ref.read(categoryProvider.notifier).createCategory(
              name: name,
              description: description,
              colorHex: colorHex,
              iconCodePoint: iconCodePoint,
              isActive: isActive,
            );
      },
    );
  }

  void _openEditCategorySheet(Category category) {
    CategoryFormSheet.show(
      context,
      category: category,
      onSave: ({
        required String name,
        required String description,
        required String colorHex,
        required int iconCodePoint,
        required bool isActive,
      }) {
        final updated = category.copyWith(
          name: name,
          description: description,
          colorHex: colorHex,
          iconCodePoint: iconCodePoint,
          isActive: isActive,
        );
        return ref.read(categoryProvider.notifier).updateCategory(updated);
      },
    );
  }

  Future<void> _handleDeleteCategory(Category category) async {
    // If category has products, notifier will block and display feedback,
    // but we also inform the user directly in the confirmation dialog.
    final message = category.productCount > 0
        ? 'Kategori "${category.name}" masih memiliki ${category.productCount} produk terkait. Kategori tidak dapat dihapus permanen untuk menjaga integritas data.'
        : 'Apakah Anda yakin ingin menghapus kategori "${category.name}"? Tindakan ini tidak dapat dibatalkan.';

    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Hapus Kategori?',
      message: message,
      confirmText: category.productCount > 0 ? 'Mengerti' : 'Hapus',
      isDanger: category.productCount == 0,
      icon: category.productCount > 0
          ? Icons.info_outline_rounded
          : Icons.delete_forever_rounded,
    );

    if (confirmed == true && category.productCount == 0) {
      await ref.read(categoryProvider.notifier).deleteCategory(category.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Reactively listen to provider state changes for feedback notifications
    ref.listen<CategoryState>(categoryProvider, (previous, next) {
      if (next.status == CategoryStatus.success &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    next.successMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
            ),
          ),
        );
        ref.read(categoryProvider.notifier).clearFeedback();
      } else if (next.status == CategoryStatus.error &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.roundedMd,
            ),
          ),
        );
        ref.read(categoryProvider.notifier).clearFeedback();
      }
    });

    final state = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategori Produk'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Kategori',
            onPressed: () {
              ref.read(categoryProvider.notifier).loadCategories();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Quick Summary Banner Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: _buildSummaryCard(theme, isDark, state),
                ),

                // Search Field & Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      AppSearchField(
                        controller: _searchController,
                        hint: 'Cari nama atau deskripsi kategori...',
                        onChanged: (val) {
                          ref.read(categoryProvider.notifier).setSearchQuery(val);
                        },
                        onClear: () {
                          ref.read(categoryProvider.notifier).setSearchQuery('');
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildFilterChips(theme, state),
                    ],
                  ),
                ),

                // Category List or State Feedback
                Expanded(
                  child: _buildContent(theme, state),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddCategorySheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Kategori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    bool isDark,
    CategoryState state,
  ) {
    return AppCard(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.primary50.withAlpha(140),
      borderColor: theme.colorScheme.primary.withAlpha(50),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            theme: theme,
            label: 'Total Kategori',
            value: state.totalCount.toString(),
            icon: Icons.category_rounded,
            color: theme.colorScheme.primary,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),
          _buildSummaryItem(
            theme: theme,
            label: 'Kategori Aktif',
            value: state.activeCount.toString(),
            icon: Icons.check_circle_rounded,
            color: AppColors.success,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),
          _buildSummaryItem(
            theme: theme,
            label: 'Total Produk',
            value: state.totalProductsCount.toString(),
            icon: Icons.inventory_2_rounded,
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required ThemeData theme,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(ThemeData theme, CategoryState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: Text('Semua (${state.totalCount})'),
            selected: state.selectedFilter == CategoryFilter.all,
            onSelected: (_) {
              ref.read(categoryProvider.notifier).setFilter(CategoryFilter.all);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          FilterChip(
            label: Text('Aktif (${state.activeCount})'),
            selected: state.selectedFilter == CategoryFilter.active,
            onSelected: (_) {
              ref
                  .read(categoryProvider.notifier)
                  .setFilter(CategoryFilter.active);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          FilterChip(
            label: Text('Nonaktif (${state.inactiveCount})'),
            selected: state.selectedFilter == CategoryFilter.inactive,
            onSelected: (_) {
              ref
                  .read(categoryProvider.notifier)
                  .setFilter(CategoryFilter.inactive);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, CategoryState state) {
    if (state.isLoading) {
      return const Center(
        child: AppLoading(message: 'Memuat kategori...'),
      );
    }

    final filteredList = state.filteredCategories;

    // Empty list due to active search filter
    if (filteredList.isEmpty && state.searchQuery.isNotEmpty) {
      return AppEmptyState(
        title: 'Kategori Tidak Ditemukan',
        message:
            'Tidak ada kategori yang cocok dengan kata kunci "${state.searchQuery}".',
        icon: Icons.search_off_rounded,
        actionText: 'Hapus Pencarian',
        onAction: () {
          _searchController.clear();
          ref.read(categoryProvider.notifier).setSearchQuery('');
        },
      );
    }

    // Empty list when total categories is zero
    if (filteredList.isEmpty) {
      return AppEmptyState(
        title: 'Belum Ada Kategori',
        message:
            'Mulai kelompokkan produk dan inventori Anda dengan menambahkan kategori pertama.',
        icon: Icons.category_outlined,
        actionText: 'Tambah Kategori Pertama',
        onAction: _openAddCategorySheet,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        88.0, // Space for FloatingActionButton
      ),
      itemCount: filteredList.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = filteredList[index];
        return CategoryCard(
          category: category,
          onEdit: () => _openEditCategorySheet(category),
          onDelete: () => _handleDeleteCategory(category),
          onToggleActive: () {
            ref.read(categoryProvider.notifier).toggleCategoryActive(category);
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/category_provider.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';
import 'package:kas_usaha/features/catalog/presentation/screens/product_form_screen.dart';
import 'package:kas_usaha/features/catalog/presentation/widgets/product_card.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';
import 'package:kas_usaha/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_empty_state.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_loading.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';
import 'package:kas_usaha/features/inventory/presentation/screens/stock_history_screen.dart';

/// Screen for managing product catalog, inventory status, search, and filtering (Task T1.3).
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (ref.read(productProvider).status == ProductStatus.initial) {
          ref.read(productProvider.notifier).loadProducts();
        }
        if (ref.read(categoryProvider).status == CategoryStatus.initial) {
          ref.read(categoryProvider.notifier).loadCategories();
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProductScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProductFormScreen(),
      ),
    );
  }

  void _openEditProductScreen(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  Future<void> _handleDeleteProduct(Product product) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Hapus Produk?',
      message:
          'Apakah Anda yakin ingin menghapus "${product.name}"? Produk ini akan dihapus dari katalog.',
      confirmText: 'Hapus Produk',
      isDanger: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true) {
      await ref.read(productProvider.notifier).deleteProduct(product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Reactively listen to provider state changes for feedback notifications
    ref.listen<ProductState>(productProvider, (previous, next) {
      if (next.status == ProductStatus.success &&
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
        ref.read(productProvider.notifier).clearFeedback();
      } else if (next.status == ProductStatus.error &&
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
        ref.read(productProvider.notifier).clearFeedback();
      }
    });

    final productState = ref.watch(productProvider);
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Produk'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Perubahan Stok',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StockHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Produk',
            onPressed: () {
              ref.read(productProvider.notifier).loadProducts();
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
                // Quick Summary Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: _buildSummaryCard(theme, isDark, productState),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: AppSearchField(
                    controller: _searchController,
                    hint: 'Cari nama, SKU, atau barcode...',
                    onChanged: (val) {
                      ref.read(productProvider.notifier).setSearchQuery(val);
                    },
                    onClear: () {
                      ref.read(productProvider.notifier).setSearchQuery('');
                    },
                  ),
                ),

                // Category Filter Horizontal Scroll
                _buildCategoryFilterRow(theme, productState, categoryState),

                // Stock Condition Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: _buildStockFilterRow(theme, productState),
                ),

                const Divider(height: 1),

                // Product List or Empty State
                Expanded(
                  child: _buildProductList(
                    theme: theme,
                    productState: productState,
                    categories: categoryState.categories,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProductScreen,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Produk',
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
    ProductState state,
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
            label: 'Total Produk',
            value: state.totalCount.toString(),
            icon: Icons.inventory_2_rounded,
            color: theme.colorScheme.primary,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),
          _buildSummaryItem(
            theme: theme,
            label: 'Stok Menipis',
            value: state.lowStockCount.toString(),
            icon: Icons.error_outline_rounded,
            color: AppColors.warning,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),
          _buildSummaryItem(
            theme: theme,
            label: 'Stok Habis',
            value: state.outOfStockCount.toString(),
            icon: Icons.warning_rounded,
            color: AppColors.error,
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

  Widget _buildCategoryFilterRow(
    ThemeData theme,
    ProductState productState,
    CategoryState categoryState,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          // "Semua Kategori" Chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              label: const Text('Semua Kategori'),
              selected: productState.selectedCategoryId == null,
              onSelected: (_) {
                ref.read(productProvider.notifier).setCategoryFilter(null);
              },
            ),
          ),

          // Chips for Each Category
          ...categoryState.categories.map((cat) {
            final isSelected = productState.selectedCategoryId == cat.id;
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
                  ref
                      .read(productProvider.notifier)
                      .setCategoryFilter(isSelected ? null : cat.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStockFilterRow(ThemeData theme, ProductState productState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          FilterChip(
            label: const Text('Semua Stok'),
            selected: productState.selectedStockFilter == ProductStockFilter.all,
            onSelected: (_) {
              ref
                  .read(productProvider.notifier)
                  .setStockFilter(ProductStockFilter.all);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: const Text('Tersedia'),
            selected:
                productState.selectedStockFilter == ProductStockFilter.inStock,
            onSelected: (_) {
              ref
                  .read(productProvider.notifier)
                  .setStockFilter(ProductStockFilter.inStock);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text('Menipis (${productState.lowStockCount})'),
            selected:
                productState.selectedStockFilter == ProductStockFilter.lowStock,
            onSelected: (_) {
              ref
                  .read(productProvider.notifier)
                  .setStockFilter(ProductStockFilter.lowStock);
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          FilterChip(
            label: Text('Habis (${productState.outOfStockCount})'),
            selected: productState.selectedStockFilter ==
                ProductStockFilter.outOfStock,
            onSelected: (_) {
              ref
                  .read(productProvider.notifier)
                  .setStockFilter(ProductStockFilter.outOfStock);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductList({
    required ThemeData theme,
    required ProductState productState,
    required List<Category> categories,
  }) {
    if (productState.isLoading) {
      return const Center(
        child: AppLoading(message: 'Memuat katalog produk...'),
      );
    }

    final filteredList = productState.filteredProducts;

    // Filter or Search Yields No Results
    if (filteredList.isEmpty &&
        (productState.searchQuery.isNotEmpty ||
            productState.selectedCategoryId != null ||
            productState.selectedStockFilter != ProductStockFilter.all)) {
      return AppEmptyState(
        title: 'Produk Tidak Ditemukan',
        message:
            'Tidak ada produk yang cocok dengan kriteria pencarian dan filter saat ini.',
        icon: Icons.search_off_rounded,
        actionText: 'Reset Filter & Pencarian',
        onAction: () {
          _searchController.clear();
          ref.read(productProvider.notifier).setSearchQuery('');
          ref.read(productProvider.notifier).setCategoryFilter(null);
          ref
              .read(productProvider.notifier)
              .setStockFilter(ProductStockFilter.all);
        },
      );
    }

    // Catalog has no products at all
    if (filteredList.isEmpty) {
      return AppEmptyState(
        title: 'Belum Ada Produk',
        message:
            'Mulai bangun katalog penjualan Anda dengan menambahkan produk pertama.',
        icon: Icons.inventory_2_outlined,
        actionText: 'Tambah Produk Pertama',
        onAction: _openAddProductScreen,
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
        final product = filteredList[index];

        // Find category color and icon if available
        final cat = categories.cast<Category?>().firstWhere(
              (c) => c?.id == product.categoryId,
              orElse: () => null,
            );

        return ProductCard(
          product: product,
          categoryColor: cat?.color,
          categoryIcon: cat?.icon,
          onEdit: () => _openEditProductScreen(product),
          onDelete: () => _handleDeleteProduct(product),
          onToggleActive: () {
            ref.read(productProvider.notifier).toggleProductActive(product);
          },
          onViewStockHistory: product.trackStock
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => StockHistoryScreen(
                        initialProductId: product.id,
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

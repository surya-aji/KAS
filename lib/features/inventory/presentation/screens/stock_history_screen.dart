import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/app/theme/app_typography.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/features/inventory/presentation/providers/stock_movement_provider.dart';
import 'package:kas_usaha/features/inventory/presentation/widgets/stock_movement_card.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_empty_state.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_loading.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';

/// Screen displaying inventory stock change history and audit logs (Task T1.5).
///
/// Supports filtering by specific product, movement type, date range,
/// and live search for audit tracking.
class StockHistoryScreen extends ConsumerStatefulWidget {
  const StockHistoryScreen({
    super.key,
    this.initialProductId,
  });

  /// Optional product ID to filter log entries on initial load.
  final String? initialProductId;

  @override
  ConsumerState<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends ConsumerState<StockHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (ref.read(productProvider).status == ProductStatus.initial) {
          ref.read(productProvider.notifier).loadProducts();
        }

        final movementNotifier = ref.read(stockMovementProvider.notifier);
        if (ref.read(stockMovementProvider).status ==
            StockMovementStatus.initial) {
          movementNotifier.loadStockMovements(
            productId: widget.initialProductId,
          );
        } else if (widget.initialProductId != null) {
          movementNotifier.setProductFilter(widget.initialProductId);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAllFilters() {
    _searchController.clear();
    ref.read(stockMovementProvider.notifier).resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final movementState = ref.watch(stockMovementProvider);
    final productState = ref.watch(productProvider);

    // List of products available for filtering (only inventory tracking products)
    final inventoryProducts = productState.products
        .where((p) => p.trackStock)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Perubahan Stok'),
        centerTitle: true,
        actions: [
          if (movementState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded),
              tooltip: 'Reset Filter',
              onPressed: _resetAllFilters,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Log',
            onPressed: () {
              ref.read(stockMovementProvider.notifier).loadStockMovements(
                    productId: movementState.selectedProductId,
                  );
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
                // Top Metrics Summary Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: _buildSummaryCard(theme, isDark, movementState),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: AppSearchField(
                    controller: _searchController,
                    hint: 'Cari no. referensi, produk, catatan...',
                    onChanged: (val) {
                      ref
                          .read(stockMovementProvider.notifier)
                          .setSearchQuery(val);
                    },
                    onClear: () {
                      ref
                          .read(stockMovementProvider.notifier)
                          .setSearchQuery('');
                    },
                  ),
                ),

                // Product Filter Selector
                _buildProductFilterRow(theme, movementState, inventoryProducts),

                // Movement Type Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: _buildTypeFilterRow(theme, movementState),
                ),

                // Date Range Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xxs,
                  ),
                  child: _buildDateFilterRow(theme, movementState),
                ),

                const SizedBox(height: AppSpacing.xs),
                const Divider(height: 1),

                // Movements List or Empty State
                Expanded(
                  child: _buildMovementsList(
                    theme: theme,
                    movementState: movementState,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    ThemeData theme,
    bool isDark,
    StockMovementState state,
  ) {
    final netColor = state.netQuantityChange >= 0
        ? (isDark ? const Color(0xFF86EFAC) : AppColors.success)
        : (isDark ? const Color(0xFFFCA5A5) : AppColors.error);

    final netPrefix = state.netQuantityChange > 0 ? '+' : '';

    return AppCard(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.primary50.withAlpha(140),
      borderColor: theme.colorScheme.primary.withAlpha(50),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Total Items Added In
          _buildSummaryItem(
            theme: theme,
            label: 'Total Masuk',
            value: '+${state.totalItemsIn}',
            icon: Icons.add_circle_outline_rounded,
            color: isDark ? const Color(0xFF86EFAC) : AppColors.success,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),

          // Total Items Deducted Out
          _buildSummaryItem(
            theme: theme,
            label: 'Total Keluar',
            value: '-${state.totalItemsOut}',
            icon: Icons.remove_circle_outline_rounded,
            color: isDark ? const Color(0xFFFCA5A5) : AppColors.error,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.dividerColor,
          ),

          // Net Change Balance
          _buildSummaryItem(
            theme: theme,
            label: 'Mutasi Bersih',
            value: '$netPrefix${state.netQuantityChange}',
            icon: Icons.balance_rounded,
            color: netColor,
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
              style: AppTypography.tabularFigures(
                fontSize: 16,
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

  Widget _buildProductFilterRow(
    ThemeData theme,
    StockMovementState movementState,
    List<Product> products,
  ) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          // "Semua Produk" Chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: ChoiceChip(
              avatar: const Icon(Icons.inventory_2_outlined, size: 14),
              label: const Text('Semua Produk'),
              selected: movementState.selectedProductId == null,
              onSelected: (_) {
                ref
                    .read(stockMovementProvider.notifier)
                    .setProductFilter(null);
              },
            ),
          ),

          // Chips for Each Tracked Product
          ...products.map((product) {
            final isSelected =
                movementState.selectedProductId == product.id;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(product.name),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(stockMovementProvider.notifier)
                      .setProductFilter(isSelected ? null : product.id);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTypeFilterRow(
    ThemeData theme,
    StockMovementState movementState,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "Semua Tipe"
          ChoiceChip(
            label: const Text('Semua Tipe'),
            selected: movementState.selectedType == null,
            onSelected: (_) {
              ref.read(stockMovementProvider.notifier).setTypeFilter(null);
            },
          ),
          const SizedBox(width: AppSpacing.xs),

          // Each Stock Movement Type Chip
          ...StockMovementType.values.map((type) {
            final isSelected = movementState.selectedType == type;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ChoiceChip(
                avatar: Icon(type.icon, size: 14),
                label: Text(type.displayName),
                selected: isSelected,
                onSelected: (_) {
                  ref
                      .read(stockMovementProvider.notifier)
                      .setTypeFilter(isSelected ? null : type);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDateFilterRow(
    ThemeData theme,
    StockMovementState movementState,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StockDateFilter.values.map((filter) {
          final isSelected = movementState.selectedDateFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: FilterChip(
              avatar: const Icon(Icons.calendar_today_rounded, size: 12),
              label: Text(filter.displayName),
              selected: isSelected,
              onSelected: (_) {
                ref
                    .read(stockMovementProvider.notifier)
                    .setDateFilter(filter);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMovementsList({
    required ThemeData theme,
    required StockMovementState movementState,
  }) {
    if (movementState.isLoading) {
      return const Center(
        child: AppLoading(message: 'Memuat riwayat perubahan stok...'),
      );
    }

    final filteredList = movementState.filteredMovements;

    // Filters Active but No Results Found
    if (filteredList.isEmpty && movementState.hasActiveFilters) {
      return Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            title: 'Riwayat Tidak Ditemukan',
            message:
                'Tidak ada catatan perubahan stok yang sesuai dengan filter atau kata kunci saat ini.',
            icon: Icons.search_off_rounded,
            actionText: 'Reset Filter',
            onAction: _resetAllFilters,
          ),
        ),
      );
    }

    // No Stock Movements in Database
    if (filteredList.isEmpty) {
      return const Center(
        child: SingleChildScrollView(
          child: AppEmptyState(
            title: 'Belum Ada Riwayat Stok',
            message:
                'Aktivitas penambahan, penjualan, atau penyesuaian stok produk akan tercatat secara otomatis di sini.',
            icon: Icons.history_rounded,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(stockMovementProvider.notifier).loadStockMovements(
              productId: movementState.selectedProductId,
            );
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        itemCount: filteredList.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final movement = filteredList[index];
          return StockMovementCard(movement: movement);
        },
      ),
    );
  }
}

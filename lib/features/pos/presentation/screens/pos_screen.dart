import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/business_settings/presentation/providers/business_profile_provider.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/category_provider.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/presentation/providers/pos_provider.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_cart_bottom_bar.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_cart_modal_sheet.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_cart_sidebar.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_category_selector.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_discount_tax_dialog.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_product_card.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_quantity_edit_dialog.dart';
import 'package:kas_usaha/shared/widgets/dialogs/app_confirm_dialog.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_empty_state.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_loading.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';
import 'package:kas_usaha/shared/widgets/layout/responsive_layout.dart';

/// Main Cashier (Point of Sale) Screen with responsive layouts for tablet and smartphone (Task T2.1, T2.2 & T2.3).
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(productProvider).status == ProductStatus.initial) {
        ref.read(productProvider.notifier).loadProducts();
      }
      if (ref.read(categoryProvider).status == CategoryStatus.initial) {
        ref.read(categoryProvider.notifier).loadCategories();
      }
      if (ref.read(businessProfileProvider).status ==
          BusinessProfileStatus.initial) {
        ref.read(businessProfileProvider.notifier).loadProfile();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openQuantityEditDialog(CartItem item) {
    PosQuantityEditDialog.show(
      context,
      cartItem: item,
      onSave: (newQuantity, notes, [discountType, discountValue]) {
        ref.read(posProvider.notifier).updateCartItemDetails(
              item.product.id,
              quantity: newQuantity,
              notes: notes,
              discountType: discountType,
              discountValue: discountValue,
            );
      },
      onDelete: () {
        ref.read(posProvider.notifier).deleteItem(item.product.id);
      },
    );
  }

  void _openDiscountTaxDialog() {
    final posState = ref.read(posProvider);
    PosDiscountTaxDialog.show(
      context,
      cartItems: posState.cartItems,
      initialDiscountType: posState.transactionDiscountType,
      initialDiscountValue: posState.transactionDiscountValue,
      initialIsTaxApplied: posState.isTaxApplied,
      initialTaxRate: posState.taxRate,
      onApply: ({
        required discountType,
        required discountValue,
        required isTaxApplied,
        required taxRate,
      }) {
        ref.read(posProvider.notifier).setTransactionDiscount(
              type: discountType,
              value: discountValue,
            );
        ref.read(posProvider.notifier).setTaxApplied(isTaxApplied);
        ref.read(posProvider.notifier).setTaxRate(taxRate);
      },
    );
  }

  Future<void> _confirmClearCart() async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Kosongkan Keranjang?',
      message: 'Apakah Anda yakin ingin menghapus semua item dalam pesanan ini?',
      confirmText: 'Kosongkan',
      cancelText: 'Batal',
      isDanger: true,
      icon: Icons.delete_sweep_rounded,
    );

    if (confirmed == true && mounted) {
      ref.read(posProvider.notifier).clearCart();
    }
  }

  void _showMobileCartSheet(BuildContext context) {
    PosCartModalSheet.show(
      context,
      onIncrement: (item) {
        ref.read(posProvider.notifier).addToCart(item.product);
      },
      onDecrement: (item) {
        ref.read(posProvider.notifier).removeFromCart(item.product.id);
      },
      onDelete: (item) {
        ref.read(posProvider.notifier).deleteItem(item.product.id);
      },
      onEdit: (item) {
        _openQuantityEditDialog(item);
      },
      onClear: () {
        ref.read(posProvider.notifier).clearCart();
      },
      onConfigureDiscountAndTax: () {
        _openDiscountTaxDialog();
      },
      onCheckout: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Siap memproses pesanan (${ref.read(posProvider).formattedTotalAmount}) — Dilanjutkan pada Task T2.4',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Listen to POS flash messages (e.g. out of stock warning)
    ref.listen<PosState>(posProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    next.errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
        ref.read(posProvider.notifier).clearMessages();
      }
    });

    final productState = ref.watch(productProvider);
    final categoryState = ref.watch(categoryProvider);
    final businessProfile = ref.watch(businessProfileProvider).profile;
    final posState = ref.watch(posProvider);
    final filteredProducts = ref.watch(posFilteredProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Kasir (POS)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (businessProfile.name.isNotEmpty)
              Text(
                businessProfile.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
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
        child: productState.isLoading
            ? const Center(
                child: AppLoading(message: 'Memuat katalog kasir...'),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet =
                      constraints.maxWidth >= AppBreakpoints.mobile;

                  if (isTablet) {
                    return _buildTabletLayout(
                      theme: theme,
                      constraints: constraints,
                      posState: posState,
                      categoryState: categoryState,
                      filteredProducts: filteredProducts,
                    );
                  }

                  return _buildMobileLayout(
                    theme: theme,
                    constraints: constraints,
                    posState: posState,
                    categoryState: categoryState,
                    filteredProducts: filteredProducts,
                  );
                },
              ),
      ),
    );
  }

  /// Tablet Layout: Dual-pane screen with product grid on the left and sticky order panel on the right.
  Widget _buildTabletLayout({
    required ThemeData theme,
    required BoxConstraints constraints,
    required PosState posState,
    required CategoryState categoryState,
    required List<Product> filteredProducts,
  }) {
    // Dynamic columns calculation for tablet screen widths
    final gridColumns = constraints.maxWidth >= 1000 ? 4 : 3;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Search, Categories, Product Grid
        Expanded(
          flex: 3,
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: AppSearchField(
                  controller: _searchController,
                  hint: 'Cari produk (Nama, SKU, Barcode)...',
                  onChanged: (val) {
                    ref.read(posProvider.notifier).setSearchQuery(val);
                  },
                  onClear: () {
                    ref.read(posProvider.notifier).setSearchQuery('');
                  },
                ),
              ),

              // Category Selector
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: PosCategorySelector(
                  categories: categoryState.categories,
                  selectedCategoryId: posState.selectedCategoryId,
                  totalActiveProductsCount: ref
                      .watch(productProvider)
                      .products
                      .where((p) => p.isActive)
                      .length,
                  onSelectCategory: (catId) {
                    ref.read(posProvider.notifier).setCategory(catId);
                  },
                ),
              ),

              const Divider(height: 1),

              // Product Grid
              Expanded(
                child: _buildProductGrid(
                  theme: theme,
                  crossAxisCount: gridColumns,
                  childAspectRatio: 0.88,
                  filteredProducts: filteredProducts,
                  categories: categoryState.categories,
                  posState: posState,
                ),
              ),
            ],
          ),
        ),

        // Right Column: Order / Cart Sidebar (Task T2.3)
        SizedBox(
          width: constraints.maxWidth >= 1100 ? 380 : 340,
          child: PosCartSidebar(
            cartItems: posState.cartItems,
            totalQuantity: posState.totalQuantity,
            totalAmount: posState.totalAmount,
            calculation: posState.calculation,
            onIncrementItem: (item) {
              ref.read(posProvider.notifier).addToCart(item.product);
            },
            onDecrementItem: (item) {
              ref.read(posProvider.notifier).removeFromCart(item.product.id);
            },
            onDeleteItem: (item) {
              ref.read(posProvider.notifier).deleteItem(item.product.id);
            },
            onEditItem: (item) {
              _openQuantityEditDialog(item);
            },
            onClearCart: () => _confirmClearCart(),
            onConfigureDiscountAndTax: _openDiscountTaxDialog,
            onCheckout: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Siap memproses pesanan (${posState.formattedTotalAmount}) — Dilanjutkan pada Task T2.4',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Mobile Smartphone Layout: Single column with search, categories, 2-column grid, and bottom cart bar.
  Widget _buildMobileLayout({
    required ThemeData theme,
    required BoxConstraints constraints,
    required PosState posState,
    required CategoryState categoryState,
    required List<Product> filteredProducts,
  }) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: AppSearchField(
            controller: _searchController,
            hint: 'Cari nama, SKU, atau barcode...',
            onChanged: (val) {
              ref.read(posProvider.notifier).setSearchQuery(val);
            },
            onClear: () {
              ref.read(posProvider.notifier).setSearchQuery('');
            },
          ),
        ),

        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: PosCategorySelector(
            categories: categoryState.categories,
            selectedCategoryId: posState.selectedCategoryId,
            totalActiveProductsCount: ref
                .watch(productProvider)
                .products
                .where((p) => p.isActive)
                .length,
            onSelectCategory: (catId) {
              ref.read(posProvider.notifier).setCategory(catId);
            },
          ),
        ),

        const Divider(height: 1),

        // Product Grid
        Expanded(
          child: _buildProductGrid(
            theme: theme,
            crossAxisCount: 2,
            childAspectRatio: 0.84,
            filteredProducts: filteredProducts,
            categories: categoryState.categories,
            posState: posState,
          ),
        ),

        // Mobile Sticky Cart Bottom Bar (Task T2.3)
        PosCartBottomBar(
          totalQuantity: posState.totalQuantity,
          totalAmount: posState.totalAmount,
          totalDiscounts: posState.calculation.totalDiscounts,
          onViewCart: () {
            _showMobileCartSheet(context);
          },
        ),
      ],
    );
  }

  /// Builds the responsive Product GridView with empty state handling.
  Widget _buildProductGrid({
    required ThemeData theme,
    required int crossAxisCount,
    required double childAspectRatio,
    required List<Product> filteredProducts,
    required List<Category> categories,
    required PosState posState,
  }) {
    // Empty search / filter state
    if (filteredProducts.isEmpty &&
        (posState.searchQuery.isNotEmpty ||
            posState.selectedCategoryId != null)) {
      return AppEmptyState(
        title: 'Produk Tidak Ditemukan',
        message:
            'Tidak ada produk kasir yang cocok dengan kata kunci atau kategori terpilih.',
        icon: Icons.search_off_rounded,
        actionText: 'Reset Filter & Pencarian',
        onAction: () {
          _searchController.clear();
          ref.read(posProvider.notifier).resetFilters();
        },
      );
    }

    // Catalog has no active products
    if (filteredProducts.isEmpty) {
      return const AppEmptyState(
        title: 'Belum Ada Produk Aktif',
        message:
            'Semua produk dalam katalog sedang nonaktif atau belum ada produk yang ditambahkan.',
        icon: Icons.inventory_2_outlined,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];

        // Retrieve category visual metadata
        final category = categories.cast<Category?>().firstWhere(
              (c) => c?.id == product.categoryId,
              orElse: () => null,
            );

        final cartQty = posState.getCartQuantity(product.id);

        return PosProductCard(
          product: product,
          categoryColor: category?.color,
          categoryIcon: category?.icon,
          cartQuantity: cartQty,
          onTap: () {
            ref.read(posProvider.notifier).addToCart(product);
          },
        );
      },
    );
  }
}

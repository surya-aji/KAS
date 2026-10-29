import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/theme/app_colors.dart';
import 'package:kas_usaha/app/theme/app_spacing.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/domain/validators/product_validator.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/category_provider.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/product_provider.dart';
import 'package:kas_usaha/shared/formatters/currency_formatter.dart';
import 'package:kas_usaha/shared/widgets/badges/app_badge.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/cards/app_card.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_currency_field.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_text_field.dart';

/// Form screen for creating or editing a product in the catalog.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({
    super.key,
    this.product,
  });

  /// Existing product to edit, or null when creating a new product.
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _unitController;
  late TextEditingController _descController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;

  late String _selectedCategoryId;
  late String _selectedCategoryName;
  late int _sellingPrice;
  late int _costPrice;
  late bool _trackStock;
  late bool _isActive;
  bool _isSubmitting = false;

  static const List<String> _quickUnits = [
    'pcs',
    'porsi',
    'cup',
    'botol',
    'bungkus',
    'paket',
    'kg',
    'layanan',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _unitController = TextEditingController(text: p?.unit ?? 'pcs');
    _descController = TextEditingController(text: p?.description ?? '');
    _stockController = TextEditingController(text: (p?.stock ?? 0).toString());
    _minStockController =
        TextEditingController(text: (p?.minStock ?? 5).toString());

    _sellingPrice = p?.sellingPrice ?? 0;
    _costPrice = p?.costPrice ?? 0;
    _selectedCategoryId = p?.categoryId ?? '';
    _selectedCategoryName = p?.categoryName ?? '';
    _trackStock = p?.trackStock ?? true;
    _isActive = p?.isActive ?? true;

    // Pre-select first category if creating new product and categories are available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final catNotifier = ref.read(categoryProvider.notifier);
      if (ref.read(categoryProvider).categories.isEmpty) {
        await catNotifier.loadCategories();
      }
      if (!mounted) return;
      final categoryState = ref.read(categoryProvider);
      if (_selectedCategoryId.isEmpty && categoryState.categories.isNotEmpty) {
        final defaultCat = categoryState.categories.firstWhere(
          (c) => c.isActive,
          orElse: () => categoryState.categories.first,
        );
        setState(() {
          _selectedCategoryId = defaultCat.id;
          _selectedCategoryName = defaultCat.name;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    _descController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kategori produk terlebih dahulu.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 5;

    bool success;
    if (widget.product != null) {
      // Edit mode
      final updated = widget.product!.copyWith(
        name: _nameController.text.trim(),
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        unit: _unitController.text.trim(),
        description: _descController.text.trim(),
        sellingPrice: _sellingPrice,
        costPrice: _costPrice,
        stock: _trackStock ? stock : 0,
        minStock: _trackStock ? minStock : 0,
        trackStock: _trackStock,
        isActive: _isActive,
      );
      success = await ref.read(productProvider.notifier).updateProduct(updated);
    } else {
      // Create mode
      success = await ref.read(productProvider.notifier).createProduct(
            name: _nameController.text.trim(),
            categoryId: _selectedCategoryId,
            categoryName: _selectedCategoryName,
            sku: _skuController.text.trim(),
            barcode: _barcodeController.text.trim(),
            unit: _unitController.text.trim(),
            description: _descController.text.trim(),
            sellingPrice: _sellingPrice,
            costPrice: _costPrice,
            stock: _trackStock ? stock : 0,
            minStock: _trackStock ? minStock : 0,
            trackStock: _trackStock,
            isActive: _isActive,
          );
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        final errorMsg = ref.read(productProvider).errorMessage ??
            'Gagal menyimpan produk. Silakan periksa data input.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditMode = widget.product != null;
    final categoryState = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Produk' : 'Tambah Produk Baru'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // Live Product Card Preview
                  _buildLivePreview(theme, isDark),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 1: Basic Information
                  _buildSectionHeader(
                    theme: theme,
                    title: 'Informasi Dasar',
                    subtitle: 'Nama, kategori, dan identitas produk',
                    icon: Icons.info_outline_rounded,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildBasicInfoSection(theme, categoryState),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: Pricing & Profit Calculation
                  _buildSectionHeader(
                    theme: theme,
                    title: 'Harga & Keuntungan',
                    subtitle: 'Harga jual dan estimasi laba kotor',
                    icon: Icons.payments_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildPricingSection(theme, isDark),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 3: Inventory & Stock Settings
                  _buildSectionHeader(
                    theme: theme,
                    title: 'Pengaturan Stok & Inventori',
                    subtitle: 'Kontrol pengurangan stok saat kasir bertransaksi',
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildInventorySection(theme, isDark),
                  const SizedBox(height: AppSpacing.xxl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Batal',
                          variant: AppButtonVariant.outlined,
                          size: AppButtonSize.large,
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: AppButton(
                          text: isEditMode
                              ? 'Simpan Perubahan'
                              : 'Tambah Produk',
                          leadingIcon: Icons.save_rounded,
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.large,
                          isLoading: _isSubmitting,
                          onPressed: _isSubmitting ? null : _submitForm,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLivePreview(ThemeData theme, bool isDark) {
    final previewName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Nama Produk';
    final previewCategory = _selectedCategoryName.isNotEmpty
        ? _selectedCategoryName
        : 'Pilih Kategori';
    final previewSku = _skuController.text.trim();
    final previewSelling = CurrencyFormatter.formatRupiah(_sellingPrice);
    final previewProfit = _sellingPrice - _costPrice;
    final margin = _sellingPrice > 0 ? (previewProfit / _sellingPrice) * 100 : 0.0;

    return AppCard(
      color: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.primary50.withAlpha(140),
      borderColor: theme.colorScheme.primary.withAlpha(60),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: AppRadius.roundedSm,
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            previewName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AppBadge(
                          label: _isActive ? 'Aktif' : 'Nonaktif',
                          variant: _isActive
                              ? AppBadgeVariant.success
                              : AppBadgeVariant.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        AppBadge(
                          label: previewCategory,
                          variant: AppBadgeVariant.info,
                        ),
                        if (previewSku.isNotEmpty)
                          AppBadge(
                            label: previewSku,
                            variant: AppBadgeVariant.neutral,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    previewSelling,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (_costPrice > 0)
                    Text(
                      'Modal: ${CurrencyFormatter.formatRupiah(_costPrice)} (Margin ${margin.toStringAsFixed(0)}%)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              AppBadge(
                label: _trackStock
                    ? 'Stok: ${_stockController.text} ${_unitController.text}'
                    : 'Tanpa Stok',
                variant: _trackStock
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.neutral,
                icon: _trackStock
                    ? Icons.check_circle_outline_rounded
                    : Icons.all_inclusive_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(
    ThemeData theme,
    CategoryState categoryState,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Selector
          Text(
            'Kategori Produk *',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          DropdownButtonFormField<String>(
            initialValue:
                _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
            decoration: const InputDecoration(
              hintText: 'Pilih kategori produk',
              prefixIcon: Icon(Icons.category_outlined, size: 20),
            ),
            items: categoryState.categories.map((c) {
              return DropdownMenuItem<String>(
                value: c.id,
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(c.name),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                final cat = categoryState.categories.firstWhere((c) => c.id == val);
                setState(() {
                  _selectedCategoryId = cat.id;
                  _selectedCategoryName = cat.name;
                });
              }
            },
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Kategori produk wajib dipilih';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Product Name
          AppTextField(
            controller: _nameController,
            label: 'Nama Produk *',
            hint: 'Contoh: Nasi Goreng Spesial, Kopi Susu',
            prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
            textInputAction: TextInputAction.next,
            onChanged: (val) => setState(() {}),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nama produk wajib diisi';
              }
              if (val.trim().length < 2) {
                return 'Nama produk minimal 2 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // SKU & Barcode Row
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _skuController,
                  label: 'SKU / Kode Produk',
                  hint: 'MKN-001',
                  prefixIcon: const Icon(Icons.qr_code_rounded, size: 20),
                  textInputAction: TextInputAction.next,
                  onChanged: (val) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  controller: _barcodeController,
                  label: 'Barcode (Opsional)',
                  hint: '8991001001',
                  prefixIcon: const Icon(Icons.barcode_reader, size: 20),
                  textInputAction: TextInputAction.next,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Unit Field & Quick Chips
          AppTextField(
            controller: _unitController,
            label: 'Satuan Produk *',
            hint: 'pcs, porsi, cup, botol',
            prefixIcon: const Icon(Icons.straighten_rounded, size: 20),
            textInputAction: TextInputAction.next,
            onChanged: (val) => setState(() {}),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Satuan produk wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _quickUnits.map((u) {
                final isSelected = _unitController.text.trim() == u;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ActionChip(
                    label: Text(u, style: const TextStyle(fontSize: 12)),
                    backgroundColor: isSelected
                        ? theme.colorScheme.primaryContainer
                        : null,
                    onPressed: () {
                      setState(() {
                        _unitController.text = u;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description Field
          AppTextField(
            controller: _descController,
            label: 'Deskripsi / Catatan Produk',
            hint: 'Catatan tambahan untuk produk ini',
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
            maxLines: 2,
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(ThemeData theme, bool isDark) {
    final profit = _sellingPrice - _costPrice;
    final margin = _sellingPrice > 0 ? (profit / _sellingPrice) * 100 : 0.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selling Price (Harga Jual)
          AppCurrencyField(
            initialAmount: _sellingPrice > 0 ? _sellingPrice : null,
            label: 'Harga Jual *',
            hint: '0',
            onAmountChanged: (val) {
              setState(() {
                _sellingPrice = val;
              });
            },
            validator: (val) => ProductValidator.validateSellingPrice(
              _sellingPrice,
              rawText: val,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Cost Price (Harga Modal / HPP)
          AppCurrencyField(
            initialAmount: _costPrice > 0 ? _costPrice : null,
            label: 'Harga Modal / HPP (Opsional)',
            hint: '0',
            helperText:
                'Digunakan untuk kalkulasi estimasi laba kotor pada laporan.',
            onAmountChanged: (val) {
              setState(() {
                _costPrice = val;
              });
            },
            validator: (val) => ProductValidator.validateCostPrice(
              _costPrice,
              rawText: val,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Profit & Margin Summary Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceVariant.withAlpha(80)
                  : AppColors.lightSurfaceVariant,
              borderRadius: AppRadius.roundedSm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimasi Laba per Unit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatRupiah(profit),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: profit >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Margin Keuntungan',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${margin.toStringAsFixed(1)}%',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Potential loss warning banner
          if (ProductValidator.isPotentialLoss(_sellingPrice, _costPrice)) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.errorDark.withAlpha(40)
                    : AppColors.errorLight,
                border: Border.all(
                  color: isDark
                      ? AppColors.errorDark
                      : AppColors.error.withAlpha(80),
                ),
                borderRadius: AppRadius.roundedSm,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Perhatian: Harga modal lebih tinggi dari harga jual. Menghasilkan estimasi rugi sebesar ${CurrencyFormatter.formatRupiah(_costPrice - _sellingPrice)} per unit.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.errorLight : AppColors.errorDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventorySection(ThemeData theme, bool isDark) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track Stock Switch
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Kelola Stok Produk',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Stok akan berkurang otomatis saat checkout kasir berhasil',
                style: TextStyle(fontSize: 12),
              ),
              value: _trackStock,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _trackStock = val;
                });
              },
            ),
          ),

          if (_trackStock) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _stockController,
                    label: 'Jumlah Stok Saat Ini *',
                    hint: '0',
                    prefixIcon:
                        const Icon(Icons.inventory_rounded, size: 20),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    onChanged: (val) => setState(() {}),
                    validator: (val) => ProductValidator.validateStock(
                      val,
                      trackStock: _trackStock,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _minStockController,
                    label: 'Batas Minimum Stok *',
                    hint: '5',
                    prefixIcon:
                        const Icon(Icons.warning_amber_rounded, size: 20),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.done,
                    helperText: 'Peringatan stok menipis',
                    onChanged: (val) => setState(() {}),
                    validator: (val) => ProductValidator.validateMinStock(
                      val,
                      trackStock: _trackStock,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildStockStatusIndicator(theme, isDark),
          ],

          const Divider(height: AppSpacing.lg),

          // Active Product Switch
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Produk Aktif',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: const Text(
                'Produk aktif dapat dipilih di kasir POS',
                style: TextStyle(fontSize: 12),
              ),
              value: _isActive,
              activeTrackColor: theme.colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _isActive = val;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockStatusIndicator(ThemeData theme, bool isDark) {
    if (!_trackStock) return const SizedBox.shrink();

    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final minStock = int.tryParse(_minStockController.text.trim()) ?? 0;

    final status = ProductValidator.evaluateStockStatus(
      trackStock: _trackStock,
      stock: stock,
      minStock: minStock,
    );

    switch (status) {
      case ProductStockLevel.outOfStock:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.errorDark.withAlpha(40) : AppColors.errorLight,
            border: Border.all(
              color: isDark ? AppColors.errorDark : AppColors.error.withAlpha(80),
            ),
            borderRadius: AppRadius.roundedSm,
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Stok Habis: Produk memiliki stok 0 dan akan langsung ditandai habis di kasir POS.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.errorLight : AppColors.errorDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case ProductStockLevel.lowStock:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.warningDark.withAlpha(40) : AppColors.warningLight,
            border: Border.all(
              color: isDark ? AppColors.warningDark : AppColors.warning.withAlpha(80),
            ),
            borderRadius: AppRadius.roundedSm,
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Peringatan Stok Menipis: Stok ($stock) berada pada atau di bawah batas minimum ($minStock).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.warningLight : AppColors.warningDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case ProductStockLevel.inStock:
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.successDark.withAlpha(40) : AppColors.successLight,
            border: Border.all(
              color: isDark ? AppColors.successDark : AppColors.success.withAlpha(80),
            ),
            borderRadius: AppRadius.roundedSm,
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Stok Aman: Stok saat ini ($stock) mencukupi di atas batas minimum ($minStock).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.successLight : AppColors.successDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );

      case ProductStockLevel.notTracked:
        return const SizedBox.shrink();
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/features/catalog/data/repositories/mock_product_repository.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/domain/repositories/product_repository.dart';
import 'package:kas_usaha/features/catalog/domain/validators/product_validator.dart';
import 'package:uuid/uuid.dart';

/// Status lifecycle for product CRUD operations.
enum ProductStatus {
  initial,
  loading,
  loaded,
  saving,
  deleting,
  success,
  error,
}

/// Filter options for inventory stock status.
enum ProductStockFilter {
  all,
  inStock,
  lowStock,
  outOfStock,
}

/// State representation for Product presentation layer.
class ProductState {
  const ProductState({
    required this.status,
    required this.products,
    this.searchQuery = '',
    this.selectedCategoryId,
    this.selectedStockFilter = ProductStockFilter.all,
    this.errorMessage,
    this.successMessage,
  });

  final ProductStatus status;
  final List<Product> products;
  final String searchQuery;
  final String? selectedCategoryId;
  final ProductStockFilter selectedStockFilter;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == ProductStatus.loading;
  bool get isSaving => status == ProductStatus.saving;
  bool get isDeleting => status == ProductStatus.deleting;
  bool get isSuccess => status == ProductStatus.success;
  bool get hasError => status == ProductStatus.error;

  /// Returns products matching category, stock filter, and search text.
  List<Product> get filteredProducts {
    return products.where((product) {
      // 1. Category Filter
      if (selectedCategoryId != null &&
          selectedCategoryId!.isNotEmpty &&
          product.categoryId != selectedCategoryId) {
        return false;
      }

      // 2. Stock Filter
      switch (selectedStockFilter) {
        case ProductStockFilter.all:
          break;
        case ProductStockFilter.inStock:
          if (product.trackStock && product.stock <= 0) return false;
          break;
        case ProductStockFilter.lowStock:
          if (!product.isLowStock) return false;
          break;
        case ProductStockFilter.outOfStock:
          if (!product.isOutOfStock) return false;
          break;
      }

      // 3. Search Query Filter
      if (searchQuery.trim().isEmpty) return true;

      final query = searchQuery.trim().toLowerCase();
      final nameMatches = product.name.toLowerCase().contains(query);
      final skuMatches = product.sku.toLowerCase().contains(query);
      final barcodeMatches = product.barcode.contains(query);
      final categoryMatches = product.categoryName.toLowerCase().contains(query);

      return nameMatches || skuMatches || barcodeMatches || categoryMatches;
    }).toList();
  }

  /// Total count of all products.
  int get totalCount => products.length;

  /// Total count of active products.
  int get activeCount => products.where((p) => p.isActive).length;

  /// Total count of products with low stock warnings.
  int get lowStockCount => products.where((p) => p.isLowStock).length;

  /// Total count of depleted products.
  int get outOfStockCount => products.where((p) => p.isOutOfStock).length;

  factory ProductState.initial() {
    return const ProductState(
      status: ProductStatus.initial,
      products: [],
    );
  }

  ProductState copyWith({
    ProductStatus? status,
    List<Product>? products,
    String? searchQuery,
    String? selectedCategoryId,
    bool clearCategory = false,
    ProductStockFilter? selectedStockFilter,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedStockFilter: selectedStockFilter ?? this.selectedStockFilter,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          products == other.products &&
          searchQuery == other.searchQuery &&
          selectedCategoryId == other.selectedCategoryId &&
          selectedStockFilter == other.selectedStockFilter &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage;

  @override
  int get hashCode =>
      status.hashCode ^
      products.hashCode ^
      searchQuery.hashCode ^
      selectedCategoryId.hashCode ^
      selectedStockFilter.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode;
}

/// Riverpod Notifier managing product catalog CRUD operations.
class ProductNotifier extends Notifier<ProductState> {
  static const _uuid = Uuid();

  @override
  ProductState build() {
    return ProductState.initial();
  }

  ProductRepository get _repository => ref.read(productRepositoryProvider);

  /// Loads products from repository.
  Future<void> loadProducts() async {
    state = state.copyWith(status: ProductStatus.loading);
    try {
      final products = await _repository.getProducts();
      state = state.copyWith(
        status: ProductStatus.loaded,
        products: products,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Gagal memuat produk: $e',
      );
    }
  }

  /// Sets text query for real-time search.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Filters products by category ID (null to clear filter).
  void setCategoryFilter(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  /// Filters products by stock level condition.
  void setStockFilter(ProductStockFilter filter) {
    state = state.copyWith(selectedStockFilter: filter);
  }

  /// Creates a new product with domain validations.
  Future<bool> createProduct({
    required String name,
    required String categoryId,
    String categoryName = '',
    String sku = '',
    String barcode = '',
    String description = '',
    String unit = 'pcs',
    required int sellingPrice,
    int costPrice = 0,
    int stock = 0,
    int minStock = 5,
    bool trackStock = true,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();
    final trimmedSku = sku.trim();

    // Validation 1: Name is required
    if (trimmedName.isEmpty) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Nama produk wajib diisi.',
      );
      return false;
    }

    // Validation 2: Category is required
    if (categoryId.trim().isEmpty) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Kategori produk wajib dipilih.',
      );
      return false;
    }

    // Validation 3: Selling Price
    final sellingPriceError = ProductValidator.validateSellingPrice(sellingPrice);
    if (sellingPriceError != null) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: sellingPriceError,
      );
      return false;
    }

    // Validation 4: Cost Price
    final costPriceError = ProductValidator.validateCostPrice(costPrice);
    if (costPriceError != null) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: costPriceError,
      );
      return false;
    }

    // Validation 5: Stock & Minimum Stock (when trackStock is enabled)
    if (trackStock) {
      final stockError = ProductValidator.validateStock(
        stock.toString(),
        trackStock: true,
      );
      if (stockError != null) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: stockError,
        );
        return false;
      }

      final minStockError = ProductValidator.validateMinStock(
        minStock.toString(),
        trackStock: true,
      );
      if (minStockError != null) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: minStockError,
        );
        return false;
      }
    }

    // Validation 6: SKU uniqueness (if SKU provided)
    if (trimmedSku.isNotEmpty) {
      final isSkuDuplicate = state.products.any(
        (p) => p.sku.toLowerCase() == trimmedSku.toLowerCase(),
      );
      if (isSkuDuplicate) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: 'SKU "$trimmedSku" sudah digunakan oleh produk lain.',
        );
        return false;
      }
    }

    state = state.copyWith(status: ProductStatus.saving);

    try {
      final newProduct = Product(
        id: _uuid.v4(),
        categoryId: categoryId,
        categoryName: categoryName,
        sku: trimmedSku,
        barcode: barcode.trim(),
        name: trimmedName,
        description: description.trim(),
        unit: unit.trim().isNotEmpty ? unit.trim() : 'pcs',
        sellingPrice: sellingPrice,
        costPrice: costPrice < 0 ? 0 : costPrice,
        stock: trackStock ? (stock < 0 ? 0 : stock) : 0,
        minStock: trackStock ? (minStock < 0 ? 0 : minStock) : 0,
        trackStock: trackStock,
        isActive: isActive,
        createdAt: DateTime.now(),
      );

      await _repository.createProduct(newProduct);
      final updatedList = await _repository.getProducts();

      state = state.copyWith(
        status: ProductStatus.success,
        products: updatedList,
        errorMessage: null,
        successMessage: 'Produk "$trimmedName" berhasil ditambahkan.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Gagal menambahkan produk: $e',
      );
      return false;
    }
  }

  /// Updates an existing product with domain validations.
  Future<bool> updateProduct(Product updated) async {
    final trimmedName = updated.name.trim();
    final trimmedSku = updated.sku.trim();

    // Validation 1: Name is required
    if (trimmedName.isEmpty) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Nama produk tidak boleh kosong.',
      );
      return false;
    }

    // Validation 2: Category is required
    if (updated.categoryId.trim().isEmpty) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Kategori produk wajib dipilih.',
      );
      return false;
    }

    // Validation 3: Selling Price
    final sellingPriceError = ProductValidator.validateSellingPrice(updated.sellingPrice);
    if (sellingPriceError != null) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: sellingPriceError,
      );
      return false;
    }

    // Validation 4: Cost Price
    final costPriceError = ProductValidator.validateCostPrice(updated.costPrice);
    if (costPriceError != null) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: costPriceError,
      );
      return false;
    }

    // Validation 5: Stock & Minimum Stock (when trackStock is enabled)
    if (updated.trackStock) {
      final stockError = ProductValidator.validateStock(
        updated.stock.toString(),
        trackStock: true,
      );
      if (stockError != null) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: stockError,
        );
        return false;
      }

      final minStockError = ProductValidator.validateMinStock(
        updated.minStock.toString(),
        trackStock: true,
      );
      if (minStockError != null) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: minStockError,
        );
        return false;
      }
    }

    // Validation 6: SKU uniqueness among other products
    if (trimmedSku.isNotEmpty) {
      final isSkuDuplicate = state.products.any(
        (p) =>
            p.id != updated.id &&
            p.sku.toLowerCase() == trimmedSku.toLowerCase(),
      );
      if (isSkuDuplicate) {
        state = state.copyWith(
          status: ProductStatus.error,
          errorMessage: 'SKU "$trimmedSku" sudah digunakan oleh produk lain.',
        );
        return false;
      }
    }

    state = state.copyWith(status: ProductStatus.saving);

    try {
      final productToSave = updated.copyWith(
        name: trimmedName,
        sku: trimmedSku,
        barcode: updated.barcode.trim(),
        description: updated.description.trim(),
        unit: updated.unit.trim().isNotEmpty ? updated.unit.trim() : 'pcs',
        costPrice: updated.costPrice < 0 ? 0 : updated.costPrice,
        stock: updated.trackStock ? (updated.stock < 0 ? 0 : updated.stock) : 0,
        minStock:
            updated.trackStock ? (updated.minStock < 0 ? 0 : updated.minStock) : 0,
        updatedAt: DateTime.now(),
      );

      await _repository.updateProduct(productToSave);
      final updatedList = await _repository.getProducts();

      state = state.copyWith(
        status: ProductStatus.success,
        products: updatedList,
        errorMessage: null,
        successMessage: 'Produk "$trimmedName" berhasil diperbarui.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Gagal memperbarui produk: $e',
      );
      return false;
    }
  }

  /// Deletes a product by ID.
  Future<bool> deleteProduct(String id) async {
    final productIndex = state.products.indexWhere((p) => p.id == id);
    if (productIndex == -1) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Produk tidak ditemukan.',
      );
      return false;
    }

    final product = state.products[productIndex];
    state = state.copyWith(status: ProductStatus.deleting);

    try {
      await _repository.deleteProduct(id);
      final updatedList = await _repository.getProducts();

      state = state.copyWith(
        status: ProductStatus.success,
        products: updatedList,
        errorMessage: null,
        successMessage: 'Produk "${product.name}" berhasil dihapus.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Gagal menghapus produk: $e',
      );
      return false;
    }
  }

  /// Toggles active status of a product.
  Future<bool> toggleProductActive(Product product) async {
    final updated = product.copyWith(
      isActive: !product.isActive,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateProduct(updated);
      final updatedList = await _repository.getProducts();

      final statusText = updated.isActive ? 'diaktifkan' : 'dinonaktifkan';
      state = state.copyWith(
        status: ProductStatus.success,
        products: updatedList,
        errorMessage: null,
        successMessage: 'Produk "${product.name}" berhasil $statusText.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProductStatus.error,
        errorMessage: 'Gagal mengubah status produk: $e',
      );
      return false;
    }
  }

  /// Resets state back to loaded and clears transient feedback messages.
  void clearFeedback() {
    if (state.status == ProductStatus.success ||
        state.status == ProductStatus.error) {
      state = state.copyWith(
        status: ProductStatus.loaded,
        errorMessage: null,
        successMessage: null,
      );
    }
  }
}

/// Provider for the ProductRepository instance.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final repo = MockProductRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// NotifierProvider for accessing and mutating product catalog state.
final productProvider =
    NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);

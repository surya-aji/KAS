import 'package:kas_usaha/features/catalog/domain/models/product.dart';

/// Abstract contract for product persistence operations.
///
/// Follows Clean Architecture to decouple UI / Riverpod state
/// from Drift SQLite tables (Sprint 0/1 specifications).
abstract class ProductRepository {
  /// Fetches all products, optionally filtered by active status or category ID.
  Future<List<Product>> getProducts({
    bool activeOnly = false,
    String? categoryId,
  });

  /// Fetches a single product by its unique identifier.
  Future<Product?> getProductById(String id);

  /// Fetches a product by its SKU code.
  Future<Product?> getProductBySku(String sku);

  /// Fetches a product by its barcode.
  Future<Product?> getProductByBarcode(String barcode);

  /// Persists a new product.
  Future<void> createProduct(Product product);

  /// Updates an existing product.
  Future<void> updateProduct(Product product);

  /// Deletes a product by its ID.
  Future<void> deleteProduct(String id);

  /// Emits real-time updates whenever products are modified.
  Stream<List<Product>> watchProducts({
    bool activeOnly = false,
    String? categoryId,
  });
}

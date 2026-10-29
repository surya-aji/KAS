import 'dart:async';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/catalog/domain/repositories/product_repository.dart';

/// In-memory mock implementation of [ProductRepository]
/// for the Frontend-First development milestone (T1.3).
///
/// Prepares dummy products, responsive streams, and query operations.
class MockProductRepository implements ProductRepository {
  MockProductRepository({List<Product>? initialProducts})
      : _products = List<Product>.from(
          initialProducts ?? Product.initialProducts(),
        ) {
    _streamController = StreamController<List<Product>>.broadcast();
    _streamController.add(List.unmodifiable(_products));
  }

  final List<Product> _products;
  late final StreamController<List<Product>> _streamController;

  /// Synchronous access for testing.
  List<Product> get currentProducts => List.unmodifiable(_products);

  void _notifyListeners() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_products));
    }
  }

  @override
  Future<List<Product>> getProducts({
    bool activeOnly = false,
    String? categoryId,
  }) async {
    return _products.where((p) {
      if (activeOnly && !p.isActive) return false;
      if (categoryId != null && categoryId.isNotEmpty && p.categoryId != categoryId) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index != -1) return _products[index];
    return null;
  }

  @override
  Future<Product?> getProductBySku(String sku) async {
    final clean = sku.trim().toLowerCase();
    if (clean.isEmpty) return null;
    final index = _products.indexWhere((p) => p.sku.toLowerCase() == clean);
    if (index != -1) return _products[index];
    return null;
  }

  @override
  Future<Product?> getProductByBarcode(String barcode) async {
    final clean = barcode.trim();
    if (clean.isEmpty) return null;
    final index = _products.indexWhere((p) => p.barcode == clean);
    if (index != -1) return _products[index];
    return null;
  }

  @override
  Future<void> createProduct(Product product) async {
    _products.add(product);
    _notifyListeners();
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      _notifyListeners();
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((p) => p.id == id);
    _notifyListeners();
  }

  @override
  Stream<List<Product>> watchProducts({
    bool activeOnly = false,
    String? categoryId,
  }) {
    return _streamController.stream.map((list) {
      return list.where((p) {
        if (activeOnly && !p.isActive) return false;
        if (categoryId != null && categoryId.isNotEmpty && p.categoryId != categoryId) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  /// Closes the reactive stream controller when disposed.
  void dispose() {
    _streamController.close();
  }
}

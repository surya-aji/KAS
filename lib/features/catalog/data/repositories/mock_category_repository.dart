import 'dart:async';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/domain/repositories/category_repository.dart';

/// In-memory mock implementation of [CategoryRepository]
/// for the Frontend-First development milestone (T1.2).
///
/// Prepares dummy state and reactive streams without requiring SQLite tables yet.
class MockCategoryRepository implements CategoryRepository {
  MockCategoryRepository({List<Category>? initialCategories})
      : _categories = List<Category>.from(
          initialCategories ?? Category.initialCategories(),
        ) {
    _streamController = StreamController<List<Category>>.broadcast();
    _streamController.add(List.unmodifiable(_categories));
  }

  final List<Category> _categories;
  late final StreamController<List<Category>> _streamController;

  /// Synchronous inspection of the internal categories list (for testing).
  List<Category> get currentCategories => List.unmodifiable(_categories);

  void _notifyListeners() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_categories));
    }
  }

  @override
  Future<List<Category>> getCategories({bool activeOnly = false}) async {
    if (activeOnly) {
      return _categories.where((c) => c.isActive).toList();
    }
    return List.unmodifiable(_categories);
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final index = _categories.indexWhere((c) => c.id == id);
    if (index != -1) {
      return _categories[index];
    }
    return null;
  }

  @override
  Future<void> createCategory(Category category) async {
    _categories.add(category);
    _notifyListeners();
  }

  @override
  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      _notifyListeners();
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _notifyListeners();
  }

  @override
  Stream<List<Category>> watchCategories({bool activeOnly = false}) {
    if (activeOnly) {
      return _streamController.stream.map(
        (list) => list.where((c) => c.isActive).toList(),
      );
    }
    return _streamController.stream;
  }

  /// Closes the reactive stream controller when disposed.
  void dispose() {
    _streamController.close();
  }
}

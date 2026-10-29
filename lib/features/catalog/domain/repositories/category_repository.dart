import 'package:kas_usaha/features/catalog/domain/models/category.dart';

/// Abstract contract for category persistence operations.
///
/// Follows Clean Architecture to decouple UI / Riverpod state
/// from Drift SQLite tables (Sprint 0/1 specifications).
abstract class CategoryRepository {
  /// Fetches all categories, optionally filtered to active-only for POS grid.
  Future<List<Category>> getCategories({bool activeOnly = false});

  /// Fetches a single category by its unique identifier.
  Future<Category?> getCategoryById(String id);

  /// Persists a new category.
  Future<void> createCategory(Category category);

  /// Updates an existing category.
  Future<void> updateCategory(Category category);

  /// Permanently deletes a category by its ID.
  Future<void> deleteCategory(String id);

  /// Emits real-time updates whenever categories are modified.
  Stream<List<Category>> watchCategories({bool activeOnly = false});
}

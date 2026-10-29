import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/features/catalog/data/repositories/mock_category_repository.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/domain/repositories/category_repository.dart';
import 'package:uuid/uuid.dart';

/// Status lifecycle for category operations.
enum CategoryStatus {
  initial,
  loading,
  loaded,
  saving,
  deleting,
  success,
  error,
}

/// Filter options for categorizing list view.
enum CategoryFilter {
  all,
  active,
  inactive,
}

/// State representation for Category management.
class CategoryState {
  const CategoryState({
    required this.status,
    required this.categories,
    this.searchQuery = '',
    this.selectedFilter = CategoryFilter.all,
    this.errorMessage,
    this.successMessage,
  });

  final CategoryStatus status;
  final List<Category> categories;
  final String searchQuery;
  final CategoryFilter selectedFilter;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == CategoryStatus.loading;
  bool get isSaving => status == CategoryStatus.saving;
  bool get isDeleting => status == CategoryStatus.deleting;
  bool get isSuccess => status == CategoryStatus.success;
  bool get hasError => status == CategoryStatus.error;

  /// Returns categories matching the search query and active status filter.
  List<Category> get filteredCategories {
    return categories.where((category) {
      // 1. Status Filter
      if (selectedFilter == CategoryFilter.active && !category.isActive) {
        return false;
      }
      if (selectedFilter == CategoryFilter.inactive && category.isActive) {
        return false;
      }

      // 2. Search Query Filter
      if (searchQuery.trim().isEmpty) {
        return true;
      }

      final query = searchQuery.trim().toLowerCase();
      final nameMatches = category.name.toLowerCase().contains(query);
      final descMatches = category.description.toLowerCase().contains(query);

      return nameMatches || descMatches;
    }).toList();
  }

  /// Total count of all categories.
  int get totalCount => categories.length;

  /// Total count of active categories.
  int get activeCount => categories.where((c) => c.isActive).length;

  /// Total count of inactive categories.
  int get inactiveCount => categories.where((c) => !c.isActive).length;

  /// Total aggregated product count across all categories.
  int get totalProductsCount =>
      categories.fold(0, (sum, c) => sum + c.productCount);

  factory CategoryState.initial() {
    return const CategoryState(
      status: CategoryStatus.initial,
      categories: [],
    );
  }

  CategoryState copyWith({
    CategoryStatus? status,
    List<Category>? categories,
    String? searchQuery,
    CategoryFilter? selectedFilter,
    String? errorMessage,
    String? successMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          categories == other.categories &&
          searchQuery == other.searchQuery &&
          selectedFilter == other.selectedFilter &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage;

  @override
  int get hashCode =>
      status.hashCode ^
      categories.hashCode ^
      searchQuery.hashCode ^
      selectedFilter.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode;
}

/// Riverpod Notifier managing category CRUD and filter operations.
class CategoryNotifier extends Notifier<CategoryState> {
  static const _uuid = Uuid();

  @override
  CategoryState build() {
    return CategoryState.initial();
  }

  CategoryRepository get _repository => ref.read(categoryRepositoryProvider);

  /// Loads categories from the local repository.
  Future<void> loadCategories() async {
    state = state.copyWith(status: CategoryStatus.loading);
    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(
        status: CategoryStatus.loaded,
        categories: categories,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Gagal memuat kategori: $e',
      );
    }
  }

  /// Updates the search filter in real-time.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets the active/inactive status filter.
  void setFilter(CategoryFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  /// Creates a new category with domain validation.
  /// Returns `true` if operation succeeded.
  Future<bool> createCategory({
    required String name,
    String description = '',
    String colorHex = Category.defaultColorHex,
    int? iconCodePoint,
    bool isActive = true,
  }) async {
    final trimmedName = name.trim();

    // Validation: Empty name
    if (trimmedName.isEmpty) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Nama kategori wajib diisi.',
      );
      return false;
    }

    // Validation: Duplicate name check (case-insensitive)
    final isDuplicate = state.categories.any(
      (c) => c.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (isDuplicate) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Kategori dengan nama "$trimmedName" sudah ada.',
      );
      return false;
    }

    state = state.copyWith(status: CategoryStatus.saving);

    try {
      final newCategory = Category(
        id: _uuid.v4(),
        name: trimmedName,
        description: description.trim(),
        colorHex: colorHex,
        iconCodePoint: iconCodePoint ?? Category.defaultIconCodePoint,
        productCount: 0,
        isActive: isActive,
        createdAt: DateTime.now(),
      );

      await _repository.createCategory(newCategory);
      final updatedList = await _repository.getCategories();

      state = state.copyWith(
        status: CategoryStatus.success,
        categories: updatedList,
        errorMessage: null,
        successMessage: 'Kategori "$trimmedName" berhasil ditambahkan.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Gagal menambahkan kategori: $e',
      );
      return false;
    }
  }

  /// Updates an existing category with domain validation.
  /// Returns `true` if operation succeeded.
  Future<bool> updateCategory(Category updated) async {
    final trimmedName = updated.name.trim();

    // Validation: Empty name
    if (trimmedName.isEmpty) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Nama kategori tidak boleh kosong.',
      );
      return false;
    }

    // Validation: Duplicate name check among other categories
    final isDuplicate = state.categories.any(
      (c) =>
          c.id != updated.id &&
          c.name.toLowerCase() == trimmedName.toLowerCase(),
    );
    if (isDuplicate) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Nama kategori "$trimmedName" sudah digunakan kategori lain.',
      );
      return false;
    }

    state = state.copyWith(status: CategoryStatus.saving);

    try {
      final categoryToSave = updated.copyWith(
        name: trimmedName,
        description: updated.description.trim(),
        updatedAt: DateTime.now(),
      );

      await _repository.updateCategory(categoryToSave);
      final updatedList = await _repository.getCategories();

      state = state.copyWith(
        status: CategoryStatus.success,
        categories: updatedList,
        errorMessage: null,
        successMessage: 'Kategori "$trimmedName" berhasil diperbarui.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Gagal memperbarui kategori: $e',
      );
      return false;
    }
  }

  /// Deletes a category by its ID.
  /// Prevents deletion if the category still contains products to protect relational integrity.
  Future<bool> deleteCategory(String id) async {
    final categoryIndex = state.categories.indexWhere((c) => c.id == id);
    if (categoryIndex == -1) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Kategori tidak ditemukan.',
      );
      return false;
    }

    final category = state.categories[categoryIndex];

    // Data integrity guard: Section 4.2 of IMPLEMENTATION_PLAN.md
    if (category.productCount > 0) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage:
            'Kategori "${category.name}" tidak dapat dihapus karena masih memuat ${category.productCount} produk. Pindahkan produk atau nonaktifkan kategori.',
      );
      return false;
    }

    state = state.copyWith(status: CategoryStatus.deleting);

    try {
      await _repository.deleteCategory(id);
      final updatedList = await _repository.getCategories();

      state = state.copyWith(
        status: CategoryStatus.success,
        categories: updatedList,
        errorMessage: null,
        successMessage: 'Kategori "${category.name}" berhasil dihapus.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Gagal menghapus kategori: $e',
      );
      return false;
    }
  }

  /// Toggles the active status of a category.
  Future<bool> toggleCategoryActive(Category category) async {
    final updated = category.copyWith(
      isActive: !category.isActive,
      updatedAt: DateTime.now(),
    );

    try {
      await _repository.updateCategory(updated);
      final updatedList = await _repository.getCategories();

      final statusText = updated.isActive ? 'diaktifkan' : 'dinonaktifkan';
      state = state.copyWith(
        status: CategoryStatus.success,
        categories: updatedList,
        errorMessage: null,
        successMessage: 'Kategori "${category.name}" berhasil $statusText.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: 'Gagal mengubah status kategori: $e',
      );
      return false;
    }
  }

  /// Resets status back to loaded and clears transient feedback messages.
  void clearFeedback() {
    if (state.status == CategoryStatus.success ||
        state.status == CategoryStatus.error) {
      state = state.copyWith(
        status: CategoryStatus.loaded,
        errorMessage: null,
        successMessage: null,
      );
    }
  }
}

/// Provider for the CategoryRepository instance.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final repo = MockCategoryRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// NotifierProvider for category state.
final categoryProvider =
    NotifierProvider<CategoryNotifier, CategoryState>(
  CategoryNotifier.new,
);

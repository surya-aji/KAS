import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/data/repositories/mock_category_repository.dart';
import 'package:kas_usaha/features/catalog/domain/models/category.dart';
import 'package:kas_usaha/features/catalog/presentation/providers/category_provider.dart';

void main() {
  group('Category Domain Model', () {
    test('instantiates with defaults and converts color & icon accurately', () {
      final now = DateTime.now();
      final category = Category(
        id: 'test-cat-1',
        name: 'Makanan',
        createdAt: now,
      );

      expect(category.id, 'test-cat-1');
      expect(category.name, 'Makanan');
      expect(category.description, '');
      expect(category.colorHex, Category.defaultColorHex);
      expect(category.isActive, isTrue);
      expect(category.productCount, 0);
      expect(category.color, const Color(0xFF137547));
      expect(category.icon, Icons.category_rounded);
    });

    test('parses custom hex color codes and handles invalid fallback gracefully', () {
      final now = DateTime.now();
      final validCat = Category(
        id: '1',
        name: 'Test',
        colorHex: '#0D9488',
        createdAt: now,
      );
      expect(validCat.color, const Color(0xFF0D9488));

      final invalidCat = Category(
        id: '2',
        name: 'Invalid',
        colorHex: 'NOT_A_HEX',
        createdAt: now,
      );
      expect(invalidCat.color, isNotNull); // falls back to primary500
    });

    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime(2026, 10, 29, 10, 0, 0);
      final category = Category(
        id: 'cat-uuid-1',
        name: 'Kopi & Minuman',
        description: 'Aneka minuman segar',
        colorHex: '#2563EB',
        iconCodePoint: Icons.local_cafe_rounded.codePoint,
        productCount: 15,
        isActive: true,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      final map = category.toMap();
      expect(map['id'], 'cat-uuid-1');
      expect(map['name'], 'Kopi & Minuman');
      expect(map['description'], 'Aneka minuman segar');
      expect(map['color_hex'], '#2563EB');
      expect(map['icon_code_point'], Icons.local_cafe_rounded.codePoint);
      expect(map['product_count'], 15);
      expect(map['is_active'], 1);
      expect(map['created_at'], now.toIso8601String());

      final reconstituted = Category.fromMap(map);
      expect(reconstituted, equals(category));
    });

    test('copyWith modifies attributes properly', () {
      final now = DateTime.now();
      final original = Category(
        id: '1',
        name: 'Original',
        createdAt: now,
      );

      final modified = original.copyWith(
        name: 'Updated',
        productCount: 10,
        isActive: false,
      );

      expect(modified.id, '1');
      expect(modified.name, 'Updated');
      expect(modified.productCount, 10);
      expect(modified.isActive, isFalse);
    });
  });

  group('MockCategoryRepository CRUD', () {
    late MockCategoryRepository repository;

    setUp(() {
      repository = MockCategoryRepository(
        initialCategories: [
          Category(
            id: 'c1',
            name: 'Makanan',
            productCount: 5,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Category(
            id: 'c2',
            name: 'Minuman',
            productCount: 0,
            isActive: false,
            createdAt: DateTime.now(),
          ),
        ],
      );
    });

    tearDown(() {
      repository.dispose();
    });

    test('getCategories returns all categories or activeOnly', () async {
      final all = await repository.getCategories();
      expect(all.length, 2);

      final activeOnly = await repository.getCategories(activeOnly: true);
      expect(activeOnly.length, 1);
      expect(activeOnly.first.id, 'c1');
    });

    test('getCategoryById returns matching category', () async {
      final item = await repository.getCategoryById('c1');
      expect(item, isNotNull);
      expect(item!.name, 'Makanan');

      final notFound = await repository.getCategoryById('non-existent');
      expect(notFound, isNull);
    });

    test('createCategory, updateCategory, and deleteCategory update state', () async {
      final newCat = Category(
        id: 'c3',
        name: 'Snack',
        createdAt: DateTime.now(),
      );
      await repository.createCategory(newCat);

      var list = await repository.getCategories();
      expect(list.length, 3);
      expect(list.any((c) => c.id == 'c3'), isTrue);

      final updatedCat = newCat.copyWith(name: 'Snack Gurih');
      await repository.updateCategory(updatedCat);

      final fetched = await repository.getCategoryById('c3');
      expect(fetched!.name, 'Snack Gurih');

      await repository.deleteCategory('c3');
      list = await repository.getCategories();
      expect(list.length, 2);
      expect(list.any((c) => c.id == 'c3'), isFalse);
    });
  });

  group('CategoryNotifier & Riverpod State', () {
    late ProviderContainer container;
    late MockCategoryRepository mockRepo;

    setUp(() {
      mockRepo = MockCategoryRepository(
        initialCategories: [
          Category(
            id: 'cat-1',
            name: 'Makanan Berat',
            description: 'Nasi goreng dan lauk',
            productCount: 5,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Category(
            id: 'cat-2',
            name: 'Minuman Segar',
            description: 'Es teh dan kopi',
            productCount: 0,
            isActive: true,
            createdAt: DateTime.now(),
          ),
          Category(
            id: 'cat-3',
            name: 'Bahan Baku',
            description: 'Beras dan minyak',
            productCount: 2,
            isActive: false,
            createdAt: DateTime.now(),
          ),
        ],
      );

      container = ProviderContainer(
        overrides: [
          categoryRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      mockRepo.dispose();
    });

    test('loadCategories populates categories list and computes metrics', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      final state = container.read(categoryProvider);
      expect(state.status, CategoryStatus.loaded);
      expect(state.categories.length, 3);
      expect(state.totalCount, 3);
      expect(state.activeCount, 2);
      expect(state.inactiveCount, 1);
      expect(state.totalProductsCount, 7);
    });

    test('searchQuery filters categories reactively', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      notifier.setSearchQuery('kopi');
      var filtered = container.read(categoryProvider).filteredCategories;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Minuman Segar');

      notifier.setSearchQuery('berat');
      filtered = container.read(categoryProvider).filteredCategories;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Makanan Berat');

      notifier.setSearchQuery('');
      filtered = container.read(categoryProvider).filteredCategories;
      expect(filtered.length, 3);
    });

    test('filter chips correctly separate active and inactive categories', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      notifier.setFilter(CategoryFilter.active);
      var filtered = container.read(categoryProvider).filteredCategories;
      expect(filtered.length, 2);

      notifier.setFilter(CategoryFilter.inactive);
      filtered = container.read(categoryProvider).filteredCategories;
      expect(filtered.length, 1);
      expect(filtered.first.name, 'Bahan Baku');
    });

    test('createCategory validates empty name and duplicates', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      // Empty name
      final emptyResult = await notifier.createCategory(name: '   ');
      expect(emptyResult, isFalse);
      expect(container.read(categoryProvider).hasError, isTrue);
      expect(
        container.read(categoryProvider).errorMessage,
        'Nama kategori wajib diisi.',
      );

      // Duplicate name (case insensitive)
      final duplicateResult = await notifier.createCategory(
        name: 'makanan berat',
      );
      expect(duplicateResult, isFalse);
      expect(container.read(categoryProvider).hasError, isTrue);
      expect(
        container.read(categoryProvider).errorMessage,
        contains('sudah ada'),
      );
    });

    test('createCategory adds new category on valid data', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      final success = await notifier.createCategory(
        name: 'Paket Promo',
        description: 'Menu bundling hemat',
        colorHex: '#2563EB',
      );

      expect(success, isTrue);
      final state = container.read(categoryProvider);
      expect(state.status, CategoryStatus.success);
      expect(state.categories.length, 4);
      expect(state.categories.any((c) => c.name == 'Paket Promo'), isTrue);
    });

    test('updateCategory modifies category and prevents duplicate name collision', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      final existing = container.read(categoryProvider).categories.first;

      // Duplicate name collision with another category
      final duplicateFail = await notifier.updateCategory(
        existing.copyWith(name: 'Minuman Segar'),
      );
      expect(duplicateFail, isFalse);
      expect(container.read(categoryProvider).hasError, isTrue);

      // Valid update
      final validUpdate = await notifier.updateCategory(
        existing.copyWith(name: 'Makanan Nusantara'),
      );
      expect(validUpdate, isTrue);
      final updatedCat = container
          .read(categoryProvider)
          .categories
          .firstWhere((c) => c.id == existing.id);
      expect(updatedCat.name, 'Makanan Nusantara');
    });

    test('deleteCategory guards against deleting categories with products', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      // cat-1 has 5 products -> deletion blocked
      final blocked = await notifier.deleteCategory('cat-1');
      expect(blocked, isFalse);
      expect(container.read(categoryProvider).hasError, isTrue);
      expect(
        container.read(categoryProvider).errorMessage,
        contains('masih memuat 5 produk'),
      );

      // cat-2 has 0 products -> deletion allowed
      final allowed = await notifier.deleteCategory('cat-2');
      expect(allowed, isTrue);
      expect(container.read(categoryProvider).categories.length, 2);
    });

    test('toggleCategoryActive switches active state', () async {
      final notifier = container.read(categoryProvider.notifier);
      await notifier.loadCategories();

      final cat = container.read(categoryProvider).categories.first;
      expect(cat.isActive, isTrue);

      await notifier.toggleCategoryActive(cat);
      final toggled = container
          .read(categoryProvider)
          .categories
          .firstWhere((c) => c.id == cat.id);
      expect(toggled.isActive, isFalse);
    });
  });
}

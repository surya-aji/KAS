import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/inventory/data/repositories/mock_stock_movement_repository.dart';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/features/inventory/presentation/providers/stock_movement_provider.dart';

void main() {
  group('StockMovement Domain Model & Enum Tests', () {
    test('StockMovementType semantics and helper getters', () {
      expect(StockMovementType.sale.isPositive, isFalse);
      expect(StockMovementType.sale.displayName, 'Penjualan');
      expect(StockMovementType.sale.toStringValue(), 'sale');

      expect(StockMovementType.restock.isPositive, isTrue);
      expect(StockMovementType.restock.displayName, 'Restok Masuk');
      expect(StockMovementType.restock.toStringValue(), 'restock');

      expect(StockMovementType.adjustmentIn.isPositive, isTrue);
      expect(StockMovementType.adjustmentIn.displayName, 'Koreksi Tambah');

      expect(StockMovementType.adjustmentOut.isPositive, isFalse);
      expect(StockMovementType.adjustmentOut.displayName, 'Koreksi Kurang');

      expect(StockMovementType.damaged.isPositive, isFalse);
      expect(StockMovementType.damaged.displayName, 'Barang Rusak / Expired');

      expect(StockMovementType.returned.isPositive, isTrue);
      expect(StockMovementType.returned.displayName, 'Retur Penjualan');

      // Parsing from string
      expect(StockMovementType.fromString('sale'), StockMovementType.sale);
      expect(StockMovementType.fromString('restock'), StockMovementType.restock);
      expect(StockMovementType.fromString('in'), StockMovementType.restock);
      expect(StockMovementType.fromString('adjustment_in'), StockMovementType.adjustmentIn);
      expect(StockMovementType.fromString('adj_out'), StockMovementType.adjustmentOut);
      expect(StockMovementType.fromString('damaged'), StockMovementType.damaged);
      expect(StockMovementType.fromString('void'), StockMovementType.returned);
      expect(StockMovementType.fromString('unknown_value'), StockMovementType.sale);
    });

    test('StockMovement properties, signed quantity and formatting calculations', () {
      final now = DateTime(2026, 10, 29, 12, 30);
      final saleMovement = StockMovement(
        id: 'mov-1',
        productId: 'prd-01',
        productName: 'Nasi Goreng Spesial',
        productSku: 'MKN-001',
        unit: 'porsi',
        type: StockMovementType.sale,
        quantity: 5,
        previousStock: 40,
        currentStock: 35,
        referenceNumber: 'TRX-101',
        notes: 'Makan siang',
        createdAt: now,
      );

      expect(saleMovement.signedQuantity, -5);
      expect(saleMovement.formattedQuantity, '-5 porsi');
      expect(saleMovement.formattedStockTransition, '40 → 35 porsi');
      expect(saleMovement.formattedDate, isNotEmpty);

      final restockMovement = StockMovement(
        id: 'mov-2',
        productId: 'prd-03',
        productName: 'Kopi Susu Gula Aren',
        productSku: 'MNM-001',
        unit: 'cup',
        type: StockMovementType.restock,
        quantity: 25,
        previousStock: 10,
        currentStock: 35,
        referenceNumber: 'PO-202',
        notes: 'Restok mingguan',
        createdAt: now,
      );

      expect(restockMovement.signedQuantity, 25);
      expect(restockMovement.formattedQuantity, '+25 cup');
      expect(restockMovement.formattedStockTransition, '10 → 35 cup');
    });

    test('StockMovement serialization toMap and fromMap preserves all fields', () {
      final now = DateTime(2026, 10, 29, 14, 0);
      final original = StockMovement(
        id: 'mov-test',
        productId: 'prd-02',
        productName: 'Mie Goreng Seafood',
        productSku: 'MKN-002',
        unit: 'porsi',
        type: StockMovementType.damaged,
        quantity: 2,
        previousStock: 6,
        currentStock: 4,
        referenceNumber: 'ADJ-001',
        notes: 'Bahan rusak',
        createdAt: now,
      );

      final map = original.toMap();
      expect(map['id'], 'mov-test');
      expect(map['type'], 'damaged');
      expect(map['quantity'], 2);

      final restored = StockMovement.fromMap(map);
      expect(restored.id, original.id);
      expect(restored.productId, original.productId);
      expect(restored.productName, original.productName);
      expect(restored.productSku, original.productSku);
      expect(restored.type, StockMovementType.damaged);
      expect(restored.quantity, 2);
      expect(restored.previousStock, 6);
      expect(restored.currentStock, 4);
      expect(restored.referenceNumber, 'ADJ-001');
      expect(restored.notes, 'Bahan rusak');
    });

    test('StockMovement copyWith maintains immutability and updates specific fields', () {
      final original = StockMovement(
        id: 'mov-1',
        productId: 'prd-01',
        productName: 'Produk A',
        type: StockMovementType.sale,
        quantity: 3,
        previousStock: 10,
        currentStock: 7,
        createdAt: DateTime(2026, 10, 20),
      );

      final copy = original.copyWith(
        notes: 'Catatan tambahan',
        currentStock: 5,
      );

      expect(copy.id, original.id);
      expect(copy.productName, original.productName);
      expect(copy.notes, 'Catatan tambahan');
      expect(copy.currentStock, 5);
      expect(original.notes, '');
      expect(original.currentStock, 7);
    });

    test('StockMovement initialMovements contains realistic dummy history', () {
      final initial = StockMovement.initialMovements();
      expect(initial, isNotEmpty);
      expect(initial.length, greaterThanOrEqualTo(8));
      expect(initial.any((m) => m.type == StockMovementType.sale), isTrue);
      expect(initial.any((m) => m.type == StockMovementType.restock), isTrue);
      expect(initial.any((m) => m.type == StockMovementType.damaged), isTrue);
      expect(initial.any((m) => m.type == StockMovementType.returned), isTrue);
    });
  });

  group('MockStockMovementRepository Tests', () {
    late MockStockMovementRepository repository;

    setUp(() {
      repository = MockStockMovementRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('getStockMovements retrieves all items and filters by product/type', () async {
      final all = await repository.getStockMovements();
      expect(all, isNotEmpty);

      final product1Movements = await repository.getStockMovements(
        productId: 'prd-01',
      );
      expect(product1Movements, isNotEmpty);
      expect(product1Movements.every((m) => m.productId == 'prd-01'), isTrue);

      final salesOnly = await repository.getStockMovements(
        type: StockMovementType.sale,
      );
      expect(salesOnly, isNotEmpty);
      expect(salesOnly.every((m) => m.type == StockMovementType.sale), isTrue);
    });

    test('getMovementById returns movement when found, null when absent', () async {
      final first = (await repository.getStockMovements()).first;
      final found = await repository.getMovementById(first.id);
      expect(found, isNotNull);
      expect(found?.id, first.id);

      final notFound = await repository.getMovementById('non_existent_id');
      expect(notFound, isNull);
    });

    test('addStockMovement inserts new log at beginning of history', () async {
      final newMovement = StockMovement(
        id: 'new-mov-001',
        productId: 'prd-05',
        productName: 'Kentang Goreng Keju',
        type: StockMovementType.restock,
        quantity: 10,
        previousStock: 25,
        currentStock: 35,
        referenceNumber: 'PO-TEST',
        createdAt: DateTime.now(),
      );

      await repository.addStockMovement(newMovement);
      final all = await repository.getStockMovements();
      expect(all.first.id, 'new-mov-001');
      expect(all.first.quantity, 10);
    });

    test('watchStockMovements emits reactive stream updates', () async {
      final stream = repository.watchStockMovements();
      expect(
        stream,
        emits(isA<List<StockMovement>>()),
      );
    });
  });

  group('StockMovementNotifier & State Management Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state starts as initial and empty', () {
      final state = container.read(stockMovementProvider);
      expect(state.status, StockMovementStatus.initial);
      expect(state.movements, isEmpty);
      expect(state.selectedProductId, isNull);
      expect(state.selectedType, isNull);
      expect(state.selectedDateFilter, StockDateFilter.all);
    });

    test('loadStockMovements loads history from repository', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      final state = container.read(stockMovementProvider);
      expect(state.status, StockMovementStatus.loaded);
      expect(state.movements, isNotEmpty);
      expect(state.totalMovementsCount, greaterThan(0));
      expect(state.totalItemsIn, greaterThan(0));
      expect(state.totalItemsOut, greaterThan(0));
    });

    test('setProductFilter filters movements for specific product and recalculates metrics', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      notifier.setProductFilter('prd-01');
      var state = container.read(stockMovementProvider);
      expect(state.selectedProductId, 'prd-01');
      expect(state.hasActiveFilters, isTrue);
      expect(state.filteredMovements.every((m) => m.productId == 'prd-01'), isTrue);

      // Clearing product filter restores all products
      notifier.setProductFilter(null);
      state = container.read(stockMovementProvider);
      expect(state.selectedProductId, isNull);
      expect(state.filteredMovements.length, state.movements.length);
    });

    test('setTypeFilter filters movements by type', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      notifier.setTypeFilter(StockMovementType.sale);
      var state = container.read(stockMovementProvider);
      expect(state.selectedType, StockMovementType.sale);
      expect(state.filteredMovements.every((m) => m.type == StockMovementType.sale), isTrue);

      notifier.setTypeFilter(null);
      state = container.read(stockMovementProvider);
      expect(state.selectedType, isNull);
    });

    test('setSearchQuery searches by reference, notes, or product name', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      notifier.setSearchQuery('kopi');
      var state = container.read(stockMovementProvider);
      expect(state.filteredMovements.every((m) =>
          m.productName.toLowerCase().contains('kopi') ||
          m.notes.toLowerCase().contains('kopi')), isTrue);

      notifier.setSearchQuery('TRX');
      state = container.read(stockMovementProvider);
      expect(
        state.filteredMovements.every((m) =>
            m.referenceNumber.toLowerCase().contains('trx') ||
            m.notes.toLowerCase().contains('trx')),
        isTrue,
      );
    });

    test('resetFilters clears all active filters and query', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      notifier.setProductFilter('prd-02');
      notifier.setTypeFilter(StockMovementType.damaged);
      notifier.setDateFilter(StockDateFilter.today);
      notifier.setSearchQuery('udang');

      var state = container.read(stockMovementProvider);
      expect(state.hasActiveFilters, isTrue);

      notifier.resetFilters();
      state = container.read(stockMovementProvider);
      expect(state.selectedProductId, isNull);
      expect(state.selectedType, isNull);
      expect(state.selectedDateFilter, StockDateFilter.all);
      expect(state.searchQuery, isEmpty);
      expect(state.hasActiveFilters, isFalse);
    });

    test('recordMovement creates new stock movement log successfully', () async {
      final notifier = container.read(stockMovementProvider.notifier);
      await notifier.loadStockMovements();

      final success = await notifier.recordMovement(
        productId: 'prd-01',
        productName: 'Nasi Goreng Spesial',
        productSku: 'MKN-001',
        unit: 'porsi',
        type: StockMovementType.restock,
        quantity: 50,
        previousStock: 35,
        currentStock: 85,
        referenceNumber: 'PO-NEW-01',
        notes: 'Restok beras dan ayam',
      );

      expect(success, isTrue);
      final state = container.read(stockMovementProvider);
      expect(state.status, StockMovementStatus.success);
      expect(state.movements.first.referenceNumber, 'PO-NEW-01');
      expect(state.movements.first.quantity, 50);
      expect(state.successMessage, isNotNull);

      notifier.clearFeedback();
      expect(container.read(stockMovementProvider).status, StockMovementStatus.loaded);
    });
  });
}

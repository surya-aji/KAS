import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/features/inventory/data/repositories/mock_stock_movement_repository.dart';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/features/inventory/domain/repositories/stock_movement_repository.dart';
import 'package:uuid/uuid.dart';

/// Status lifecycle for stock movement presentation operations.
enum StockMovementStatus {
  initial,
  loading,
  loaded,
  saving,
  success,
  error,
}

/// Date range filter options for stock audit logs.
enum StockDateFilter {
  all,
  today,
  thisWeek,
  thisMonth;

  String get displayName {
    switch (this) {
      case StockDateFilter.all:
        return 'Semua Waktu';
      case StockDateFilter.today:
        return 'Hari Ini';
      case StockDateFilter.thisWeek:
        return '7 Hari Terakhir';
      case StockDateFilter.thisMonth:
        return 'Bulan Ini';
    }
  }

  /// Evaluates whether a target [DateTime] satisfies this date condition.
  bool matches(DateTime dateTime) {
    final now = DateTime.now();
    final localTarget = dateTime.toLocal();

    switch (this) {
      case StockDateFilter.all:
        return true;
      case StockDateFilter.today:
        return localTarget.year == now.year &&
            localTarget.month == now.month &&
            localTarget.day == now.day;
      case StockDateFilter.thisWeek:
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        return localTarget.isAfter(sevenDaysAgo) ||
            (localTarget.year == now.year &&
                localTarget.month == now.month &&
                localTarget.day == now.day);
      case StockDateFilter.thisMonth:
        return localTarget.year == now.year && localTarget.month == now.month;
    }
  }
}

/// State representation for inventory stock movement logs.
class StockMovementState {
  const StockMovementState({
    required this.status,
    required this.movements,
    this.selectedProductId,
    this.selectedType,
    this.selectedDateFilter = StockDateFilter.all,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  final StockMovementStatus status;
  final List<StockMovement> movements;
  final String? selectedProductId;
  final StockMovementType? selectedType;
  final StockDateFilter selectedDateFilter;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading => status == StockMovementStatus.loading;
  bool get isSaving => status == StockMovementStatus.saving;
  bool get hasError => status == StockMovementStatus.error;

  /// Returns movements matching product filter, type filter, date filter, and search query.
  List<StockMovement> get filteredMovements {
    return movements.where((item) {
      // 1. Product Filter
      if (selectedProductId != null &&
          selectedProductId!.isNotEmpty &&
          item.productId != selectedProductId) {
        return false;
      }

      // 2. Movement Type Filter
      if (selectedType != null && item.type != selectedType) {
        return false;
      }

      // 3. Date Range Filter
      if (!selectedDateFilter.matches(item.createdAt)) {
        return false;
      }

      // 4. Search Query Filter (Matches product name, SKU, reference, notes)
      if (searchQuery.trim().isEmpty) return true;

      final query = searchQuery.trim().toLowerCase();
      final nameMatches = item.productName.toLowerCase().contains(query);
      final skuMatches = item.productSku.toLowerCase().contains(query);
      final refMatches = item.referenceNumber.toLowerCase().contains(query);
      final notesMatches = item.notes.toLowerCase().contains(query);

      return nameMatches || skuMatches || refMatches || notesMatches;
    }).toList();
  }

  /// Total count of filtered movements.
  int get totalMovementsCount => filteredMovements.length;

  /// Total quantity of goods added into inventory across filtered items.
  int get totalItemsIn {
    return filteredMovements
        .where((m) => m.type.isPositive)
        .fold<int>(0, (sum, m) => sum + m.quantity);
  }

  /// Total quantity of goods deducted from inventory across filtered items.
  int get totalItemsOut {
    return filteredMovements
        .where((m) => !m.type.isPositive)
        .fold<int>(0, (sum, m) => sum + m.quantity);
  }

  /// Net balance change of inventory (items in - items out).
  int get netQuantityChange => totalItemsIn - totalItemsOut;

  /// Whether any active filter is applied.
  bool get hasActiveFilters =>
      selectedProductId != null ||
      selectedType != null ||
      selectedDateFilter != StockDateFilter.all ||
      searchQuery.trim().isNotEmpty;

  factory StockMovementState.initial() {
    return const StockMovementState(
      status: StockMovementStatus.initial,
      movements: [],
    );
  }

  StockMovementState copyWith({
    StockMovementStatus? status,
    List<StockMovement>? movements,
    String? selectedProductId,
    bool clearProduct = false,
    StockMovementType? selectedType,
    bool clearType = false,
    StockDateFilter? selectedDateFilter,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return StockMovementState(
      status: status ?? this.status,
      movements: movements ?? this.movements,
      selectedProductId:
          clearProduct ? null : (selectedProductId ?? this.selectedProductId),
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockMovementState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          movements == other.movements &&
          selectedProductId == other.selectedProductId &&
          selectedType == other.selectedType &&
          selectedDateFilter == other.selectedDateFilter &&
          searchQuery == other.searchQuery &&
          errorMessage == other.errorMessage &&
          successMessage == other.successMessage;

  @override
  int get hashCode =>
      status.hashCode ^
      movements.hashCode ^
      selectedProductId.hashCode ^
      selectedType.hashCode ^
      selectedDateFilter.hashCode ^
      searchQuery.hashCode ^
      errorMessage.hashCode ^
      successMessage.hashCode;
}

/// Riverpod Notifier managing inventory stock movement logs.
class StockMovementNotifier extends Notifier<StockMovementState> {
  static const _uuid = Uuid();

  @override
  StockMovementState build() {
    return StockMovementState.initial();
  }

  StockMovementRepository get _repository =>
      ref.read(stockMovementRepositoryProvider);

  /// Loads all stock movements from repository.
  Future<void> loadStockMovements({String? productId}) async {
    state = state.copyWith(status: StockMovementStatus.loading);
    try {
      final items = await _repository.getStockMovements();
      state = state.copyWith(
        status: StockMovementStatus.loaded,
        movements: items,
        selectedProductId: productId,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: StockMovementStatus.error,
        errorMessage: 'Gagal memuat riwayat stok: $e',
      );
    }
  }

  /// Sets product filter (pass null to show all products).
  void setProductFilter(String? productId) {
    if (productId == null || productId.isEmpty) {
      state = state.copyWith(clearProduct: true);
    } else {
      state = state.copyWith(selectedProductId: productId);
    }
  }

  /// Sets movement type filter (pass null to show all types).
  void setTypeFilter(StockMovementType? type) {
    if (type == null) {
      state = state.copyWith(clearType: true);
    } else {
      state = state.copyWith(selectedType: type);
    }
  }

  /// Sets date filter range.
  void setDateFilter(StockDateFilter filter) {
    state = state.copyWith(selectedDateFilter: filter);
  }

  /// Sets live search query string.
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Clears all active filters and search query.
  void resetFilters() {
    state = state.copyWith(
      clearProduct: true,
      clearType: true,
      selectedDateFilter: StockDateFilter.all,
      searchQuery: '',
    );
  }

  /// Records a new stock movement.
  Future<bool> recordMovement({
    required String productId,
    required String productName,
    String productSku = '',
    String unit = 'pcs',
    required StockMovementType type,
    required int quantity,
    required int previousStock,
    required int currentStock,
    String referenceNumber = '',
    String notes = '',
  }) async {
    state = state.copyWith(status: StockMovementStatus.saving);

    try {
      final newMovement = StockMovement(
        id: _uuid.v4(),
        productId: productId,
        productName: productName,
        productSku: productSku,
        unit: unit,
        type: type,
        quantity: quantity,
        previousStock: previousStock,
        currentStock: currentStock,
        referenceNumber: referenceNumber,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _repository.addStockMovement(newMovement);
      final updatedList = await _repository.getStockMovements();

      state = state.copyWith(
        status: StockMovementStatus.success,
        movements: updatedList,
        errorMessage: null,
        successMessage: 'Perubahan stok berhasil dicatat.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: StockMovementStatus.error,
        errorMessage: 'Gagal mencatat perubahan stok: $e',
      );
      return false;
    }
  }

  /// Clears transient feedback messages.
  void clearFeedback() {
    if (state.status == StockMovementStatus.success ||
        state.status == StockMovementStatus.error) {
      state = state.copyWith(
        status: StockMovementStatus.loaded,
        errorMessage: null,
        successMessage: null,
      );
    }
  }
}

/// Provider for [StockMovementRepository] dependency injection.
final stockMovementRepositoryProvider = Provider<StockMovementRepository>((ref) {
  final repo = MockStockMovementRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Riverpod NotifierProvider for accessing and mutating stock movements state.
final stockMovementProvider =
    NotifierProvider<StockMovementNotifier, StockMovementState>(
  StockMovementNotifier.new,
);

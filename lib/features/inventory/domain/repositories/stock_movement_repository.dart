import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';

/// Abstract contract for stock movement persistence operations.
///
/// Follows Clean Architecture to decouple UI / Riverpod state
/// from Drift SQLite tables (Sprint 0/1 specifications).
abstract class StockMovementRepository {
  /// Fetches all stock movement logs, optionally filtered by product ID or movement type.
  Future<List<StockMovement>> getStockMovements({
    String? productId,
    StockMovementType? type,
  });

  /// Fetches a single stock movement log by its unique ID.
  Future<StockMovement?> getMovementById(String id);

  /// Records a new stock movement log in the persistence store.
  Future<void> addStockMovement(StockMovement movement);

  /// Emits real-time updates whenever stock movements are added or modified.
  Stream<List<StockMovement>> watchStockMovements({
    String? productId,
    StockMovementType? type,
  });
}

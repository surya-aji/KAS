import 'dart:async';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/features/inventory/domain/repositories/stock_movement_repository.dart';

/// In-memory mock implementation of [StockMovementRepository]
/// for the Frontend-First development milestone (T1.5).
///
/// Prepares realistic dummy stock log entries, filtering, and responsive streams.
class MockStockMovementRepository implements StockMovementRepository {
  MockStockMovementRepository({List<StockMovement>? initialMovements})
      : _movements = List<StockMovement>.from(
          initialMovements ?? StockMovement.initialMovements(),
        ) {
    _streamController = StreamController<List<StockMovement>>.broadcast();
    _streamController.add(List.unmodifiable(_movements));
  }

  final List<StockMovement> _movements;
  late final StreamController<List<StockMovement>> _streamController;

  /// Synchronous access for testing purposes.
  List<StockMovement> get currentMovements => List.unmodifiable(_movements);

  void _notifyListeners() {
    if (!_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_movements));
    }
  }

  @override
  Future<List<StockMovement>> getStockMovements({
    String? productId,
    StockMovementType? type,
  }) async {
    return _movements.where((item) {
      if (productId != null &&
          productId.isNotEmpty &&
          item.productId != productId) {
        return false;
      }
      if (type != null && item.type != type) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<StockMovement?> getMovementById(String id) async {
    final index = _movements.indexWhere((m) => m.id == id);
    if (index != -1) return _movements[index];
    return null;
  }

  @override
  Future<void> addStockMovement(StockMovement movement) async {
    // Insert at beginning to keep newest-first chronological order
    _movements.insert(0, movement);
    _notifyListeners();
  }

  @override
  Stream<List<StockMovement>> watchStockMovements({
    String? productId,
    StockMovementType? type,
  }) async* {
    yield await getStockMovements(productId: productId, type: type);
    yield* _streamController.stream.map((list) {
      return list.where((item) {
        if (productId != null &&
            productId.isNotEmpty &&
            item.productId != productId) {
          return false;
        }
        if (type != null && item.type != type) {
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

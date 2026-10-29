import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/domain/validators/product_validator.dart';

void main() {
  group('ProductValidator - Selling Price Validation', () {
    test('rejects empty input with mandatory message', () {
      expect(
        ProductValidator.validateSellingPrice(0, rawText: ''),
        'Harga jual wajib diisi',
      );
      expect(
        ProductValidator.validateSellingPrice(0, rawText: '   '),
        'Harga jual wajib diisi',
      );
    });

    test('rejects zero or negative price', () {
      expect(
        ProductValidator.validateSellingPrice(0, rawText: '0'),
        'Harga jual harus lebih besar dari Rp 0',
      );
      expect(
        ProductValidator.validateSellingPrice(-1000, rawText: '-1000'),
        'Harga jual harus lebih besar dari Rp 0',
      );
      expect(
        ProductValidator.validateSellingPrice(null),
        'Harga jual harus lebih besar dari Rp 0',
      );
    });

    test('rejects prices exceeding maximum threshold', () {
      expect(
        ProductValidator.validateSellingPrice(1000000001, rawText: '1.000.000.001'),
        'Harga jual maksimal Rp 1.000.000.000',
      );
    });

    test('accepts valid price values within range', () {
      expect(
        ProductValidator.validateSellingPrice(1, rawText: '1'),
        isNull,
      );
      expect(
        ProductValidator.validateSellingPrice(25000, rawText: '25.000'),
        isNull,
      );
      expect(
        ProductValidator.validateSellingPrice(ProductValidator.maxPrice, rawText: '1.000.000.000'),
        isNull,
      );
    });
  });

  group('ProductValidator - Cost Price (HPP) Validation', () {
    test('accepts null, zero, or empty strings as optional', () {
      expect(ProductValidator.validateCostPrice(null), isNull);
      expect(ProductValidator.validateCostPrice(0), isNull);
      expect(ProductValidator.validateCostPrice(0, rawText: ''), isNull);
      expect(ProductValidator.validateCostPrice(0, rawText: '  '), isNull);
    });

    test('rejects negative cost price', () {
      expect(
        ProductValidator.validateCostPrice(-500, rawText: '-500'),
        'Harga modal tidak boleh kurang dari Rp 0',
      );
    });

    test('rejects cost prices exceeding maximum threshold', () {
      expect(
        ProductValidator.validateCostPrice(1000000001, rawText: '1.000.000.001'),
        'Harga modal maksimal Rp 1.000.000.000',
      );
    });

    test('accepts valid cost price values within range', () {
      expect(
        ProductValidator.validateCostPrice(15000, rawText: '15.000'),
        isNull,
      );
      expect(
        ProductValidator.validateCostPrice(ProductValidator.maxPrice),
        isNull,
      );
    });
  });

  group('ProductValidator - Stock Validation', () {
    test('bypasses validation when trackStock is false', () {
      expect(ProductValidator.validateStock(null, trackStock: false), isNull);
      expect(ProductValidator.validateStock('', trackStock: false), isNull);
      expect(ProductValidator.validateStock('-10', trackStock: false), isNull);
    });

    test('rejects null or empty stock when trackStock is true', () {
      expect(
        ProductValidator.validateStock(null, trackStock: true),
        'Jumlah stok wajib diisi',
      );
      expect(
        ProductValidator.validateStock('', trackStock: true),
        'Jumlah stok wajib diisi',
      );
      expect(
        ProductValidator.validateStock('   ', trackStock: true),
        'Jumlah stok wajib diisi',
      );
    });

    test('rejects non-integer stock values', () {
      expect(
        ProductValidator.validateStock('abc', trackStock: true),
        'Jumlah stok harus berupa angka bulat',
      );
      expect(
        ProductValidator.validateStock('12.5', trackStock: true),
        'Jumlah stok harus berupa angka bulat',
      );
    });

    test('rejects negative stock values', () {
      expect(
        ProductValidator.validateStock('-5', trackStock: true),
        'Jumlah stok tidak boleh kurang dari 0',
      );
    });

    test('rejects stock exceeding maximum threshold', () {
      expect(
        ProductValidator.validateStock('1000000', trackStock: true),
        'Jumlah stok maksimal 999.999',
      );
    });

    test('accepts valid stock values', () {
      expect(ProductValidator.validateStock('0', trackStock: true), isNull);
      expect(ProductValidator.validateStock('50', trackStock: true), isNull);
      expect(
        ProductValidator.validateStock(
          ProductValidator.maxStock.toString(),
          trackStock: true,
        ),
        isNull,
      );
    });
  });

  group('ProductValidator - Minimum Stock Threshold Validation', () {
    test('bypasses validation when trackStock is false', () {
      expect(ProductValidator.validateMinStock(null, trackStock: false), isNull);
      expect(ProductValidator.validateMinStock('', trackStock: false), isNull);
      expect(ProductValidator.validateMinStock('-5', trackStock: false), isNull);
    });

    test('rejects null or empty min stock when trackStock is true', () {
      expect(
        ProductValidator.validateMinStock(null, trackStock: true),
        'Batas stok minimum wajib diisi',
      );
      expect(
        ProductValidator.validateMinStock('', trackStock: true),
        'Batas stok minimum wajib diisi',
      );
    });

    test('rejects non-integer min stock values', () {
      expect(
        ProductValidator.validateMinStock('xyz', trackStock: true),
        'Batas stok minimum harus berupa angka bulat',
      );
      expect(
        ProductValidator.validateMinStock('3.14', trackStock: true),
        'Batas stok minimum harus berupa angka bulat',
      );
    });

    test('rejects negative min stock values', () {
      expect(
        ProductValidator.validateMinStock('-1', trackStock: true),
        'Batas stok minimum tidak boleh kurang dari 0',
      );
    });

    test('rejects min stock exceeding maximum threshold', () {
      expect(
        ProductValidator.validateMinStock('1000000', trackStock: true),
        'Batas stok minimum maksimal 999.999',
      );
    });

    test('accepts valid min stock values', () {
      expect(ProductValidator.validateMinStock('0', trackStock: true), isNull);
      expect(ProductValidator.validateMinStock('5', trackStock: true), isNull);
      expect(
        ProductValidator.validateMinStock(
          ProductValidator.maxStock.toString(),
          trackStock: true,
        ),
        isNull,
      );
    });
  });

  group('ProductValidator - Business Logic Helpers', () {
    test('isPotentialLoss correctly flags negative margin conditions', () {
      // Cost price higher than selling price -> potential loss
      expect(ProductValidator.isPotentialLoss(10000, 15000), isTrue);

      // Cost price equal or less than selling price -> no loss
      expect(ProductValidator.isPotentialLoss(15000, 10000), isFalse);
      expect(ProductValidator.isPotentialLoss(10000, 10000), isFalse);

      // Cost price 0 (not set) -> no loss warning
      expect(ProductValidator.isPotentialLoss(10000, 0), isFalse);
    });

    test('evaluateStockStatus correctly determines stock status levels', () {
      // When tracking is disabled
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: false,
          stock: 0,
          minStock: 5,
        ),
        ProductStockLevel.notTracked,
      );

      // Depleted stock (zero or below)
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: 0,
          minStock: 5,
        ),
        ProductStockLevel.outOfStock,
      );
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: -1,
          minStock: 5,
        ),
        ProductStockLevel.outOfStock,
      );

      // Low stock warning (stock non-zero and <= minStock)
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: 3,
          minStock: 5,
        ),
        ProductStockLevel.lowStock,
      );
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: 5,
          minStock: 5,
        ),
        ProductStockLevel.lowStock,
      );

      // Sufficient stock (> minStock)
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: 6,
          minStock: 5,
        ),
        ProductStockLevel.inStock,
      );
      expect(
        ProductValidator.evaluateStockStatus(
          trackStock: true,
          stock: 100,
          minStock: 5,
        ),
        ProductStockLevel.inStock,
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/pos/domain/models/cart_item.dart';
import 'package:kas_usaha/features/pos/domain/models/discount_type.dart';
import 'package:kas_usaha/features/pos/domain/services/transaction_calculator.dart';

void main() {
  group('TransactionCalculator Unit Tests (Task T2.3)', () {
    final testProduct1 = Product(
      id: 'p-1',
      categoryId: 'c-food',
      categoryName: 'Makanan',
      sku: 'MKN-01',
      barcode: '111',
      name: 'Nasi Goreng Spesial',
      sellingPrice: 25000,
      costPrice: 15000,
      stock: 10,
      trackStock: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    final testProduct2 = Product(
      id: 'p-2',
      categoryId: 'c-drink',
      categoryName: 'Minuman',
      sku: 'MNM-01',
      barcode: '222',
      name: 'Es Teh Manis',
      sellingPrice: 5000,
      costPrice: 2000,
      stock: 20,
      trackStock: true,
      isActive: true,
      createdAt: DateTime.now(),
    );

    test('Empty cart returns all zero amounts and respects input parameters', () {
      final calc = TransactionCalculator.calculate(
        cartItems: const [],
        transactionDiscountType: DiscountType.percentage,
        transactionDiscountValue: 10.0,
        isTaxEnabled: true,
        taxRate: 11.0,
      );

      expect(calc.totalQuantity, 0);
      expect(calc.grossSubtotal, 0);
      expect(calc.itemDiscounts, 0);
      expect(calc.subtotalAfterItemDiscounts, 0);
      expect(calc.transactionDiscountAmount, 0);
      expect(calc.totalDiscounts, 0);
      expect(calc.taxableAmount, 0);
      expect(calc.taxAmount, 0);
      expect(calc.grandTotal, 0);
      expect(calc.formattedGrandTotal, 'Rp0');
    });

    test('Standard calculation without discounts or tax matches gross subtotal', () {
      final items = [
        CartItem(product: testProduct1, quantity: 2), // 25.000 * 2 = 50.000
        CartItem(product: testProduct2, quantity: 3), // 5.000 * 3 = 15.000
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        isTaxEnabled: false,
      );

      expect(calc.totalQuantity, 5);
      expect(calc.grossSubtotal, 65000);
      expect(calc.itemDiscounts, 0);
      expect(calc.subtotalAfterItemDiscounts, 65000);
      expect(calc.transactionDiscountAmount, 0);
      expect(calc.totalDiscounts, 0);
      expect(calc.taxableAmount, 65000);
      expect(calc.taxAmount, 0);
      expect(calc.grandTotal, 65000);
      expect(calc.formattedGrossSubtotal, 'Rp65.000');
      expect(calc.formattedGrandTotal, 'Rp65.000');
    });

    test('Item-level percentage discount calculates correctly with integer arithmetic', () {
      final items = [
        CartItem(
          product: testProduct1,
          quantity: 2, // Gross = 50.000
          discountType: DiscountType.percentage,
          discountValue: 10.0, // 10% of 50.000 = 5.000
        ),
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        isTaxEnabled: false,
      );

      expect(calc.grossSubtotal, 50000);
      expect(calc.itemDiscounts, 5000);
      expect(calc.subtotalAfterItemDiscounts, 45000);
      expect(calc.grandTotal, 45000);
      expect(items[0].discountDescription, 'Diskon 10%');
      expect(items[0].formattedSubtotal, 'Rp45.000');
    });

    test('Item-level fixed nominal discount calculates correctly', () {
      final items = [
        CartItem(
          product: testProduct1,
          quantity: 1, // Gross = 25.000
          discountType: DiscountType.fixed,
          discountValue: 3000.0, // Rp3.000
        ),
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        isTaxEnabled: false,
      );

      expect(calc.grossSubtotal, 25000);
      expect(calc.itemDiscounts, 3000);
      expect(calc.subtotalAfterItemDiscounts, 22000);
      expect(calc.grandTotal, 22000);
      expect(items[0].discountDescription, 'Diskon Rp3.000');
    });

    test('Item discount exceeding item gross amount is safely clamped to gross amount', () {
      final items = [
        CartItem(
          product: testProduct2,
          quantity: 1, // Gross = 5.000
          discountType: DiscountType.fixed,
          discountValue: 10000.0, // Rp10.000 (exceeds gross 5.000)
        ),
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        isTaxEnabled: false,
      );

      expect(calc.grossSubtotal, 5000);
      expect(calc.itemDiscounts, 5000);
      expect(calc.subtotalAfterItemDiscounts, 0);
      expect(calc.grandTotal, 0);
      expect(items[0].subtotal, 0);
    });

    test('Transaction-level percentage discount calculates on net item subtotal', () {
      final items = [
        CartItem(product: testProduct1, quantity: 2), // 50.000
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        transactionDiscountType: DiscountType.percentage,
        transactionDiscountValue: 10.0, // 10% of 50.000 = 5.000
        isTaxEnabled: false,
      );

      expect(calc.grossSubtotal, 50000);
      expect(calc.transactionDiscountAmount, 5000);
      expect(calc.totalDiscounts, 5000);
      expect(calc.taxableAmount, 45000);
      expect(calc.grandTotal, 45000);
      expect(calc.transactionDiscountLabel, 'Diskon Transaksi (10%)');
    });

    test('Transaction-level fixed nominal discount calculates correctly', () {
      final items = [
        CartItem(product: testProduct1, quantity: 2), // 50.000
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        transactionDiscountType: DiscountType.fixed,
        transactionDiscountValue: 15000.0, // Rp15.000
        isTaxEnabled: false,
      );

      expect(calc.grossSubtotal, 50000);
      expect(calc.transactionDiscountAmount, 15000);
      expect(calc.totalDiscounts, 15000);
      expect(calc.taxableAmount, 35000);
      expect(calc.grandTotal, 35000);
    });

    test('Combined item discounts, transaction discount, and PPN 11% tax pipeline', () {
      // 1. Item 1: 2 * 25.000 = 50.000, 10% item discount = 5.000 -> Net = 45.000
      // 2. Item 2: 1 * 5.000 = 5.000, no discount -> Net = 5.000
      // Net items subtotal = 50.000 (Gross = 55.000, Item discounts = 5.000)
      // 3. Transaction discount: 10% of 50.000 = 5.000
      // 4. Taxable base (DPP) = 50.000 - 5.000 = 45.000
      // 5. Tax (PPN 11%): 11% of 45.000 = 4.950
      // 6. Grand total = 45.000 + 4.950 = 49.950
      final items = [
        CartItem(
          product: testProduct1,
          quantity: 2,
          discountType: DiscountType.percentage,
          discountValue: 10.0,
        ),
        CartItem(
          product: testProduct2,
          quantity: 1,
        ),
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        transactionDiscountType: DiscountType.percentage,
        transactionDiscountValue: 10.0,
        isTaxEnabled: true,
        taxRate: 11.0,
      );

      expect(calc.totalQuantity, 3);
      expect(calc.grossSubtotal, 55000);
      expect(calc.itemDiscounts, 5000);
      expect(calc.subtotalAfterItemDiscounts, 50000);
      expect(calc.transactionDiscountAmount, 5000);
      expect(calc.totalDiscounts, 10000);
      expect(calc.taxableAmount, 45000);
      expect(calc.taxAmount, 4950);
      expect(calc.grandTotal, 49950);
      expect(calc.formattedGrossSubtotal, 'Rp55.000');
      expect(calc.formattedItemDiscounts, 'Rp5.000');
      expect(calc.formattedTransactionDiscountAmount, 'Rp5.000');
      expect(calc.formattedTotalDiscounts, 'Rp10.000');
      expect(calc.formattedTaxableAmount, 'Rp45.000');
      expect(calc.formattedTaxAmount, 'Rp4.950');
      expect(calc.formattedGrandTotal, 'Rp49.950');
    });

    test('100% total discount yields zero tax and zero grand total', () {
      final items = [
        CartItem(product: testProduct1, quantity: 2), // 50.000
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        transactionDiscountType: DiscountType.percentage,
        transactionDiscountValue: 100.0,
        isTaxEnabled: true,
        taxRate: 11.0,
      );

      expect(calc.grossSubtotal, 50000);
      expect(calc.transactionDiscountAmount, 50000);
      expect(calc.taxableAmount, 0);
      expect(calc.taxAmount, 0);
      expect(calc.grandTotal, 0);
    });

    test('Negative discount inputs are cleanly clamped to 0', () {
      final items = [
        CartItem(
          product: testProduct1,
          quantity: 1,
          discountType: DiscountType.percentage,
          discountValue: -15.0, // Invalid negative
        ),
      ];

      final calc = TransactionCalculator.calculate(
        cartItems: items,
        transactionDiscountType: DiscountType.fixed,
        transactionDiscountValue: -5000.0, // Invalid negative
        isTaxEnabled: false,
      );

      expect(calc.itemDiscounts, 0);
      expect(calc.transactionDiscountAmount, 0);
      expect(calc.grandTotal, 25000);
    });
  });
}

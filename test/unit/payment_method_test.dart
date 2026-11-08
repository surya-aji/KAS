import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/catalog/domain/models/product.dart';
import 'package:kas_usaha/features/pos/pos.dart';

void main() {
  group('PaymentMethodType Enum Tests (Task T2.4)', () {
    test('Enum values have correct labels, icons, codes, and helper flags', () {
      expect(PaymentMethodType.cash.code, 'tunai');
      expect(PaymentMethodType.cash.name, 'Tunai');
      expect(PaymentMethodType.cash.label, 'Tunai (Cash)');
      expect(PaymentMethodType.cash.icon, Icons.payments_rounded);
      expect(PaymentMethodType.cash.isCash, isTrue);
      expect(PaymentMethodType.cash.isTransfer, isFalse);
      expect(PaymentMethodType.cash.isQris, isFalse);

      expect(PaymentMethodType.transfer.code, 'transfer');
      expect(PaymentMethodType.transfer.name, 'Transfer');
      expect(PaymentMethodType.transfer.label, 'Transfer Bank');
      expect(PaymentMethodType.transfer.icon, Icons.account_balance_rounded);
      expect(PaymentMethodType.transfer.isCash, isFalse);
      expect(PaymentMethodType.transfer.isTransfer, isTrue);
      expect(PaymentMethodType.transfer.isQris, isFalse);

      expect(PaymentMethodType.qris.code, 'qris');
      expect(PaymentMethodType.qris.name, 'QRIS');
      expect(PaymentMethodType.qris.label, 'QRIS Digital');
      expect(PaymentMethodType.qris.icon, Icons.qr_code_scanner_rounded);
      expect(PaymentMethodType.qris.isCash, isFalse);
      expect(PaymentMethodType.qris.isTransfer, isFalse);
      expect(PaymentMethodType.qris.isQris, isTrue);
    });

    test('fromCode parses valid codes and handles aliases & fallbacks', () {
      expect(PaymentMethodType.fromCode('tunai'), PaymentMethodType.cash);
      expect(PaymentMethodType.fromCode('cash'), PaymentMethodType.cash);
      expect(PaymentMethodType.fromCode('CASH'), PaymentMethodType.cash);
      expect(PaymentMethodType.fromCode('transfer'), PaymentMethodType.transfer);
      expect(PaymentMethodType.fromCode('bank_transfer'), PaymentMethodType.transfer);
      expect(PaymentMethodType.fromCode('qris'), PaymentMethodType.qris);
      expect(PaymentMethodType.fromCode('QRIS'), PaymentMethodType.qris);
      expect(PaymentMethodType.fromCode('unknown'), PaymentMethodType.cash);
      expect(PaymentMethodType.fromCode(null), PaymentMethodType.cash);
    });
  });

  group('QuickCashHelper Tests (Task T2.4)', () {
    test('generateSuggestions includes exact amount first and standard denominations', () {
      final suggestions = QuickCashHelper.generateSuggestions(35000);
      expect(suggestions.first, 35000); // Uang pas
      expect(suggestions.contains(40000), isTrue); // Round up
      expect(suggestions.contains(50000), isTrue);
      expect(suggestions.contains(100000), isTrue);
      expect(suggestions.length, lessThanOrEqualTo(5));

      // Must be sorted in ascending order
      for (int i = 0; i < suggestions.length - 1; i++) {
        expect(suggestions[i], lessThanOrEqualTo(suggestions[i + 1]));
      }
    });

    test('generateSuggestions handles 0 or negative gracefully', () {
      final suggestions = QuickCashHelper.generateSuggestions(0);
      expect(suggestions, isNotEmpty);
      expect(suggestions.contains(10000), isTrue);
      expect(suggestions.contains(50000), isTrue);
    });

    test('generateSuggestions for exact banknote like 50000', () {
      final suggestions = QuickCashHelper.generateSuggestions(50000);
      expect(suggestions.first, 50000);
      expect(suggestions.contains(100000), isTrue);
    });
  });

  group('PaymentResult Domain Model Tests (Task T2.4)', () {
    test('Calculates exact cash payment change accurately', () {
      final result = PaymentResult(
        method: PaymentMethodType.cash,
        totalPayable: 50000,
        amountPaid: 50000,
      );

      expect(result.changeAmount, 0);
      expect(result.isSufficient, isTrue);
      expect(result.isExactAmount, isTrue);
      expect(result.shortageAmount, 0);
      expect(result.formattedTotalPayable, 'Rp50.000');
      expect(result.formattedAmountPaid, 'Rp50.000');
      expect(result.formattedChangeAmount, 'Rp0');
      expect(result.formattedShortageAmount, 'Rp0');
    });

    test('Calculates cash overpayment change accurately', () {
      final result = PaymentResult(
        method: PaymentMethodType.cash,
        totalPayable: 35000,
        amountPaid: 50000,
      );

      expect(result.changeAmount, 15000);
      expect(result.isSufficient, isTrue);
      expect(result.isExactAmount, isFalse);
      expect(result.shortageAmount, 0);
      expect(result.formattedTotalPayable, 'Rp35.000');
      expect(result.formattedAmountPaid, 'Rp50.000');
      expect(result.formattedChangeAmount, 'Rp15.000');
    });

    test('Calculates cash underpayment / shortage accurately', () {
      final result = PaymentResult(
        method: PaymentMethodType.cash,
        totalPayable: 50000,
        amountPaid: 30000,
      );

      expect(result.changeAmount, 0);
      expect(result.isSufficient, isFalse);
      expect(result.isExactAmount, isFalse);
      expect(result.shortageAmount, 20000);
      expect(result.formattedShortageAmount, 'Rp20.000');
    });

    test('Bank Transfer and QRIS record reference numbers and bank name', () {
      final transferResult = PaymentResult(
        method: PaymentMethodType.transfer,
        totalPayable: 75000,
        amountPaid: 75000,
        bankName: 'BCA',
        referenceNumber: 'TRF-123456',
        note: 'Transfer via BCA',
      );

      expect(transferResult.method, PaymentMethodType.transfer);
      expect(transferResult.bankName, 'BCA');
      expect(transferResult.referenceNumber, 'TRF-123456');
      expect(transferResult.isSufficient, isTrue);

      final qrisResult = PaymentResult(
        method: PaymentMethodType.qris,
        totalPayable: 88000,
        amountPaid: 88000,
        referenceNumber: 'RRN-987654',
      );

      expect(qrisResult.method, PaymentMethodType.qris);
      expect(qrisResult.referenceNumber, 'RRN-987654');
    });

    test('Serialization toMap and fromMap roundtrip preserves all attributes', () {
      final original = PaymentResult(
        id: 'pay-001',
        method: PaymentMethodType.transfer,
        totalPayable: 120000,
        amountPaid: 120000,
        changeAmount: 0,
        bankName: 'Mandiri',
        referenceNumber: 'REF-888',
        note: 'Pembayaran catering',
        timestamp: DateTime(2026, 11, 8, 10, 0),
      );

      final map = original.toMap();
      final restored = PaymentResult.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.method, original.method);
      expect(restored.totalPayable, original.totalPayable);
      expect(restored.amountPaid, original.amountPaid);
      expect(restored.changeAmount, original.changeAmount);
      expect(restored.bankName, original.bankName);
      expect(restored.referenceNumber, original.referenceNumber);
      expect(restored.note, original.note);
      expect(restored.timestamp, original.timestamp);
      expect(restored, equals(original));
    });

    test('copyWith updates specified fields and retains others', () {
      final original = PaymentResult(
        id: 'pay-1',
        method: PaymentMethodType.cash,
        totalPayable: 50000,
        amountPaid: 50000,
      );

      final modified = original.copyWith(
        amountPaid: 100000,
        changeAmount: 50000,
        note: 'Pecahan 100k',
      );

      expect(modified.id, 'pay-1');
      expect(modified.amountPaid, 100000);
      expect(modified.changeAmount, 50000);
      expect(modified.note, 'Pecahan 100k');
      expect(modified.totalPayable, 50000);
    });
  });

  group('PosNotifier Payment Method State Tests (Task T2.4)', () {
    test('Default POS state has Tunai as selected payment method', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(posProvider);
      expect(state.selectedPaymentMethod, PaymentMethodType.cash);
      expect(state.paymentResult, isNull);
    });

    test('setSelectedPaymentMethod updates state.selectedPaymentMethod', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(posProvider.notifier)
          .setSelectedPaymentMethod(PaymentMethodType.transfer);

      expect(
        container.read(posProvider).selectedPaymentMethod,
        PaymentMethodType.transfer,
      );

      container
          .read(posProvider.notifier)
          .setSelectedPaymentMethod(PaymentMethodType.qris);

      expect(
        container.read(posProvider).selectedPaymentMethod,
        PaymentMethodType.qris,
      );
    });

    test('setPaymentResult records result, updates method, and sets successMessage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = PaymentResult(
        method: PaymentMethodType.qris,
        totalPayable: 25000,
        amountPaid: 25000,
        referenceNumber: 'Q-01',
      );

      container.read(posProvider.notifier).setPaymentResult(result);

      final state = container.read(posProvider);
      expect(state.paymentResult, equals(result));
      expect(state.selectedPaymentMethod, PaymentMethodType.qris);
      expect(state.successMessage, contains('QRIS Digital'));
    });

    test('clearPaymentResult resets payment result to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = PaymentResult(
        method: PaymentMethodType.cash,
        totalPayable: 10000,
        amountPaid: 10000,
      );

      container.read(posProvider.notifier).setPaymentResult(result);
      expect(container.read(posProvider).paymentResult, isNotNull);

      container.read(posProvider.notifier).clearPaymentResult();
      expect(container.read(posProvider).paymentResult, isNull);
    });

    test('clearCart empties cart and clears paymentResult', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sampleProduct = Product(
        id: 'prod-1',
        categoryId: 'cat-1',
        categoryName: 'Makanan',
        sku: 'MKN-1',
        name: 'Mie Ayam',
        sellingPrice: 15000,
        costPrice: 10000,
        stock: 10,
        minStock: 2,
        trackStock: true,
        isActive: true,
        createdAt: DateTime.now(),
      );

      container.read(posProvider.notifier).addToCart(sampleProduct);
      container.read(posProvider.notifier).setPaymentResult(
            PaymentResult(
              method: PaymentMethodType.cash,
              totalPayable: 15000,
              amountPaid: 20000,
            ),
          );

      expect(container.read(posProvider).hasItems, isTrue);
      expect(container.read(posProvider).paymentResult, isNotNull);

      container.read(posProvider.notifier).clearCart();

      expect(container.read(posProvider).hasItems, isFalse);
      expect(container.read(posProvider).paymentResult, isNull);
    });
  });
}


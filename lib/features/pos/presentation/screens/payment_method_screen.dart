import 'package:flutter/material.dart';
import 'package:kas_usaha/features/pos/domain/models/payment_method.dart';
import 'package:kas_usaha/features/pos/domain/models/pos_calculation.dart';
import 'package:kas_usaha/features/pos/presentation/widgets/pos_payment_modal.dart';

/// Standalone Full-Page Payment Method Screen (Task T2.4).
///
/// Wraps [PosPaymentModal] within a dedicated scaffold for route navigation.
class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({
    super.key,
    required this.totalAmount,
    this.totalQuantity = 0,
    this.businessName = 'Kas Usaha POS',
    this.calculation,
    this.initialMethod = PaymentMethodType.cash,
    this.onPaymentConfirmed,
  });

  /// Total bill amount payable in integer Rupiah.
  final int totalAmount;

  /// Total quantity of items in the current transaction.
  final int totalQuantity;

  /// Business name to display.
  final String businessName;

  /// Optional calculation breakdown for discounts and tax.
  final PosCalculation? calculation;

  /// Initial selected payment method.
  final PaymentMethodType initialMethod;

  /// Callback when payment is confirmed.
  final ValueChanged<PaymentResult>? onPaymentConfirmed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Pembayaran'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PosPaymentModal(
              totalAmount: totalAmount,
              totalQuantity: totalQuantity,
              businessName: businessName,
              calculation: calculation,
              initialMethod: initialMethod,
              onPaymentConfirmed: (result) {
                onPaymentConfirmed?.call(result);
                Navigator.of(context).pop(result);
              },
            ),
          ),
        ),
      ),
    );
  }
}


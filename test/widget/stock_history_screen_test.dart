import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/features/inventory/domain/models/stock_movement.dart';
import 'package:kas_usaha/features/inventory/presentation/screens/stock_history_screen.dart';
import 'package:kas_usaha/features/inventory/presentation/widgets/stock_movement_card.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';
import 'package:kas_usaha/shared/widgets/feedback/app_empty_state.dart';
import 'package:kas_usaha/shared/widgets/inputs/app_search_field.dart';

Widget createTestWidget({
  String? initialProductId,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: StockHistoryScreen(initialProductId: initialProductId),
    ),
  );
}

void main() {
  group('StockHistoryScreen Widget Tests', () {
    testWidgets('renders screen title, summary metrics, search bar, and movement cards',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Riwayat Perubahan Stok'), findsOneWidget);

      // Check Summary Metrics
      expect(find.text('Total Masuk'), findsOneWidget);
      expect(find.text('Total Keluar'), findsOneWidget);
      expect(find.text('Mutasi Bersih'), findsOneWidget);

      // Check Search Field
      expect(find.byType(AppSearchField), findsOneWidget);

      // Check Filter Chips
      expect(find.text('Semua Produk'), findsOneWidget);
      expect(find.text('Semua Tipe'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Penjualan'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Restok Masuk'), findsOneWidget);

      // Check that stock movement cards are rendered
      expect(find.byType(StockMovementCard), findsWidgets);
    });

    testWidgets('filtering by movement type chip filters displayed list',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap on "Penjualan" type chip
      final penjualanChip = find.widgetWithText(ChoiceChip, 'Penjualan');
      expect(penjualanChip, findsOneWidget);
      await tester.tap(penjualanChip);
      await tester.pumpAndSettle();

      // All rendered cards should have Penjualan badge
      final cards = tester.widgetList<StockMovementCard>(find.byType(StockMovementCard));
      expect(cards, isNotEmpty);
      expect(cards.every((c) => c.movement.type == StockMovementType.sale), isTrue);
    });

    testWidgets('searching dynamically filters stock movements',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter search query for "TRX-20261029-003"
      await tester.enterText(find.byType(TextField), 'TRX-20261029-003');
      await tester.pumpAndSettle();

      // Only the card matching that reference should remain
      final cards = tester.widgetList<StockMovementCard>(find.byType(StockMovementCard));
      expect(cards.length, 1);
      expect(cards.first.movement.referenceNumber, 'TRX-20261029-003');
      expect(cards.first.movement.productName, 'Nasi Goreng Spesial');
    });

    testWidgets('empty state is shown when search has no matches and resets on button click',
        (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter impossible query
      await tester.enterText(find.byType(TextField), 'xyz_impossible_query_999');
      await tester.pumpAndSettle();

      // Empty state should be visible
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Riwayat Tidak Ditemukan'), findsOneWidget);

      // Tap 'Reset Filter' button
      final resetButton = find.widgetWithText(AppButton, 'Reset Filter');
      expect(resetButton, findsOneWidget);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // List is restored
      expect(find.byType(StockMovementCard), findsWidgets);
    });

    testWidgets('initialProductId correctly pre-filters list for specific product',
        (tester) async {
      await tester.pumpWidget(createTestWidget(initialProductId: 'prd-02'));
      await tester.pumpAndSettle();

      // Cards rendered must belong to prd-02 (Mie Goreng Seafood)
      final cards = tester.widgetList<StockMovementCard>(find.byType(StockMovementCard));
      expect(cards, isNotEmpty);
      expect(cards.every((c) => c.movement.productId == 'prd-02'), isTrue);
    });
  });
}

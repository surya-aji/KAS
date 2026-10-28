import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/shared/widgets/shared_widgets.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Shared Reusable Widgets', () {
    testWidgets('AppButton renders label and triggers onPressed callback', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _wrap(
          AppButton(
            text: 'Simpan',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Simpan'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(pressed, isTrue);
    });

    testWidgets('AppButton shows progress indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppButton(
            text: 'Simpan',
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('AppIconButton displays icon and badge count', (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppIconButton(
            icon: Icons.shopping_cart_outlined,
            badgeCount: 5,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('AppTextField renders label, hint, and allows text input', (tester) async {
      String value = '';
      await tester.pumpWidget(
        _wrap(
          AppTextField(
            label: 'Nama Produk',
            hint: 'Masukkan nama produk',
            onChanged: (val) => value = val,
          ),
        ),
      );

      expect(find.text('Nama Produk'), findsOneWidget);
      expect(find.text('Masukkan nama produk'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Kopi Susu');
      expect(value, 'Kopi Susu');
    });

    testWidgets('AppCurrencyField formats input with thousands separator and emits integer rupiah', (tester) async {
      int amount = 0;
      await tester.pumpWidget(
        _wrap(
          AppCurrencyField(
            label: 'Harga Jual',
            onAmountChanged: (val) => amount = val,
          ),
        ),
      );

      expect(find.text('Harga Jual'), findsOneWidget);
      expect(find.text('Rp'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '25000');
      await tester.pump();

      expect(amount, 25000);
      expect(find.text('25.000'), findsOneWidget);
    });

    testWidgets('AppSearchField allows typing and clearing text', (tester) async {
      String query = '';
      await tester.pumpWidget(
        _wrap(
          AppSearchField(
            onChanged: (val) => query = val,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Latte');
      await tester.pump();
      expect(query, 'Latte');
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(query, '');
    });

    testWidgets('AppBadge renders label and variant styles', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppBadge(
            label: 'Sukses',
            variant: AppBadgeVariant.success,
            icon: Icons.check_circle_outline,
          ),
        ),
      );

      expect(find.text('Sukses'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('AppEmptyState displays title and action button', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        _wrap(
          AppEmptyState(
            title: 'Belum Ada Produk',
            message: 'Tambahkan produk pertama untuk mulai berjualan.',
            actionText: 'Tambah Produk',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('Belum Ada Produk'), findsOneWidget);
      expect(find.text('Tambahkan produk pertama untuk mulai berjualan.'), findsOneWidget);
      expect(find.text('Tambah Produk'), findsOneWidget);

      await tester.tap(find.text('Tambah Produk'));
      await tester.pump();
      expect(actionTriggered, isTrue);
    });
  });
}

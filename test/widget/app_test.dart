import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kas_usaha/app/app.dart';

void main() {
  group('KasUsahaApp', () {
    testWidgets('renders app title and subtitle', (tester) async {
      await tester.pumpWidget(const KasUsahaApp());

      expect(find.text('Kas Usaha'), findsOneWidget);
      expect(
        find.text('Aplikasi Kasir & Manajemen Kas Offline'),
        findsOneWidget,
      );
    });

    testWidgets('renders store icon', (tester) async {
      await tester.pumpWidget(const KasUsahaApp());

      expect(find.byIcon(Icons.store_rounded), findsOneWidget);
    });
  });
}

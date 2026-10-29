import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';
import 'package:kas_usaha/features/business_settings/presentation/screens/business_profile_screen.dart';
import 'package:kas_usaha/features/catalog/presentation/screens/category_list_screen.dart';
import 'package:kas_usaha/features/catalog/presentation/screens/product_list_screen.dart';
import 'package:kas_usaha/features/inventory/presentation/screens/stock_history_screen.dart';
import 'package:kas_usaha/features/pos/pos.dart';
import 'package:kas_usaha/shared/widgets/buttons/app_button.dart';

/// Root widget of the application.
class KasUsahaApp extends StatelessWidget {
  const KasUsahaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kas Usaha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      // TODO(T0.7): Replace with go_router's routerConfig
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary landing placeholder displaying app identity and shortcut to active feature screens.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Kas Usaha',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aplikasi Kasir & Manajemen Kas Offline',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              AppButton(
                text: 'Buka Layar Kasir / POS (Task T2.1)',
                leadingIcon: Icons.point_of_sale_rounded,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PosScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Buka Profil Usaha (Task T1.1)',
                leadingIcon: Icons.storefront_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BusinessProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Kelola Kategori (Task T1.2)',
                leadingIcon: Icons.category_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CategoryListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Kelola Produk (Task T1.3)',
                leadingIcon: Icons.inventory_2_rounded,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.large,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProductListScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Riwayat Stok (Task T1.5)',
                leadingIcon: Icons.history_rounded,
                variant: AppButtonVariant.secondary,
                size: AppButtonSize.large,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const StockHistoryScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

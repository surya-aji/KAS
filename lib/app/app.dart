import 'package:flutter/material.dart';
import 'package:kas_usaha/app/theme/app_theme.dart';

/// Root widget of the application.
///
/// Will be wrapped with ProviderScope (T0.6) and use
/// go_router for navigation (T0.7).
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

/// Temporary placeholder — replaced when go_router is set up (T0.7).
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
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
          ],
        ),
      ),
    );
  }
}

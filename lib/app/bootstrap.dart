import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kas_usaha/app/app.dart';

/// Initializes all services and runs the app.
///
/// This is the single place where startup logic lives.
Future<void> bootstrap() async {
  // SQLite + Drift and security services will be initialized here (T0.4 / T0.8)
  runApp(
    const ProviderScope(
      child: KasUsahaApp(),
    ),
  );
}

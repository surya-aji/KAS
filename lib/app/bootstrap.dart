import 'package:flutter/material.dart';
import 'package:kas_usaha/app/app.dart';

/// Initializes all services and runs the app.
///
/// This is the single place where startup logic lives.
/// Future tasks (T0.4–T0.8) will add database initialization,
/// dependency injection, and error handling here.
Future<void> bootstrap() async {
  // TODO(T0.4): Initialize SQLite + Drift database
  // TODO(T0.6): Initialize Riverpod container
  // TODO(T0.8): Setup global error handling

  runApp(const KasUsahaApp());
}

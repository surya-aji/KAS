// Application-wide error types and exception handling.
//
// Defines a sealed hierarchy of failure types so that
// every layer can communicate errors in a structured way.

/// Base failure class for the application.
///
/// All domain-level errors should extend this class.
/// Use [message] for user-facing descriptions and
/// [originalError] to preserve the underlying cause.
class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// User-friendly error description.
  final String message;

  /// The original error, if any.
  final Object? originalError;

  /// Stack trace captured at the point of failure.
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppFailure: $message';
}

/// A failure originating from the database layer.
class DatabaseFailure extends AppFailure {
  const DatabaseFailure({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// A failure originating from validation logic.
class ValidationFailure extends AppFailure {
  const ValidationFailure({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

/// A failure related to file I/O operations (backup, export, import).
class FileFailure extends AppFailure {
  const FileFailure({
    required super.message,
    super.originalError,
    super.stackTrace,
  });
}

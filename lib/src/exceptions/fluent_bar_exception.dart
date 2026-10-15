import 'package:fluent_bar/src/internal.dart';

/// An error reported by the library to the handlers added with `FluentBar.addErrorHandler`.
///
/// It wraps what went wrong in user code (a callback, a builder, a theme, a type) or a
/// misuse the library recovered from.
///
/// ```dart
/// FluentBar.addErrorHandler((FluentBarException error, StackTrace stackTrace) {
///   crashReporter.record(error.error, stackTrace, reason: error.type.displayName);
/// });
/// ```
class FluentBarException implements Exception {
  /// The original error or exception.
  final Object error;

  /// Where the original error was thrown.
  final StackTrace stackTrace;

  /// Which part of the library reported the error.
  final FluentBarErrorType type;

  /// A warning for a recovered misuse, an error for a failure in user code.
  final FluentBarErrorSeverity severity;

  /// Creates an exception that wraps [error].
  const FluentBarException({required this.error, required this.stackTrace, required this.type, this.severity = FluentBarErrorSeverity.error});

  @override
  String toString() => 'FluentBarException [${type.displayName}]: $error';
}

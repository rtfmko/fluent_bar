import 'package:fluent_bar/src/internal.dart';

/// Runs user code under protection and reports what it throws to the registered error handlers.
class FluentBarErrorHandler {
  FluentBarErrorHandler._();

  /// The single instance.
  static final FluentBarErrorHandler instance = FluentBarErrorHandler._();

  /// Reports an error to the handlers (`FluentBar.addErrorHandler`) and prints it in debug builds.
  ///
  /// Never throws. A ready [FluentBarException] is passed on as is, with its own type and
  /// severity; [type] and [severity] are ignored for it.
  void handle(Object error, FluentBarErrorType type, [StackTrace? stackTrace, FluentBarErrorSeverity? severity, String? debugContext]) {
    final FluentBarException exception = error is FluentBarException
        ? error
        : FluentBarException(error: error, stackTrace: stackTrace ?? StackTrace.current, type: type, severity: severity ?? FluentBarErrorSeverity.error);

    FluentBarManager.instance.notifyErrors(exception, exception.stackTrace);

    if (kDebugMode) {
      final bool isWarning = exception.severity.isWarning;
      final String icon = isWarning ? '🟡' : '🔴';
      final String levelName = isWarning ? 'WARNING' : 'ERROR';

      final String typeName = exception.type.displayName.toUpperCase();
      final String title = debugContext != null ? '$typeName -> $debugContext' : typeName;

      debugPrint('┌─────────────────────────────────────────────────────────');
      debugPrint('$icon [FluentBar] $title [$levelName]');
      debugPrint('│ Message: ${exception.error}');
      debugPrint('├─────────────────────────────────────────────────────────');
      debugPrint('${exception.stackTrace}');
      debugPrint('└─────────────────────────────────────────────────────────');
    }
  }

  /// Returns the result of [overrideCall]; if it throws, reports the error and returns [fallbackCall].
  ///
  /// [fallbackCall] is not guarded: it is our own fallback path, and its failure must be visible.
  T executeSafe<T>({required T Function() overrideCall, required T Function() fallbackCall, required FluentBarErrorType type, required String debugContext, FluentBarErrorSeverity? errorSeverity}) {
    try {
      return overrideCall();
    } catch (e, st) {
      handle(e, type, st, errorSeverity, debugContext);
      return fallbackCall();
    }
  }

  /// Awaits [overrideCall]; if it throws (synchronously or not), reports the error and returns
  /// [fallback]. The returned future never completes with an error.
  Future<T?> executeSafeAsync<T>({required FutureOr<T> Function() overrideCall, required FluentBarErrorType type, T? fallback, String? debugContext, FluentBarErrorSeverity? errorSeverity}) async {
    try {
      return await overrideCall();
    } catch (e, st) {
      handle(e, type, st, errorSeverity, debugContext);
      return fallback;
    }
  }
}

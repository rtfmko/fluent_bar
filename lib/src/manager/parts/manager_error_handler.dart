part of '../fluent_bar_manager.dart';

/// Error handlers.
extension FluentBarManagerErrorHandler on FluentBarManager {
  /// Adds an error handler; adding the same one twice has no effect.
  void addErrorHandler(void Function(FluentBarException, StackTrace) handler) {
    _errorHandlers ??= <void Function(FluentBarException, StackTrace)>[];
    if (!_errorHandlers!.contains(handler)) {
      _errorHandlers!.add(handler);
    }
  }

  /// Removes an error handler.
  void removeErrorHandler(void Function(FluentBarException, StackTrace) handler) {
    _errorHandlers?.remove(handler);
    if (_errorHandlers != null && _errorHandlers!.isEmpty) {
      _errorHandlers = null;
    }
  }

  /// Delivers [error] to the handlers. A throwing handler does not affect the others.
  void notifyErrors(FluentBarException error, StackTrace stackTrace) {
    if (_errorHandlers == null) return;
    for (final void Function(FluentBarException, StackTrace) handler in _errorHandlers!.toList()) {
      try {
        handler(error, stackTrace);
      } catch (callbackError) {
        if (kDebugMode) {
          debugPrint('[FluentBar] Error handler $handler threw: $callbackError');
        }
      }
    }
  }
}

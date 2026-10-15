import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarErrorHandler handler = FluentBarErrorHandler.instance;
  final List<(FluentBarException, StackTrace)> received = <(FluentBarException, StackTrace)>[];
  void onError(FluentBarException error, StackTrace stackTrace) => received.add((error, stackTrace));

  setUp(() {
    received.clear();
    FluentBar.addErrorHandler(onError);
  });

  tearDown(() => FluentBar.removeErrorHandler(onError));

  group('handle', () {
    test('wraps a raw error into FluentBarException with the given type, severity and stack trace', () {
      final StackTrace stackTrace = StackTrace.current;

      handler.handle('Raw error', FluentBarErrorType.callbackTap, stackTrace, FluentBarErrorSeverity.warning);

      final (FluentBarException exception, StackTrace reported) = received.single;
      expect(exception.error, 'Raw error');
      expect(exception.type, FluentBarErrorType.callbackTap);
      expect(exception.severity, FluentBarErrorSeverity.warning);
      expect(exception.stackTrace, same(stackTrace));
      expect(reported, same(stackTrace));
    });

    test('defaults: severity is error, and a stack trace is captured when none is given', () {
      handler.handle(Exception('boom'), FluentBarErrorType.overlay);

      final FluentBarException exception = received.single.$1;
      expect(exception.severity, FluentBarErrorSeverity.error);
      expect(exception.stackTrace.toString(), isNotEmpty);
    });

    test('an existing FluentBarException is passed through unchanged', () {
      const FluentBarException original = FluentBarException(error: 'original', stackTrace: StackTrace.empty, type: FluentBarErrorType.queueOverflow, severity: FluentBarErrorSeverity.warning);

      handler.handle(original, FluentBarErrorType.overlay, StackTrace.current, FluentBarErrorSeverity.error);

      expect(received.single.$1, same(original));
      expect(received.single.$2, same(StackTrace.empty));
    });

    test('works with no handlers registered, with a debug context, and never throws', () {
      FluentBar.removeErrorHandler(onError);

      expect(() => handler.handle('nobody listens', FluentBarErrorType.overlay), returnsNormally);
      expect(() => handler.handle('with context', FluentBarErrorType.fluentBarTheme, null, null, 'titleStyle'), returnsNormally);
      expect(received, isEmpty);
    });

    test('a throwing handler does not stop the others and does not escape', () {
      void throwing(FluentBarException error, StackTrace stackTrace) => throw Exception('handler failed');
      FluentBar.removeErrorHandler(onError);
      FluentBar.addErrorHandler(throwing);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(throwing));

      expect(() => handler.handle('error', FluentBarErrorType.overlay), returnsNormally);
      expect(received, hasLength(1));
    });

    test('a handler may report another error or unregister itself while being notified', () {
      late void Function(FluentBarException, StackTrace) reentrant;
      int calls = 0;
      reentrant = (FluentBarException error, StackTrace stackTrace) {
        calls++;
        FluentBar.removeErrorHandler(reentrant);
        handler.handle('nested', FluentBarErrorType.overlay);
      };
      FluentBar.addErrorHandler(reentrant);
      addTearDown(() => FluentBar.removeErrorHandler(reentrant));

      handler.handle('outer', FluentBarErrorType.overlay);

      expect(calls, 1);
      expect(received.map(((FluentBarException, StackTrace) r) => r.$1.error), containsAll(<String>['outer', 'nested']));
    });
  });

  group('executeSafe', () {
    test('returns the result of the call and reports nothing when it succeeds', () {
      bool fallbackCalled = false;
      final int result = handler.executeSafe<int>(
        overrideCall: () => 42,
        fallbackCall: () {
          fallbackCalled = true;
          return -1;
        },
        type: FluentBarErrorType.fluentBarResolver,
        debugContext: 'test',
      );

      expect(result, 42);
      expect(fallbackCalled, isFalse);
      expect(received, isEmpty);
    });

    test('on a throw reports the error with type and severity, then returns the fallback', () {
      final int result = handler.executeSafe<int>(
        overrideCall: () => throw StateError('boom'),
        fallbackCall: () => -1,
        type: FluentBarErrorType.fluentBarResolver,
        debugContext: 'test',
        errorSeverity: FluentBarErrorSeverity.warning,
      );

      expect(result, -1);
      expect(received.single.$1.error, isA<StateError>());
      expect(received.single.$1.type, FluentBarErrorType.fluentBarResolver);
      expect(received.single.$1.severity, FluentBarErrorSeverity.warning);
    });

    test('supports nullable results', () {
      final String? result = handler.executeSafe<String?>(overrideCall: () => throw Exception('boom'), fallbackCall: () => null, type: FluentBarErrorType.fluentBarResolver, debugContext: 'test');

      expect(result, isNull);
      expect(received, hasLength(1));
    });

    test('an error inside the fallback is not swallowed', () {
      expect(
        () => handler.executeSafe<int>(
          overrideCall: () => throw Exception('first'),
          fallbackCall: () => throw StateError('fallback failed'),
          type: FluentBarErrorType.fluentBarResolver,
          debugContext: 'test',
        ),
        throwsStateError,
      );
      expect(received, hasLength(1), reason: 'only the first error goes to the handlers');
    });
  });

  group('executeSafeAsync', () {
    test('returns the result of a synchronous or asynchronous call', () async {
      expect(await handler.executeSafeAsync<int>(overrideCall: () => 1, type: FluentBarErrorType.actionPressed), 1);
      expect(await handler.executeSafeAsync<int>(overrideCall: () async => 2, type: FluentBarErrorType.actionPressed), 2);
      expect(received, isEmpty);
    });

    test('catches both a synchronous throw and a failed future', () async {
      final int? sync = await handler.executeSafeAsync<int>(overrideCall: () => throw Exception('sync'), type: FluentBarErrorType.actionPressed, fallback: -1);
      final int? async = await handler.executeSafeAsync<int>(
        overrideCall: () => Future<int>.error(Exception('async')),
        type: FluentBarErrorType.callbackShow,
        fallback: -2,
        errorSeverity: FluentBarErrorSeverity.warning,
      );

      expect(sync, -1);
      expect(async, -2);
      expect(received.map(((FluentBarException, StackTrace) r) => r.$1.type), <FluentBarErrorType>[FluentBarErrorType.actionPressed, FluentBarErrorType.callbackShow]);
      expect(received.last.$1.severity, FluentBarErrorSeverity.warning);
    });

    test('without a fallback returns null even for a non-nullable type, instead of failing', () async {
      final int? result = await handler.executeSafeAsync<int>(overrideCall: () => throw Exception('boom'), type: FluentBarErrorType.actionPressed);

      expect(result, isNull);
      expect(received, hasLength(1));
    });

    test('works for void callbacks, which is how the library uses it', () async {
      int calls = 0;
      await handler.executeSafeAsync<void>(overrideCall: () => calls++, type: FluentBarErrorType.callbackTap);
      await handler.executeSafeAsync<void>(overrideCall: () async => throw Exception('boom'), type: FluentBarErrorType.callbackTap);

      expect(calls, 1);
      expect(received.single.$1.type, FluentBarErrorType.callbackTap);
    });
  });

  group('FluentBarException', () {
    test('toString uses the label of the type, or its name when there is no label', () {
      const FluentBarException labelled = FluentBarException(error: 'Some error', stackTrace: StackTrace.empty, type: FluentBarErrorType.initialization);
      const FluentBarException unlabelled = FluentBarException(error: 'Some error', stackTrace: StackTrace.empty, type: FluentBarErrorType.fluentBarTheme);

      expect(labelled.toString(), 'FluentBarException [Manager: Multiple init]: Some error');
      expect(unlabelled.toString(), 'FluentBarException [fluentBarTheme]: Some error');
      expect(labelled.severity, FluentBarErrorSeverity.error);
    });

    test('is an Exception and can be thrown and caught as one', () {
      const FluentBarException exception = FluentBarException(error: 'x', stackTrace: StackTrace.empty, type: FluentBarErrorType.overlay);

      expect(exception, isA<Exception>());
      expect(() => throw exception, throwsA(isA<FluentBarException>()));
    });
  });

  group('FluentBarErrorType', () {
    test('every value has a non-empty display name', () {
      for (final FluentBarErrorType type in FluentBarErrorType.values) {
        expect(type.displayName, isNotEmpty, reason: type.name);
        expect(type.displayName, type.label ?? type.name);
      }
    });
  });
}

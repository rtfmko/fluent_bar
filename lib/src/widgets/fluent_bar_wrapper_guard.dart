part of 'fluent_bar_wrapper.dart';

/// Draws a widget made by user code (content, icon, action) and catches what it throws while it
/// builds, lays out or paints.
///
/// Flutter reports such errors itself and draws its error widget in place. Here the first one is
/// reported once through the error handler as [type], and [fallback] is drawn from then on.
///
/// The work below the guard runs inside its own build, layout and paint (the first build of the
/// subtree, an update from above, a layout or paint that goes through the guard). While it runs,
/// `FlutterError.onError` is replaced for a moment to catch the reports; it is put back right
/// after. A part of the subtree that rebuilds or repaints on its own is not covered.
class FluentBarUserWidgetGuard extends StatefulWidget {
  /// The widget made by user code.
  final Widget child;

  /// What is drawn once [child] has failed.
  final WidgetBuilder fallback;

  /// The error type of the report.
  final FluentBarErrorType type;

  /// Where the widget came from, for the report.
  final String debugContext;

  /// Creates a guard around [child].
  const FluentBarUserWidgetGuard({super.key, required this.child, required this.fallback, required this.type, required this.debugContext});

  @override
  StatefulElement createElement() => _UserWidgetGuardElement(this);

  @override
  State<FluentBarUserWidgetGuard> createState() => _UserWidgetGuardState();

  /// The handler that gets the reports which are not failures of the widget, while a capture runs.
  static FlutterExceptionHandler? _passOn;

  /// The first failure seen by the capture that runs now.
  static FlutterErrorDetails? _failure;

  static void _onError(FlutterErrorDetails details) {
    if (_isFailure(details)) {
      _failure ??= details;
    } else {
      _passOn?.call(details);
    }
  }

  /// Reports of the library itself ([FluentBarException]) and the debug overflow warning of Flutter
  /// (drawn as stripes, nothing breaks; in release there is none) are not failures of the widget.
  static bool _isFailure(FlutterErrorDetails details) {
    final Object exception = details.exception;
    if (exception is FluentBarException) return false;
    return !(exception is FlutterError && details.library == 'rendering library' && exception.message.contains(' overflowed by '));
  }

  /// Runs [body] and returns the first failure it reported to `FlutterError.onError` or threw.
  ///
  /// Nothing is allocated for a pass without errors. Captures nest: an inner guard keeps its own
  /// failures and passes the rest to the handler outside the outer one.
  static FlutterErrorDetails? _capture(VoidCallback body) {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    final FlutterExceptionHandler? outerPassOn = _passOn;
    final FlutterErrorDetails? outerFailure = _failure;
    final bool isNested = identical(previous, _onError);
    if (!isNested) _passOn = previous;
    _failure = null;
    FlutterError.onError = _onError;
    try {
      body();
    } catch (error, stackTrace) {
      _failure ??= FlutterErrorDetails(exception: error, stack: stackTrace, library: 'fluent_bar');
    } finally {
      FlutterError.onError = previous;
    }
    final FlutterErrorDetails? failure = _failure;
    _failure = outerFailure;
    _passOn = outerPassOn;
    return failure;
  }
}

class _UserWidgetGuardState extends State<FluentBarUserWidgetGuard> {
  bool _hasFailed = false;
  bool _isRebuildScheduled = false;

  /// New content is another chance: the fallback stays only for the widget that failed.
  @override
  void didUpdateWidget(covariant FluentBarUserWidgetGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasFailed && oldWidget.child != widget.child) _hasFailed = false;
  }

  void _fail(FlutterErrorDetails details) {
    if (_hasFailed) return;
    _hasFailed = true;
    FluentBarErrorHandler.instance.handle(details.exception, widget.type, details.stack, null, widget.debugContext);
  }

  /// A failure in layout or paint: the tree cannot change now, the fallback comes with the next frame.
  void _failLater(FlutterErrorDetails details) {
    _fail(details);
    if (_isRebuildScheduled) return;
    _isRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isRebuildScheduled = false;
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => _hasFailed ? widget.fallback(context) : _UserWidgetGuardBox(onFailed: _failLater, child: widget.child);
}

class _UserWidgetGuardElement extends StatefulElement {
  _UserWidgetGuardElement(FluentBarUserWidgetGuard super.widget);

  @override
  void performRebuild() {
    final _UserWidgetGuardState guard = state as _UserWidgetGuardState;
    if (guard._hasFailed) {
      super.performRebuild();
      return;
    }

    final FlutterErrorDetails? failure = FluentBarUserWidgetGuard._capture(super.performRebuild);
    if (failure == null) return;

    guard._fail(failure);
    super.performRebuild();
  }
}

class _UserWidgetGuardBox extends SingleChildRenderObjectWidget {
  const _UserWidgetGuardBox({required this.onFailed, required super.child});

  final void Function(FlutterErrorDetails details) onFailed;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderUserWidgetGuard(onFailed);

  @override
  void updateRenderObject(BuildContext context, _RenderUserWidgetGuard renderObject) => renderObject.onFailed = onFailed;
}

class _RenderUserWidgetGuard extends RenderProxyBox {
  _RenderUserWidgetGuard(this.onFailed);

  void Function(FlutterErrorDetails details) onFailed;

  /// The child failed: it is neither painted nor hit until the fallback replaces it.
  bool _hasFailed = false;

  // Kept for the time of [paint], so the capture takes a tear-off instead of a new closure.
  PaintingContext? _paintContext;
  Offset _paintOffset = Offset.zero;

  void _paintChild() => super.paint(_paintContext!, _paintOffset);

  void _report(FlutterErrorDetails? failure) {
    if (failure == null) return;
    _hasFailed = true;
    onFailed(failure);
  }

  @override
  void performLayout() {
    if (_hasFailed) {
      size = constraints.smallest;
      return;
    }

    _report(FluentBarUserWidgetGuard._capture(super.performLayout));
    if (_hasFailed) size = constraints.smallest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasFailed) return;

    _paintContext = context;
    _paintOffset = offset;
    final FlutterErrorDetails? failure = FluentBarUserWidgetGuard._capture(_paintChild);
    _paintContext = null;
    if (failure == null) return;

    // The painter stopped half way: the canvas may hold its unfinished saves. The count is not
    // taken before painting, that would start a picture for a child that may not need one; a
    // restore with nothing to pop does nothing.
    final Canvas canvas = context.canvas;
    while (canvas.getSaveCount() > 1) {
      canvas.restore();
    }
    _report(failure);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) => !_hasFailed && super.hitTestChildren(result, position: position);

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_hasFailed) super.visitChildrenForSemantics(visitor);
  }
}

import 'package:fluent_bar/src/internal.dart';

/// Hosts the overlay in which bars are shown, above the navigator.
///
/// Bars then survive route changes and need no `BuildContext`.
///
/// ```dart
/// MaterialApp(
///   builder: FluentBarScope.builder(),
///   home: const HomePage(),
/// );
/// ```
class FluentBarScope extends StatefulWidget {
  /// The app below the bars.
  final Widget child;

  /// The global config to apply; `null` keeps the current one.
  final FluentBarConfig? config;

  /// Creates a scope around [child].
  const FluentBarScope({super.key, required this.child, this.config});

  /// A builder for `MaterialApp.builder` or `CupertinoApp.builder`.
  ///
  /// ```dart
  /// MaterialApp(builder: FluentBarScope.builder(config: const FluentBarConfig()));
  /// ```
  static TransitionBuilder builder({FluentBarConfig? config}) =>
      (BuildContext context, Widget? child) => FluentBarScope(config: config, child: child ?? const SizedBox.shrink());

  @override
  State<FluentBarScope> createState() => _FluentBarScopeState();
}

class _FluentBarScopeState extends State<FluentBarScope> {
  final GlobalKey<OverlayState> _scopeOverlayKey = GlobalKey<OverlayState>();
  late final OverlayEntry _childEntry;

  @override
  void initState() {
    super.initState();
    _childEntry = OverlayEntry(builder: (BuildContext context) => widget.child);

    final FluentBarManager manager = FluentBarManager.instance;
    if (!manager.isInitialized) {
      // Without its own config the scope keeps the one already in the manager: it may have been set
      // with FluentBar.updateConfig before runApp and must not be overwritten with defaults.
      manager.initialize(widget.config ?? manager.config);
    } else if (widget.config != null) {
      _applyConfig(widget.config!);
    }

    manager.registerScopeOverlayKey(_scopeOverlayKey);
  }

  @override
  void didUpdateWidget(covariant FluentBarScope oldWidget) {
    super.didUpdateWidget(oldWidget);

    final FluentBarConfig? newConfig = widget.config;
    if (newConfig != null && !identical(newConfig, oldWidget.config)) {
      _applyConfig(newConfig);
    }

    if (widget.child != oldWidget.child) {
      _childEntry.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    FluentBarManager.instance.unregisterScopeOverlayKey(_scopeOverlayKey);
    // The child Overlay is already disposed here (descendants go before the parent); remove() only
    // detaches the entry from it, and without that dispose() fails an assert.
    _childEntry
      ..remove()
      ..dispose();
    super.dispose();
  }

  /// A config change notifies listeners and may show or close bars, which is not allowed while
  /// the tree is being built (this is called from initState / didUpdateWidget), so it waits for the frame to end.
  void _applyConfig(FluentBarConfig config) {
    // Outside a frame (for example on the first mount) one must be requested, or the callback never runs.
    WidgetsBinding.instance.ensureVisualUpdate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The config may have changed again during the frame: apply only the current one.
      if (mounted && identical(widget.config, config)) {
        FluentBarManager.instance.updateConfig(config);
      }
    });
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    child: Overlay(key: _scopeOverlayKey, initialEntries: <OverlayEntry>[_childEntry]),
  );
}

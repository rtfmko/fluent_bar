import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/scheduler.dart' show SchedulerPhase;

part 'parts/manager_analytics.dart';
part 'parts/manager_error_handler.dart';
part 'parts/manager_lifecycle.dart';
part 'parts/manager_overlay.dart';
part 'parts/manager_queue.dart';
part 'parts/manager_relocation.dart';

/// The current config for listeners. A plain ValueNotifier does not fit: it compares with `==`,
/// and functions (duplicate rule, builders) are not part of config equality, so changing one
/// would go unnoticed.
class _ConfigNotifier extends ChangeNotifier with FrameSafeNotifier implements ValueListenable<FluentBarConfig> {
  _ConfigNotifier(this._value);

  FluentBarConfig _value;

  @override
  FluentBarConfig get value => _value;

  set value(FluentBarConfig next) {
    final FluentBarConfig previous = _value;
    _value = next;
    if (previous == next && previous.hasSameFunctionsAs(next)) return;

    notifyListeners();
  }
}

/// Owns the queues and the bars on screen. The static `FluentBar` API is a thin layer over it.
class FluentBarManager {
  FluentBarManager._();

  /// The single instance.
  static final FluentBarManager instance = FluentBarManager._();

  static const Duration _exitAnimationMargin = Duration(milliseconds: 500);

  FluentBarConfig _config = const FluentBarConfig();
  bool _isInitialized = false;

  GlobalKey<NavigatorState>? _navigatorKey;
  GlobalKey<OverlayState>? _scopeOverlayKey;

  final Map<FluentBarRegion, List<FluentBarEntry<dynamic>>> _queues = <FluentBarRegion, List<FluentBarEntry<dynamic>>>{
    FluentBarRegion.main: <FluentBarEntry<dynamic>>[],
    FluentBarRegion.bottom: <FluentBarEntry<dynamic>>[],
  };
  final Map<FluentBarRegion, FluentBarEntry<dynamic>?> _activeItems = <FluentBarRegion, FluentBarEntry<dynamic>?>{};
  final Map<FluentBarRegion, FluentBarEntry<dynamic>?> _dismissingEntries = <FluentBarRegion, FluentBarEntry<dynamic>?>{};

  /// Bars that are leaving the screen right now to wait in the queue of another region.
  /// Unlike dismissing bars they stay alive: showing the same bar again updates them.
  final Set<FluentBarEntry<dynamic>> _relocating = <FluentBarEntry<dynamic>>{};

  /// Bars that were closed while they were leaving for another region: they must not come back.
  final Map<FluentBarEntry<dynamic>, FluentBarDismissReason> _closedWhileRelocating = <FluentBarEntry<dynamic>, FluentBarDismissReason>{};

  final Map<FluentBarRegion, FluentBarEntry<dynamic>?> _forcedNexts = <FluentBarRegion, FluentBarEntry<dynamic>?>{};
  final Map<FluentBarRegion, OverlayEntry?> _activeOverlayEntries = <FluentBarRegion, OverlayEntry?>{};

  // Show order: time cannot be compared, two bars may appear at the same moment.
  final Map<FluentBarRegion, int> _shownOrders = <FluentBarRegion, int>{};
  int _showCounter = 0;

  final Map<FluentBarRegion, ValueNotifier<int>> _queueLengthNotifiers = <FluentBarRegion, ValueNotifier<int>>{
    FluentBarRegion.main: FrameSafeValueNotifier<int>(0),
    FluentBarRegion.bottom: FrameSafeValueNotifier<int>(0),
  };

  late final CombinedValueListenable _allQueueLengthNotifier = CombinedValueListenable(_queueLengthNotifiers[FluentBarRegion.main]!, _queueLengthNotifiers[FluentBarRegion.bottom]!);

  List<void Function(FluentBarAnalyticsPayload)>? _analyticsListeners;
  List<void Function(FluentBarException, StackTrace)>? _errorHandlers;

  late final _ConfigNotifier _configNotifier = _ConfigNotifier(_config);

  // The library never creates the binding itself: `ensureInitialized()` fixes its type, and app
  // tests would get a regular binding instead of the test one. So before Flutter starts (calls
  // from main() before runApp) nothing is scheduled; the app creates the binding.

  bool _isDequeueScheduled = false;

  /// Schedules showing the waiting bars at the end of the next frame.
  ///
  /// If Flutter is not running yet, it retries once after the current synchronous code, by which
  /// time `runApp` has usually been called. If there is still no binding it gives up quietly:
  /// the bars stay queued and are shown on the next call into the library.
  void _scheduleDequeue({bool isRetry = false}) {
    if (_isDequeueScheduled && !isRetry) return;

    final WidgetsBinding? binding = FluentBarManager.bindingLookup();
    if (binding == null) {
      _isDequeueScheduled = !isRetry;
      if (!isRetry) Timer.run(() => _scheduleDequeue(isRetry: true));
      return;
    }

    _isDequeueScheduled = true;
    binding.addPostFrameCallback((_) {
      _isDequeueScheduled = false;
      tryDequeuePending();
      _reportMissingOverlay(binding);
    });
    // An idle app may produce no frame for a long time: no show and no warning would happen.
    binding.ensureVisualUpdate();
  }

  bool _isMissingOverlayReported = false;

  /// The app is on screen, bars are waiting and there is nowhere to show them: almost certainly the
  /// library was not set up. From outside it looks like "show() does nothing", so it is reported once.
  void _reportMissingOverlay(WidgetsBinding binding) {
    if (_getOverlayState() != null) {
      _isMissingOverlayReported = false;
      return;
    }

    // The app is not running yet (the bar was requested before runApp): waiting for an overlay is normal.
    if (_isMissingOverlayReported || allQueueLength == 0 || binding.rootElement == null) return;

    _isMissingOverlayReported = true;
    FluentBarErrorHandler.instance.handle(
      StateError(
        'FluentBar: there is nowhere to show bars, so they wait in the queue. '
        'Wrap the app in FluentBarScope (MaterialApp(builder: FluentBarScope.builder())), '
        'or add FluentBarObserver.instance to navigatorObservers, or pass a navigatorKey to FluentBar.initialize.',
      ),
      FluentBarErrorType.overlay,
      StackTrace.current,
      FluentBarErrorSeverity.warning,
    );
  }

  // App panels (app bar, bottom navigation) report their height through FluentBarTopInset and
  // FluentBarBottomInset. There may be several (nested screens); the largest one is used.

  final Map<Object, double> _topInsets = <Object, double>{};
  final Map<Object, double> _bottomInsets = <Object, double>{};
  final ValueNotifier<double> _topInsetNotifier = FrameSafeValueNotifier<double>(0);
  final ValueNotifier<double> _bottomInsetNotifier = FrameSafeValueNotifier<double>(0);

  /// The measured height of the app bar that top bars must stay below.
  ValueListenable<double> get topInsetNotifier => _topInsetNotifier;

  /// The measured height of the bottom panel that bottom bars must stay above.
  ValueListenable<double> get bottomInsetNotifier => _bottomInsetNotifier;

  /// Reports the height of an app bar on behalf of [owner] (`null`: the app bar is gone).
  void setTopInset(Object owner, double? height) => _setInset(_topInsets, _topInsetNotifier, owner, height);

  /// Reports the height of a bottom panel on behalf of [owner] (`null`: the panel is gone).
  void setBottomInset(Object owner, double? height) => _setInset(_bottomInsets, _bottomInsetNotifier, owner, height);

  void _setInset(Map<Object, double> insets, ValueNotifier<double> notifier, Object owner, double? height) {
    if (height == null) {
      insets.remove(owner);
    } else {
      insets[owner] = height;
    }

    double max = 0;
    for (final double value in insets.values) {
      if (value > max) max = value;
    }
    notifier.value = max;
  }

  /// The global config in effect.
  FluentBarConfig get config => _config;

  /// Whether the manager was initialized by `FluentBar.initialize` or a `FluentBarScope`.
  bool get isInitialized => _isInitialized;

  /// Both regions are created up front and never removed.
  List<FluentBarEntry<dynamic>> _queueOf(FluentBarRegion region) => _queues[region]!;

  /// The bars waiting in both queues.
  List<FluentBarEntry<dynamic>> get allQueue => List<FluentBarEntry<dynamic>>.unmodifiable(<FluentBarEntry<dynamic>>[..._queueOf(FluentBarRegion.main), ..._queueOf(FluentBarRegion.bottom)]);

  /// The bars waiting in the queue of the top region.
  List<FluentBarEntry<dynamic>> get mainQueue => List<FluentBarEntry<dynamic>>.unmodifiable(_queueOf(FluentBarRegion.main));

  /// The bars waiting in the queue of the bottom region.
  List<FluentBarEntry<dynamic>> get bottomQueue => List<FluentBarEntry<dynamic>>.unmodifiable(_queueOf(FluentBarRegion.bottom));

  /// How many bars wait in both queues.
  int get allQueueLength => _queueOf(FluentBarRegion.main).length + _queueOf(FluentBarRegion.bottom).length;

  /// How many bars wait in the queue of the top region.
  int get mainQueueLength => _queueOf(FluentBarRegion.main).length;

  /// How many bars wait in the queue of the bottom region.
  int get bottomQueueLength => _queueOf(FluentBarRegion.bottom).length;

  /// The bars that are on screen right now.
  List<FluentBarEntry<dynamic>> get activeItems => <FluentBarEntry<dynamic>>[
    if (_activeItems[FluentBarRegion.main] != null) _activeItems[FluentBarRegion.main]!,
    if (_activeItems[FluentBarRegion.bottom] != null) _activeItems[FluentBarRegion.bottom]!,
  ];

  /// The bar shown in the top region, if any.
  FluentBarEntry<dynamic>? get mainActiveItem => _activeItems[FluentBarRegion.main];

  /// The bar shown in the bottom region, if any.
  FluentBarEntry<dynamic>? get bottomActiveItem => _activeItems[FluentBarRegion.bottom];

  /// The bar that appeared on screen last, if any.
  FluentBarEntry<dynamic>? get lastActiveItem => _activeItems[_latestActiveRegion];

  /// The bars with [tag]: the shown ones first, then the queued ones.
  List<FluentBarEntry<dynamic>> findByTag(String tag) => <FluentBarEntry<dynamic>>[
    for (final FluentBarRegion region in FluentBarRegion.values)
      if (_activeItems[region] case final FluentBarEntry<dynamic> active when active.currentItem.tags.contains(tag)) active,
    for (final FluentBarRegion region in FluentBarRegion.values)
      for (final FluentBarEntry<dynamic> entry in _queueOf(region))
        if (entry.currentItem.tags.contains(tag)) entry,
  ];

  /// Looks among the shown bars first, then among the queued ones.
  FluentBarEntry<dynamic>? findById(String id) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active != null && active.currentItem.id == id) return active;
    }
    for (final FluentBarRegion region in FluentBarRegion.values) {
      for (final FluentBarEntry<dynamic> entry in _queueOf(region)) {
        if (entry.currentItem.id == id) return entry;
      }
    }
    return null;
  }

  /// The region (queue) of an entry. With [FluentBarConfig.enableMultiRegion] off there is one
  /// queue: every entry, bottom ones included, goes through [FluentBarRegion.main]. The position
  /// of the bar on screen is not affected.
  FluentBarRegion _regionOf(FluentBarEntry<dynamic> entry) => _config.enableMultiRegion ? entry.resolvePosition(_config).toRegion() : FluentBarRegion.main;

  /// The region whose active bar occupies the slot for [region]: with two queues it is [region]
  /// itself, with one queue any region (a bar may have stayed there after a config change).
  FluentBarRegion? _occupiedRegion(FluentBarRegion region) {
    if (_activeItems[region] != null) return region;
    if (_config.enableMultiRegion) return null;

    for (final FluentBarRegion other in FluentBarRegion.values) {
      if (_activeItems[other] != null) return other;
    }
    return null;
  }

  /// The region whose active bar was shown last.
  FluentBarRegion? get _latestActiveRegion {
    FluentBarRegion? latest;
    for (final FluentBarRegion region in FluentBarRegion.values) {
      if (_activeItems[region] == null) continue;
      if (latest == null || (_shownOrders[region] ?? 0) > (_shownOrders[latest] ?? 0)) {
        latest = region;
      }
    }
    return latest;
  }

  /// Notifies when the total number of waiting bars changes.
  ValueListenable<int> get allQueueLengthNotifier => _allQueueLengthNotifier;

  /// Notifies when the number of bars waiting in the top region changes.
  ValueListenable<int> get mainQueueLengthNotifier => _queueLengthNotifiers[FluentBarRegion.main]!;

  /// Notifies when the number of bars waiting in the bottom region changes.
  ValueListenable<int> get bottomQueueLengthNotifier => _queueLengthNotifiers[FluentBarRegion.bottom]!;

  /// Notifies when the global config changes, including a change of a function in it.
  ValueListenable<FluentBarConfig> get configNotifier => _configNotifier;

  /// The binding if Flutter is already running, otherwise `null`. Replaceable in tests.
  @visibleForTesting
  static WidgetsBinding? Function() bindingLookup = defaultBindingLookup;

  /// Returns the widgets binding, or `null` if Flutter has not been started yet.
  @visibleForTesting
  static WidgetsBinding? defaultBindingLookup() {
    try {
      return WidgetsBinding.instance;
    } catch (_) {
      return null;
    }
  }
}

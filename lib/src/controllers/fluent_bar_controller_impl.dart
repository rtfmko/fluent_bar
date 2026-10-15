import 'package:fluent_bar/src/internal.dart';

part 'parts/controller_extensions.dart';
part 'parts/controller_item_notifier.dart';
part 'parts/controller_lifetime.dart';
part 'parts/controller_live_notifier.dart';

/// The controller behind every bar: its content, lifetime, progress and attention effects.
class FluentBarControllerImpl<T> implements FluentBarInternalController<T> {
  @override
  FluentBarManager? manager;

  @override
  bool isClosedBeforeShow = false;

  final _ItemNotifier<T> _itemNotifier;
  final ValueNotifier<FluentBarLifecycleState> _stateNotifier = FrameSafeValueNotifier<FluentBarLifecycleState>(FluentBarLifecycleState.queued);

  // Time values are computed from the clock when read; the ticker exists only to notify
  // listeners. While there are none (no timeout bar), it does not run at all.
  late final _LiveNotifier<Duration> _elapsedDurationNotifier;
  late final _LiveNotifier<Duration> _remainingDurationNotifier;
  late final ValueNotifier<Duration?> _totalDurationNotifier;
  late final _LiveNotifier<double> _remainingProgressNotifier;
  late final _LiveNotifier<double> _elapsedProgressNotifier;
  late final ValueNotifier<double?> _taskProgressNotifier;
  late final ValueNotifier<FluentBarProgressState?> _progressStateNotifier;
  final ValueNotifier<bool> _isActionExecutingNotifier = FrameSafeValueNotifier<bool>(false);

  @override
  ValueListenable<FluentBarItem<T>> get itemNotifier => _itemNotifier;

  @override
  ValueListenable<FluentBarLifecycleState> get stateNotifier => _stateNotifier;

  @override
  ValueListenable<Duration> get elapsedDurationNotifier => _elapsedDurationNotifier;

  @override
  ValueListenable<Duration> get remainingDurationNotifier => _remainingDurationNotifier;

  @override
  ValueListenable<Duration?> get totalDurationNotifier => _totalDurationNotifier;

  @override
  ValueListenable<double> get remainingProgressNotifier => _remainingProgressNotifier;

  @override
  ValueListenable<double> get elapsedProgressNotifier => _elapsedProgressNotifier;

  @override
  ValueListenable<double?> get taskProgressNotifier => _taskProgressNotifier;

  @override
  ValueListenable<FluentBarProgressState?> get progressStateNotifier => _progressStateNotifier;

  @override
  ValueListenable<bool> get isActionExecutingNotifier => _isActionExecutingNotifier;

  FluentBarEffectEvent? _pendingEffect;
  FluentBarEffectEvent? _latestEffect;

  /// The effect requested last, kept for a widget that was not built yet when it was triggered.
  FluentBarEffectEvent? get latestEffect => _latestEffect;

  final StreamController<FluentBarEffectEvent> _effectController = StreamController<FluentBarEffectEvent>.broadcast();

  /// Attention effects to play, in the order they were requested.
  Stream<FluentBarEffectEvent> get effectStream => _effectController.stream;

  Completer<void> _dismissCompleter = Completer<void>();
  bool _isDismissRequested = false;

  DateTime? _lastActionTime;

  // The budget and the time spent live only in [_lifetime]. The timers below are derived:
  // after ANY change [_sync] decides again whether the clock runs and re-arms them, so the
  // budget may be changed in any state (paused, loading, action running).
  late final _Lifetime _lifetime;

  /// The item duration that was applied to the budget last. Tells "the item changed its
  /// duration" from "the item was rebound for another reason", so add/subtractDuration survive.
  Duration? _itemBudget;

  Timer? _expiryTimer;
  Timer? _tickTimer;
  Duration? _tickInterval;

  bool _isClockRunning = false;

  bool _isShown = false;
  bool _isClosing = false;
  bool _hasExpired = false;

  bool _isPausedByUser = false;
  bool _isLoading = false;
  bool _loadingHoldsTime = false;
  bool _isActionRunning = false;
  bool _isHeldByTouch = false;

  // Same clock factory as the lifetime, so in tests these move together with it.
  final Stopwatch _queuedWatch = stopwatchFactory()..start();
  final Stopwatch _pausedWatch = stopwatchFactory();
  final Stopwatch _showingWatch = stopwatchFactory();
  final Stopwatch _visibleWatch = stopwatchFactory();

  /// Moves the bar to `visible` if the widget never reports the end of its entrance animation
  /// (for example the overlay is not being painted). Without it such a bar would never time out.
  Timer? _entranceTimer;

  /// How long the fallback waits after the entrance animation should have ended.
  static const Duration entranceFallbackDelay = Duration(milliseconds: 250);

  bool _wasVisible = false;

  int _updateCount = 0;
  FluentBarProgressOutcome? _progressOutcome;

  @override
  int get updateCount => _updateCount;

  @override
  FluentBarProgressOutcome? get progressOutcome => _progressOutcome;

  @override
  bool get wasVisible => _wasVisible;

  @override
  Duration get showingDuration => _showingWatch.elapsed;

  @override
  Duration get visibleDuration => _visibleWatch.elapsed;
  final Map<FluentBarInteraction, int> _interactions = <FluentBarInteraction, int>{};

  @override
  Duration get queuedDuration => _queuedWatch.elapsed;

  @override
  Duration get pausedDuration => _pausedWatch.elapsed;

  @override
  Map<FluentBarInteraction, int> get interactions => Map<FluentBarInteraction, int>.unmodifiable(_interactions);

  @override
  void recordInteraction(FluentBarInteraction interaction) => _interactions.update(interaction, (int count) => count + 1, ifAbsent: () => 1);

  /// How long a bar must be held before the touch counts as a pause for analytics.
  /// The countdown stops at once; the threshold keeps every tap and accidental hover from
  /// turning into a paused / resumed pair.
  static const Duration touchPauseReportDelay = Duration(milliseconds: 400);

  Timer? _touchReportTimer;
  bool _isTouchHoldReported = false;

  /// The pause reason reported to analytics (null: no pause was reported).
  FluentBarPauseReason? _reportedPause;

  /// A touch becomes a reason only after the hold threshold.
  FluentBarPauseReason? get _pauseReason {
    if (_isPausedByUser) return FluentBarPauseReason.manual;
    if (_isLoading && _loadingHoldsTime) return FluentBarPauseReason.loading;
    if (_isActionRunning) return FluentBarPauseReason.action;
    if (_isTouchHoldReported) return FluentBarPauseReason.touch;
    return null;
  }

  ({bool? isSwipeEnabled, bool? dismissOnTap})? _gesturesBeforeLoading;

  bool _isDisposed = false;

  @override
  bool get isDisposed => _isDisposed;

  bool get _isVisible => _stateNotifier.value == FluentBarLifecycleState.visible;

  /// The bar is in front of the user: appearing or already in place.
  bool get _isInteractive => _stateNotifier.value.isInteractive;

  /// While the bar waits in the queue [manager] is not assigned yet; then it is the shared instance.
  FluentBarManager get _owner => manager ?? FluentBarManager.instance;

  FluentBarConfig get _config => _owner.config;

  bool get _isHeld => _isPausedByUser || _isHeldByTouch || (_isLoading && _loadingHoldsTime) || _isActionRunning;

  /// Creates a controller for [initialItem]; the bar starts in the queued state.
  FluentBarControllerImpl(FluentBarItem<T> initialItem) : _itemNotifier = _ItemNotifier<T>(initialItem) {
    _itemBudget = initialItem.resolveEffectiveDuration(_config);
    _lifetime = _Lifetime(stopwatchFactory(), _itemBudget);

    _totalDurationNotifier = FrameSafeValueNotifier<Duration?>(_lifetime.total);
    _elapsedDurationNotifier = _LiveNotifier<Duration>(() => _hasExpired ? (_lifetime.total ?? Duration.zero) : _lifetime.elapsed, _updateTicker);
    _remainingDurationNotifier = _LiveNotifier<Duration>(() => _hasExpired ? Duration.zero : _lifetime.remaining, _updateTicker);
    _remainingProgressNotifier = _LiveNotifier<double>(() => _hasExpired ? 0.0 : _lifetime.remainingRatio, _updateTicker);
    _elapsedProgressNotifier = _LiveNotifier<double>(() => _hasExpired ? 1.0 : _lifetime.elapsedRatio, _updateTicker);
    _taskProgressNotifier = FrameSafeValueNotifier<double?>(initialItem.progressState?.progress);
    _progressStateNotifier = FrameSafeValueNotifier<FluentBarProgressState?>(initialItem.progressState);
  }

  /// The only place where the state changes. The library reacts at once; listeners of
  /// [stateNotifier] may be told a moment later if a frame is being built (see [FrameSafeNotifier]).
  void _setState(FluentBarLifecycleState next) {
    if (_stateNotifier.value == next) return;
    _stateNotifier.value = next;
    _onStateChanged();
  }

  void _onStateChanged() {
    if (_isDisposed) return;

    final FluentBarLifecycleState state = _stateNotifier.value;
    if (state == FluentBarLifecycleState.showing) {
      _showingWatch.start();
    } else {
      _showingWatch.stop();
      _entranceTimer?.cancel();
      _entranceTimer = null;
    }
    if (state == FluentBarLifecycleState.visible) {
      _wasVisible = true;
      _visibleWatch.start();
    } else {
      _visibleWatch.stop();
    }

    _sync();

    if (_stateNotifier.value == FluentBarLifecycleState.visible && _pendingEffect != null) {
      final FluentBarEffectEvent effectToPlay = _pendingEffect!;
      _pendingEffect = null;
      if (!_effectController.isClosed) {
        _effectController.add(effectToPlay);
      }
    }
  }

  /// Forgets the last effect once the widget has taken it.
  void clearLatestEffect() => _latestEffect = null;

  /// The only place where the item changes.
  ///
  /// A new position of a shown bar may mean moving to another region. The manager decides
  /// (see [FluentBarRelocationStrategy]); if the move is refused or postponed, the bar stays put.
  void _setItem(FluentBarItem<T> next) {
    // Another button is a new button for the user: the guard against a double tap belongs to
    // the previous one.
    // Not while the handler of the tapped button runs: a button it puts in place appears under
    // the same finger, and the second half of a double tap must not reach it.
    final FluentBarActions<T>? before = _itemNotifier.value.actions;
    final FluentBarActions<T>? after = next.actions;
    final bool isAnotherButton = before?.label != after?.label || _widgetIdentity(before?.child) != _widgetIdentity(after?.child) || (before?.builder == null) != (after?.builder == null);
    if (isAnotherButton && !_isActionRunning) _lastActionTime = null;

    final FluentBarPosition? keep = _owner.relocate(this, next);
    _itemNotifier.value = keep == null ? next : next.copyWith(behavior: next.behavior.copyWith(position: keep));

    if (!_isShown) _owner.syncQueuedRegion(this);
  }

  /// A widget built again is another instance of the same thing: its type and key tell what it is.
  static Object? _widgetIdentity(Widget? widget) => widget == null ? null : (widget.runtimeType, widget.key);

  void _triggerEffect(FluentBarEffect type, double intensity, Duration duration, bool repeat) {
    if (_isDisposed) return;

    final FluentBarEffectEvent event = FluentBarEffectEvent(
      type: type,
      intensity: intensity,
      duration: duration.isNegative || duration == Duration.zero ? const Duration(milliseconds: 400) : duration,
      repeat: repeat,
    );

    _latestEffect = event;

    if (_stateNotifier.value != FluentBarLifecycleState.visible) {
      _pendingEffect = event;
    } else {
      if (!_effectController.isClosed) {
        _effectController.add(event);
      }
    }
  }

  @override
  Future<void> dismiss() async {
    if (_isDisposed || isClosedBeforeShow) return;

    if (!_isDismissRequested) {
      _isDismissRequested = true;
      _setState(FluentBarLifecycleState.hiding);
    }
    return _dismissCompleter.future;
  }

  @override
  void notifyDismissCompleted() {
    if (_isDisposed) return;
    if (!_dismissCompleter.isCompleted) {
      _dismissCompleter.complete();
    }
  }

  @override
  void changeState(FluentBarLifecycleState newState) {
    if (_isDisposed) return;
    _setState(newState);
  }

  @override
  void returnToQueue(FluentBarPosition position) {
    if (_isDisposed) return;

    _isShown = false;
    _isClosing = false;
    _hasExpired = false;
    _isHeldByTouch = false;
    _touchReportTimer?.cancel();
    _touchReportTimer = null;
    _isTouchHoldReported = false;
    _reportedPause = null;
    manager = null;
    _queuedWatch.start();

    // The dismissal was not a real one: the next show needs a fresh "exit animation finished" signal.
    _isDismissRequested = false;
    if (!_dismissCompleter.isCompleted) _dismissCompleter.complete();
    _dismissCompleter = Completer<void>();

    final FluentBarItem<T> item = _itemNotifier.value;
    _itemNotifier.value = item.copyWith(behavior: item.behavior.copyWith(position: position));

    _lifetime.reset(_itemBudget);
    _setState(FluentBarLifecycleState.queued);
    _sync();
  }

  @override
  bool accepts(FluentBarItem<dynamic> item) => item is FluentBarItem<T> && item.hasPayloadType<T>();

  bool _isCancellingProgress = false;
  bool _isProgressCanceled = false;

  bool get _removesActionWithProgress => _itemNotifier.value.actions?.removeWhenProgressEnds ?? false;

  @override
  void beginProgressCancel() => _isCancellingProgress = true;

  @override
  void abortProgressCancel() => _isCancellingProgress = false;

  @override
  void rebindItem(FluentBarItem<T> newItem, {bool resetTimer = false, bool isNewShow = false}) {
    if (_isDisposed) return;

    final bool answered = isNewShow && _stopAwaitingAnswer();
    final FluentBarProgressState? oldProgress = _progressStateNotifier.value;
    FluentBarProgressState? newProgress = newItem.progressState;

    // A re-show with the same id is also a way to send progress, so the cancel rules apply to
    // it: while the task is being stopped the progress stays as it is. The rest of the update
    // (texts, behavior, look) is applied.
    if (_isCancellingProgress && newProgress != null && !newProgress.isCompleted) newProgress = oldProgress;
    // After a cancellation the existing bar has no progress, so a re-show with one starts over.
    if (newProgress != null) _isProgressCanceled = false;

    final bool completedNow = (oldProgress == null || !oldProgress.isCompleted) && (newProgress != null && newProgress.isCompleted);
    final FluentBarItem<T> boundItem = newItem.copyWith(
      uuid: _itemNotifier.value.uuid,
      progressState: newProgress,
      clearProgressState: newProgress == null,
      clearActions: (completedNow && (newItem.actions?.removeWhenProgressEnds ?? false)) || (newProgress != null && _retryAction != null && identical(newItem.actions, _retryAction)),
    );
    _updateCount++;

    _setItem(boundItem);
    _taskProgressNotifier.value = newProgress?.progress;
    _progressStateNotifier.value = newProgress;

    if (completedNow) {
      _handleProgressCompletion(boundItem);
      return;
    }

    _applyItemBudget(reset: resetTimer || answered);
  }

  @override
  void startTimersOnShow(Duration? duration, FluentBarManager managerInstance, {Duration entrance = Duration.zero}) {
    if (_isDisposed) return;
    manager = managerInstance;
    _isShown = true;
    _queuedWatch.stop();

    _itemBudget = _awaitsAnswer || _itemNotifier.value.resolveIsPersistent(_config) ? null : duration;
    _lifetime.reset(_itemBudget);
    _sync();

    // The countdown starts when the bar is in place, not while it is still moving in. Without
    // an entrance animation that is right now.
    _entranceTimer?.cancel();
    _entranceTimer = null;
    if (entrance <= Duration.zero) {
      markEntranceCompleted();
    } else {
      _entranceTimer = Timer(entrance + entranceFallbackDelay, markEntranceCompleted);
    }
  }

  @override
  void markEntranceCompleted() {
    if (_isDisposed || _stateNotifier.value != FluentBarLifecycleState.showing) return;
    _setState(FluentBarLifecycleState.visible);
  }

  @override
  void addDuration(Duration extraDuration) {
    if (_isDisposed || _isNegative(extraDuration, 'addDuration') || !_isInteractive || !_lifetime.isTimed) return;

    _lifetime.shift(extraDuration);
    _sync();
  }

  @override
  void subtractDuration(Duration lessDuration) {
    if (_isDisposed || _isNegative(lessDuration, 'subtractDuration') || !_isInteractive || !_lifetime.isTimed) return;

    if (_lifetime.remaining <= lessDuration) {
      FluentBarErrorHandler.instance.handle(
        StateError('Cannot subtract duration greater than remaining duration.'),
        FluentBarErrorType.subtractDuration,
        StackTrace.current,
        FluentBarErrorSeverity.warning,
        'Cannot subtract duration greater than remaining duration.',
      );
      return;
    }

    _lifetime.shift(-lessDuration);
    _sync();
  }

  /// A negative amount would turn adding into taking away and back: it is reported and ignored.
  static bool _isNegative(Duration amount, String call) {
    if (!amount.isNegative) return false;
    FluentBarErrorHandler.instance.handle(
      ArgumentError.value(amount, 'duration', '$call takes a positive duration; nothing was changed'),
      FluentBarErrorType.invalidCall,
      StackTrace.current,
      FluentBarErrorSeverity.warning,
      call,
    );
    return true;
  }

  @override
  void updateContent({String? title, String? message, T? payload, FluentBarType? type, bool clearTitle = false}) {
    if (_isDisposed) return;
    _updateCount++;
    _setItem(_itemNotifier.value.copyWith(title: title, message: message, payload: payload, type: type, clearTitle: clearTitle));
    // The new type may have another duration: apply it now, not on the next rebind.
    if (type != null) _applyItemBudget(reset: false);
  }

  @override
  void patchBehavior(FluentBarBehavior Function(FluentBarBehavior current) update) {
    if (_isDisposed) return;
    final FluentBarBehavior? updated = _patch(() => update(_itemNotifier.value.behavior), 'patchBehavior');
    if (updated != null) updateBehavior(behavior: updated);
  }

  @override
  void makePersistent() => updateDuration(null);

  @override
  void removeAction() => updateActions(null);

  @override
  void patchAppearance(FluentBarAppearance<dynamic> Function(FluentBarAppearance<T> current) update) {
    if (_isDisposed) return;

    // The callback is typed loosely so that it can be passed through a `FluentBarController<dynamic>`
    // reference; a copy of `current` always has the right type.
    final FluentBarAppearance<dynamic>? updated = _patch(() => update(_itemNotifier.value.appearance), 'patchAppearance');
    if (updated == null) return;
    if (updated is! FluentBarAppearance<T>) {
      FluentBarErrorHandler.instance.handle(
        ArgumentError.value(updated, 'update', 'patchAppearance must return a copy of the appearance it was given (current.copyWith(...))'),
        FluentBarErrorType.patchCallback,
        StackTrace.current,
        FluentBarErrorSeverity.warning,
        'patchAppearance',
      );
      return;
    }
    updateAppearance(updated);
  }

  /// Runs the callback of a patch method; a throw is reported and leaves the bar unchanged.
  static R? _patch<R extends Object>(R Function() update, String name) =>
      FluentBarErrorHandler.instance.executeSafe<R?>(overrideCall: update, fallbackCall: () => null, type: FluentBarErrorType.patchCallback, debugContext: name);

  @override
  void updateBehavior({FluentBarBehavior? behavior, bool? isPersistent}) {
    if (_isDisposed) return;
    final FluentBarItem<T> updatedItem = _itemNotifier.value.copyWith(behavior: behavior, isPersistent: isPersistent);
    rebindItem(updatedItem, resetTimer: false);
  }

  @override
  void updateDuration(Duration? newDuration, {bool resetTimer = false}) {
    if (_isDisposed) return;

    final bool newIsPersistent = newDuration == null;

    _updateCount++;
    _stopAwaitingAnswer();
    _setItem(_itemNotifier.value.copyWith(duration: newDuration, clearDuration: newIsPersistent, isPersistent: newIsPersistent));

    _applyItemBudget(reset: resetTimer, force: true);
  }

  @override
  void pause() {
    if (_isDisposed || _isPausedByUser) return;
    _isPausedByUser = true;
    _sync();
  }

  @override
  void resume() {
    if (_isDisposed || !_isPausedByUser) return;
    _isPausedByUser = false;
    _sync();
  }

  @override
  void shake({double intensity = 8.0, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) {
    _triggerEffect(FluentBarEffect.shake, intensity.abs(), duration, repeat);
  }

  @override
  void bounce({double scale = 0.1, Duration duration = const Duration(milliseconds: 400), bool repeat = false}) {
    _triggerEffect(FluentBarEffect.bounce, scale.abs().clamp(0.0, 2.0), duration, repeat);
  }

  @override
  void pulse({double scale = 1.05, Duration duration = const Duration(milliseconds: 600), bool repeat = false}) {
    _triggerEffect(FluentBarEffect.pulse, scale.abs(), duration, repeat);
  }

  @override
  void heartbeat({double scale = 1.15, Duration duration = const Duration(milliseconds: 800), bool repeat = false}) {
    _triggerEffect(FluentBarEffect.heartbeat, scale.abs(), duration, repeat);
  }

  @override
  void customEffect({double intensity = 1.0, Duration duration = const Duration(milliseconds: 500), bool repeat = false}) {
    _triggerEffect(FluentBarEffect.custom, intensity, duration, repeat);
  }

  @override
  void triggerEffect(FluentBarEffect type, {double? intensity, Duration? duration, bool repeat = false}) {
    if (_isDisposed) return;

    final double defaultIntensity = switch (type) {
      FluentBarEffect.shake => 8.0,
      FluentBarEffect.bounce => 0.1,
      FluentBarEffect.pulse => 1.05,
      FluentBarEffect.heartbeat => 1.15,
      FluentBarEffect.custom => 1.0,
    };

    final Duration defaultDuration = switch (type) {
      FluentBarEffect.shake => const Duration(milliseconds: 400),
      FluentBarEffect.bounce => const Duration(milliseconds: 400),
      FluentBarEffect.pulse => const Duration(milliseconds: 600),
      FluentBarEffect.heartbeat => const Duration(milliseconds: 800),
      FluentBarEffect.custom => const Duration(milliseconds: 500),
    };

    _triggerEffect(type, (intensity ?? defaultIntensity).abs(), duration ?? defaultDuration, repeat);
  }

  @override
  void updateActions(FluentBarActions<T>? actions) {
    if (_isDisposed) return;
    _updateCount++;
    final bool answered = _stopAwaitingAnswer();
    _setItem(_itemNotifier.value.copyWith(actions: actions, clearActions: actions == null));
    if (answered) _applyItemBudget(reset: true);
  }

  @override
  void updateAppearance(FluentBarAppearance<T> appearance) {
    if (_isDisposed) return;
    _updateCount++;
    _setItem(_itemNotifier.value.copyWith(appearance: appearance));
  }

  @override
  void updateProgress(FluentBarProgressState newProgressState, {String? completedMessage, String? completedTitle, FluentBarType? completedType}) {
    if (_isDisposed) return;
    // A stopped task may still send what was on its way; a finished one is let through.
    if (_isProgressCanceled || (_isCancellingProgress && !newProgressState.isCompleted)) return;
    _stopAwaitingAnswer();
    if (_showsRetry) _setItem(_itemNotifier.value.copyWith(clearActions: true));
    final FluentBarProgressState? oldState = _progressStateNotifier.value;

    _taskProgressNotifier.value = newProgressState.progress;
    _progressStateNotifier.value = newProgressState;

    final bool isCompletion = (oldState == null || !oldState.isCompleted) && newProgressState.isCompleted;

    if (isCompletion) {
      final FluentBarItem<T> updatedItem = _itemNotifier.value.copyWith(
        progressState: newProgressState,
        message: completedMessage ?? _itemNotifier.value.message,
        title: completedTitle ?? _itemNotifier.value.title,
        type: completedType ?? _itemNotifier.value.type,
        clearActions: _removesActionWithProgress,
      );
      _setItem(updatedItem);
      _handleProgressCompletion(updatedItem);
    } else {
      _setItem(_itemNotifier.value.copyWith(progressState: newProgressState));
      // Unfinished progress makes the bar persistent; the budget must reflect that.
      _applyItemBudget(reset: false);
    }
  }

  @override
  void setTouchHold({required bool isHeld}) {
    if (_isDisposed || _isHeldByTouch == isHeld) return;
    _isHeldByTouch = isHeld;

    _touchReportTimer?.cancel();
    _touchReportTimer = null;
    _isTouchHoldReported = false;
    if (isHeld) {
      _touchReportTimer = Timer(touchPauseReportDelay, () {
        _touchReportTimer = null;
        _isTouchHoldReported = true;
        recordInteraction(FluentBarInteraction.hold);
        _sync();
      });
    }

    _sync();
  }

  @override
  void stopTimers() {
    if (_isDisposed) return;
    _isClosing = true;
    _sync();
  }

  @override
  void force({OverlayState? overlayState}) {
    if (_isDisposed) return;
    _owner.forceController(this, overlayState: overlayState);
  }

  @override
  Future<void> handleAction({
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed,
    bool closeOnAction = true,
    Duration throttleDuration = const Duration(milliseconds: 400),
  }) async {
    if (_isDisposed || !_isInteractive) return;

    if (_isActionExecutingNotifier.value) return;

    final DateTime now = DateTime.now();
    if (_lastActionTime != null && now.difference(_lastActionTime!) < throttleDuration) {
      _lastActionTime = now;
      return;
    }

    _lastActionTime = now;
    _isActionRunning = true;
    _syncBusy();

    try {
      final T? payload = itemNotifier.value.payload;

      recordInteraction(FluentBarInteraction.action);
      _owner.notifyAnalytics(FluentBarAnalyticsEvent.actionTapped, itemNotifier.value);

      if (closeOnAction) {
        close(reason: FluentBarDismissReason.actionButton);
      }

      if (onPressed != null) {
        await FluentBarErrorHandler.instance.executeSafeAsync(overrideCall: () => onPressed(this, payload), type: FluentBarErrorType.actionPressed);
      }
    } finally {
      if (!_isDisposed) {
        _isActionRunning = false;
        _syncBusy();
      }
    }
  }

  @override
  void close({FluentBarDismissReason reason = FluentBarDismissReason.manual}) {
    if (_isDisposed) return;
    if (manager == null) {
      isClosedBeforeShow = true;
      if (!FluentBarManager.instance.discardQueuedByController(this)) {
        _setState(FluentBarLifecycleState.dismissed);
        dispose();
      }
      return;
    }
    manager?.dismissController(this, reason: reason);
  }

  @override
  void setLoading({required bool isLoading, bool? dismissOnTap, bool? isSwipeEnabled, bool pauseTimeoutTimer = true}) {
    if (_isDisposed || _isLoading == isLoading) return;

    final FluentBarBehavior behavior = _itemNotifier.value.behavior;
    final bool? nextSwipe;
    final bool? nextDismissOnTap;

    if (isLoading) {
      _gesturesBeforeLoading = (isSwipeEnabled: behavior.isSwipeEnabled, dismissOnTap: behavior.dismissOnTap);
      nextSwipe = isSwipeEnabled ?? false;
      nextDismissOnTap = dismissOnTap ?? false;
    } else {
      // Restore the gestures as they were before loading (`null` means "the type or the config decides").
      nextSwipe = isSwipeEnabled ?? _gesturesBeforeLoading?.isSwipeEnabled;
      nextDismissOnTap = dismissOnTap ?? _gesturesBeforeLoading?.dismissOnTap;
      _gesturesBeforeLoading = null;
    }

    _isLoading = isLoading;
    _loadingHoldsTime = isLoading && pauseTimeoutTimer;

    _setItem(
      _itemNotifier.value.copyWith(
        behavior: behavior.withGestures(isSwipeEnabled: nextSwipe, dismissOnTap: nextDismissOnTap),
      ),
    );

    _syncBusy();
  }

  @override
  void cancelProgress({String? fallbackMessage, FluentBarType? fallbackType, bool dismiss = false}) {
    if (_isDisposed) return;
    // The progress has already ended (completed or failed), or there was none: nothing to cancel.
    if (_progressStateNotifier.value == null) {
      if (dismiss) close(reason: FluentBarDismissReason.manual);
      return;
    }
    _progressOutcome = FluentBarProgressOutcome.canceled;
    _isProgressCanceled = _isCancellingProgress;
    _owner.notifyProgressCanceled(_itemNotifier.value);

    if (dismiss) {
      close(reason: FluentBarDismissReason.manual);
    } else {
      _endProgress(message: fallbackMessage, type: fallbackType);
    }
  }

  @override
  void completeProgress({String? message, String? title, FluentBarType? type}) {
    if (_isDisposed) return;

    // A fraction completes as "total / total"; everything else completes as 100%.
    final FluentBarProgressState? current = _progressStateNotifier.value;
    final FluentBarProgressState completed = current is FluentBarProgressFraction ? FluentBarProgressFraction(current.total, current.total) : const FluentBarProgressValue(1.0);

    updateProgress(completed, completedMessage: message, completedTitle: title, completedType: type);
  }

  @override
  void failProgress({String? message, String? title, FluentBarType? type, String? retryLabel, FutureOr<void> Function()? onRetry, bool? isPersistent}) {
    if (_isDisposed) return;
    // A Retry button without a callback would do nothing, and a callback without a button would
    // never be called: the bar fails without a Retry button, and the misuse is reported.
    final bool isPaired = (retryLabel == null) == (onRetry == null);
    if (!isPaired) {
      FluentBarErrorHandler.instance.handle(
        ArgumentError('failProgress: retryLabel and onRetry go together; the bar fails without a Retry button.'),
        FluentBarErrorType.invalidCall,
        StackTrace.current,
        FluentBarErrorSeverity.warning,
        'failProgress',
      );
    }
    final String? label = isPaired ? retryLabel : null;
    final FutureOr<void> Function()? callback = isPaired ? onRetry : null;
    // A task stopped by the Cancel button usually ends with an error: that is not a failure.
    if (_isProgressCanceled) return;
    // Already failed and nothing has run since: one failure is reported once.
    if (_progressStateNotifier.value == null && _progressOutcome == FluentBarProgressOutcome.failed) return;
    _progressOutcome = FluentBarProgressOutcome.failed;
    _owner.notifyProgressFailed(_itemNotifier.value);

    final FluentBarActions<T>? retry = label == null
        ? null
        : FluentBarActions<T>(
            label: label,
            closeOnAction: false,
            analyticsName: 'retry',
            // The work is done after the handler has returned. The callback may be the whole
            // task, and an action that runs keeps the bar busy: the Cancel button of the new
            // attempt would not answer, and the countdown would be reported as paused.
            onPressed: (FluentBarController<T> controller, T? payload) => Timer.run(() => _retry(callback)),
          );

    _retryAction = retry;
    _awaitsAnswer = isPersistent ?? retry != null;
    _endProgress(message: message, title: title, type: type ?? FluentBarType.error, actions: retry);
  }

  void _retry(FutureOr<void> Function()? onRetry) {
    if (_isDisposed) return;
    removeAction();
    if (onRetry != null) {
      unawaited(FluentBarErrorHandler.instance.executeSafeAsync(overrideCall: () async => onRetry(), type: FluentBarErrorType.actionPressed));
    }
    // A button that the callback has put in place appeared under the finger that tapped Retry.
    _lastActionTime = DateTime.now();
  }

  /// The Retry button put by [failProgress], to take it away when the progress goes on without a tap.
  FluentBarActions<T>? _retryAction;

  bool get _showsRetry => _retryAction != null && identical(_itemNotifier.value.actions, _retryAction);

  /// Whether a failed bar is held on screen until the user answers: a tap on Retry, another
  /// button, a new progress or duration, or the same id shown again. It is a state of the bar,
  /// not of its item.
  bool _awaitsAnswer = false;

  @override
  bool get isAwaitingAnswer => _awaitsAnswer;

  bool _stopAwaitingAnswer() {
    final bool wasAwaiting = _awaitsAnswer;
    _awaitsAnswer = false;
    return wasAwaiting;
  }

  /// Removes the indicator and starts the usual countdown; texts and type change only if given.
  void _endProgress({String? message, String? title, FluentBarType? type, FluentBarActions<T>? actions}) {
    _isCancellingProgress = false;
    _setItem(_itemNotifier.value.copyWith(message: message, title: title, type: type, clearProgressState: true, actions: actions, clearActions: actions == null && _removesActionWithProgress));
    _taskProgressNotifier.value = null;
    _progressStateNotifier.value = null;

    _applyItemBudget(reset: true);
  }

  void _handleProgressCompletion(FluentBarItem<T> item) {
    // The task may finish while the bar is still queued: callbacks and analytics must fire anyway.
    _isCancellingProgress = false;
    _progressOutcome = FluentBarProgressOutcome.completed;
    _owner.notifyProgressCompleted(item);
    _applyItemBudget(reset: true);
  }

  /// Brings the budget in line with the duration of the current item.
  ///
  /// With [reset] the countdown starts over. Otherwise the budget changes (keeping the time
  /// already spent) only if the duration of the item changed or [force] is set, so a
  /// rebind for an unrelated reason does not undo add/subtractDuration.
  void _applyItemBudget({required bool reset, bool force = false}) {
    final Duration? target = _awaitsAnswer ? null : _itemNotifier.value.resolveEffectiveDuration(_config);

    if (reset) {
      _lifetime.reset(target);
    } else if (force || target != _itemBudget) {
      _lifetime.retarget(target);
    }

    _itemBudget = target;
    _sync();
  }

  void _syncBusy() {
    _isActionExecutingNotifier.value = _isLoading || _isActionRunning;
    _sync();
  }

  /// The only place that decides whether the clock runs and arms the timers.
  void _sync() {
    if (_isDisposed) return;

    final bool shouldRun = _isShown && !_isClosing && _isVisible && _lifetime.isTimed && !_isHeld;

    // Pause and resume are reported only for a bar on screen that has a countdown to stop.
    final bool isCounting = _isShown && !_isClosing && _isVisible && _lifetime.isTimed;
    isCounting && _isHeld ? _pausedWatch.start() : _pausedWatch.stop();
    final FluentBarPauseReason? reason = _pauseReason;
    if (isCounting && (reason == null) != (_reportedPause == null)) {
      final FluentBarPauseReason reported = reason ?? _reportedPause!;
      _reportedPause = reason;
      _owner.notifyAnalytics(reason == null ? FluentBarAnalyticsEvent.resumed : FluentBarAnalyticsEvent.paused, _itemNotifier.value, pauseReason: reported);
    }

    _expiryTimer?.cancel();
    _expiryTimer = null;

    _isClockRunning = shouldRun;
    if (shouldRun) {
      _lifetime.start();
      _expiryTimer = Timer(_lifetime.remaining, _onExpired);
    } else {
      _lifetime.stop();
    }

    _updateTicker();
    _publish();
  }

  /// The ticker is needed only while the clock runs and somebody watches the time.
  /// Called on a state change and when a time value gains or loses its last listener.
  void _updateTicker() {
    if (_isDisposed) return;

    final bool isObserved = _elapsedDurationNotifier.isObserved || _remainingDurationNotifier.isObserved || _remainingProgressNotifier.isObserved || _elapsedProgressNotifier.isObserved;
    _isClockRunning && isObserved ? _startTicker() : _stopTicker();
  }

  void _onExpired() {
    _expiryTimer = null;
    if (_isDisposed) return;

    // Trust the timer instead of re-reading the clock: timers use fake time in widget tests.
    _isClosing = true;
    _hasExpired = true;
    _isClockRunning = false;
    _lifetime.stop();
    _stopTicker();
    _publish();

    manager?.dismissController(this, reason: FluentBarDismissReason.timeout);
  }

  void _startTicker() {
    final Duration interval = _itemNotifier.value.resolveProgressInterval(_config);
    if (_tickTimer != null && _tickInterval == interval) return;

    _stopTicker();
    if (interval <= Duration.zero) return;

    _tickInterval = interval;
    _tickTimer = Timer.periodic(interval, (_) => _publish());
  }

  void _stopTicker() {
    _tickTimer?.cancel();
    _tickTimer = null;
    _tickInterval = null;
  }

  void _publish() {
    if (_isDisposed) return;

    _totalDurationNotifier.value = _lifetime.total;

    _elapsedDurationNotifier.publish();
    _remainingDurationNotifier.publish();
    _remainingProgressNotifier.publish();
    _elapsedProgressNotifier.publish();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    if (!_dismissCompleter.isCompleted) {
      _dismissCompleter.complete();
    }

    _pendingEffect = null;
    _latestEffect = null;

    _expiryTimer?.cancel();
    _expiryTimer = null;
    _entranceTimer?.cancel();
    _entranceTimer = null;
    _touchReportTimer?.cancel();
    _touchReportTimer = null;
    _queuedWatch.stop();
    _pausedWatch.stop();
    _showingWatch.stop();
    _visibleWatch.stop();
    _stopTicker();
    _lifetime.stop();

    _itemNotifier.dispose();
    _stateNotifier.dispose();
    _elapsedDurationNotifier.dispose();
    _elapsedProgressNotifier.dispose();
    _remainingProgressNotifier.dispose();
    _remainingDurationNotifier.dispose();
    _totalDurationNotifier.dispose();
    _taskProgressNotifier.dispose();
    _progressStateNotifier.dispose();
    _isActionExecutingNotifier.dispose();

    if (!_effectController.isClosed) {
      _effectController.close();
    }
  }

  /// Clock factory for the lifetime. Tests replace it with a controllable [Stopwatch]
  /// (for example `clock.stopwatch()`) so that time moves together with fake async.
  @visibleForTesting
  static Stopwatch Function() stopwatchFactory = Stopwatch.new;
}

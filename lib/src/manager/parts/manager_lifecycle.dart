part of '../fluent_bar_manager.dart';

/// Initialization and closing of bars.
extension FluentBarManagerLifecycle on FluentBarManager {
  /// Sets the config and the navigator once; a second call is reported as an error.
  void initialize(FluentBarConfig config, {GlobalKey<NavigatorState>? navigatorKey}) {
    if (_isInitialized) {
      FluentBarErrorHandler.instance.handle(StateError('FluentBar: Already initialized. Use FluentBar.updateConfig() to update settings.'), FluentBarErrorType.initialization, StackTrace.current);
      return;
    }

    _config = config;
    _configNotifier.value = config;
    _navigatorKey = navigatorKey;
    _isInitialized = true;
    _scheduleDequeue();
  }

  /// Closes the bars on screen in both regions.
  Future<void> dismissActive({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    final List<Future<void>> futures = <Future<void>>[];

    if (_activeItems[FluentBarRegion.main] != null) {
      futures.add(_dismissCurrentInRegion(FluentBarRegion.main, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation));
    }
    if (_activeItems[FluentBarRegion.bottom] != null) {
      futures.add(_dismissCurrentInRegion(FluentBarRegion.bottom, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation));
    }

    await Future.wait(futures);
  }

  /// Closes the bar that appeared last.
  Future<void> dismissLatest({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    final FluentBarRegion? region = _latestActiveRegion;

    if (region != null) {
      await _dismissCurrentInRegion(region, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);
    }
  }

  /// Closes the bar of [controller], shown or queued.
  Future<void> dismissController(
    FluentBarInternalController<dynamic> controller, {
    FluentBarDismissReason reason = FluentBarDismissReason.manual,
    OverlayState? overlayState,
    bool skipAnimation = false,
  }) async {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active != null && identical(active.internalController, controller)) {
        await _dismissCurrentInRegion(region, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);
        return;
      }
    }

    if (!discardQueuedByController(controller, reason: reason)) {
      if (controller is FluentBarControllerImpl) {
        controller.changeState(FluentBarLifecycleState.dismissed);
        controller.dispose();
      }
    }
  }

  /// Closes the bar shown in the top region.
  Future<void> dismissCurrentMain({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    await _dismissCurrentInRegion(FluentBarRegion.main, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);
  }

  /// Closes the bar shown in the bottom region.
  Future<void> dismissCurrentBottom({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    await _dismissCurrentInRegion(FluentBarRegion.bottom, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);
  }

  /// Clears the queues and closes the bars on screen with their exit animation.
  Future<void> dismissAll({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    // Only the bars that are there now: one shown from an onDismiss of a waiting bar is a new bar and stays.
    final List<(FluentBarRegion, FluentBarEntry<dynamic>)> shown = _shownBars();
    _discardQueued(reason: reason);

    await Future.wait(<Future<void>>[
      for (final (FluentBarRegion region, FluentBarEntry<dynamic> active) in shown)
        if (identical(_activeItems[region], active)) _dismissCurrentInRegion(region, reason: reason, overlayState: overlayState, skipAnimation: skipAnimation),
    ]);
  }

  Future<void> _dismissCurrentInRegion(FluentBarRegion region, {FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async {
    final FluentBarEntry<dynamic>? target = _activeItems[region];
    if (target == null) return;

    // Without a mounted overlay entry there is no widget to play the exit: waiting for it would
    // keep the region for a bar nobody sees.
    final bool skip = skipAnimation || reason == FluentBarDismissReason.swipe || !(_activeOverlayEntries[region]?.mounted ?? false);
    final FluentBarInternalController<dynamic> controller = target.internalController;

    if (_dismissingEntries[region] != null) {
      if (skip) {
        _finalizeDismiss(target, region, reason, _buildMetrics(target, reason), overlayState: overlayState);
      } else if (_relocating.contains(target)) {
        // Its exit animation already runs, as a move. When it ends the bar is closed, not queued.
        _closedWhileRelocating.putIfAbsent(target, () => reason);
      }
      return;
    }

    _dismissingEntries[region] = target;

    controller.stopTimers();

    final FluentBarMetrics metrics = _buildMetrics(target, reason);

    if (!skip && !controller.isDisposed) {
      // dismiss() never fails; the timeout covers a widget that never reports the end of its
      // animation (for example, it is already off screen).
      final Duration limit = target.resolveReverseTransitionDuration(_config) + FluentBarManager._exitAnimationMargin;
      await controller.dismiss().timeout(limit, onTimeout: () {});
    }
    _finalizeDismiss(target, region, reason, metrics, overlayState: overlayState);
  }

  void _finalizeDismiss(FluentBarEntry<dynamic> entry, FluentBarRegion region, FluentBarDismissReason reason, FluentBarMetrics metrics, {OverlayState? overlayState}) {
    if (!identical(_activeItems[region], entry)) return;

    final FluentBarItem<dynamic> item = entry.currentItem;
    _releaseActive(entry, region);
    _announceDismissed(item, metrics);

    // With one queue the next bar always comes from main, wherever the current one closed.
    _showNextForRegion(_config.enableMultiRegion ? region : FluentBarRegion.main, overlayState: overlayState);
  }

  /// Takes a shown bar off screen and frees its region. Notifies nobody about a dismissal.
  void _releaseActive(FluentBarEntry<dynamic> entry, FluentBarRegion region) {
    _removeOverlayEntryForRegion(region);
    _activeItems[region] = null;
    _dismissingEntries[region] = null;

    final FluentBarInternalController<dynamic> controller = entry.internalController;
    if (!controller.isDisposed) {
      controller.stopTimers();
      controller.changeState(FluentBarLifecycleState.dismissed);
      controller.notifyDismissCompleted();
      scheduleMicrotask(controller.dispose);
    }
  }

  void _announceDismissed(FluentBarItem<dynamic> item, FluentBarMetrics metrics) {
    unawaited(_safeExecute(() => item.notifyDismissed(metrics), FluentBarErrorType.callbackDismiss));
    notifyAnalytics(FluentBarAnalyticsEvent.dismissed, item, metrics: metrics);
  }

  /// Ends a bar that is not on screen.
  ///
  /// [reason] is given for a bar that waited in the queue: it ends like a shown one, once, with
  /// `onDismiss` and the `dismissed` event. [event] is reported before that (`queueOverflow` for a
  /// bar dropped because the queue was full); a bar that never got into the queue gets only [event].
  void _discard(FluentBarEntry<dynamic> entry, {FluentBarAnalyticsEvent? event, FluentBarDismissReason? reason}) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      if (identical(_forcedNexts[region], entry)) _forcedNexts[region] = null;
    }

    final FluentBarInternalController<dynamic> ctrl = entry.internalController;
    if (ctrl.isDisposed) return;

    final FluentBarItem<dynamic> item = entry.currentItem;

    // A bar that never reached the screen still tells how long it waited and why it is gone.
    final bool isHeard = _analyticsListeners != null && event == FluentBarAnalyticsEvent.queueOverflow && !_config.disabledAnalyticsEvents.contains(event);
    final FluentBarMetrics? overflowMetrics = isHeard ? _buildMetrics(entry, FluentBarDismissReason.dropped) : null;
    final FluentBarMetrics? endMetrics = reason == null ? null : _buildMetrics(entry, reason);

    ctrl.changeState(FluentBarLifecycleState.dismissed);
    ctrl.dispose();

    if (event == null && endMetrics == null) return;
    void notify() {
      if (event != null) notifyAnalytics(event, item, metrics: overflowMetrics);
      if (endMetrics != null) _announceDismissed(item, endMetrics);
    }

    if (_queueChangeDepth > 0) {
      (_pendingEndNotifications ??= <void Function()>[]).add(notify);
    } else {
      notify();
    }
  }

  /// Runs [change] on the queues; the bars it ends are announced after it, when the queues are
  /// consistent again.
  R _changeQueues<R>(R Function() change) {
    _queueChangeDepth++;
    try {
      return change();
    } finally {
      _queueChangeDepth--;
      if (_queueChangeDepth == 0) _flushEndNotifications();
    }
  }

  void _flushEndNotifications() {
    // A notification may end more bars; those are announced in the same loop.
    while (_pendingEndNotifications != null) {
      final List<void Function()> pending = _pendingEndNotifications!;
      _pendingEndNotifications = null;
      for (final void Function() notify in pending) {
        notify();
      }
    }
  }

  void _triggerHaptic(FluentBarEntry<dynamic> entry) {
    if (!_config.enableHaptics) return;

    if (entry.resolveHapticCallback(_config) != null) {
      _safeExecute(entry.resolveHapticCallback(_config)!, FluentBarErrorType.hapticExternal);
      return;
    }
    HapticHelper.instance.triggerHaptic(entry.resolveHaptic(_config));
  }

  Future<void> _safeExecute(FutureOr<void> Function() action, FluentBarErrorType type) async => FluentBarErrorHandler.instance.executeSafeAsync<void>(overrideCall: () => action(), type: type);

  /// Returns the manager to its initial state between tests.
  @visibleForTesting
  void resetForTesting() {
    dismissAndClear();
    _isInitialized = false;
    _config = const FluentBarConfig();
    _configNotifier.value = _config;
    _activeItems.clear();
    _activeOverlayEntries.clear();
    _scopeOverlayKey = null;
    _navigatorKey = null;
    _dismissingEntries.clear();
    _forcedNexts.clear();
    _relocating.clear();
    _closedWhileRelocating.clear();
    _shownOrders.clear();
    _isDequeueScheduled = false;
    _isMissingOverlayReported = false;
    _topInsets.clear();
    _topInsetNotifier.value = 0;
    _bottomInsets.clear();
    _bottomInsetNotifier.value = 0;
    _allQueueLengthNotifier?.dispose();
    _allQueueLengthNotifier = null;
  }
}

part of '../fluent_bar_manager.dart';

/// The overlay bars are inserted into.
extension FluentBarManagerOverlay on FluentBarManager {
  /// Registers the overlay of a `FluentBarScope` and shows the bars that were waiting for one.
  void registerScopeOverlayKey(GlobalKey<OverlayState> key) {
    _scopeOverlayKey = key;
    WidgetsBinding.instance.addPostFrameCallback((_) => tryDequeuePending());
  }

  /// Leaves a key of another scope alone: when one scope replaces another, the new one registers
  /// before the old one is disposed.
  void unregisterScopeOverlayKey(GlobalKey<OverlayState> key) {
    if (identical(_scopeOverlayKey, key)) _scopeOverlayKey = null;
  }

  OverlayState? _getOverlayState({OverlayState? overlayState}) {
    if (overlayState != null && overlayState.mounted) return overlayState;

    final OverlayState? scopeOverlay = _scopeOverlayKey?.currentState;
    if (scopeOverlay != null && scopeOverlay.mounted) return scopeOverlay;

    final OverlayState? observerOverlay = FluentBarObserver.instance.overlay;
    if (observerOverlay != null && observerOverlay.mounted) return observerOverlay;

    final OverlayState? navOverlay = _navigatorKey?.currentState?.overlay;
    if (navOverlay != null && navOverlay.mounted) return navOverlay;

    return null;
  }

  void _presentInRegion(FluentBarEntry<dynamic> entry, FluentBarRegion region, OverlayState overlay) {
    final FluentBarInternalController<dynamic> internalController = entry.internalController;

    _activeItems[region] = entry;
    _dismissingEntries[region] = null;
    _shownOrders[region] = ++_showCounter;
    internalController.changeState(FluentBarLifecycleState.showing);

    // The overlay is mounted here (see _getOverlayState), but the insert may still fail, for
    // example if it was passed in from outside in a broken state.
    final OverlayEntry overlayEntry = OverlayEntry(builder: (BuildContext overlayContext) => entry.buildWidget(_config));
    try {
      overlay.insert(overlayEntry);
    } catch (error, stackTrace) {
      FluentBarErrorHandler.instance.handle(error, FluentBarErrorType.overlay, stackTrace);
      overlayEntry.dispose();
      _activeItems[region] = null;
      _discard(entry, event: FluentBarAnalyticsEvent.dismissed);
      return;
    }
    _activeOverlayEntries[region] = overlayEntry;

    final Duration actualDuration = entry.resolveDuration(_config);
    final bool isPersistent = entry.resolveIsPersistent(_config);

    // The bar stays `showing` while it moves in and becomes `visible` when the widget reports the
    // end of the entrance animation. With animations off both happen here, one after the other.
    final Duration entrance = entry.resolveDisableAnimations(_config) ? Duration.zero : entry.resolveTransitionDuration(_config);
    internalController.startTimersOnShow(isPersistent ? null : actualDuration, this, entrance: entrance);
    _triggerHaptic(entry);

    final FluentBarItem<dynamic> item = entry.currentItem;
    unawaited(_safeExecute(item.notifyShown, FluentBarErrorType.callbackShow));
    notifyAnalytics(FluentBarAnalyticsEvent.shown, item);
  }

  void _removeOverlayEntryForRegion(FluentBarRegion region) {
    final OverlayEntry? entry = _activeOverlayEntries[region];
    _activeOverlayEntries[region] = null;

    if (entry == null) return;

    // A call from a widget inside the overlay (a content builder, for example) arrives while the
    // overlay builds, and removing an entry it has not mounted yet breaks the frame. The entry
    // leaves at the end of the frame then, before the controller of its bar is disposed.
    final WidgetsBinding binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => _removeOverlayEntry(entry));
    } else {
      _removeOverlayEntry(entry);
    }
  }

  // The entry was inserted by us and is removed exactly once, and remove() copes with a disposed
  // overlay by itself, so there is nothing to catch here.
  static void _removeOverlayEntry(OverlayEntry entry) {
    entry
      ..remove()
      ..dispose();
  }
}

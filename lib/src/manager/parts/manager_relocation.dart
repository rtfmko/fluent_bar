part of '../fluent_bar_manager.dart';

/// Moving a bar between regions when its position changes on the fly.
///
/// A region is a slot on screen that shows one bar. When a bar changes position so that it
/// belongs to another region, the slot must be taken or freed, or two bars would overlap.
/// [FluentBarRelocationStrategy] decides what happens when the target region is busy.
extension FluentBarManagerRelocation on FluentBarManager {
  /// Called by the controller before its item changes to [next].
  ///
  /// Returns the position the bar must keep (the move was refused or postponed), or `null` if
  /// [next] can be applied as it is.
  FluentBarPosition? relocate(FluentBarInternalController<dynamic> controller, FluentBarItem<dynamic> next) {
    // With one queue the slot is shared: the bar is drawn in the new place.
    if (!_config.enableMultiRegion) return null;

    final FluentBarRegion? from = _activeRegionOf(controller);
    if (from == null) return null;

    final FluentBarPosition target = next.resolvePosition(_config);
    final FluentBarRegion to = target.toRegion();
    if (to == from) return null;

    final FluentBarEntry<dynamic> entry = _activeItems[from]!;
    final FluentBarPosition current = entry.resolvePosition(_config);

    if (_dismissingEntries[from] != null) return current;

    final FluentBarEntry<dynamic>? occupant = _activeItems[to];
    if (occupant == null) {
      _moveActive(entry, from, to);
      notifyAnalytics(FluentBarAnalyticsEvent.relocated, next, previousPosition: current);
      _showNextForRegion(from);
      return null;
    }

    switch (next.resolveRelocationStrategy(_config)) {
      case FluentBarRelocationStrategy.ignore:
        return current;

      case FluentBarRelocationStrategy.forceReplace:
        final FluentBarItem<dynamic> occupantItem = occupant.currentItem;
        final FluentBarMetrics metrics = _buildMetrics(occupant, FluentBarDismissReason.force);

        // Take the slot first and notify afterwards: onDismiss may show a new bar synchronously.
        _releaseActive(occupant, to);
        _moveActive(entry, from, to);
        _announceDismissed(occupantItem, metrics);
        notifyAnalytics(FluentBarAnalyticsEvent.relocated, next, previousPosition: current);
        _showNextForRegion(from);
        return null;

      case FluentBarRelocationStrategy.queueNext:
        unawaited(_requeueRelocated(entry, from, target));
        return current;
    }
  }

  /// Called by the controller after the item of a queued bar changed: if the position now belongs
  /// to another region, the bar moves to its queue.
  void syncQueuedRegion(FluentBarInternalController<dynamic> controller) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> queue = _queueOf(region);
      final int index = queue.indexWhere((FluentBarEntry<dynamic> e) => identical(e.internalController, controller));
      if (index == -1) continue;

      final FluentBarEntry<dynamic> entry = queue[index];
      final FluentBarRegion target = _regionOf(entry);
      if (target == region) return;

      queue.removeAt(index);
      if (identical(_forcedNexts[region], entry)) _forcedNexts[region] = null;
      _updateQueueNotifier(region);

      _enqueueViaStrategy(target, entry);
      _showNextForRegion(target);
      return;
    }
  }

  /// Puts [entry] first in the queue of the region, right after forced entries. The queue limit
  /// still holds: the extra entry is evicted from the end.
  void _requeueFirst(FluentBarRegion region, FluentBarEntry<dynamic> entry) {
    final List<FluentBarEntry<dynamic>> queue = _queueOf(region);

    int index = 0;
    while (index < queue.length && queue[index].isForce) {
      index++;
    }
    queue.insert(index, entry);
    if (index == 0) _forcedNexts[region] = entry;

    while (queue.length > _config.maxQueueLength) {
      final int victimIndex = queue.lastIndexWhere((FluentBarEntry<dynamic> e) => !identical(e, entry));
      if (victimIndex == -1) break;
      _discard(queue.removeAt(victimIndex), event: FluentBarAnalyticsEvent.queueOverflow);
    }
    _updateQueueNotifier(region);
  }

  /// The widget of a shown bar was disposed although nobody closed the bar: the overlay itself is
  /// gone (the app recreated the root with `FluentBarScope`, or the navigator). Such a bar is
  /// invisible but would keep its region, and the others would wait behind it, forever in the
  /// case of a persistent bar.
  ///
  /// The bar goes back to the front of its queue and is shown again as soon as there is a place.
  /// It is the same bar (controller, id, callbacks); its countdown starts over.
  void recoverDetached(FluentBarEntry<dynamic> entry) {
    final FluentBarInternalController<dynamic> controller = entry.internalController;
    if (controller.isDisposed) return;

    for (final FluentBarRegion region in FluentBarRegion.values) {
      if (!identical(_activeItems[region], entry)) continue;

      if (_dismissingEntries[region] != null) return;
      // The overlay entry is alive: the widget was merely recreated in place.
      if (_activeOverlayEntries[region]?.mounted ?? false) return;

      _removeOverlayEntryForRegion(region);
      _activeItems[region] = null;

      controller.returnToQueue(entry.resolvePosition(_config));
      _requeueFirst(_regionOf(entry), entry);

      tryDequeuePending();
      if (controller.stateNotifier.value == FluentBarLifecycleState.queued) _scheduleDequeue();
      return;
    }
  }

  FluentBarRegion? _activeRegionOf(FluentBarInternalController<dynamic> controller) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active != null && identical(active.internalController, controller)) return region;
    }
    return null;
  }

  /// Moves a shown bar into a free region: the bar stays on screen, only the slot changes.
  void _moveActive(FluentBarEntry<dynamic> entry, FluentBarRegion from, FluentBarRegion to) {
    _activeItems[to] = entry;
    _activeItems[from] = null;

    _activeOverlayEntries[to] = _activeOverlayEntries[from];
    _activeOverlayEntries[from] = null;

    _shownOrders[to] = _shownOrders.remove(from) ?? ++_showCounter;
  }

  /// [FluentBarRelocationStrategy.queueNext]: the bar hides normally and goes first into the queue
  /// of the new region. It stays the same bar (controller, id, callbacks); `onDismiss` is not called.
  Future<void> _requeueRelocated(FluentBarEntry<dynamic> entry, FluentBarRegion from, FluentBarPosition target) async {
    final FluentBarInternalController<dynamic> controller = entry.internalController;
    final FluentBarPosition previous = entry.resolvePosition(_config);

    _dismissingEntries[from] = entry;
    _relocating.add(entry);
    controller.stopTimers();

    final Duration limit = entry.resolveReverseTransitionDuration(_config) + FluentBarManager._exitAnimationMargin;
    await controller.dismiss().timeout(limit, onTimeout: () {});
    _relocating.remove(entry);
    final FluentBarDismissReason? closedWith = _closedWhileRelocating.remove(entry);

    // The bar may have been closed for real during the animation (swipe, dismissAndClear).
    if (controller.isDisposed || !identical(_activeItems[from], entry)) return;

    if (closedWith != null) {
      _finalizeDismiss(entry, from, closedWith, _buildMetrics(entry, closedWith));
      return;
    }

    _removeOverlayEntryForRegion(from);
    _activeItems[from] = null;
    _dismissingEntries[from] = null;

    controller.returnToQueue(target);

    // The region is computed again: the config may have changed during the animation (enableMultiRegion turned off).
    final FluentBarRegion to = _regionOf(entry);
    _requeueFirst(to, entry);
    notifyAnalytics(FluentBarAnalyticsEvent.relocated, entry.currentItem, previousPosition: previous);

    _showNextForRegion(_config.enableMultiRegion ? from : FluentBarRegion.main);
    _showNextForRegion(to);
  }
}

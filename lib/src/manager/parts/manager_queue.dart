part of '../fluent_bar_manager.dart';

/// The queue: showing, duplicates, priorities and forced bars.
extension FluentBarManagerQueue on FluentBarManager {
  /// Replaces the config, rebuilds the bars on screen and rebalances the queues.
  void updateConfig(FluentBarConfig newConfig) {
    _config = newConfig;
    _configNotifier.value = _config;

    _rebuildActiveBars();

    _rebalanceRegions();

    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> q = _queueOf(region);
      final int excess = q.length - _config.maxQueueLength;
      if (excess <= 0) continue;

      final int keepCount = q.length - excess;
      final List<FluentBarEntry<dynamic>> dropped = q.sublist(keepCount);
      _queues[region] = q.sublist(0, keepCount);
      _updateQueueNotifier(region);

      for (final FluentBarEntry<dynamic> entry in dropped) {
        _discard(entry, event: FluentBarAnalyticsEvent.queueOverflow);
      }
    }

    tryDequeuePending();
  }

  void _rebuildActiveBars() {
    // No bars on screen, nothing to rebuild. This also keeps updateConfig safe before Flutter
    // starts (main() before runApp): WidgetsBinding is not touched, and there can be no shown
    // bars without it.
    final List<OverlayEntry> visible = _activeOverlayEntries.values.whereType<OverlayEntry>().toList();
    if (visible.isEmpty) return;

    // Elements cannot be marked while the tree is being built: do it after the frame.
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildActiveBars());
      return;
    }

    for (final OverlayEntry overlayEntry in visible) {
      overlayEntry.markNeedsBuild();
    }
  }

  /// Moves waiting entries into the queue they belong to under the current config (a change of
  /// enableMultiRegion, the default position or type overrides). A shown bar moves only if its
  /// new region is free; otherwise it lives out its time where it is.
  void _rebalanceRegions() {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active == null || _dismissingEntries[region] != null) continue;

      final FluentBarRegion target = _regionOf(active);
      if (target != region && _activeItems[target] == null) _moveActive(active, region, target);
    }

    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> queue = _queueOf(region);
      final List<FluentBarEntry<dynamic>> misplaced = queue.where((FluentBarEntry<dynamic> e) => _regionOf(e) != region).toList();
      if (misplaced.isEmpty) continue;

      _queues[region] = queue.where((FluentBarEntry<dynamic> e) => !misplaced.contains(e)).toList();
      if (misplaced.contains(_forcedNexts[region])) _forcedNexts[region] = null;
      _updateQueueNotifier(region);

      for (final FluentBarEntry<dynamic> entry in misplaced) {
        _enqueueViaStrategy(_regionOf(entry), entry);
      }
    }
  }

  /// Changes a part of the config.
  void patchConfig(FluentBarConfig Function(FluentBarConfig current) update) {
    final FluentBarConfig? updated = FluentBarErrorHandler.instance.executeSafe<FluentBarConfig?>(
      overrideCall: () => update(_config),
      fallbackCall: () => null,
      type: FluentBarErrorType.patchCallback,
      debugContext: 'patchConfig',
    );
    if (updated != null) updateConfig(updated);
  }

  /// Shows the next waiting bar in every free region.
  void tryDequeuePending() {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      if (_queueOf(region).isNotEmpty && _activeItems[region] == null) {
        _showNextForRegion(region);
      }
    }
  }

  /// Shows [item], updates the bar it duplicates, or queues it.
  ///
  /// Returns the entry that now represents the bar, or `null` if the bar was dropped.
  FluentBarEntry<T>? show<T>(FluentBarItem<T> item, {OverlayState? overlayState}) {
    _purgeDisposed();

    final FluentBarDuplicatePolicy requestedPolicy = item.resolveDuplicatePolicy(_config);
    notifyAnalytics(FluentBarAnalyticsEvent.requested, item);

    // With `allow` duplicates are not searched for, but a progress update of the same bar (by id) is not a new bar.
    final bool allowsDuplicates = requestedPolicy == FluentBarDuplicatePolicy.allow;
    final FluentBarDuplicatePolicy policy = allowsDuplicates ? FluentBarDuplicatePolicy.update : requestedPolicy;
    bool matches(FluentBarEntry<dynamic> existing) => allowsDuplicates ? _isRunningProgressOf(item, existing) : _isDuplicate(item, existing);

    // Duplicates are searched by the item itself: an entry with a controller is created only for a
    // new bar, so a re-show with the same id (frequent progress updates) allocates nothing.

    // All regions are searched: a bar with the same id sent with another position is the same bar
    // (it is updated and moves if needed), not a second one in the neighbouring region.
    for (final FluentBarRegion candidate in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[candidate];
      // A bar that moves to another region stays the same bar, unless it was closed on the way.
      final bool isLeaving = _dismissingEntries[candidate] != null && (!_relocating.contains(active) || _closedWhileRelocating.containsKey(active));
      if (active != null && !isLeaving && matches(active)) {
        _handleActiveDuplicate(active, item, policy);
        return active is FluentBarEntry<T> ? active : null;
      }
    }

    for (final FluentBarRegion candidate in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> candidateQueue = _queueOf(candidate);
      final int queuedIndex = candidateQueue.indexWhere(matches);
      if (queuedIndex == -1) continue;

      final FluentBarEntry<dynamic> existing = candidateQueue[queuedIndex];

      if (_effectivePolicy(existing, item, policy) == FluentBarDuplicatePolicy.ignore) {
        notifyAnalytics(FluentBarAnalyticsEvent.ignoredDuplicate, item);
        return existing is FluentBarEntry<T> ? existing : null;
      }

      return _mergeIntoQueued<T>(existing, item, overlayState);
    }

    if (!allowsDuplicates) _reportPayloadTypeMismatch(item);

    final FluentBarEntry<T> newEntry = FluentBarEntry<T>(item: item);
    final FluentBarRegion region = _regionOf(newEntry);
    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);

    if (newEntry.isForce) {
      _forceAndShowEntry(newEntry, region, overlayState: overlayState);
      _notifyIfQueued(newEntry);
      return newEntry;
    }

    if (regionQueue.length >= _config.maxQueueLength) {
      final String identifier = newEntry.currentItem.id ?? '<no-id, type: ${newEntry.resolvedType(_config).name}>';
      FluentBarErrorHandler.instance.handle(
        StateError('FluentBar: Queue overflow in region $region. Dropped item: $identifier'),
        FluentBarErrorType.queueOverflow,
        StackTrace.current,
        FluentBarErrorSeverity.warning,
      );
      _discard(newEntry, event: FluentBarAnalyticsEvent.queueOverflow);
      return null;
    }

    // The queue length is published once at the end; otherwise listeners would see "1 -> 0" for
    // every bar that goes straight to the screen.
    final QueueOperationResult result = _enqueueViaStrategy(region, newEntry, notify: false);
    if (!_queueOf(region).contains(newEntry)) {
      _updateQueueNotifier(region);
      return null;
    }

    final OverlayState? targetOverlay = _getOverlayState(overlayState: overlayState);

    final FluentBarRegion? occupied = _occupiedRegion(region);

    if (result.shouldForce && occupied != null) {
      unawaited(_dismissCurrentInRegion(occupied, reason: FluentBarDismissReason.force, overlayState: targetOverlay, skipAnimation: true));
    } else if (occupied == null && targetOverlay != null) {
      _showNextForRegion(region, overlayState: targetOverlay, notify: false);
    } else if (targetOverlay == null) {
      _scheduleDequeue();
    }

    _updateQueueNotifier(region);
    _notifyIfQueued(newEntry);
    return newEntry;
  }

  /// A bar with this id exists but cannot be updated with the incoming one: their payload types
  /// differ (see [FluentBarItem.hasPayloadType]). The incoming bar is shown separately, and this
  /// must be said: from outside it looks like "same id, but the bar did not update".
  void _reportPayloadTypeMismatch(FluentBarItem<dynamic> item) {
    final String? id = item.id;
    // With a custom duplicate rule the id may mean nothing; then there is nothing to warn about.
    if (id == null || _config.duplicateComparator != null) return;

    final FluentBarEntry<dynamic>? existing = findById(id);
    if (existing == null || existing.internalController.accepts(item)) return;

    FluentBarErrorHandler.instance.handle(
      StateError(
        'FluentBar: a bar with id "$id" already exists, but its payload type differs '
        '(${existing.currentItem.runtimeType} vs ${item.runtimeType}), so it cannot be updated and the new bar is shown separately. '
        'Use the same type argument for both, for example FluentBar.info<void>(...).',
      ),
      FluentBarErrorType.payloadTypeMismatch,
      StackTrace.current,
      FluentBarErrorSeverity.warning,
    );
  }

  /// Reports that the bar did not reach the screen at once and waits in the queue.
  void _notifyIfQueued(FluentBarEntry<dynamic> entry) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      if (_queueOf(region).contains(entry)) {
        notifyAnalytics(FluentBarAnalyticsEvent.queued, entry.currentItem);
        return;
      }
    }
  }

  /// Shows a loading bar and drives it by [future]: completes the progress on success
  /// (`completeProgress`), marks a failure on error (`failProgress`).
  ///
  /// Returns the same [future] so that the caller can await the result and handle the error:
  /// the library neither swallows nor replaces it.
  Future<R> showFuture<T, R>(
    Future<R> future,
    FluentBarItem<T> item, {
    String Function(R result)? success,
    String Function(Object error)? error,
    FluentBarType? successType,
    FluentBarType? errorType,
    OverlayState? overlayState,
  }) {
    final FluentBarEntry<T>? entry = show<T>(item, overlayState: overlayState);
    if (entry == null) return future;

    String? describe(String name, String Function() build) =>
        FluentBarErrorHandler.instance.executeSafe<String?>(overrideCall: build, fallbackCall: () => null, type: FluentBarErrorType.fluentBarResolver, debugContext: name);

    // If the bar is already closed by then, its controller is disposed and the calls do nothing.
    unawaited(
      future.then<void>(
        (R result) => entry.controller.completeProgress(message: success == null ? null : describe('future.success', () => success(result)), type: successType ?? FluentBarType.success),
        onError: (Object failure) => entry.controller.failProgress(message: error == null ? null : describe('future.error', () => error(failure)), type: errorType),
      ),
    );

    return future;
  }

  /// A duplicate is an item that can be merged into an existing one. Bars with different payload
  /// types cannot be merged (the content of one does not fit the controller of the other), so
  /// they are not duplicates.
  bool _isDuplicate(FluentBarItem<dynamic> incoming, FluentBarEntry<dynamic> existing) => existing.internalController.accepts(incoming) && incoming.isDuplicateOf(existing.currentItem, _config);

  FluentBarEntry<T>? _mergeIntoQueued<T>(FluentBarEntry<dynamic> existing, FluentBarItem<T> incomingItem, OverlayState? overlayState) {
    final FluentBarItem<dynamic> incoming = _updatedItem(existing, incomingItem);

    final FluentBarPriority existingPriority = existing.resolvePriority(_config);
    final FluentBarPriority incomingPriority = incomingItem.behavior.priority ?? incomingItem.resolvedType(_config).priority;
    final FluentBarPriority priority = incomingPriority.weight >= existingPriority.weight ? incomingPriority : existingPriority;
    final bool force = existing.isForce || incomingItem.behavior.isForce;
    final bool tierChanged = priority.weight != existingPriority.weight || force != existing.isForce;

    final FluentBarItem<dynamic> merged = incoming.copyWith(
      behavior: incoming.behavior.copyWith(priority: priority, isForce: force),
    );

    existing.internalController.rebindItem(merged, isNewShow: true);
    notifyAnalytics(FluentBarAnalyticsEvent.updated, merged);

    final FluentBarRegion region = _regionOf(existing);
    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
    if (!regionQueue.contains(existing)) return existing is FluentBarEntry<T> ? existing : null;

    if (tierChanged) {
      regionQueue.remove(existing);
      if (force) {
        _forceAndShowEntry<dynamic>(existing, region, overlayState: overlayState);
      } else {
        _enqueueViaStrategy(region, existing);
      }
    }

    if (_activeItems[region] == null) _showNextForRegion(region, overlayState: overlayState);

    return existing is FluentBarEntry<T> ? existing : null;
  }

  /// The `ignore` policy must not freeze progress: the same bar with another progress state is an
  /// update, not a repeat. The rule is the same for a shown bar and for a queued one.
  FluentBarDuplicatePolicy _effectivePolicy(FluentBarEntry<dynamic> existing, FluentBarItem<dynamic> incoming, FluentBarDuplicatePolicy policy) {
    if (policy != FluentBarDuplicatePolicy.ignore) return policy;

    final FluentBarProgressState? current = existing.internalController.progressStateNotifier.value;
    final FluentBarProgressState? next = incoming.progressState;
    return current != null && next != null && next != current ? FluentBarDuplicatePolicy.update : policy;
  }

  /// Both the existing bar and the incoming one carry progress, so this is a progress update.
  bool _isProgressUpdate(FluentBarEntry<dynamic> existing, FluentBarItem<dynamic> incoming) => existing.internalController.progressStateNotifier.value != null && incoming.progressState != null;

  /// For the `allow` policy: [incoming] continues the unfinished progress of [existing] with the same id.
  /// A completed bar is done: the same id with progress starts a new bar.
  bool _isRunningProgressOf(FluentBarItem<dynamic> incoming, FluentBarEntry<dynamic> existing) {
    final String? id = incoming.id;
    if (id == null || existing.currentItem.id != id || !existing.internalController.accepts(incoming)) return false;

    return _isProgressUpdate(existing, incoming) && !existing.internalController.progressStateNotifier.value!.isCompleted;
  }

  /// What replaces the item of the existing bar: a progress update changes only progress, texts
  /// and type; otherwise the incoming bar replaces it entirely.
  FluentBarItem<dynamic> _updatedItem(FluentBarEntry<dynamic> existing, FluentBarItem<dynamic> incoming) =>
      _isProgressUpdate(existing, incoming) ? existing.currentItem.withProgressFrom(incoming) : incoming;

  void _handleActiveDuplicate(FluentBarEntry<dynamic> active, FluentBarItem<dynamic> incoming, FluentBarDuplicatePolicy policy) {
    final FluentBarInternalController<dynamic> internalController = active.internalController;

    final FluentBarDuplicatePolicy effectivePolicy = _effectivePolicy(active, incoming, policy);

    if (effectivePolicy == FluentBarDuplicatePolicy.ignore) {
      notifyAnalytics(FluentBarAnalyticsEvent.ignoredDuplicate, incoming);
      return;
    }

    notifyAnalytics(FluentBarAnalyticsEvent.updated, incoming);
    internalController.rebindItem(_updatedItem(active, incoming), resetTimer: effectivePolicy == FluentBarDuplicatePolicy.updateAndResetTimer, isNewShow: true);
  }

  FluentBarEntry<dynamic>? _takeForced(FluentBarRegion region, {bool notify = true}) {
    final FluentBarEntry<dynamic>? forced = _forcedNexts[region];
    _forcedNexts[region] = null;
    if (forced == null) return null;

    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
    final int index = regionQueue.indexOf(forced);
    if (index == -1) return null;

    regionQueue.removeAt(index);
    if (notify) _updateQueueNotifier(region);
    return forced;
  }

  void _updateQueueNotifier(FluentBarRegion region) {
    final ValueNotifier<int> notifier = _queueLengthNotifiers[region]!;
    final int len = _queueOf(region).length;
    if (notifier.value != len) {
      notifier.value = len;
    }
  }

  void _showNextForRegion(FluentBarRegion region, {OverlayState? overlayState, bool notify = true}) {
    // Not final: the list of the region is replaced after every dequeue, and the loop must see the current one.
    List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
    if (regionQueue.isEmpty || _occupiedRegion(region) != null) return;

    final OverlayState? targetOverlay = _getOverlayState(overlayState: overlayState);
    if (targetOverlay == null) return;

    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showNextForRegion(region, overlayState: overlayState));
      return;
    }

    FluentBarEntry<dynamic>? nextEntry = _takeForced(region, notify: notify);
    if (nextEntry != null && (nextEntry.internalController.isDisposed || nextEntry.internalController.isClosedBeforeShow)) {
      _discard(nextEntry);
      nextEntry = null;
    }

    while (nextEntry == null && regionQueue.isNotEmpty) {
      (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) dequeueResult;
      try {
        dequeueResult = _config.defaultQueueStrategy.onDequeue(queue: List<FluentBarEntry<dynamic>>.from(regionQueue), config: _config);
      } catch (error, stackTrace) {
        FluentBarErrorHandler.instance.handle(error, FluentBarErrorType.queueDequeue, stackTrace);
        final List<FluentBarEntry<dynamic>> mutableQueue = List<FluentBarEntry<dynamic>>.from(regionQueue);
        final FluentBarEntry<dynamic> item = mutableQueue.removeAt(0);
        dequeueResult = (item, mutableQueue);
      }

      final (FluentBarEntry<dynamic>? dequeuedItem, List<FluentBarEntry<dynamic>> updatedQueue) = dequeueResult;

      final Set<FluentBarEntry<dynamic>> kept = updatedQueue.toSet();
      final List<FluentBarEntry<dynamic>> evicted = regionQueue.where((FluentBarEntry<dynamic> e) => !identical(e, dequeuedItem) && !kept.contains(e)).toList();

      regionQueue = List<FluentBarEntry<dynamic>>.from(updatedQueue);
      _queues[region] = regionQueue;
      if (notify) _updateQueueNotifier(region);

      for (final FluentBarEntry<dynamic> entry in evicted) {
        _discard(entry, event: FluentBarAnalyticsEvent.queueOverflow);
      }

      if (dequeuedItem == null) return;

      final FluentBarInternalController<dynamic> controller = dequeuedItem.internalController;
      if (controller.isDisposed || controller.isClosedBeforeShow) {
        _discard(dequeuedItem);
        continue;
      }

      nextEntry = dequeuedItem;
    }

    if (nextEntry == null) return;

    _presentInRegion(nextEntry, region, targetOverlay);
  }

  /// Changes the priority of a queued bar and puts it back in order.
  void updateItemPriority({String? id, FluentBarItem<dynamic>? item, required FluentBarPriority newPriority}) {
    if (id == null && item == null) return;

    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
      final int index = regionQueue.indexWhere((FluentBarEntry<dynamic> q) {
        if (id != null && q.currentItem.id == id) return true;
        if (item != null && q.currentItem.isDuplicateOf(item, _config)) return true;
        return false;
      });

      if (index != -1) {
        final FluentBarEntry<dynamic> targetEntry = regionQueue.removeAt(index);
        final FluentBarItem<dynamic> updatedItem = targetEntry.currentItem.copyWith(behavior: targetEntry.currentItem.behavior.copyWith(priority: newPriority));

        targetEntry.internalController.rebindItem(updatedItem);
        _enqueueViaStrategy(region, targetEntry);
        return;
      }
    }
  }

  /// Shows [item] out of turn, replacing the bar on screen.
  FluentBarEntry<T> forceItem<T>(FluentBarItem<T> item, {OverlayState? overlayState}) {
    final FluentBarEntry<T> entry = FluentBarEntry<T>(item: item);
    final FluentBarRegion region = _regionOf(entry);
    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);

    if (item.id != null) {
      final List<FluentBarEntry<dynamic>> duplicates = regionQueue.where((FluentBarEntry<dynamic> q) => q.currentItem.isDuplicateOf(item, _config)).toList();
      if (duplicates.isNotEmpty) {
        regionQueue.removeWhere(duplicates.contains);
        _updateQueueNotifier(region);
        for (final FluentBarEntry<dynamic> dup in duplicates) {
          _discard(dup, event: FluentBarAnalyticsEvent.ignoredDuplicate);
        }
      }
    }

    notifyAnalytics(FluentBarAnalyticsEvent.requested, entry.currentItem);
    return _forceAndShowEntry(entry, region, overlayState: overlayState);
  }

  /// Shows an existing entry out of turn.
  FluentBarEntry<T> forceEntry<T>(FluentBarEntry<T> entry, {OverlayState? overlayState}) {
    final FluentBarRegion region = _regionOf(entry);
    return _forceAndShowEntry(entry, region, overlayState: overlayState);
  }

  /// Pulls the queued bar with [id] to the screen out of turn.
  void forceItemFromQueue({required String id, OverlayState? overlayState}) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
      final int index = regionQueue.indexWhere((FluentBarEntry<dynamic> entry) => entry.currentItem.id == id);
      if (index != -1) {
        _forceAndShowEntry(regionQueue[index], region, overlayState: overlayState);
        return;
      }
    }
  }

  /// Shows the bar of [controller] out of turn.
  void forceController(FluentBarInternalController<dynamic> controller, {OverlayState? overlayState}) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active != null && identical(active.internalController, controller)) {
        _forceAndShowEntry<dynamic>(active, region, overlayState: overlayState);
        return;
      }

      final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
      final int index = regionQueue.indexWhere((FluentBarEntry<dynamic> e) => identical(e.internalController, controller));
      if (index != -1) {
        _forceAndShowEntry<dynamic>(regionQueue[index], region, overlayState: overlayState);
        return;
      }
    }
  }

  QueueOperationResult _enqueueViaStrategy(FluentBarRegion region, FluentBarEntry<dynamic> incoming, {bool notify = true}) {
    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
    QueueOperationResult result;
    try {
      result = _config.defaultQueueStrategy.onEnqueue(queue: List<FluentBarEntry<dynamic>>.from(regionQueue), incoming: incoming, config: _config);
    } catch (error, stackTrace) {
      FluentBarErrorHandler.instance.handle(error, FluentBarErrorType.queueEnqueue, stackTrace);
      result = QueueOperationResult(queue: List<FluentBarEntry<dynamic>>.from(regionQueue)..add(incoming));
    }

    final Set<FluentBarEntry<dynamic>> kept = result.queue.toSet();
    final List<FluentBarEntry<dynamic>> evicted = <FluentBarEntry<dynamic>>[...regionQueue.where((FluentBarEntry<dynamic> e) => !kept.contains(e)), if (!kept.contains(incoming)) incoming];

    _queues[region] = List<FluentBarEntry<dynamic>>.from(result.queue);
    if (notify) _updateQueueNotifier(region);

    for (final FluentBarEntry<dynamic> entry in evicted) {
      _discard(entry, event: FluentBarAnalyticsEvent.queueOverflow);
    }

    return result;
  }

  FluentBarEntry<T> _forceAndShowEntry<T>(FluentBarEntry<T> entry, FluentBarRegion region, {OverlayState? overlayState}) {
    final FluentBarItem<T> forcedItem = entry.currentItem.copyWith(behavior: entry.currentItem.behavior.copyWith(isForce: true));

    if (identical(_activeItems[region], entry)) {
      entry.internalController.rebindItem(forcedItem, resetTimer: true);
      return entry;
    }

    entry.internalController.rebindItem(forcedItem);

    final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
    regionQueue.remove(entry);

    int insertIndex = 0;
    while (insertIndex < regionQueue.length && regionQueue[insertIndex].isForce && regionQueue[insertIndex].sequence <= entry.sequence) {
      insertIndex++;
    }
    regionQueue.insert(insertIndex, entry);

    if (insertIndex == 0) _forcedNexts[region] = entry;

    final OverlayState? targetOverlay = _getOverlayState(overlayState: overlayState);
    final FluentBarRegion? occupied = _occupiedRegion(region);
    final FluentBarEntry<dynamic>? active = occupied == null ? null : _activeItems[occupied];

    // A forced entry that goes straight to the screen takes no place in the queue, so nothing
    // has to be evicted because of it.
    final bool showsImmediately = _forcedNexts[region] == entry && targetOverlay != null && (active == null || !active.isForce);
    final int limit = _config.maxQueueLength + (showsImmediately ? 1 : 0);

    while (regionQueue.length > limit) {
      final int victimIndex = regionQueue.lastIndexWhere((FluentBarEntry<dynamic> e) => !identical(e, entry));
      if (victimIndex == -1) break;
      _discard(regionQueue.removeAt(victimIndex), event: FluentBarAnalyticsEvent.queueOverflow);
    }
    _updateQueueNotifier(region);

    if (active == null) {
      _showNextForRegion(region, overlayState: targetOverlay);
    } else if (!active.isForce) {
      unawaited(_dismissCurrentInRegion(occupied!, reason: FluentBarDismissReason.force, overlayState: targetOverlay, skipAnimation: true));
    }

    return entry;
  }

  /// Removes the bar of [controller] from the queue. Returns `false` if it was not queued.
  bool discardQueuedByController(FluentBarInternalController<dynamic> controller) {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
      final int index = regionQueue.indexWhere((FluentBarEntry<dynamic> e) => identical(e.internalController, controller));
      if (index != -1) {
        final FluentBarEntry<dynamic> entry = regionQueue.removeAt(index);
        if (identical(_forcedNexts[region], entry)) _forcedNexts[region] = null;
        _updateQueueNotifier(region);

        _discard(entry, event: FluentBarAnalyticsEvent.dismissed);
        return true;
      }
    }
    return false;
  }

  void _purgeDisposed() {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> regionQueue = _queueOf(region);
      final int before = regionQueue.length;
      regionQueue.removeWhere((FluentBarEntry<dynamic> e) => e.internalController.isDisposed);
      if (regionQueue.length != before) _updateQueueNotifier(region);
    }
  }

  void _discardQueued() {
    for (final FluentBarRegion region in FluentBarRegion.values) {
      final List<FluentBarEntry<dynamic>> queued = _queueOf(region);
      _queues[region] = <FluentBarEntry<dynamic>>[];
      _forcedNexts[region] = null;
      _updateQueueNotifier(region);

      for (final FluentBarEntry<dynamic> entry in queued) {
        _discard(entry, event: FluentBarAnalyticsEvent.dismissed);
      }
    }
  }

  /// Removes the waiting bars. Shown ones stay on screen.
  void clearQueue() => _discardQueued();

  /// Removes everything at once, the queue and the shown bars, without the exit animation.
  /// For a normal animated close there is [dismissAll].
  void dismissAndClear() {
    _discardQueued();

    for (final FluentBarRegion region in FluentBarRegion.values) {
      // _finalizeDismiss removes the overlay entry and clears the region itself. Clearing again here
      // is wrong: onDismiss may show a new bar synchronously, and that one would be wiped.
      final FluentBarEntry<dynamic>? active = _activeItems[region];
      if (active != null) {
        _finalizeDismiss(active, region, FluentBarDismissReason.manual, _buildMetrics(active, FluentBarDismissReason.manual));
      }
    }
  }
}

part of '../fluent_bar_manager.dart';

/// Analytics listeners, metrics and progress notifications.
extension FluentBarManagerAnalytics on FluentBarManager {
  /// Adds a listener for analytics events; adding the same one twice has no effect.
  void addAnalyticsListener(void Function(FluentBarAnalyticsPayload) listener) {
    _analyticsListeners ??= <void Function(FluentBarAnalyticsPayload)>[];
    if (!_analyticsListeners!.contains(listener)) {
      _analyticsListeners!.add(listener);
    }
  }

  /// Removes an analytics listener.
  void removeAnalyticsListener(void Function(FluentBarAnalyticsPayload) listener) {
    _analyticsListeners?.remove(listener);
    if (_analyticsListeners != null && _analyticsListeners!.isEmpty) {
      _analyticsListeners = null;
    }
  }

  FluentBarMetrics _buildMetrics(FluentBarEntry<dynamic> entry, FluentBarDismissReason reason) {
    final FluentBarInternalController<dynamic> controller = entry.internalController;

    final Map<FluentBarInteraction, int> interactions = <FluentBarInteraction, int>{
      ...controller.interactions,
      if (reason == FluentBarDismissReason.swipe) FluentBarInteraction.swipe: 1,
      if (reason == FluentBarDismissReason.closeButton) FluentBarInteraction.close: 1,
      if (reason == FluentBarDismissReason.accessibility) FluentBarInteraction.accessibility: 1,
    };

    return FluentBarMetrics(
      id: entry.currentItem.id,
      visibleDuration: controller.visibleDuration,
      wasVisible: controller.wasVisible,
      showingDuration: controller.showingDuration,
      // A persistent bar has no countdown, so there is nothing planned.
      plannedDuration: controller.isAwaitingAnswer ? null : entry.resolveEffectiveDuration(_config),
      dismissReason: reason,
      timedOut: reason == FluentBarDismissReason.timeout,
      updateCount: controller.updateCount,
      hadAction: entry.currentItem.actions != null,
      progressOutcome: controller.progressOutcome,
      queuedDuration: controller.queuedDuration,
      pausedDuration: controller.pausedDuration,
      interactions: interactions,
      position: entry.resolvePosition(_config),
      wasForced: entry.isForce,
      preset: entry.currentItem.preset,
      tags: entry.currentItem.tags,
      typeName: entry.resolvedType(_config).name,
    );
  }

  /// Delivers [event] to the listeners unless the config disables it. A throwing listener does not affect the others.
  void notifyAnalytics(FluentBarAnalyticsEvent event, FluentBarItem<dynamic> item, {FluentBarMetrics? metrics, FluentBarPauseReason? pauseReason, FluentBarPosition? previousPosition}) {
    if (_analyticsListeners == null || _config.disabledAnalyticsEvents.contains(event)) return;

    final FluentBarAnalyticsPayload payload = FluentBarAnalyticsPayload(event: event, item: item, metrics: metrics, pauseReason: pauseReason, previousPosition: previousPosition);

    for (final void Function(FluentBarAnalyticsPayload) listener in _analyticsListeners!.toList()) {
      _safeExecute(() => listener(payload), FluentBarErrorType.callbackAnalytics);
    }
  }

  /// Reports a completed progress: analytics, haptic feedback and the `onProgressCompleted` callback.
  void notifyProgressCompleted(FluentBarItem<dynamic> item) {
    notifyAnalytics(FluentBarAnalyticsEvent.progressCompleted, item);

    final FutureOr<void> Function()? customHaptic = item.resolveProgressCompletedHapticCallback(_config);
    if (!_config.enableHaptics) {
    } else if (customHaptic != null) {
      _safeExecute(customHaptic, FluentBarErrorType.hapticExternal);
    } else {
      final FluentBarHapticType hapticType = item.resolveProgressCompletedHaptic(_config);
      HapticHelper.instance.triggerHaptic(hapticType);
    }

    _safeExecute(item.notifyProgressCompleted, FluentBarErrorType.callbackProgressCompleted);
  }

  /// Reports a failed progress: analytics and the `onProgressFailed` callback.
  void notifyProgressFailed(FluentBarItem<dynamic> item) {
    notifyAnalytics(FluentBarAnalyticsEvent.progressFailed, item);

    _safeExecute(item.notifyProgressFailed, FluentBarErrorType.callbackProgressFailed);
  }

  /// Reports a cancelled progress: analytics and the `onProgressCanceled` callback.
  void notifyProgressCanceled(FluentBarItem<dynamic> item) {
    notifyAnalytics(FluentBarAnalyticsEvent.progressCanceled, item);

    _safeExecute(item.notifyProgressCanceled, FluentBarErrorType.callbackProgressCanceled);
  }
}

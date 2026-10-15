import 'package:fluent_bar/src/internal.dart';

/// The entry point of the library.
///
/// There are three ways to show a bar, from the shortest to the most flexible:
///
/// ```dart
/// // 1. One line: everything comes from the type and the config.
/// FluentBar.showSuccess('Saved');
/// FluentBar.showSnack('Deleted', action: 'Undo', onAction: (_, __) => restore());
///
/// // 2. A chain: a draft plus the .with...() calls you need, then show().
/// FluentBar.info('Uploading the file').withLinearProgress(showText: true).atBottom().show();
///
/// // 3. Fully by hand: every parameter, or a ready FluentBarItem.
/// FluentBar.show(message: 'Done', type: FluentBarType.success, options: const FluentBarOptions(behavior: FluentBarBehavior(position: FluentBarPosition.bottom)));
///
/// final FluentBarItem<void> item = FluentBarItem<void>(type: FluentBarType.info, message: 'Saved');
/// FluentBar.showItem(item);
/// ```
///
/// Naming rule: `showX(...)` shows at once and returns a [FluentBarEntry];
/// `x(...)` without `show` returns a draft ([FluentBarItem]) for a chain.
class FluentBar {
  FluentBar._();

  /// Sets the global config and, optionally, the navigator whose overlay shows the bars.
  ///
  /// *Not needed when the app is wrapped in [FluentBarScope].*
  ///
  /// ```dart
  /// final navigatorKey = GlobalKey<NavigatorState>();
  /// FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);
  /// ```
  static void initialize({required FluentBarConfig config, GlobalKey<NavigatorState>? navigatorKey}) => FluentBarManager.instance.initialize(config, navigatorKey: navigatorKey);

  /// Replaces the global config. Bars already on screen pick it up at once.
  ///
  /// ```dart
  /// FluentBar.updateConfig(const FluentBarConfig(defaultPosition: FluentBarPosition.bottom));
  /// ```
  static void updateConfig(FluentBarConfig config) => FluentBarManager.instance.updateConfig(config);

  /// Changes a part of the global config.
  ///
  /// ```dart
  /// FluentBar.patchConfig((config) => config.copyWith(maxQueueLength: 5));
  /// ```
  static void patchConfig(FluentBarConfig Function(FluentBarConfig current) update) => FluentBarManager.instance.patchConfig(update);

  /// A draft of an info bar for a chain.
  ///
  /// ```dart
  /// FluentBar.info('Copied to clipboard').atBottom().show();
  /// ```
  static FluentBarItem<T> info<T>(String message, {String? title, String? id, Duration? duration, T? payload}) =>
      custom<T>(FluentBarType.info, message, title: title, id: id, duration: duration, payload: payload);

  /// A draft of a success bar for a chain.
  ///
  /// ```dart
  /// FluentBar.success('Profile saved').withTitle('Done').show();
  /// ```
  static FluentBarItem<T> success<T>(String message, {String? title, String? id, Duration? duration, T? payload}) =>
      custom<T>(FluentBarType.success, message, title: title, id: id, duration: duration, payload: payload);

  /// A draft of a warning bar for a chain.
  ///
  /// ```dart
  /// FluentBar.warning('Storage is almost full').withAction('Manage').show();
  /// ```
  static FluentBarItem<T> warning<T>(String message, {String? title, String? id, Duration? duration, T? payload}) =>
      custom<T>(FluentBarType.warning, message, title: title, id: id, duration: duration, payload: payload);

  /// A draft of an error bar for a chain.
  ///
  /// ```dart
  /// FluentBar.error('Payment failed').persistent().show();
  /// ```
  static FluentBarItem<T> error<T>(String message, {String? title, String? id, Duration? duration, T? payload}) =>
      custom<T>(FluentBarType.error, message, title: title, id: id, duration: duration, payload: payload);

  /// A draft with a custom type: a subclass of [FluentBarType] or `FluentBarType.info.copyWith(...)`.
  /// To replace a type for the whole app, use [FluentBarConfig.typeOverrides].
  static FluentBarItem<T> custom<T>(FluentBarType type, String message, {String? title, String? id, Duration? duration, T? payload}) =>
      FluentBarItem<T>(type: type, message: message, title: title, id: id, duration: duration, payload: payload);

  /// Like a SnackBar: at the bottom, without an icon, with an optional action button.
  /// To lift it above the bottom navigation, wrap the navigation in [FluentBarBottomInset].
  static FluentBarItem<T> snack<T>(
    String message, {
    String? action,
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onAction,
    FluentBarType type = FluentBarType.info,
    Duration? duration,
    String? id,
    T? payload,
  }) => FluentBarItem<T>(
    type: type,
    message: message,
    id: id,
    duration: duration,
    payload: payload,
    preset: 'snack',
    behavior: const FluentBarBehavior(position: FluentBarPosition.bottom),
    appearance: FluentBarAppearance<T>(showIcon: false, showCloseButton: false),
    actions: _action<T>(action, onAction),
  );

  /// A short hint: compact, without an icon, disappears by itself and cannot be dismissed by hand.
  static FluentBarItem<T> toast<T>(
    String message, {
    FluentBarType type = FluentBarType.info,
    Duration duration = const Duration(seconds: 2),
    FluentBarPosition position = FluentBarPosition.bottom,
    String? id,
    T? payload,
  }) => FluentBarItem<T>(
    type: type,
    message: message,
    id: id,
    duration: duration,
    payload: payload,
    preset: 'toast',
    behavior: FluentBarBehavior(position: position, isSwipeEnabled: false, dismissOnTap: false, pauseOnTouch: false, haptic: FluentBarHapticType.none),
    appearance: FluentBarAppearance<T>(
      showIcon: false,
      showCloseButton: false,
      messageTextAlign: TextAlign.center,
      entranceAnimation: FluentBarEntranceAnimation.fade,
      constraints: const BoxConstraints(maxWidth: 320),
    ),
  );

  /// A message pinned at the top ("No connection", "Update available"): it does not disappear by
  /// itself and cannot be dismissed by hand, only by its action or from code.
  static FluentBarItem<T> banner<T>(
    String message, {
    String? title,
    String? action,
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onAction,
    FluentBarType type = FluentBarType.info,
    String? id,
    T? payload,
  }) => FluentBarItem<T>(
    type: type,
    message: message,
    title: title,
    id: id,
    payload: payload,
    isPersistent: true,
    preset: 'banner',
    behavior: const FluentBarBehavior(position: FluentBarPosition.top, isSwipeEnabled: false, dismissOnTap: false),
    appearance: FluentBarAppearance<T>(showCloseButton: false),
    actions: _action<T>(action, onAction),
  );

  /// A loading bar: stays while the work is in progress. Finish it with `completeProgress()` or
  /// `failProgress()` on the returned entry; after that it closes by the usual timer.
  /// If the work is a `Future`, [future] is simpler.
  static FluentBarItem<T> loading<T>(String message, {String? title, FluentBarType type = FluentBarType.info, bool linear = false, String? id, T? payload}) => FluentBarItem<T>(
    type: type,
    message: message,
    title: title,
    id: id,
    payload: payload,
    // Unfinished progress, not a flag, keeps the bar open: once finished it must close by itself.
    progressState: const FluentBarProgressState.indeterminate(),
    preset: 'loading',
    behavior: const FluentBarBehavior(isSwipeEnabled: false, dismissOnTap: false),
    appearance: FluentBarAppearance<T>(
      showCloseButton: false,
      progressTheme: linear ? const FluentBarProgressTheme() : const FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.replaceIcon),
    ),
  );

  static FluentBarActions<T>? _action<T>(String? label, FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed) =>
      label == null ? null : FluentBarActions<T>(label: label, onPressed: onPressed);

  /// The full call: any type and any settings through [options].
  static FluentBarEntry<T>? show<T>({
    required String message,
    FluentBarType type = FluentBarType.info,
    String? title,
    String? id,
    Duration? duration,
    T? payload,
    bool? isPersistent,
    FluentBarOptions<T>? options,
    OverlayState? overlayState,
  }) {
    final FluentBarOptions<T> opts = options ?? FluentBarOptions<T>();

    final FluentBarItem<T> item = FluentBarItem<T>(
      id: id,
      type: type,
      title: title,
      message: message,
      duration: duration,
      payload: payload,
      isPersistent: isPersistent,
      meta: opts.meta,
      tags: opts.tags,
      behavior: opts.behavior,
      actions: opts.actions,
      appearance: opts.appearance,
      callbacks: opts.callbacks,
      progressState: opts.progressState,
    );

    return FluentBarManager.instance.show(item, overlayState: overlayState);
  }

  /// Shows a ready [item].
  ///
  /// ```dart
  /// final item = FluentBar.info('Hello').atBottom();
  /// FluentBar.showItem(item);
  /// ```
  static FluentBarEntry<T>? showItem<T>(FluentBarItem<T> item, {OverlayState? overlayState}) => FluentBarManager.instance.show(item, overlayState: overlayState);

  /// Shows an info bar.
  ///
  /// ```dart
  /// FluentBar.showInfo('Copied to clipboard');
  /// ```
  static FluentBarEntry<T>? showInfo<T>(String message, {String? title, String? id, Duration? duration, T? payload, bool? isPersistent, FluentBarOptions<T>? options, OverlayState? overlayState}) =>
      showCustom<T>(FluentBarType.info, message, title: title, id: id, duration: duration, payload: payload, isPersistent: isPersistent, options: options, overlayState: overlayState);

  /// Shows a success bar.
  ///
  /// ```dart
  /// FluentBar.showSuccess('Profile saved');
  /// ```
  static FluentBarEntry<T>? showSuccess<T>(String message, {String? title, String? id, Duration? duration, T? payload, bool? isPersistent, FluentBarOptions<T>? options, OverlayState? overlayState}) =>
      showCustom<T>(FluentBarType.success, message, title: title, id: id, duration: duration, payload: payload, isPersistent: isPersistent, options: options, overlayState: overlayState);

  /// Shows a warning bar.
  ///
  /// ```dart
  /// FluentBar.showWarning('Storage is almost full');
  /// ```
  static FluentBarEntry<T>? showWarning<T>(String message, {String? title, String? id, Duration? duration, T? payload, bool? isPersistent, FluentBarOptions<T>? options, OverlayState? overlayState}) =>
      showCustom<T>(FluentBarType.warning, message, title: title, id: id, duration: duration, payload: payload, isPersistent: isPersistent, options: options, overlayState: overlayState);

  /// Shows an error bar.
  ///
  /// ```dart
  /// FluentBar.showError('Payment failed', title: 'Checkout');
  /// ```
  static FluentBarEntry<T>? showError<T>(String message, {String? title, String? id, Duration? duration, T? payload, bool? isPersistent, FluentBarOptions<T>? options, OverlayState? overlayState}) =>
      showCustom<T>(FluentBarType.error, message, title: title, id: id, duration: duration, payload: payload, isPersistent: isPersistent, options: options, overlayState: overlayState);

  /// Shows a bar with a custom type (see [custom]).
  static FluentBarEntry<T>? showCustom<T>(
    FluentBarType type,
    String message, {
    String? title,
    String? id,
    Duration? duration,
    T? payload,
    bool? isPersistent,
    FluentBarOptions<T>? options,
    OverlayState? overlayState,
  }) => show<T>(message: message, type: type, title: title, id: id, duration: duration, payload: payload, isPersistent: isPersistent, options: options, overlayState: overlayState);

  /// See [snack].
  static FluentBarEntry<T>? showSnack<T>(
    String message, {
    String? action,
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onAction,
    FluentBarType type = FluentBarType.info,
    Duration? duration,
    String? id,
    T? payload,
    OverlayState? overlayState,
  }) => showItem<T>(
    snack<T>(message, action: action, onAction: onAction, type: type, duration: duration, id: id, payload: payload),
    overlayState: overlayState,
  );

  /// See [toast].
  static FluentBarEntry<T>? showToast<T>(
    String message, {
    FluentBarType type = FluentBarType.info,
    Duration duration = const Duration(seconds: 2),
    FluentBarPosition position = FluentBarPosition.bottom,
    String? id,
    T? payload,
    OverlayState? overlayState,
  }) => showItem<T>(
    toast<T>(message, type: type, duration: duration, position: position, id: id, payload: payload),
    overlayState: overlayState,
  );

  /// See [banner].
  static FluentBarEntry<T>? showBanner<T>(
    String message, {
    String? title,
    String? action,
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onAction,
    FluentBarType type = FluentBarType.info,
    String? id,
    T? payload,
    OverlayState? overlayState,
  }) => showItem<T>(
    banner<T>(message, title: title, action: action, onAction: onAction, type: type, id: id, payload: payload),
    overlayState: overlayState,
  );

  /// See [loading].
  static FluentBarEntry<T>? showLoading<T>(String message, {String? title, FluentBarType type = FluentBarType.info, bool linear = false, String? id, T? payload, OverlayState? overlayState}) =>
      showItem<T>(
        loading<T>(message, title: title, type: type, linear: linear, id: id, payload: payload),
        overlayState: overlayState,
      );

  /// Shows a loading bar for the time of [future] and turns it into the outcome: on success the
  /// type [successType] and the text from [success], on failure [errorType] and the text from [error].
  ///
  /// ```dart
  /// final User user = await FluentBar.future(
  ///   api.saveProfile(),
  ///   loading: 'Saving...',
  ///   success: (User user) => 'Profile of ${user.name} saved',
  ///   error: (Object e) => 'Could not save',
  /// );
  /// ```
  ///
  /// Returns the same [future]: the caller gets the result and the error as usual.
  /// Without [success] or [error] the text stays and only the type changes.
  static Future<R> future<R>(
    Future<R> future, {
    required String loading,
    String? title,
    String? id,
    String Function(R result)? success,
    String Function(Object error)? error,
    FluentBarType type = FluentBarType.info,
    FluentBarType successType = FluentBarType.success,
    FluentBarType errorType = FluentBarType.error,
    FluentBarOptions<void>? options,
    OverlayState? overlayState,
  }) {
    final FluentBarOptions<void> opts = options ?? const FluentBarOptions<void>();

    final FluentBarItem<void> item = FluentBarItem<void>(
      id: id,
      type: type,
      title: title,
      message: loading,
      meta: opts.meta,
      tags: opts.tags,
      behavior: opts.behavior,
      actions: opts.actions,
      appearance: opts.appearance,
      callbacks: opts.callbacks,
      progressState: opts.progressState ?? const FluentBarProgressState.indeterminate(),
    );

    return FluentBarManager.instance.showFuture<void, R>(future, item, success: success, error: error, successType: successType, errorType: errorType, overlayState: overlayState);
  }

  /// The bar with the given [id], shown or waiting in the queue.
  static FluentBarEntry<dynamic>? find(String id) => FluentBarManager.instance.findById(id);

  /// Closes the bar with the given [id] (a shown one with its animation, a queued one is removed).
  /// Returns `false` if there is no such bar.
  static bool close(String id, {FluentBarDismissReason reason = FluentBarDismissReason.manual}) {
    final FluentBarEntry<dynamic>? entry = find(id);
    entry?.controller.close(reason: reason);
    return entry != null;
  }

  /// The bars with [tag], shown or waiting in the queue.
  static List<FluentBarEntry<dynamic>> findByTag(String tag) => FluentBarManager.instance.findByTag(tag);

  /// Closes every bar with [tag]: a shown one with its animation, queued ones are removed and
  /// never appear. Returns how many bars were closed.
  ///
  /// ```dart
  /// FluentBar.info('Card declined').withTag('checkout').show();
  /// FluentBar.closeTag('checkout'); // for example when the checkout screen is left
  /// ```
  static int closeTag(String tag, {FluentBarDismissReason reason = FluentBarDismissReason.manual}) {
    final List<FluentBarEntry<dynamic>> entries = findByTag(tag);
    for (final FluentBarEntry<dynamic> entry in entries) {
      entry.controller.close(reason: reason);
    }
    return entries.length;
  }

  /// Closes the bars that are on screen; queued ones are shown next.
  ///
  /// ```dart
  /// await FluentBar.closeActive();
  /// ```
  static Future<void> closeActive({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async =>
      FluentBarManager.instance.dismissActive(reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);

  /// Clears the queue and closes the bars on screen with their exit animation.
  ///
  /// ```dart
  /// await FluentBar.closeAll();
  /// ```
  static Future<void> closeAll({FluentBarDismissReason reason = FluentBarDismissReason.manual, OverlayState? overlayState, bool skipAnimation = false}) async =>
      FluentBarManager.instance.dismissAll(reason: reason, overlayState: overlayState, skipAnimation: skipAnimation);

  /// Removes the waiting bars. Shown ones stay on screen.
  static void clearQueue() => FluentBarManager.instance.clearQueue();

  /// Removes everything at once, the queue and the shown bars, without the exit animation.
  /// For a normal animated close use [closeAll].
  static void dismissAndClear() => FluentBarManager.instance.dismissAndClear();

  /// Changes the priority of a queued bar found by [id] or by [item].
  ///
  /// ```dart
  /// FluentBar.updateItemPriority(id: 'sync', newPriority: FluentBarPriority.high);
  /// ```
  static void updateItemPriority({String? id, FluentBarItem<dynamic>? item, required FluentBarPriority newPriority}) =>
      FluentBarManager.instance.updateItemPriority(id: id, item: item, newPriority: newPriority);

  /// Shows [item] out of turn, replacing the bar on screen.
  ///
  /// ```dart
  /// FluentBar.forceItem(FluentBar.error('Session expired'));
  /// ```
  static FluentBarEntry<T> forceItem<T>(FluentBarItem<T> item, {OverlayState? overlayState}) => FluentBarManager.instance.forceItem<T>(item, overlayState: overlayState);

  /// Pulls a queued bar to the screen out of turn.
  ///
  /// ```dart
  /// FluentBar.forceItemFromQueue(id: 'sync');
  /// ```
  static void forceItemFromQueue({required String id, OverlayState? overlayState}) => FluentBarManager.instance.forceItemFromQueue(id: id, overlayState: overlayState);

  /// The bars that are on screen right now.
  static List<FluentBarEntry<dynamic>> get activeItems => FluentBarManager.instance.activeItems;

  /// The bar that appeared on screen last, if any.
  static FluentBarEntry<dynamic>? get lastActiveItem => FluentBarManager.instance.lastActiveItem;

  /// The bar shown in the top region, if any.
  static FluentBarEntry<dynamic>? get mainActiveItem => FluentBarManager.instance.mainActiveItem;

  /// The bar shown in the bottom region, if any.
  static FluentBarEntry<dynamic>? get bottomActiveItem => FluentBarManager.instance.bottomActiveItem;

  /// The bars waiting in both queues.
  static List<FluentBarEntry<dynamic>> get allQueue => FluentBarManager.instance.allQueue;

  /// The bars waiting in the queue of the top region.
  static List<FluentBarEntry<dynamic>> get mainQueue => FluentBarManager.instance.mainQueue;

  /// The bars waiting in the queue of the bottom region.
  static List<FluentBarEntry<dynamic>> get bottomQueue => FluentBarManager.instance.bottomQueue;

  /// How many bars wait in both queues.
  static int get allQueueLength => FluentBarManager.instance.allQueueLength;

  /// How many bars wait in the queue of the top region.
  static int get mainQueueLength => FluentBarManager.instance.mainQueueLength;

  /// How many bars wait in the queue of the bottom region.
  static int get bottomQueueLength => FluentBarManager.instance.bottomQueueLength;

  /// The global config in effect.
  static FluentBarConfig get currentConfig => FluentBarManager.instance.config;

  /// Notifies when the total number of waiting bars changes.
  static ValueListenable<int> get allQueueLengthNotifier => FluentBarManager.instance.allQueueLengthNotifier;

  /// Notifies when the number of bars waiting in the top region changes.
  static ValueListenable<int> get mainQueueLengthNotifier => FluentBarManager.instance.mainQueueLengthNotifier;

  /// Notifies when the number of bars waiting in the bottom region changes.
  static ValueListenable<int> get bottomQueueLengthNotifier => FluentBarManager.instance.bottomQueueLengthNotifier;

  /// Notifies when the global config changes.
  static ValueListenable<FluentBarConfig> get configNotifier => FluentBarManager.instance.configNotifier;

  /// The height of the app bar measured by `FluentBarTopInset` (0 if it is not wrapped).
  /// Used as the inset of top bars until the config sets its own `topInset`.
  static ValueListenable<double> get measuredTopInset => FluentBarManager.instance.topInsetNotifier;

  /// The height of the bottom panel measured by `FluentBarBottomInset` (0 if it is not wrapped).
  static ValueListenable<double> get measuredBottomInset => FluentBarManager.instance.bottomInsetNotifier;

  /// Adds a listener for analytics events of every bar.
  ///
  /// ```dart
  /// FluentBar.addAnalyticsListener((payload) => analytics.log(payload.event.name));
  /// ```
  static void addAnalyticsListener(void Function(FluentBarAnalyticsPayload) listener) => FluentBarManager.instance.addAnalyticsListener(listener);

  /// Removes a listener added with [addAnalyticsListener].
  ///
  /// ```dart
  /// FluentBar.removeAnalyticsListener(listener);
  /// ```
  static void removeAnalyticsListener(void Function(FluentBarAnalyticsPayload) listener) => FluentBarManager.instance.removeAnalyticsListener(listener);

  /// Adds a handler for errors in user callbacks, builders, themes and types.
  ///
  /// ```dart
  /// FluentBar.addErrorHandler((error, stackTrace) => crashReporter.record(error.error, stackTrace));
  /// ```
  static void addErrorHandler(void Function(FluentBarException, StackTrace) handler) => FluentBarManager.instance.addErrorHandler(handler);

  /// Removes a handler added with [addErrorHandler].
  ///
  /// ```dart
  /// FluentBar.removeErrorHandler(handler);
  /// ```
  static void removeErrorHandler(void Function(FluentBarException, StackTrace) handler) => FluentBarManager.instance.removeErrorHandler(handler);
}

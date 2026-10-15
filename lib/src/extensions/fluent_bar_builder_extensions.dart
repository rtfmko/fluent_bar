import 'package:fluent_bar/src/internal.dart';

/// The chain that configures a bar before it is shown.
///
/// Every method returns a new [FluentBarItem] and leaves the original untouched, so a draft can
/// be reused. `show()` ends the chain:
///
/// ```dart
/// FluentBar.info('Uploading the file')
///     .withTitle('Upload')
///     .withLinearProgress(showText: true)
///     .atBottom()
///     .show();
/// ```
///
/// Whatever the chain does not touch comes from the type and the global config.
extension FluentBarItemBuilder<T> on FluentBarItem<T> {
  FluentBarItem<T> _behavior(FluentBarBehavior Function(FluentBarBehavior behavior) change) => copyWith(behavior: change(behavior));

  FluentBarItem<T> _appearance(FluentBarAppearance<T> Function(FluentBarAppearance<T> appearance) change) => copyWith(appearance: change(appearance));

  FluentBarItem<T> _callbacks(FluentBarCallbacks<T> Function(FluentBarCallbacks<T> callbacks) change) => copyWith(callbacks: change(callbacks ?? FluentBarCallbacks<T>()));

  /// Sets the title shown above the message.
  ///
  /// ```dart
  /// FluentBar.info('Saved to drafts').withTitle('Message').show();
  /// ```
  FluentBarItem<T> withTitle(String title) => copyWith(title: title);

  /// The identifier used to find the bar (`FluentBar.find`), close it and detect duplicates.
  FluentBarItem<T> withId(String id) => copyWith(id: id);

  /// Attaches a typed payload; it comes back in `onTap` and in the action handler.
  ///
  /// ```dart
  /// FluentBar.success<Order>('Order shipped').withPayload(order).show();
  /// ```
  FluentBarItem<T> withPayload(T payload) => copyWith(payload: payload);

  /// Attaches free-form data for analytics and for a custom duplicate rule.
  ///
  /// ```dart
  /// FluentBar.info('New message').withMeta({'group': 'chat_42'}).show();
  /// ```
  FluentBarItem<T> withMeta(Map<String, dynamic> meta) => copyWith(meta: meta);

  /// A label for logs and analytics: what this bar is in terms of the app (`promo`, `undo`, ...).
  FluentBarItem<T> withPreset(String preset) => copyWith(preset: preset);

  /// Adds a tag: a label that groups bars so that they can be closed together.
  ///
  /// ```dart
  /// FluentBar.error('Card declined').withTag('checkout').show();
  /// FluentBar.closeTag('checkout');
  /// ```
  FluentBarItem<T> withTag(String tag) => copyWith(tags: <String>{...tags, tag});

  /// Adds several tags at once.
  ///
  /// ```dart
  /// FluentBar.info('Uploading').withTags({'checkout', 'upload'}).show();
  /// ```
  FluentBarItem<T> withTags(Iterable<String> tags) => copyWith(tags: <String>{...this.tags, ...tags});

  /// Sets how long the bar stays on screen and makes it non-persistent.
  ///
  /// ```dart
  /// FluentBar.info('Copied').withDuration(const Duration(seconds: 2)).show();
  /// ```
  FluentBarItem<T> withDuration(Duration duration) => copyWith(duration: duration, isPersistent: false);

  /// The bar does not close by timer, only by the user or from code.
  FluentBarItem<T> persistent() => copyWith(isPersistent: true);

  /// Shows the countdown line.
  FluentBarItem<T> withTimeoutBar({FluentBarTimeoutBarPosition? position, FluentBarTimeoutBarDirection? direction}) =>
      _appearance((FluentBarAppearance<T> a) => a.copyWith(showTimeoutBar: true, timeoutBarPosition: position, timeoutBarDirection: direction));

  /// Hides the countdown line, also when the type or the config turns it on.
  ///
  /// ```dart
  /// FluentBar.info('Saved').withoutTimeoutBar().show();
  /// ```
  FluentBarItem<T> withoutTimeoutBar() => _appearance((FluentBarAppearance<T> a) => a.copyWith(showTimeoutBar: false));

  /// Shows a close button at the end of the bar. It only closes the bar: a running task is not
  /// stopped (see `withCancelButton` for that).
  ///
  /// ```dart
  /// FluentBar.info('Update available').persistent().withCloseButton().show();
  /// FluentBar.snack('Saved').withCloseButton(icon: const Icon(Icons.cancel_outlined)).show();
  /// ```
  FluentBarItem<T> withCloseButton({Widget? icon}) => _appearance((FluentBarAppearance<T> a) => a.copyWith(showCloseButton: true, closeIcon: icon));

  /// Hides the close button, also when the type or the config turns it on.
  ///
  /// ```dart
  /// FluentBar.info('Saved').withoutCloseButton().show();
  /// ```
  FluentBarItem<T> withoutCloseButton() => _appearance((FluentBarAppearance<T> a) => a.copyWith(showCloseButton: false));

  /// Any progress state; the look of the indicator stays as the theme defines it.
  FluentBarItem<T> withProgress(FluentBarProgressState state) => copyWith(progressState: state);

  /// A linear indicator. Without [value] and [state] it is indeterminate.
  ///
  /// Whatever is not set here (text, position, color, effect) comes from the type and the
  /// global config, like every other setting of a bar.
  ///
  /// [successIconDuration] is how long the success icon stays after completion; without it
  /// the icon stays until the bar closes.
  ///
  /// [animationDuration] is how long the indicator takes to cross the whole scale on a sharp
  /// jump; smaller jumps take proportionally less (see `FluentBarProgressTheme.animationDuration`).
  FluentBarItem<T> withLinearProgress({
    double? value,
    FluentBarProgressState? state,
    bool? showText,
    FluentBarProgressPosition? position,
    Color? color,
    FluentBarProgressTextEffect? textEffect,
    Duration? successIconDuration,
    Duration? animationDuration,
  }) => _withStyledProgress(
    FluentBarProgressStyle.linear,
    value: value,
    state: state,
    showText: showText,
    position: position,
    color: color,
    textEffect: textEffect,
    successIconDuration: successIconDuration,
    animationDuration: animationDuration,
  );

  /// A circular indicator, by default in place of the icon. Without [value] and [state] it is
  /// indeterminate. Unset settings come from the type and the global config.
  FluentBarItem<T> withCircularProgress({
    double? value,
    FluentBarProgressState? state,
    bool? showText,
    FluentBarProgressPosition position = FluentBarProgressPosition.replaceIcon,
    double? size,
    Color? color,
    FluentBarProgressTextEffect? textEffect,
    Duration? successIconDuration,
    Duration? animationDuration,
  }) => _withStyledProgress(
    FluentBarProgressStyle.circular,
    value: value,
    state: state,
    showText: showText,
    position: position,
    size: size,
    color: color,
    textEffect: textEffect,
    successIconDuration: successIconDuration,
    animationDuration: animationDuration,
  );

  FluentBarItem<T> _withStyledProgress(
    FluentBarProgressStyle style, {
    required double? value,
    required FluentBarProgressState? state,
    required bool? showText,
    required FluentBarProgressPosition? position,
    required Color? color,
    required FluentBarProgressTextEffect? textEffect,
    required Duration? successIconDuration,
    required Duration? animationDuration,
    double? size,
  }) {
    final FluentBarProgressState resolved = state ?? (value == null ? const FluentBarProgressState.indeterminate() : FluentBarProgressValue(value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble()));

    final FluentBarProgressTheme theme = (appearance.progressTheme ?? const FluentBarProgressTheme()).copyWith(
      style: style,
      position: position,
      showText: showText,
      size: size,
      progressColor: color,
      textEffect: textEffect,
      successIconDuration: successIconDuration,
      animationDuration: animationDuration,
    );

    return copyWith(
      progressState: resolved,
      appearance: appearance.copyWith(progressTheme: theme),
    );
  }

  /// Places the bar at [position].
  ///
  /// ```dart
  /// FluentBar.info('Hello').at(FluentBarPosition.center).show();
  /// ```
  FluentBarItem<T> at(FluentBarPosition position) => _behavior((FluentBarBehavior b) => b.copyWith(position: position));

  /// Places the bar at the top of the screen.
  ///
  /// ```dart
  /// FluentBar.info('Hello').atTop().show();
  /// ```
  FluentBarItem<T> atTop() => at(FluentBarPosition.top);

  /// Places the bar at the bottom of the screen.
  ///
  /// ```dart
  /// FluentBar.info('Hello').atBottom().show();
  /// ```
  FluentBarItem<T> atBottom() => at(FluentBarPosition.bottom);

  /// Places the bar in the center of the screen.
  ///
  /// ```dart
  /// FluentBar.info('Hello').atCenter().show();
  /// ```
  FluentBarItem<T> atCenter() => at(FluentBarPosition.center);

  /// What to do when the bar changes position on the fly and the new region is busy.
  FluentBarItem<T> withRelocationStrategy(FluentBarRelocationStrategy strategy) => _behavior((FluentBarBehavior b) => b.copyWith(relocationStrategy: strategy));

  /// Sets the priority that orders the bar in the queue.
  ///
  /// ```dart
  /// FluentBar.error('Connection lost').withPriority(FluentBarPriority.critical).show();
  /// ```
  FluentBarItem<T> withPriority(FluentBarPriority priority) => _behavior((FluentBarBehavior b) => b.copyWith(priority: priority));

  /// Shows the bar out of turn, replacing the one on screen.
  FluentBarItem<T> forced() => _behavior((FluentBarBehavior b) => b.copyWith(isForce: true));

  /// Sets what happens when a bar with the same id is shown again.
  ///
  /// ```dart
  /// FluentBar.toast('Saved', id: 'saved')
  ///     .withDuplicatePolicy(FluentBarDuplicatePolicy.updateAndResetTimer)
  ///     .show();
  /// ```
  FluentBarItem<T> withDuplicatePolicy(FluentBarDuplicatePolicy policy) => _behavior((FluentBarBehavior b) => b.copyWith(duplicatePolicy: policy));

  /// Allows or forbids dismissing the bar with a swipe.
  ///
  /// ```dart
  /// FluentBar.info('Stay here').swipeable(false).show();
  /// ```
  FluentBarItem<T> swipeable([bool enabled = true]) => _behavior((FluentBarBehavior b) => b.copyWith(isSwipeEnabled: enabled));

  /// Allows or forbids dismissing the bar with a tap.
  ///
  /// ```dart
  /// FluentBar.info('Tap to close').dismissOnTap().show();
  /// ```
  FluentBarItem<T> dismissOnTap([bool enabled = true]) => _behavior((FluentBarBehavior b) => b.copyWith(dismissOnTap: enabled));

  /// The bar cannot be dismissed by hand: no swipe, no tap and no close button.
  FluentBarItem<T> undismissible() =>
      _behavior((FluentBarBehavior b) => b.copyWith(isSwipeEnabled: false, dismissOnTap: false))._appearance((FluentBarAppearance<T> a) => a.copyWith(showCloseButton: false));

  /// Sets how the bar is presented to a screen reader.
  ///
  /// ```dart
  /// FluentBar.toast('Copied').withSemantics(FluentBarSemantics.quiet).show();
  /// ```
  FluentBarItem<T> withSemantics(FluentBarSemantics semantics) => _behavior((FluentBarBehavior b) => b.copyWith(semantics: semantics));

  /// Sets whether the countdown stops while the bar is held or hovered.
  ///
  /// ```dart
  /// FluentBar.info('Read me slowly').pauseOnTouch().withTimeoutBar().show();
  /// ```
  FluentBarItem<T> pauseOnTouch([bool enabled = true]) => _behavior((FluentBarBehavior b) => b.copyWith(pauseOnTouch: enabled));

  /// Sets the haptic feedback played when the bar appears.
  ///
  /// ```dart
  /// FluentBar.success('Done').withHaptic(FluentBarHapticType.medium).show();
  /// ```
  FluentBarItem<T> withHaptic(FluentBarHapticType haptic) => _behavior((FluentBarBehavior b) => b.copyWith(haptic: haptic));

  /// The distance from the screen edge for this bar: [top] for a top bar, [bottom] for a bottom one.
  /// A value set here is used as is, instead of the inset from the type, the config or the measuring widgets.
  FluentBarItem<T> withInsets({double? top, double? bottom}) => _behavior((FluentBarBehavior b) => b.copyWith(topInset: top, bottomInset: bottom));

  /// Lets the bar ignore the system safe area (notch, status bar, home gesture).
  ///
  /// ```dart
  /// FluentBar.info('Edge to edge').withoutSafeArea().show();
  /// ```
  FluentBarItem<T> withoutSafeArea() => _behavior((FluentBarBehavior b) => b.copyWith(useSafeArea: false));

  /// Sets the background color of this bar.
  ///
  /// ```dart
  /// FluentBar.info('Bonus points').withBackground(const Color(0xFF7C3AED)).dark().show();
  /// ```
  FluentBarItem<T> withBackground(Color color) => _appearance((FluentBarAppearance<T> a) => a.copyWith(backgroundColor: color));

  /// Sets the icon of this bar, optionally with its color and size.
  ///
  /// ```dart
  /// FluentBar.info('Launch').withIcon(const Icon(Icons.rocket_launch), color: Colors.amber).show();
  /// ```
  FluentBarItem<T> withIcon(Widget icon, {Color? color, double? size}) => _appearance((FluentBarAppearance<T> a) => a.copyWith(showIcon: true, icon: icon, iconColor: color, iconSize: size));

  /// Hides the icon.
  ///
  /// ```dart
  /// FluentBar.info('Plain text').withoutIcon().show();
  /// ```
  FluentBarItem<T> withoutIcon() => _appearance((FluentBarAppearance<T> a) => a.copyWith(showIcon: false));

  /// Uses [theme] for this bar instead of the theme from the config.
  ///
  /// ```dart
  /// FluentBar.info('Glass').withTheme(FluentBarTheme.liquidGlass).show();
  /// ```
  FluentBarItem<T> withTheme(FluentBarTheme theme) => _appearance((FluentBarAppearance<T> a) => a.copyWith(theme: theme));

  /// Forces the light or dark look of this bar.
  ///
  /// ```dart
  /// FluentBar.info('Always dark').withThemeMode(FluentBarThemeMode.dark).show();
  /// ```
  FluentBarItem<T> withThemeMode(FluentBarThemeMode mode) => _appearance((FluentBarAppearance<T> a) => a.copyWith(themeMode: mode));

  /// Forces the dark look of this bar.
  ///
  /// ```dart
  /// FluentBar.info('Always dark').dark().show();
  /// ```
  FluentBarItem<T> dark() => withThemeMode(FluentBarThemeMode.dark);

  /// Forces the light look of this bar.
  ///
  /// ```dart
  /// FluentBar.info('Always light').light().show();
  /// ```
  FluentBarItem<T> light() => withThemeMode(FluentBarThemeMode.light);

  /// Sets how the bar enters and leaves the screen.
  ///
  /// ```dart
  /// FluentBar.success('Saved').withEntrance(FluentBarEntranceAnimation.elastic).show();
  /// ```
  FluentBarItem<T> withEntrance(FluentBarEntranceAnimation animation) => _appearance((FluentBarAppearance<T> a) => a.copyWith(entranceAnimation: animation));

  /// Turns off every animation of this bar.
  ///
  /// ```dart
  /// FluentBar.info('Instant').withoutAnimations().show();
  /// ```
  FluentBarItem<T> withoutAnimations() => _appearance((FluentBarAppearance<T> a) => a.copyWith(disableAnimations: true));

  /// Replaces the whole content of the bar.
  FluentBarItem<T> withContent(Widget Function(BuildContext context, FluentBarEntry<T> entry) builder) => _appearance((FluentBarAppearance<T> a) => a.copyWith(builder: builder));

  /// A Cancel button for a bar with progress. It takes the place of the action button.
  ///
  /// On a tap the bar stops following the progress and the button shows a loader while [onCancel]
  /// stops your task (a loader is visible only if [onCancel] is asynchronous). Then the progress
  /// is cancelled and the bar closes by its usual timer.
  ///
  /// * If [onCancel] throws, the error is reported and the bar follows the progress again, so the
  ///   user can retry.
  /// * If the task finishes or fails while it is being stopped, that result stays.
  /// * Progress sent by the stopped task after the cancellation is ignored. To start over, show
  ///   the bar again with the same id.
  /// * The button goes away by itself when the progress ends in any way, also without a tap.
  /// * [onCancel] must complete: while it runs the bar is busy and ignores progress.
  /// * On a bar without progress the button only runs [onCancel] and shows [canceledMessage].
  ///
  /// [child] replaces the text of the button; [canceledMessage] and [canceledType] are what the
  /// bar shows after the cancellation.
  ///
  /// ```dart
  /// FluentBar.info('Downloading the map')
  ///     .withLinearProgress(value: 0, showText: true)
  ///     .withCancelButton('Cancel', onCancel: () => download.cancel(), canceledMessage: 'Download cancelled')
  ///     .show();
  /// ```
  FluentBarItem<T> withCancelButton(String label, {Widget? child, FutureOr<void> Function()? onCancel, String? canceledMessage, FluentBarType? canceledType}) {
    final FluentBarItem<T> item = withAction(
      label,
      closeOnAction: false,
      onPressed: (FluentBarController<T> controller, T? payload) async {
        final FluentBarInternalController<T> internal = controller as FluentBarInternalController<T>;
        final FluentBarProgressState? before = controller.progressStateNotifier.value;
        final bool wasRunning = before != null && !before.isCompleted;

        if (wasRunning) internal.beginProgressCancel();
        try {
          await onCancel?.call();
        } on Object {
          internal.abortProgressCancel();
          rethrow;
        }

        // No progress to cancel: the bar only shows what was asked, unless a progress has started
        // on it while the callback ran.
        if (!wasRunning) {
          if (controller.progressStateNotifier.value != null) return;
          controller
            ..updateContent(message: canceledMessage, type: canceledType)
            ..removeAction();
          return;
        }

        // The task may have finished or failed while it was being stopped: that result is the truth.
        final FluentBarProgressState? after = controller.progressStateNotifier.value;
        if (after == null || after.isCompleted) {
          internal.abortProgressCancel();
          return;
        }

        controller.cancelProgress(fallbackMessage: canceledMessage, fallbackType: canceledType);
      },
    );

    return item.copyWith(
      actions: item.actions!.copyWith(child: child, removeWhenProgressEnds: true, analyticsName: 'cancel'),
    );
  }

  /// The action button. While [onPressed] runs, the button shows a loader and the countdown stands still.
  ///
  /// A call describes the whole button: label, handler and closing. A second call replaces the
  /// previous button together with its handler (its look - line count, loader color - is kept).
  ///
  /// [analyticsName] is a stable key for analytics (`undo`, `open_cart`), sent as `action_name`.
  FluentBarItem<T> withAction(String label, {FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed, bool closeOnAction = true, String? analyticsName}) {
    final FluentBarActions<T>? previous = actions;

    return copyWith(
      actions: FluentBarActions<T>(
        label: label,
        onPressed: onPressed,
        closeOnAction: closeOnAction,
        analyticsName: analyticsName,
        maxActionLines: previous?.maxActionLines,
        actionOverflow: previous?.actionOverflow,
        throttleDuration: previous?.throttleDuration ?? const Duration(milliseconds: 400),
        actionLoaderColor: previous?.actionLoaderColor,
        actionLoadingWidget: previous?.actionLoadingWidget,
      ),
    );
  }

  /// Sets a callback for a tap on the bar; it receives the payload.
  ///
  /// ```dart
  /// FluentBar.info('New message').onTap((_) => openChat()).show();
  /// ```
  FluentBarItem<T> onTap(void Function(T? payload) callback) => _callbacks((FluentBarCallbacks<T> c) => c.copyWith(onTap: callback));

  /// Sets a callback for the moment the bar appears on screen.
  ///
  /// ```dart
  /// FluentBar.info('Welcome').onShow((item) => log('shown ${item.id}')).show();
  /// ```
  FluentBarItem<T> onShow(void Function(FluentBarItem<T> item) callback) => _callbacks((FluentBarCallbacks<T> c) => c.copyWith(onShow: callback));

  /// Sets a callback for the moment the bar is closed; it receives the metrics.
  ///
  /// ```dart
  /// FluentBar.info('Bye').onDismiss((item, metrics) => log(metrics.dismissReason.name)).show();
  /// ```
  FluentBarItem<T> onDismiss(void Function(FluentBarItem<T> item, FluentBarMetrics metrics) callback) => _callbacks((FluentBarCallbacks<T> c) => c.copyWith(onDismiss: callback));
}

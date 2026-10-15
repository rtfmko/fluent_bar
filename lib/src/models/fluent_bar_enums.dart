import 'package:fluent_bar/src/internal.dart' show FluentBarAnalyticsPayload, FluentBarMetrics, FluentBarProgressBytes;

/// The haptic feedback played when a bar appears or its progress completes.
enum FluentBarHapticType {
  /// No feedback.
  none,

  /// A light impact.
  light,

  /// A medium impact.
  medium,

  /// A heavy impact.
  heavy,
}

/// An event in the life of a bar, delivered to analytics listeners.
enum FluentBarAnalyticsEvent {
  /// A bar was requested (any show call).
  requested,

  /// There was nowhere to show it at once: the bar went into the queue.
  queued,

  /// The bar appeared on screen.
  shown,

  /// The bar was closed; the event carries metrics (reason, time on screen).
  dismissed,

  /// A repeated show was ignored by the duplicate policy.
  ignoredDuplicate,

  /// An existing bar was updated by a repeated show.
  updated,

  /// The bar was evicted from a full queue.
  queueOverflow,

  /// The user tapped the bar itself.
  tapped,

  /// The user tapped the action button.
  actionTapped,

  /// The countdown stopped; the reason is in [FluentBarAnalyticsPayload.pauseReason].
  paused,

  /// The countdown continued.
  resumed,

  /// The bar changed position and moved to another region (at once or through its queue).
  relocated,

  /// The progress of the bar completed.
  progressCompleted,

  /// The progress of the bar was cancelled.
  progressCanceled,

  /// The progress of the bar failed.
  progressFailed;

  /// A step of the life of a bar: [requested], [queued], [shown] or [dismissed].
  bool get isLifecycle => this == requested || this == queued || this == shown || this == dismissed;

  /// Something the user did: [tapped] or [actionTapped].
  ///
  /// A swipe closes the bar, so it arrives as [dismissed] with the reason in the metrics.
  bool get isInteraction => this == tapped || this == actionTapped;

  /// The outcome of a progress: [progressCompleted], [progressFailed] or [progressCanceled].
  bool get isProgress => this == progressCompleted || this == progressFailed || this == progressCanceled;

  /// The bar was turned away: [ignoredDuplicate] or [queueOverflow].
  bool get isRejected => this == ignoredDuplicate || this == queueOverflow;

  /// The countdown stopped or went on: [paused] or [resumed].
  bool get isCountdown => this == paused || this == resumed;

  /// Whether [FluentBarAnalyticsPayload.metrics] is filled: [dismissed] or [queueOverflow].
  bool get hasMetrics => this == dismissed || this == queueOverflow;
}

/// Where a bar appears on screen.
///
/// `bottom` belongs to the bottom region; every other position shares the top region.
enum FluentBarPosition {
  /// At the top edge.
  top,

  /// At the right edge, vertically centered.
  right,

  /// At the bottom edge.
  bottom,

  /// At the left edge, vertically centered.
  left,

  /// In the center of the screen.
  center,
}

/// How the user interacted with a bar (see [FluentBarMetrics.interactions]).
enum FluentBarInteraction {
  /// A tap on the bar itself.
  tap,

  /// A tap on the action button.
  action,

  /// Holding with a finger or the cursor longer than the pause threshold.
  hold,

  /// The bar was swiped away.
  swipe,

  /// A tap on the close button.
  close,

  /// The dismiss gesture of a screen reader.
  accessibility,
}

/// What stopped the countdown of a bar (comes with the paused / resumed events).
enum FluentBarPauseReason {
  /// A pause() call from code.
  manual,

  /// The bar was put into the loading state (setLoading).
  loading,

  /// The handler of the action button is running.
  action,

  /// The user holds the bar with a finger or the cursor longer than a short threshold; a plain
  /// tap and an accidental hover do not count as a pause.
  touch,
}

/// How important a bar is: a higher priority is shown earlier.
enum FluentBarPriority {
  /// Shown after everything else.
  low(10),

  /// The default.
  normal(50),

  /// Shown before normal bars.
  high(90),

  /// Shown before every other waiting bar.
  critical(100);

  /// The number priorities are compared by.
  final int weight;

  const FluentBarPriority(this.weight);
}

/// What to do when a bar is shown that is already on screen or in the queue (the same id).
///
/// Under any policy a repeated bar with progress is a progress update of the same bar, not a
/// new bar: progress, texts and type change, the rest (action, callbacks, behavior, look) is kept.
enum FluentBarDuplicatePolicy {
  /// Show it as a separate bar.
  allow,

  /// Leave the existing bar as it is.
  ignore,

  /// Replace the content of the existing bar with the incoming one.
  update,

  /// Like [update], and restart the countdown.
  updateAndResetTimer,
}

/// Which built-in theme is used when no theme is set.
enum FluentBarThemeStyle {
  /// The Material theme.
  material,

  /// The Cupertino theme.
  cupertino,

  /// The Windows theme.
  windows,

  /// The theme that matches the platform the app runs on.
  auto,
}

/// The light or dark look of a bar.
enum FluentBarThemeMode {
  /// Follows the theme of the app.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// Which way the countdown line moves.
enum FluentBarTimeoutBarDirection {
  /// The line shrinks as the time runs out.
  forward,

  /// The line grows as the time runs out.
  reverse,
}

/// Why a bar was closed.
enum FluentBarDismissReason {
  /// Its time ran out.
  timeout,

  /// The user swiped it away.
  swipe,

  /// The user pressed the action button.
  actionButton,

  /// Another bar replaced it out of turn.
  force,

  /// It was closed from code.
  manual,

  /// The user tapped it.
  tap,

  /// The user pressed the close button.
  closeButton,

  /// The user closed it with the dismiss gesture of a screen reader (TalkBack, VoiceOver).
  accessibility,

  /// It never reached the screen: the queue was full and the bar was dropped.
  dropped;

  /// The user closed it: [swipe], [tap], [actionButton], [closeButton] or [accessibility].
  bool get isByUser => this == swipe || this == tap || this == actionButton || this == closeButton || this == accessibility;

  /// The app closed it: [manual] (a close call) or [force] (another bar took its place).
  bool get isByCode => this == manual || this == force;

  /// Nobody closed it: its time ran out ([timeout]) or the full queue dropped it ([dropped]).
  bool get isAutomatic => this == timeout || this == dropped;
}

/// How the task of a bar with progress ended.
enum FluentBarProgressOutcome {
  /// The progress reached the end.
  completed,

  /// `failProgress` was called.
  failed,

  /// `cancelProgress` was called.
  canceled,
}

/// How a bar is presented to a screen reader (TalkBack, VoiceOver).
enum FluentBarSemantics {
  /// Announced when it appears and when its title or message changes. The default.
  announce,

  /// Readable when the user moves to it, but never announced by itself.
  quiet,

  /// Not exposed to the screen reader at all. Use with care: a blind user will not know about the bar.
  hidden,
}

/// Where a bar is in its life.
enum FluentBarLifecycleState {
  /// Waiting in the queue.
  queued,

  /// On screen and playing its entrance animation. Taps and the action already work; the
  /// countdown has not started yet.
  showing,

  /// In place: the entrance animation has finished and the countdown runs. Without an entrance
  /// animation the bar gets here right after `showing`.
  visible,

  /// Playing its exit animation.
  hiding,

  /// Closed for good.
  dismissed;

  /// Waiting in the queue.
  bool get isQueued => this == queued;

  /// Playing its entrance animation.
  bool get isShowing => this == showing;

  /// In place, the countdown runs.
  bool get isVisible => this == visible;

  /// Playing its exit animation.
  bool get isHiding => this == hiding;

  /// Drawn on screen, moving or not: [showing], [visible] or [hiding].
  bool get isOnScreen => this == showing || this == visible || this == hiding;

  /// On screen and reacting to the user: [showing] or [visible].
  bool get isInteractive => this == showing || this == visible;

  /// Playing its entrance or exit animation: [showing] or [hiding].
  bool get isAnimating => this == showing || this == hiding;

  /// On its way out or already gone: [hiding] or [dismissed]. Updating the bar no longer makes sense.
  bool get isFinished => this == hiding || this == dismissed;

  /// Closed for good.
  bool get isDismissed => this == dismissed;
}

/// What the text of a [FluentBarProgressBytes] shows when the total size is known.
enum FluentBarBytesLabel {
  /// The amount: `3.1 / 50 MB`. The default.
  amount,

  /// The percent: `6%`.
  percent,

  /// Both: `3.1 / 50 MB · 6%`.
  both,
}

/// The shape of a progress indicator.
enum FluentBarProgressStyle {
  /// A ring.
  circular,

  /// A line.
  linear,
}

/// Where the progress indicator sits inside a bar.
enum FluentBarProgressPosition {
  /// Above the content.
  top,

  /// Below the content.
  bottom,

  /// Before the content.
  left,

  /// After the content.
  right,

  /// In place of the icon. The text there is the percent whatever the state is: a fraction,
  /// bytes or a custom label would not fit. A progress without a percent shows no text.
  replaceIcon,
}

/// How serious a reported error is.
enum FluentBarErrorSeverity {
  /// A misuse the library recovered from.
  warning,

  /// A failure in user code or in the library.
  error;

  /// A misuse the library recovered from: worth a log entry, usually not a crash report.
  bool get isWarning => this == warning;

  /// A failure in user code or in the library: worth a crash report.
  bool get isError => this == error;
}

/// An attention effect played on a visible bar.
enum FluentBarEffect {
  /// A sideways shake.
  shake,

  /// A single bounce.
  bounce,

  /// A soft scale up and down.
  pulse,

  /// A double-beat scale.
  heartbeat,

  /// The effect drawn by `FluentBarAppearance.customEffectBuilder`.
  custom,
}

/// How a bar enters and leaves the screen.
enum FluentBarEntranceAnimation {
  /// A plain slide with a fade (the default).
  slide,

  /// A short shift with a fade.
  fadeSlide,

  /// A springy slide with a small overshoot at the end.
  bouncingSlide,

  /// A plain fade, no movement.
  fade,

  /// Grows from the center.
  scale,

  /// A 3D turn around the X axis, like a flip board.
  flip3d,

  /// A strong elastic effect.
  elastic,
}

/// Where the countdown line sits inside a bar.
enum FluentBarTimeoutBarPosition {
  /// Along the top edge of the bar.
  top,

  /// Along the bottom edge of the bar.
  bottom,
}

/// Where the progress text sits relative to the indicator.
enum FluentBarProgressTextAlign {
  /// The text is to the left of the indicator.
  left,

  /// The text is to the right of the indicator.
  right,

  /// The text is centered: inside the ring for a circular indicator, under the line for a linear one.
  center,
}

/// How the progress text ("42%", "3 / 5") changes when the value updates.
enum FluentBarProgressTextEffect {
  /// The text changes at once.
  none,

  /// Percents count up to the new value (the default). For fractions and custom labels it equals [none].
  count,

  /// The old text fades out, the new one fades in.
  fade,

  /// An odometer: changed characters roll up and new ones roll in from below (the other way when
  /// the value decreases). Unchanged characters stay in place.
  roll,

  /// A flip board: changed characters flip around the horizontal axis.
  flip,

  /// The new text pops in with a light springy growth.
  pop,
}

/// What to do when a visible bar changes position and the region it moves to is busy.
enum FluentBarRelocationStrategy {
  /// If the target region is busy, the bar hides and goes to the front of the queue of that region.
  queueNext,

  /// Replaces the bar that occupies the target region.
  forceReplace,

  /// If the target region is busy, the move is ignored and the bar stays where it was.
  ignore,
}

/// Which part of the library reported an error.
enum FluentBarErrorType {
  /// A queue strategy threw while placing a bar.
  queueEnqueue('QueueStrategy: Enqueue'),

  /// A queue strategy threw while picking the next bar.
  queueDequeue('QueueStrategy: Dequeue'),

  /// A content builder threw.
  customBuilderAppearance('Appearance: Custom Builder'),

  /// A progress builder threw.
  customProgressBuilder('Appearance: Progress Builder'),

  /// A transition builder threw.
  customBuilderTransition('Appearance: Transition Builder'),

  /// A custom effect builder threw.
  customBuilderEffect('Actions: Effects Builder'),

  /// An action builder threw.
  customButtonBuilder('Actions: Buttons Builder'),

  /// An action handler threw.
  actionPressed('Action: OnPressed'),

  /// More time was subtracted than the bar had left.
  subtractDuration('Controller: Subtract Duration'),

  /// A call got arguments that do not fit together, for example `failProgress` with a
  /// `retryLabel` but no `onRetry`, or `addDuration` with a negative amount. The library took the safe way (described for each call) and
  /// went on.
  invalidCall('Controller: Invalid call'),

  /// The callback of `patchAppearance`, `patchBehavior` or `FluentBar.patchConfig` threw, or
  /// `patchAppearance` got back an appearance of another payload type. Nothing was changed.
  patchCallback('Callback: Patch'),

  /// An `onShow` callback threw.
  callbackShow('Callback: OnShow'),

  /// An `onTap` callback threw.
  callbackTap('Callback: OnTap'),

  /// An `onProgressCompleted` callback threw.
  callbackProgressCompleted('Callback: On Progress Completed'),

  /// An `onProgressCanceled` callback threw.
  callbackProgressCanceled('Callback: On Progress Canceled'),

  /// An `onProgressFailed` callback threw.
  callbackProgressFailed('Callback: On Progress Failed'),

  /// An `onDismiss` callback threw.
  callbackDismiss('Callback: OnDismiss'),

  /// An analytics listener threw.
  callbackAnalytics('Callback: OnAnalytics'),

  /// The built-in haptic feedback failed.
  hapticInternal('Haptic: Trigger Internal'),

  /// A custom haptic callback threw.
  hapticExternal('Haptic: Trigger External'),

  /// The library was initialized more than once.
  initialization('Manager: Multiple init'),

  /// A bar was dropped because the queue was full.
  queueOverflow('Manager: Queue overflow'),

  /// There was no overlay to show bars in, or inserting into it failed.
  overlay('Manager: Overlay'),

  /// A bar reused the id of a bar with another payload type and was shown separately.
  payloadTypeMismatch('Manager: Payload type mismatch'),

  /// A custom duplicate rule threw.
  callbackDuplicateComparator('Extension: Duplicate Comparator'),

  /// A custom `isDarkMode` of a theme threw.
  darkMode('Theme: Dark mode'),

  /// A method of a theme threw.
  fluentBarTheme,

  /// A getter of a custom type threw.
  fluentBarType,

  /// A label builder, a position builder or another resolved callback threw.
  fluentBarResolver;

  /// A readable name of the error type, if it has one.
  final String? label;

  const FluentBarErrorType([this.label]);

  /// The readable name: [label], or the name of the value.
  String get displayName => label ?? name;
}

import 'package:fluent_bar/src/internal.dart';

/// How one bar behaves: where it appears, how it reacts to touch, how it queues.
///
/// Whatever is left `null` comes from the type of the bar, then from the config.
///
/// ```dart
/// FluentBar.info('Swipe sideways').copyWith(
///   behavior: const FluentBarBehavior(
///     position: FluentBarPosition.bottom,
///     dismissDirection: DismissDirection.horizontal,
///     dismissOnTap: false,
///   ),
/// ).show();
/// ```
class FluentBarBehavior {
  /// Shows the bar out of turn, replacing the one on screen.
  final bool isForce;

  /// Whether the bar can be swiped away.
  final bool? isSwipeEnabled;

  /// Whether the bar keeps clear of the notch, status bar and home gesture.
  final bool? useSafeArea;

  /// Whether a tap closes the bar.
  final bool? dismissOnTap;

  /// Whether the countdown stops while the bar is held or hovered.
  final bool? pauseOnTouch;

  /// How the bar is presented to a screen reader.
  final FluentBarSemantics? semantics;

  /// The priority that orders the bar in the queue.
  final FluentBarPriority? priority;

  /// Where the bar appears.
  final FluentBarPosition? position;

  /// Which way the bar can be swiped away.
  final DismissDirection? dismissDirection;

  /// What happens when a bar with the same id is shown again.
  final FluentBarDuplicatePolicy? duplicatePolicy;

  /// How often the countdown values of the bar are published to listeners.
  final FluentBarUpdateRate? timeoutUpdateInterval;

  /// The haptic feedback played when the bar appears.
  final FluentBarHapticType? haptic;

  /// The haptic feedback played when the progress completes.
  final FluentBarHapticType? progressCompletedHaptic;

  /// What happens when the bar changes position and the new region is busy.
  final FluentBarRelocationStrategy? relocationStrategy;

  /// Places the bar on screen with a custom widget instead of a position.
  final Widget Function(BuildContext context, Widget child)? positionBuilder;

  /// The distance of a top bar from the top edge. A value set here is used as is, instead of the
  /// inset from the type, the config and the measured `FluentBarTopInset`.
  final double? topInset;

  /// The same for a bottom bar and the bottom edge (see `FluentBarBottomInset`).
  final double? bottomInset;

  /// Creates a behavior; everything left out comes from the type and the config.
  const FluentBarBehavior({
    this.isForce = false,
    this.isSwipeEnabled,
    this.useSafeArea,
    this.dismissOnTap,
    this.pauseOnTouch,
    this.semantics,
    this.priority,
    this.position,
    this.dismissDirection,
    this.duplicatePolicy,
    this.timeoutUpdateInterval,
    this.haptic,
    this.progressCompletedHaptic,
    this.relocationStrategy,
    this.positionBuilder,
    this.topInset,
    this.bottomInset,
  });

  /// A copy with the given fields replaced; `null` keeps a field.
  FluentBarBehavior copyWith({
    bool? isForce,
    bool? isSwipeEnabled,
    bool? useSafeArea,
    bool? dismissOnTap,
    bool? pauseOnTouch,
    FluentBarSemantics? semantics,
    FluentBarPriority? priority,
    FluentBarPosition? position,
    DismissDirection? dismissDirection,
    FluentBarDuplicatePolicy? duplicatePolicy,
    FluentBarUpdateRate? timeoutUpdateInterval,
    FluentBarHapticType? haptic,
    FluentBarHapticType? progressCompletedHaptic,
    FluentBarRelocationStrategy? relocationStrategy,
    Widget Function(BuildContext context, Widget child)? positionBuilder,
    double? topInset,
    double? bottomInset,
  }) => FluentBarBehavior(
    isForce: isForce ?? this.isForce,
    isSwipeEnabled: isSwipeEnabled ?? this.isSwipeEnabled,
    useSafeArea: useSafeArea ?? this.useSafeArea,
    dismissOnTap: dismissOnTap ?? this.dismissOnTap,
    pauseOnTouch: pauseOnTouch ?? this.pauseOnTouch,
    semantics: semantics ?? this.semantics,
    priority: priority ?? this.priority,
    position: position ?? this.position,
    dismissDirection: dismissDirection ?? this.dismissDirection,
    duplicatePolicy: duplicatePolicy ?? this.duplicatePolicy,
    timeoutUpdateInterval: timeoutUpdateInterval ?? this.timeoutUpdateInterval,
    haptic: haptic ?? this.haptic,
    progressCompletedHaptic: progressCompletedHaptic ?? this.progressCompletedHaptic,
    relocationStrategy: relocationStrategy ?? this.relocationStrategy,
    positionBuilder: positionBuilder ?? this.positionBuilder,
    topInset: topInset ?? this.topInset,
    bottomInset: bottomInset ?? this.bottomInset,
  );

  /// The same behavior with other gestures. Unlike [copyWith], this accepts `null`:
  /// "not set, the type or the config decides".
  ///
  /// The field list repeats the constructor: when adding a field, add it here too.
  FluentBarBehavior withGestures({required bool? isSwipeEnabled, required bool? dismissOnTap}) => FluentBarBehavior(
    isForce: isForce,
    isSwipeEnabled: isSwipeEnabled,
    useSafeArea: useSafeArea,
    dismissOnTap: dismissOnTap,
    pauseOnTouch: pauseOnTouch,
    semantics: semantics,
    priority: priority,
    position: position,
    dismissDirection: dismissDirection,
    duplicatePolicy: duplicatePolicy,
    timeoutUpdateInterval: timeoutUpdateInterval,
    haptic: haptic,
    progressCompletedHaptic: progressCompletedHaptic,
    relocationStrategy: relocationStrategy,
    positionBuilder: positionBuilder,
    topInset: topInset,
    bottomInset: bottomInset,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentBarBehavior &&
          runtimeType == other.runtimeType &&
          priority == other.priority &&
          isForce == other.isForce &&
          position == other.position &&
          isSwipeEnabled == other.isSwipeEnabled &&
          dismissDirection == other.dismissDirection &&
          duplicatePolicy == other.duplicatePolicy &&
          useSafeArea == other.useSafeArea &&
          dismissOnTap == other.dismissOnTap &&
          pauseOnTouch == other.pauseOnTouch &&
          semantics == other.semantics &&
          timeoutUpdateInterval == other.timeoutUpdateInterval &&
          haptic == other.haptic &&
          progressCompletedHaptic == other.progressCompletedHaptic &&
          relocationStrategy == other.relocationStrategy &&
          topInset == other.topInset &&
          bottomInset == other.bottomInset;

  @override
  int get hashCode => Object.hash(
    priority,
    isForce,
    position,
    isSwipeEnabled,
    dismissDirection,
    duplicatePolicy,
    useSafeArea,
    dismissOnTap,
    pauseOnTouch,
    semantics,
    timeoutUpdateInterval,
    haptic,
    progressCompletedHaptic,
    relocationStrategy,
    topInset,
    bottomInset,
  );
}

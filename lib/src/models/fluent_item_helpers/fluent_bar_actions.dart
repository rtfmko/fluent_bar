import 'package:fluent_bar/src/internal.dart';

/// The action button of a bar.
///
/// ```dart
/// FluentBar.info('Message archived').copyWith(
///   actions: FluentBarActions(
///     label: 'Undo',
///     closeOnAction: false,
///     onPressed: (controller, payload) async => restore(),
///   ),
/// ).show();
/// ```
class FluentBarActions<T> {
  /// The text of the button.
  final String? label;

  /// A widget shown instead of [label].
  final Widget? child;

  /// What this button is called in analytics: a stable key such as `undo`, unlike [label],
  /// which is translated. `withCancelButton` sets `cancel`, a Retry button sets `retry`.
  /// Sent as `action_name` by `FluentBarAnalyticsPayload.toFlatMap`.
  final String? analyticsName;

  /// Whether pressing the button closes the bar.
  final bool closeOnAction;

  /// Whether the button goes away by itself when the progress of the bar ends, whatever the
  /// outcome. For buttons that make sense only while a task runs: Cancel, Pause.
  final bool removeWhenProgressEnds;

  /// Called when the button is pressed. While an async handler runs, the button shows a loader.
  final FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed;

  /// Draws the action area with a custom widget instead of the default button.
  final Widget Function(BuildContext context, FluentBarController<T> controller, FluentBarType type, FluentBarThemeMode themeMode)? builder;

  /// How many lines the label may take.
  final int? maxActionLines;

  /// How a label that does not fit is cut.
  final TextOverflow? actionOverflow;

  /// A second press within this time is ignored.
  final Duration throttleDuration;

  /// The color of the loader shown while the handler runs.
  final Color? actionLoaderColor;

  /// A widget shown instead of the default loader.
  final Widget? actionLoadingWidget;

  /// Creates an action button.
  const FluentBarActions({
    this.label,
    this.child,
    this.closeOnAction = true,
    this.removeWhenProgressEnds = false,
    this.analyticsName,
    this.onPressed,
    this.builder,
    this.maxActionLines,
    this.actionOverflow,
    this.throttleDuration = const Duration(milliseconds: 400),
    this.actionLoaderColor,
    this.actionLoadingWidget,
  });

  /// A copy with the given fields replaced; `null` keeps a field.
  FluentBarActions<T> copyWith({
    String? label,
    Widget? child,
    bool? closeOnAction,
    bool? removeWhenProgressEnds,
    String? analyticsName,
    FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed,
    Widget Function(BuildContext context, FluentBarController<T> controller, FluentBarType type, FluentBarThemeMode themeMode)? builder,
    int? maxActionLines,
    TextOverflow? actionOverflow,
    Duration? throttleDuration,
    Color? actionLoaderColor,
    Widget? actionLoadingWidget,
  }) => FluentBarActions<T>(
    label: label ?? this.label,
    child: child ?? this.child,
    closeOnAction: closeOnAction ?? this.closeOnAction,
    removeWhenProgressEnds: removeWhenProgressEnds ?? this.removeWhenProgressEnds,
    analyticsName: analyticsName ?? this.analyticsName,
    onPressed: onPressed ?? this.onPressed,
    builder: builder ?? this.builder,
    maxActionLines: maxActionLines ?? this.maxActionLines,
    actionOverflow: actionOverflow ?? this.actionOverflow,
    throttleDuration: throttleDuration ?? this.throttleDuration,
    actionLoaderColor: actionLoaderColor ?? this.actionLoaderColor,
    actionLoadingWidget: actionLoadingWidget ?? this.actionLoadingWidget,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentBarActions &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          closeOnAction == other.closeOnAction &&
          maxActionLines == other.maxActionLines &&
          actionOverflow == other.actionOverflow &&
          removeWhenProgressEnds == other.removeWhenProgressEnds &&
          analyticsName == other.analyticsName &&
          throttleDuration == other.throttleDuration &&
          actionLoaderColor == other.actionLoaderColor;

  @override
  int get hashCode => Object.hash(label, closeOnAction, removeWhenProgressEnds, analyticsName, maxActionLines, actionOverflow, throttleDuration, actionLoaderColor);
}

import 'package:fluent_bar/src/internal.dart';

/// What the manager and the widgets need from a controller beyond the public [FluentBarController].
abstract class FluentBarInternalController<T> implements FluentBarController<T> {
  /// The manager that shows the bar; `null` while the bar waits in the queue.
  FluentBarManager? get manager;

  /// Sets the manager when the bar is shown.
  set manager(FluentBarManager? value);

  /// Whether the controller was disposed; every call on it is then a no-op.
  bool get isDisposed;

  /// Whether the bar was closed while it was still waiting in the queue.
  bool get isClosedBeforeShow;

  /// Stops the countdown for good; used when the bar starts closing.
  void stopTimers();

  /// Stops the countdown while the bar is held or hovered. Independent of pause()/resume() and of loading.
  void setTouchHold({required bool isHeld});

  /// Whether [item] can be bound to this controller (the payload type matches).
  bool accepts(FluentBarItem<dynamic> item);

  /// Replaces the item, for a duplicate merge or a behavior change. With [resetTimer] the countdown
  /// starts over; [isNewShow] says the bar was shown again by its id, which answers a failed bar.
  void rebindItem(FluentBarItem<T> newItem, {bool resetTimer = false, bool isNewShow = false});

  /// Whether a failed bar is held on screen until the user answers (see `failProgress`).
  bool get isAwaitingAnswer;

  /// Starts the countdown of [duration] (`null` for a persistent bar) when the bar appears.
  void startTimersOnShow(Duration? duration, FluentBarManager managerInstance, {Duration entrance = Duration.zero});

  /// Called by the widget when the entrance animation has finished: the bar becomes `visible`
  /// and its countdown starts. Does nothing in any state but `showing`.
  void markEntranceCompleted();

  /// Whether the bar has reached the `visible` state at least once.
  bool get wasVisible;

  /// How long the bar spent appearing.
  Duration get showingDuration;

  /// How long the bar has been in the `visible` state, over all the times it was shown.
  Duration get visibleDuration;

  /// How many times the bar was changed after it was created.
  int get updateCount;

  /// How the progress of the bar ended, if it did.
  FluentBarProgressOutcome? get progressOutcome;

  /// Releases timers, notifiers and streams.
  void dispose();

  /// Starts the exit animation and completes when the widget reports its end.
  Future<void> dismiss();

  /// Called by the widget when the exit animation has finished.
  void notifyDismissCompleted();

  /// Moves the bar to another lifecycle state.
  void changeState(FluentBarLifecycleState newState);

  /// How long the bar waited in the queue.
  Duration get queuedDuration;

  /// How long the countdown stood still while the bar was on screen.
  Duration get pausedDuration;

  /// What the user did with the bar and how many times.
  Map<FluentBarInteraction, int> get interactions;

  /// Counts one interaction of the user with the bar.
  void recordInteraction(FluentBarInteraction interaction);

  /// The user asked to cancel the task and it is being stopped. From now on progress updates
  /// are ignored: only a completion still gets through, because a finished task is a fact.
  /// A `cancelProgress` that follows keeps the bar closed for late updates of the stopped task.
  void beginProgressCancel();

  /// The task could not be stopped: progress updates are followed again.
  void abortProgressCancel();

  /// Puts a shown bar back into the "waiting in the queue" state (a move into a busy region):
  /// on the next show it appears at [position] and starts its countdown over.
  void returnToQueue(FluentBarPosition position);
}

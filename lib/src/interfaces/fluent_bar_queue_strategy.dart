import 'package:fluent_bar/src/internal.dart';

/// What [FluentBarQueueStrategy.onEnqueue] returns: the new queue and whether to show the bar at once.
class QueueOperationResult {
  /// The queue after the incoming bar was placed. Entries left out are dropped.
  final List<FluentBarEntry<dynamic>> queue;

  /// Whether the incoming bar must replace the bar on screen.
  final bool shouldForce;

  /// Creates the result of an enqueue.
  const QueueOperationResult({required this.queue, this.shouldForce = false});
}

/// Decides the order of waiting bars.
///
/// Built-in strategies: `SmartQueueStrategy` (by priority, the default), `FifoQueueStrategy`
/// and `LifoQueueStrategy`. Extend this class for your own order.
///
/// ```dart
/// class NewestFirst extends FluentBarQueueStrategy {
///   const NewestFirst();
///
///   @override
///   QueueOperationResult onEnqueue({required queue, required incoming, required config}) =>
///       QueueOperationResult(queue: [incoming, ...queue]);
///
///   @override
///   (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required queue, required config}) =>
///       queue.isEmpty ? (null, queue) : (queue.first, queue.sublist(1));
/// }
///
/// FluentBar.patchConfig((config) => config.copyWith(defaultQueueStrategy: const NewestFirst()));
/// ```
abstract class FluentBarQueueStrategy {
  /// Lets subclasses be const.
  const FluentBarQueueStrategy();

  /// Places `incoming` into `queue` and returns the new queue.
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config});

  /// Picks the next bar to show and returns it with the rest of the queue.
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config});
}

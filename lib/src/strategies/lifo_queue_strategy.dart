import 'package:fluent_bar/src/internal.dart';

/// Shows the most recently requested bar first.
///
/// ```dart
/// FluentBar.patchConfig((config) => config.copyWith(defaultQueueStrategy: const LifoQueueStrategy()));
/// ```
class LifoQueueStrategy implements FluentBarQueueStrategy {
  /// Creates the strategy.
  const LifoQueueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) {
    final List<FluentBarEntry<dynamic>> mutableQueue = List<FluentBarEntry<dynamic>>.from(queue);

    mutableQueue.insert(0, incoming);

    return QueueOperationResult(queue: mutableQueue, shouldForce: incoming.isForce);
  }

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) {
    if (queue.isEmpty) return (null, <FluentBarEntry<dynamic>>[]);

    final List<FluentBarEntry<dynamic>> mutableQueue = List<FluentBarEntry<dynamic>>.from(queue);
    final FluentBarEntry<dynamic> nextItem = mutableQueue.removeAt(0);
    return (nextItem, mutableQueue);
  }
}

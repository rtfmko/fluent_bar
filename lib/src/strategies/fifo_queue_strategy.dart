import 'package:fluent_bar/src/internal.dart';

/// Shows waiting bars in the order they were requested; a forced bar goes first.
///
/// ```dart
/// FluentBar.patchConfig((config) => config.copyWith(defaultQueueStrategy: const FifoQueueStrategy()));
/// ```
class FifoQueueStrategy implements FluentBarQueueStrategy {
  /// Creates the strategy.
  const FifoQueueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) {
    final List<FluentBarEntry<dynamic>> mutableQueue = List<FluentBarEntry<dynamic>>.from(queue);

    if (incoming.isForce) {
      mutableQueue.insert(0, incoming);
    } else {
      mutableQueue.add(incoming);
    }

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

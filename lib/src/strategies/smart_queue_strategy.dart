import 'package:fluent_bar/src/internal.dart';

/// Shows waiting bars by priority, then in the order they were requested. The default.
///
/// ```dart
/// FluentBar.patchConfig((config) => config.copyWith(defaultQueueStrategy: const SmartQueueStrategy()));
/// ```
class SmartQueueStrategy implements FluentBarQueueStrategy {
  /// Creates the strategy.
  const SmartQueueStrategy();

  static int _weight(FluentBarEntry<dynamic> entry, FluentBarConfig config) => entry.resolvePriority(config).weight + (entry.isForce ? 1000 : 0);

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) {
    final List<FluentBarEntry<dynamic>> mutableQueue = <FluentBarEntry<dynamic>>[...queue, incoming];

    mutableQueue.sort((FluentBarEntry<dynamic> a, FluentBarEntry<dynamic> b) {
      final int byWeight = _weight(b, config).compareTo(_weight(a, config));
      if (byWeight != 0) return byWeight;
      return a.sequence.compareTo(b.sequence);
    });

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

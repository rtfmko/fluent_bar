import 'dart:math';

import 'package:fluent_bar/fluent_bar.dart';

// A custom queue strategy: onEnqueue places a new bar, onDequeue picks the next one to show.
class RandomQueueStrategy extends FluentBarQueueStrategy {
  const RandomQueueStrategy();

  @override
  QueueOperationResult onEnqueue({required List<FluentBarEntry<dynamic>> queue, required FluentBarEntry<dynamic> incoming, required FluentBarConfig config}) {
    final updatedQueue = List<FluentBarEntry<dynamic>>.from(queue);

    bool shouldForce = false;
    if (updatedQueue.length >= config.maxQueueLength) {
      if (incoming.isForce) {
        shouldForce = true;
      } else {
        return QueueOperationResult(queue: updatedQueue, shouldForce: false);
      }
    }

    updatedQueue.add(incoming);
    return QueueOperationResult(queue: updatedQueue, shouldForce: shouldForce);
  }

  @override
  (FluentBarEntry<dynamic>?, List<FluentBarEntry<dynamic>>) onDequeue({required List<FluentBarEntry<dynamic>> queue, required FluentBarConfig config}) {
    if (queue.isEmpty) {
      return (null, queue);
    }

    final updatedQueue = List<FluentBarEntry<dynamic>>.from(queue);

    final randomIndex = Random().nextInt(updatedQueue.length);
    final chosenEntry = updatedQueue.removeAt(randomIndex);

    return (chosenEntry, updatedQueue);
  }
}

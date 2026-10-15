import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const FluentBarConfig config = FluentBarConfig();

  FluentBarEntry<void> entry(String message, {FluentBarPriority? priority, bool isForce = false, FluentBarType type = FluentBarType.info}) => FluentBarEntry<void>(
    item: FluentBarItem<void>(
      type: type,
      message: message,
      behavior: FluentBarBehavior(priority: priority, isForce: isForce),
    ),
  );

  List<String> messages(List<FluentBarEntry<dynamic>> queue) => queue.map((FluentBarEntry<dynamic> e) => e.currentItem.message).toList();

  List<FluentBarEntry<dynamic>> enqueueAll(FluentBarQueueStrategy strategy, List<FluentBarEntry<void>> entries) {
    List<FluentBarEntry<dynamic>> queue = <FluentBarEntry<dynamic>>[];
    for (final FluentBarEntry<void> e in entries) {
      queue = strategy.onEnqueue(queue: queue, incoming: e, config: config).queue;
    }
    return queue;
  }

  List<String> drain(FluentBarQueueStrategy strategy, List<FluentBarEntry<dynamic>> queue) {
    final List<String> order = <String>[];
    List<FluentBarEntry<dynamic>> rest = queue;
    while (true) {
      final (FluentBarEntry<dynamic>? next, List<FluentBarEntry<dynamic>> remaining) = strategy.onDequeue(queue: rest, config: config);
      if (next == null) break;
      order.add(next.currentItem.message);
      rest = remaining;
    }
    return order;
  }

  for (final (String name, FluentBarQueueStrategy strategy) in <(String, FluentBarQueueStrategy)>[
    ('FifoQueueStrategy', const FifoQueueStrategy()),
    ('LifoQueueStrategy', const LifoQueueStrategy()),
    ('SmartQueueStrategy', const SmartQueueStrategy()),
  ]) {
    group('$name contract', () {
      test('dequeue from an empty queue returns null and an empty queue', () {
        final (FluentBarEntry<dynamic>? next, List<FluentBarEntry<dynamic>> remaining) = strategy.onDequeue(queue: <FluentBarEntry<dynamic>>[], config: config);
        expect(next, isNull);
        expect(remaining, isEmpty);
      });

      test('does not mutate the queue passed in', () {
        final FluentBarEntry<void> a = entry('A');
        final List<FluentBarEntry<dynamic>> source = <FluentBarEntry<dynamic>>[a];

        strategy.onEnqueue(queue: source, incoming: entry('B'), config: config);
        expect(source, <FluentBarEntry<dynamic>>[a]);

        strategy.onDequeue(queue: source, config: config);
        expect(source, <FluentBarEntry<dynamic>>[a]);
      });

      test('keeps every element: nothing is lost or duplicated', () {
        final List<FluentBarEntry<void>> entries = <FluentBarEntry<void>>[entry('A'), entry('B', priority: FluentBarPriority.high), entry('C', isForce: true)];
        final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, entries);

        expect(queue, unorderedEquals(entries));
        expect(drain(strategy, queue), unorderedEquals(<String>['A', 'B', 'C']));
      });

      test('a forced element goes first and requests a forced show', () {
        final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[entry('A'), entry('B', priority: FluentBarPriority.critical)]);

        final QueueOperationResult plain = strategy.onEnqueue(queue: queue, incoming: entry('Plain'), config: config);
        expect(plain.shouldForce, isFalse);

        final QueueOperationResult forced = strategy.onEnqueue(queue: queue, incoming: entry('Forced', isForce: true), config: config);
        expect(forced.shouldForce, isTrue);
        expect(forced.queue.first.currentItem.message, 'Forced');
      });
    });
  }

  test('strategies can be created at runtime, not only as constants', () {
    // ignore: prefer_const_constructors
    final List<FluentBarQueueStrategy> strategies = <FluentBarQueueStrategy>[FifoQueueStrategy(), LifoQueueStrategy(), SmartQueueStrategy()];

    for (final FluentBarQueueStrategy strategy in strategies) {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[entry('A')]);
      expect(messages(queue), <String>['A']);
    }
  });

  group('FifoQueueStrategy', () {
    const FifoQueueStrategy strategy = FifoQueueStrategy();

    test('shows elements in the order they were added, ignoring priority', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[
        entry('First', priority: FluentBarPriority.low),
        entry('Second', priority: FluentBarPriority.critical),
        entry('Third'),
      ]);

      expect(messages(queue), <String>['First', 'Second', 'Third']);
      expect(drain(strategy, queue), <String>['First', 'Second', 'Third']);
    });
  });

  group('LifoQueueStrategy', () {
    const LifoQueueStrategy strategy = LifoQueueStrategy();

    test('shows the most recently added element first, ignoring priority', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[
        entry('First', priority: FluentBarPriority.critical),
        entry('Second', priority: FluentBarPriority.low),
        entry('Third'),
      ]);

      expect(messages(queue), <String>['Third', 'Second', 'First']);
      expect(drain(strategy, queue), <String>['Third', 'Second', 'First']);
    });
  });

  group('SmartQueueStrategy', () {
    const SmartQueueStrategy strategy = SmartQueueStrategy();

    test('orders by priority, highest first', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[
        entry('Low', priority: FluentBarPriority.low),
        entry('Critical', priority: FluentBarPriority.critical),
        entry('Normal', priority: FluentBarPriority.normal),
        entry('High', priority: FluentBarPriority.high),
      ]);

      expect(drain(strategy, queue), <String>['Critical', 'High', 'Normal', 'Low']);
    });

    test('keeps insertion order inside one priority', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[entry('A'), entry('High', priority: FluentBarPriority.high), entry('B'), entry('C')]);

      expect(messages(queue), <String>['High', 'A', 'B', 'C']);
    });

    test('uses the priority of the type when the item does not set one', () {
      expect(FluentBarType.error.priority.weight, greaterThan(FluentBarType.info.priority.weight));

      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[entry('Info'), entry('Error', type: FluentBarType.error)]);

      expect(messages(queue), <String>['Error', 'Info']);
    });

    test('a local priority beats the priority of the type', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[entry('Error but low', type: FluentBarType.error, priority: FluentBarPriority.low), entry('Info')]);

      expect(messages(queue), <String>['Info', 'Error but low']);
    });

    test('a forced element outranks even critical priority; forced ones keep their order', () {
      final List<FluentBarEntry<dynamic>> queue = enqueueAll(strategy, <FluentBarEntry<void>>[
        entry('Critical', priority: FluentBarPriority.critical),
        entry('Forced 1', isForce: true, priority: FluentBarPriority.low),
        entry('Forced 2', isForce: true, priority: FluentBarPriority.low),
      ]);

      expect(messages(queue), <String>['Forced 1', 'Forced 2', 'Critical']);
    });
  });
}

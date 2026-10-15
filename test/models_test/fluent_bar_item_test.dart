import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FluentBarItem<String> itemOf({String? id, String message = 'Message', FluentBarCallbacks<String>? callbacks}) => FluentBarItem<String>(
    id: id,
    type: FluentBarType.info,
    title: 'Title',
    message: message,
    duration: const Duration(seconds: 5),
    payload: 'payload',
    meta: const <String, dynamic>{'k': 1},
    callbacks: callbacks,
  );

  group('FluentBarItem', () {
    test('gets default behavior and appearance, and a unique uuid', () {
      final FluentBarItem<void> a = FluentBarItem<void>(type: FluentBarType.info, message: 'A');
      final FluentBarItem<void> b = FluentBarItem<void>(type: FluentBarType.info, message: 'A');

      expect(a.uuid, isNotEmpty);
      expect(a.uuid, isNot(b.uuid));
      expect(a.behavior, const FluentBarBehavior());
      expect(a.appearance, const FluentBarAppearance<void>());
      expect(a.id, isNull);
      expect(a.duration, isNull);
      expect(a.isPersistent, isNull);
      expect(a.progressState, isNull);
      expect(a.actions, isNull);
      expect(a.callbacks, isNull);
    });

    test('copyWith changes only what was passed and keeps the uuid', () {
      final FluentBarItem<String> item = itemOf(id: 'a');
      final FluentBarItem<String> modified = item.copyWith(message: 'Updated', duration: const Duration(seconds: 8));

      expect(modified.uuid, item.uuid);
      expect(modified.id, 'a');
      expect(modified.message, 'Updated');
      expect(modified.duration, const Duration(seconds: 8));
      expect(modified.title, 'Title');
      expect(modified.payload, 'payload');
      expect(modified.copyWith(uuid: 'other').uuid, 'other');
    });

    test('copyWith can clear nullable fields explicitly', () {
      final FluentBarItem<String> item = itemOf().copyWith(
        progressState: const FluentBarProgressValue(0.5),
        actions: const FluentBarActions<String>(label: 'Undo'),
      );

      final FluentBarItem<String> cleared = item.copyWith(clearTitle: true, clearDuration: true, clearPayload: true, clearMeta: true, clearProgressState: true, clearActions: true);

      expect(cleared.title, isNull);
      expect(cleared.duration, isNull);
      expect(cleared.payload, isNull);
      expect(cleared.meta, isNull);
      expect(cleared.progressState, isNull);
      expect(cleared.actions, isNull);

      expect(item.copyWith().progressState, const FluentBarProgressValue(0.5));
      expect(item.copyWith().actions?.label, 'Undo');
    });

    test('equality compares content, not identity or uuid', () {
      final FluentBarItem<String> a = itemOf(id: 'a');
      final FluentBarItem<String> b = itemOf(id: 'a');

      expect(a.uuid, isNot(b.uuid));
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a == itemOf(id: 'a', message: 'Other'), isFalse);
      expect(a == itemOf(id: 'b'), isFalse);
      expect(a == a.copyWith(meta: const <String, dynamic>{'k': 2}), isFalse);
    });

    test('items with different payload types are not equal', () {
      final FluentBarItem<String> typed = FluentBarItem<String>(type: FluentBarType.info, message: 'A');
      final FluentBarItem<int> other = FluentBarItem<int>(type: FluentBarType.info, message: 'A');

      // ignore: unrelated_type_equality_checks
      expect(typed == other, isFalse);
    });

    test('toString describes the item', () {
      final String description = itemOf(id: 'a').toString();

      expect(description, contains('FluentBarItem<String>'));
      expect(description, contains('id: a'));
      expect(description, contains('type: info'));
      expect(description, contains('message: Message'));
    });

    test('lifecycle callbacks are called through the item with the typed item', () {
      final List<String> calls = <String>[];
      final FluentBarItem<String> item = itemOf(
        callbacks: FluentBarCallbacks<String>(
          onShow: (FluentBarItem<String> i) => calls.add('show ${i.payload}'),
          onDismiss: (FluentBarItem<String> i, FluentBarMetrics m) => calls.add('dismiss ${m.dismissReason.name}'),
          onProgressCompleted: (FluentBarItem<String> i) => calls.add('completed'),
          onProgressCanceled: (FluentBarItem<String> i) => calls.add('canceled'),
        ),
      );

      final FluentBarItem<dynamic> erased = item;
      erased.notifyShown();
      erased.notifyDismissed(const FluentBarMetrics(id: null, visibleDuration: Duration.zero, plannedDuration: null, dismissReason: FluentBarDismissReason.swipe, timedOut: false));
      erased.notifyProgressCompleted();
      erased.notifyProgressCanceled();

      expect(calls, <String>['show payload', 'dismiss swipe', 'completed', 'canceled']);

      itemOf()
        ..notifyShown()
        ..notifyProgressCompleted()
        ..notifyProgressCanceled();
    });
  });

  group('FluentBarEntry', () {
    test('item always reflects the current content of the bar', () {
      final FluentBarEntry<String> entry = FluentBarEntry<String>(item: itemOf());
      addTearDown(entry.internalController.dispose);

      entry.controller.updateContent(message: 'Changed');

      expect(entry.item.message, 'Changed');
      expect(entry.item, same(entry.controller.itemNotifier.value));
    });

    test('every entry gets the next sequence number; an explicit one is kept', () {
      final FluentBarEntry<String> first = FluentBarEntry<String>(item: itemOf());
      final FluentBarEntry<String> second = FluentBarEntry<String>(item: itemOf());
      addTearDown(first.internalController.dispose);
      addTearDown(second.internalController.dispose);

      expect(second.sequence, greaterThan(first.sequence));

      expect(FluentBarEntry<String>(item: itemOf(), controller: first.controller, sequence: 7).sequence, 7);
    });
  });

  group('FluentBarAnalyticsPayload', () {
    test('toString is readable', () {
      final FluentBarAnalyticsPayload payload = FluentBarAnalyticsPayload(
        event: FluentBarAnalyticsEvent.shown,
        item: itemOf(id: 'a'),
      );

      expect(payload.toString(), contains('FluentBarAnalyticsEvent.shown'));
      expect(payload.toString(), contains('id: a'));
    });
  });

  group('FluentBarUpdateRate', () {
    test('rates with the same interval are equal', () {
      expect(FluentBarUpdateRate.ms(50), equals(FluentBarUpdateRate.medium));
      expect(FluentBarUpdateRate.ms(50).hashCode, FluentBarUpdateRate.medium.hashCode);
      expect(FluentBarUpdateRate.ms(51) == FluentBarUpdateRate.medium, isFalse);
      expect(const FluentBarBehavior(timeoutUpdateInterval: FluentBarUpdateRate.medium), equals(FluentBarBehavior(timeoutUpdateInterval: FluentBarUpdateRate.ms(50))));
      expect(FluentBarUpdateRate.medium.toString(), 'FluentBarUpdateRate(50ms)');
    });
  });
}

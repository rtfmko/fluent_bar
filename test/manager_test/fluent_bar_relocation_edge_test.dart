import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;
  final List<FluentBarException> errors = <FluentBarException>[];
  void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);

  setUp(() {
    FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
    errors.clear();
    FluentBar.addErrorHandler(onError);
  });

  tearDown(() {
    FluentBar.removeErrorHandler(onError);
    FluentBarControllerImpl.stopwatchFactory = Stopwatch.new;
  });

  Future<void> boot(WidgetTester tester, {FluentBarConfig config = const FluentBarConfig()}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: config),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    errors.clear();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  FluentBarItem<void> bar(String message, {String? id, bool bottom = false}) {
    final FluentBarItem<void> item = FluentBar.info<void>(message).withId(id ?? message).persistent();
    return bottom ? item.atBottom() : item.atTop();
  }

  bool isAtBottom(WidgetTester tester, String message) => tester.getCenter(find.text(message)).dy > 300;

  group('showing the same id with another position', () {
    testWidgets('moves the shown bar instead of creating a second one', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> entry = bar('Note', id: 'note').show()!;
      await settle(tester);

      final FluentBarEntry<void>? again = bar('Note moved', id: 'note', bottom: true).show();
      await settle(tester);

      expect(again, same(entry));
      expect(FluentBar.activeItems, hasLength(1));
      expect(FluentBar.bottomActiveItem, same(entry));
      expect(FluentBar.mainActiveItem, isNull);
      expect(FluentBar.allQueueLength, 0);
      expect(isAtBottom(tester, 'Note moved'), isTrue);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a queued bar goes straight to the screen when its new region is free', (WidgetTester tester) async {
      await boot(tester);
      bar('Active').show();
      final FluentBarEntry<void> queued = bar('Queued', id: 'q').show()!;
      await settle(tester);
      expect(FluentBar.mainQueueLength, 1);

      final FluentBarEntry<void>? again = bar('Queued', id: 'q', bottom: true).withPriority(FluentBarPriority.critical).show();
      await settle(tester);

      expect(again, same(queued));
      expect(FluentBar.allQueueLength, 0);
      expect(FluentBar.bottomActiveItem, same(queued));
      expect(find.text('Queued'), findsOneWidget);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a queued bar moves to the queue of its new region when that region is busy', (WidgetTester tester) async {
      await boot(tester);
      bar('Top').show();
      bar('Bottom', bottom: true).show();
      final FluentBarEntry<void> queued = bar('Queued', id: 'q').show()!;
      await settle(tester);

      expect(bar('Queued', id: 'q', bottom: true).show(), same(queued));

      expect(FluentBar.mainQueueLength, 0);
      expect(FluentBar.bottomQueue.single, same(queued));
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });

  testWidgets('an update that arrives while the bar is on its way to another region reaches the same bar', (WidgetTester tester) async {
    await boot(tester);
    final FluentBarEntry<void> upload = FluentBar.info<void>('Uploading').withId('upload').withLinearProgress(value: 0.1).show()!;
    bar('Snack', bottom: true).show();
    await settle(tester);

    upload.controller.updateBehavior(behavior: upload.currentItem.behavior.copyWith(position: FluentBarPosition.bottom));
    await tester.pump();

    final FluentBarEntry<void>? again = FluentBar.info<void>('Uploading').withId('upload').withLinearProgress(value: 0.6).show();
    await settle(tester);

    expect(again, same(upload));
    expect(upload.controller.progressStateNotifier.value?.progress, 0.6);
    expect(FluentBar.bottomQueue.single, same(upload));
    expect(FluentBar.mainQueueLength, 0);
    expect(FluentBar.mainActiveItem, isNull);
    expect(errors, isEmpty);

    await cleanup(tester);
  });

  group('config change with a bar on screen', () {
    testWidgets('switching to two queues gives a bottom bar its own slot', (WidgetTester tester) async {
      await boot(tester, config: const FluentBarConfig(enableMultiRegion: false));
      final FluentBarEntry<void> low = bar('Low', bottom: true).show()!;
      await settle(tester);
      expect(FluentBar.mainActiveItem, same(low));

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(enableMultiRegion: true));
      await settle(tester);
      expect(FluentBar.bottomActiveItem, same(low));
      expect(FluentBar.mainActiveItem, isNull);

      final FluentBarEntry<void> second = bar('Second', bottom: true).show()!;
      await settle(tester);
      expect(FluentBar.bottomQueue.single, same(second));
      expect(find.text('Second'), findsNothing);
      expect(errors, isEmpty);

      await cleanup(tester);
    });

    testWidgets('a bar stays in its slot when the new one is taken', (WidgetTester tester) async {
      await boot(tester);
      final FluentBarEntry<void> top = FluentBar.info<void>('Default').withId('d').persistent().show()!;
      final FluentBarEntry<void> low = bar('Low', bottom: true).show()!;
      await settle(tester);

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith(defaultPosition: FluentBarPosition.bottom));
      await settle(tester);

      expect(FluentBar.mainActiveItem, same(top));
      expect(FluentBar.bottomActiveItem, same(low));
      expect(errors, isEmpty);

      await cleanup(tester);
    });
  });
}

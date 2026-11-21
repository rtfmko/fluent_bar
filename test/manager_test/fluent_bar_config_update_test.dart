import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  FluentBarConfig configWith(int maxQueueLength) => FluentBarConfig(defaultTransitionDuration: Duration.zero, maxQueueLength: maxQueueLength);

  Widget app(FluentBarConfig config) => MaterialApp(
    builder: FluentBarScope.builder(config: config),
    home: const Scaffold(body: SizedBox()),
  );

  Future<int Function()> showCountingBar(WidgetTester tester, FluentBarConfig config) async {
    manager.resetForTesting();
    await tester.pumpWidget(app(config));
    await tester.pump();
    int builds = 0;
    FluentBar.info<void>('same', id: 'x').persistent().withContent((BuildContext context, FluentBarEntry<void> e) {
      builds++;
      return Text(e.item.message);
    }).show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    return () => builds;
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  group('an equal config changes nothing', () {
    testWidgets('updateConfig with an equal config rebuilds nothing', (WidgetTester tester) async {
      final int Function() builds = await showCountingBar(tester, configWith(7));
      final int before = builds();

      FluentBar.updateConfig(FluentBar.currentConfig.copyWith());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(builds(), before);
      await cleanup(tester);
    });

    testWidgets('patchConfig returning an equal config rebuilds nothing', (WidgetTester tester) async {
      final int Function() builds = await showCountingBar(tester, configWith(7));
      final int before = builds();

      FluentBar.patchConfig((FluentBarConfig c) => c.copyWith());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(builds(), before);
      await cleanup(tester);
    });

    testWidgets('a scope rebuilt with an equal config does what a rebuild with the same instance does', (WidgetTester tester) async {
      final FluentBarConfig config = configWith(7);
      final int Function() builds = await showCountingBar(tester, config);

      Future<int> rebuildWith(FluentBarConfig next) async {
        final int before = builds();
        await tester.pumpWidget(app(next));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        return builds() - before;
      }

      final int withSameInstance = await rebuildWith(config);
      final int withEqualConfig = await rebuildWith(configWith(7));

      expect(withEqualConfig, withSameInstance);
      await cleanup(tester);
    });

    testWidgets('a scope rebuilt with another config applies it', (WidgetTester tester) async {
      await showCountingBar(tester, configWith(7));

      await tester.pumpWidget(app(configWith(4)));
      await tester.pump();

      expect(manager.config.maxQueueLength, 4);
      await cleanup(tester);
    });
  });

  test('resetForTesting disposes the combined queue length notifier and a new one is created on access', () {
    manager.resetForTesting();
    final ValueListenable<int> before = FluentBar.allQueueLengthNotifier;

    manager.resetForTesting();

    expect(() => before.addListener(() {}), throwsFlutterError);
    final ValueListenable<int> after = FluentBar.allQueueLengthNotifier;
    expect(after, isNot(same(before)));
    int calls = 0;
    void listener() => calls++;
    after.addListener(listener);
    after.removeListener(listener);
    expect(after.value, 0);
    expect(calls, 0);
  });
}

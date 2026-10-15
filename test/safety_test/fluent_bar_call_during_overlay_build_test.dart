import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<void> boot(WidgetTester tester, {Duration transition = Duration.zero}) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: FluentBarConfig(enableMultiRegion: true, defaultTransitionDuration: transition)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  final Map<String, void Function()> calls = <String, void Function()>{
    'close another bar': () => FluentBar.close('other'),
    'closeAll': FluentBar.closeAll,
    'closeActive': FluentBar.closeActive,
    'dismissAndClear': FluentBar.dismissAndClear,
  };

  for (final Duration transition in <Duration>[Duration.zero, const Duration(milliseconds: 300)]) {
    for (final MapEntry<String, void Function()> call in calls.entries) {
      testWidgets('${call.key} from a content builder does not break the frame (transition ${transition.inMilliseconds} ms)', (WidgetTester tester) async {
        await boot(tester, transition: transition);
        bool isCalled = false;
        FluentBar.info<void>('Caller').withId('caller').persistent().atBottom().withContent((BuildContext context, FluentBarEntry<void> entry) {
          if (!isCalled) {
            isCalled = true;
            call.value();
          }
          return const Text('Caller');
        }).show();
        FluentBar.info<void>('Other').withId('other').persistent().atTop().show();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(isCalled, isTrue);
        expect(find.text('Other'), findsNothing);
        await cleanup(tester);
      });
    }
  }
}

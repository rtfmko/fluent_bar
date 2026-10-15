import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  final VoidCallback? onInit;
  final VoidCallback? onDispose;

  const _Probe({this.onInit, this.onDispose});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit?.call();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

class _Watch<T> extends StatelessWidget {
  final ValueListenable<T> listenable;

  const _Watch(this.listenable);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<T>(valueListenable: listenable, builder: (BuildContext context, T value, _) => Text('$value', maxLines: 1));
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  late FluentBarEntry<void> visible;
  late FluentBarEntry<void> queued;

  Widget app({required bool withProbe, VoidCallback? onInit, VoidCallback? onDispose}) => MaterialApp(
    builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _Watch<FluentBarConfig>(FluentBar.configNotifier),
            _Watch<int>(FluentBar.allQueueLengthNotifier),
            _Watch<int>(FluentBar.mainQueueLengthNotifier),
            _Watch<int>(FluentBar.bottomQueueLengthNotifier),
            _Watch<double>(FluentBar.measuredTopInset),
            _Watch<double>(FluentBar.measuredBottomInset),
            if (FluentBar.find('visible') case final FluentBarEntry<dynamic> entry) ...<Widget>[
              _Watch<FluentBarLifecycleState>(entry.controller.stateNotifier),
              _Watch<Duration>(entry.controller.remainingDurationNotifier),
              _Watch<Duration>(entry.controller.elapsedDurationNotifier),
              _Watch<Duration?>(entry.controller.totalDurationNotifier),
              _Watch<double>(entry.controller.remainingProgressNotifier),
              _Watch<double>(entry.controller.elapsedProgressNotifier),
              _Watch<FluentBarProgressState?>(entry.controller.progressStateNotifier),
              _Watch<double?>(entry.controller.taskProgressNotifier),
              _Watch<bool>(entry.controller.isActionExecutingNotifier),
              _Watch<Object>(entry.controller.itemNotifier),
            ],
            if (FluentBar.find('queued') case final FluentBarEntry<dynamic> entry) _Watch<FluentBarLifecycleState>(entry.controller.stateNotifier),
            if (withProbe) _Probe(onInit: onInit, onDispose: onDispose),
          ],
        ),
      ),
    ),
  );

  Future<void> boot(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(withProbe: false));
    await tester.pump();

    visible = FluentBar.info<void>('Visible').withId('visible').withDuration(const Duration(seconds: 30)).withTimeoutBar().withLinearProgress(value: 0.2, showText: true).withAction('Undo').show()!;
    queued = FluentBar.info<void>('Queued').withId('queued').persistent().show()!;
    FluentBar.info<void>('Bottom').withId('bottom').persistent().atBottom().show();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> cleanup(WidgetTester tester) async {
    manager.resetForTesting();
    await tester.pump();
  }

  final Map<String, VoidCallback> actions = <String, VoidCallback>{
    'patchConfig': () => FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(defaultPosition: FluentBarPosition.bottom, maxQueueLength: 3)),
    'updateConfig': () => FluentBar.updateConfig(const FluentBarConfig(defaultShowTimeoutBar: true)),
    'patchConfig with a builder': () =>
        FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(defaultTransitionBuilder: (BuildContext context, Animation<double> animation, Widget child) => child)),
    'show': () => FluentBar.showInfo<void>('From a lifecycle method'),
    'show with the same id': () => FluentBar.info<void>('Changed').withId('visible').persistent().show(),
    'close by id': () => FluentBar.close('visible'),
    'close a queued bar': () => FluentBar.close('queued'),
    'entry.close': () => visible.close(),
    'closeActive': FluentBar.closeActive,
    'closeAll': FluentBar.closeAll,
    'clearQueue': FluentBar.clearQueue,
    'dismissAndClear': FluentBar.dismissAndClear,
    'update': () => visible.update(title: 'New title', message: 'New message'),
    'updateContent with a type': () => visible.controller.updateContent(type: FluentBarType.error),
    'updateValue': () => visible.updateValue(0.7),
    'completeProgress': () => visible.completeProgress(message: 'Done'),
    'failProgress': () => visible.failProgress(),
    'cancelProgress': () => visible.cancelProgress(),
    'updateBytes': () => visible.updateBytes(1024, 4096),
    'pause': () => visible.pause(),
    'pause and resume': () {
      visible.pause();
      visible.resume();
    },
    'addDuration': () => visible.controller.addDuration(const Duration(seconds: 5)),
    'updateDuration': () => visible.controller.updateDuration(const Duration(seconds: 2), resetTimer: true),
    'makePersistent': () => visible.makePersistent(),
    'removeAction': () => visible.removeAction(),
    'setLoading': () => visible.controller.setLoading(isLoading: true),
    'patchAppearance': () => visible.patchAppearance((FluentBarAppearance<void> appearance) => appearance.copyWith(backgroundColor: Colors.teal)),
    'relocate': () => visible.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom)),
    'relocate and replace': () =>
        visible.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: FluentBarPosition.bottom, relocationStrategy: FluentBarRelocationStrategy.forceReplace)),
    'shake': () => visible.shake(),
    'force a queued bar': () => FluentBar.forceItemFromQueue(id: 'queued'),
    'forceItem': () => FluentBar.forceItem<void>(FluentBar.error<void>('Forced')),
    'updateItemPriority': () => FluentBar.updateItemPriority(id: 'queued', newPriority: FluentBarPriority.critical),
    'queued.update': () => queued.update(message: 'Changed while waiting'),
  };

  testWidgets('a change made in dispose() changes the value at once and reaches listeners after the frame', (WidgetTester tester) async {
    await boot(tester);
    int notifications = 0;
    void onConfig() => notifications++;
    FluentBar.configNotifier.addListener(onConfig);
    addTearDown(() => FluentBar.configNotifier.removeListener(onConfig));

    int? seenInDispose;
    await tester.pumpWidget(
      app(
        withProbe: true,
        onDispose: () {
          FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(maxQueueLength: 7));
          seenInDispose = FluentBar.currentConfig.maxQueueLength;
          expect(notifications, 0, reason: 'listeners are not called while the tree is locked');
        },
      ),
    );
    await tester.pump();
    await tester.pumpWidget(app(withProbe: false));

    expect(seenInDispose, 7, reason: 'the value itself changes immediately');
    expect(notifications, 1, reason: 'and listeners hear about it right after the frame');
    expect(find.textContaining('maxQueueLength: 7'), findsNothing);

    await cleanup(tester);
  });

  testWidgets('the last state of a bar closed in dispose() still reaches its listeners', (WidgetTester tester) async {
    await boot(tester);
    final List<FluentBarLifecycleState> states = <FluentBarLifecycleState>[];
    queued.controller.stateNotifier.addListener(() => states.add(queued.controller.stateNotifier.value));

    await tester.pumpWidget(app(withProbe: true, onDispose: () => FluentBar.close('queued')));
    await tester.pump();
    await tester.pumpWidget(app(withProbe: false));
    await tester.pump();

    expect(states, <FluentBarLifecycleState>[FluentBarLifecycleState.dismissed]);
    expect(tester.takeException(), isNull);

    await cleanup(tester);
  });

  test('outside a frame notifications are synchronous, as before', () {
    final FrameSafeValueNotifier<int> notifier = FrameSafeValueNotifier<int>(0);
    int calls = 0;
    notifier.addListener(() => calls++);

    notifier.value = 1;
    expect(calls, 1);

    notifier.dispose();
    notifier.dispose();
  });

  for (final MapEntry<String, VoidCallback> action in actions.entries) {
    testWidgets('${action.key} from dispose() does not touch a locked widget tree', (WidgetTester tester) async {
      await boot(tester);
      await tester.pumpWidget(app(withProbe: true, onDispose: action.value));
      await tester.pump();

      await tester.pumpWidget(app(withProbe: false));
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });

    testWidgets('${action.key} from initState() does not mark widgets dirty during build', (WidgetTester tester) async {
      await boot(tester);

      await tester.pumpWidget(app(withProbe: true, onInit: action.value));
      expect(tester.takeException(), isNull);

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      await cleanup(tester);
    });
  }
}

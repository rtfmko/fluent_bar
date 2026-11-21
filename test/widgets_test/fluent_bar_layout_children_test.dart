import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Probe extends StatefulWidget {
  const _Probe(this.onInit);

  final VoidCallback onInit;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Text('probe');
}

void main() {
  final FluentBarManager manager = FluentBarManager.instance;

  Future<FluentBarEntry<void>> show(WidgetTester tester, FluentBarItem<void> item, {Size size = const Size(400, 300)}) async {
    manager.resetForTesting();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        builder: FluentBarScope.builder(config: const FluentBarConfig(defaultTransitionDuration: Duration.zero)),
        home: const Scaffold(body: SizedBox()),
      ),
    );
    await tester.pump();
    final FluentBarEntry<void> entry = item.persistent().show()!;
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return entry;
  }

  tearDown(manager.resetForTesting);

  testWidgets('a custom progress builder and a custom action get the bounded height of the bar', (WidgetTester tester) async {
    final List<double> heights = <double>[];
    Widget measure(BuildContext context, BoxConstraints constraints) {
      heights.add(constraints.maxHeight);
      return const SizedBox(width: 20, height: 20);
    }

    final FluentBarItem<void> base = FluentBar.info<void>('Message');
    final FluentBarItem<void> item = base.copyWith(
      progressState: const FluentBarProgressState.value(0.4),
      appearance: base.appearance.copyWith(
        progressTheme: FluentBarProgressTheme(
          position: FluentBarProgressPosition.left,
          progressBuilder: (BuildContext context, ValueListenable<FluentBarProgressState?> notifier) => LayoutBuilder(builder: measure),
        ),
      ),
      actions: FluentBarActions<void>(builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode mode) => LayoutBuilder(builder: measure)),
    );
    await show(tester, item);

    expect(tester.takeException(), isNull);
    expect(heights, hasLength(greaterThanOrEqualTo(2)));
    expect(heights.every((double h) => h.isFinite), isTrue, reason: '$heights');
  });

  testWidgets('a custom action that uses Expanded in a column does not break the bar', (WidgetTester tester) async {
    final FluentBarItem<void> base = FluentBar.info<void>('Message');
    await show(
      tester,
      base.copyWith(
        actions: FluentBarActions<void>(
          builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode mode) => const SizedBox(
            width: 60,
            child: Column(children: <Widget>[Expanded(child: Text('Go'))]),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Go'), findsOneWidget);
  });

  testWidgets('an action keeps its state when the bar switches between the action beside the text and under it', (WidgetTester tester) async {
    int inits = 0;
    final FluentBarItem<void> base = FluentBar.info<void>('Message', title: 'Title');
    final FluentBarEntry<void> entry = await show(
      tester,
      base
          .copyWith(
            actions: FluentBarActions<void>(child: _Probe(() => inits++), label: 'x'),
          )
          .withCloseButton(),
      size: const Size(230, 300),
    );
    final double withClose = tester.getRect(find.text('probe')).top;

    entry.controller.updateAppearance(entry.item.appearance.copyWith(showCloseButton: false));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final double withoutClose = tester.getRect(find.text('probe')).top;

    expect(withClose, isNot(withoutClose), reason: 'the layout switched');
    expect(inits, 1);
  });

  testWidgets('the default icon of the theme is not built while a custom icon works', (WidgetTester tester) async {
    int calls = 0;
    final FluentBarTheme theme = FluentBarTheme.material.copyWith(
      defaultIcon: (BuildContext c, FluentBarType t, FluentBarThemeMode? m, double? size) {
        calls++;
        return const Icon(Icons.info);
      },
    );
    final FluentBarItem<void> base = FluentBar.info<void>('Message');
    await show(
      tester,
      base.copyWith(
        appearance: base.appearance.copyWith(theme: theme, icon: const Icon(Icons.star)),
      ),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(calls, 0);
  });
}

import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarWrapper Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should render default transition and content correctly', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Wrapper Test Message');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Wrapper Test Message'), findsOneWidget);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('should support custom transitionBuilder in appearance', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Transition Message',
        appearance: FluentBarAppearance<dynamic>(
          transitionBuilder: (BuildContext context, Animation<double> animation, Widget child) => ScaleTransition(key: const Key('custom_scale_transition'), scale: animation, child: child),
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Custom Transition Message'), findsOneWidget);
      expect(find.byKey(const Key('custom_scale_transition')), findsOneWidget);
    });

    testWidgets('should render custom builder inside appearance when provided', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Ignored Default Message',
        appearance: FluentBarAppearance<dynamic>(
          builder: (BuildContext context, FluentBarEntry<dynamic> entry) => Container(key: const Key('custom_appearance_widget'), child: Text('Custom Content: ${entry.item.message}')),
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_appearance_widget')), findsOneWidget);
      expect(find.text('Custom Content: Ignored Default Message'), findsOneWidget);
    });
  });

  group('FluentBarWrapper Alignment & Default Transitions Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();
    final Map<FluentBarPosition, Alignment> positions = <FluentBarPosition, Alignment>{
      FluentBarPosition.top: Alignment.topCenter,
      FluentBarPosition.bottom: Alignment.bottomCenter,
      FluentBarPosition.left: Alignment.centerLeft,
      FluentBarPosition.right: Alignment.centerRight,
      FluentBarPosition.center: Alignment.center,
    };

    positions.forEach((FluentBarPosition barPosition, Alignment expectedAlignment) {
      testWidgets('should apply correct alignment for ${barPosition.name}', (WidgetTester tester) async {
        final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
          type: FluentBarType.info,
          message: 'Position ${barPosition.name}',
          behavior: FluentBarBehavior(position: barPosition, useSafeArea: false),
        );
        final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
              ),
            ),
          ),
        );

        expect(find.text('Position ${barPosition.name}'), findsOneWidget);

        final Align alignWidget = tester.widget<Align>(find.byType(Align).first);
        expect(alignWidget.alignment, expectedAlignment);
      });
    });

    testWidgets('should execute defaultTransitionBuilder successfully for all positions', (WidgetTester tester) async {
      for (final FluentBarPosition barPosition in FluentBarPosition.values) {
        final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
          type: FluentBarType.info,
          message: 'Transition ${barPosition.name}',
          behavior: FluentBarBehavior(position: barPosition),
        );
        final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
              ),
            ),
          ),
        );

        expect(find.text('Transition ${barPosition.name}'), findsOneWidget);
        expect(find.byType(SlideTransition), findsWidgets);
        expect(find.byType(FadeTransition), findsWidgets);

        await tester.pumpWidget(const SizedBox());
      }
    });
  });

  group('FluentBarWrapper Error Fallbacks Widget Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should fallback to default transition when custom transitionBuilder throws', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Fallback Transition Message',
        appearance: FluentBarAppearance<dynamic>(transitionBuilder: (BuildContext context, Animation<double> animation, Widget child) => throw Exception('Custom transition builder crash')),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Fallback Transition Message'), findsOneWidget);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('should fallback to DefaultFluentBarWidget when custom appearance builder throws', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Fallback Content Message',
        appearance: FluentBarAppearance<dynamic>(builder: (BuildContext context, FluentBarEntry<dynamic> entry) => throw Exception('Custom appearance builder crash')),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Fallback Content Message'), findsOneWidget);
      expect(find.byWidgetPredicate((Widget widget) => widget is DefaultFluentBarWidget), findsOneWidget);
    });
  });

  group('FluentBarWrapper Extended Coverage Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should bypass animations when disableAnimations is true', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'No Animations',
        appearance: FluentBarAppearance<void>(disableAnimations: true, builder: (BuildContext context, FluentBarEntry<dynamic> entry) => Text(entry.currentItem.message)),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('No Animations'), findsOneWidget);

      final Finder wrapperFinder = find.byType(FluentBarWrapper<dynamic>);

      expect(find.descendant(of: wrapperFinder, matching: find.byType(FadeTransition)), findsNothing);
    });

    testWidgets('should render SafeArea when useSafeArea is true', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Safe Area True', behavior: const FluentBarBehavior(useSafeArea: true));
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should bypass SafeArea when useSafeArea is false', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Safe Area False', behavior: const FluentBarBehavior(useSafeArea: false));
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsNothing);
    });

    testWidgets('should use positionBuilder if provided in behavior', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Position Builder',
        behavior: FluentBarBehavior(
          positionBuilder: (BuildContext context, Widget child) => Positioned(key: const Key('custom_position_builder'), top: 100, child: child),
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('custom_position_builder')), findsOneWidget);
      expect(find.byType(Align), findsNothing);
    });

    testWidgets('should trigger dismiss animation on state hiding', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Dismiss Animation');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(item);
      controller.changeState(FluentBarLifecycleState.hiding);
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Dismiss Animation'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should handle didUpdateWidget successfully and update animation durations', (WidgetTester tester) async {
      final FluentBarItem<dynamic> initialItem = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Update Durations',
        appearance: const FluentBarAppearance<dynamic>(transitionDuration: Duration(milliseconds: 300), reverseTransitionDuration: Duration(milliseconds: 200)),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: initialItem);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      final FluentBarItem<dynamic> updatedItem = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Update Durations',
        appearance: const FluentBarAppearance<void>(transitionDuration: Duration(milliseconds: 500), reverseTransitionDuration: Duration(milliseconds: 400)),
      );

      final FluentBarEntry<dynamic> updatedEntry = FluentBarEntry<dynamic>(item: updatedItem);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: updatedEntry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Update Durations'), findsOneWidget);
    });
  });

  group('FluentBarWrapper Effects Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should apply shake effect transition correctly', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Shake Effect Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Shake Effect Test'), findsOneWidget);

      entry.controller.shake(intensity: 5.0, duration: const Duration(milliseconds: 300));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Shake Effect Test'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('should apply bounce effect transition correctly', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Bounce Effect Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Bounce Effect Test'), findsOneWidget);

      entry.controller.bounce(scale: 0.2, duration: const Duration(milliseconds: 300));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Bounce Effect Test'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });

  group('FluentBarWrapper Additional Entrance Animations Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    const List<FluentBarEntranceAnimation> animations = FluentBarEntranceAnimation.values;

    for (final FluentBarEntranceAnimation anim in animations) {
      testWidgets('should render entrance animation type ${anim.name} correctly', (WidgetTester tester) async {
        final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
          type: FluentBarType.info,
          message: 'Anim ${anim.name}',
          appearance: FluentBarAppearance<void>(entranceAnimation: anim),
        );
        final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
              ),
            ),
          ),
        );

        expect(find.text('Anim ${anim.name}'), findsOneWidget);
        await tester.pumpAndSettle();
      });
    }
  });

  group('FluentBarWrapper Extended Effects & Deferred Queue Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should apply pulse effect transition correctly', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Pulse Effect Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      entry.controller.pulse(scale: 1.2, duration: const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Pulse Effect Test'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should apply heartbeat effect transition correctly', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Heartbeat Effect Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      entry.controller.heartbeat(scale: 1.3, duration: const Duration(milliseconds: 400));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Heartbeat Effect Test'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should support custom effect builder and handle its exceptions', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Effect Test',
        appearance: FluentBarAppearance<void>(
          customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) => ScaleTransition(key: const Key('custom_effect_scale'), scale: controller, child: child),
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Custom Effect Test'), findsOneWidget);
    });

    testWidgets('should defer effect if entrance animation is not yet completed', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Deferred Effect Test',
        appearance: const FluentBarAppearance<void>(transitionDuration: Duration(milliseconds: 500)),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      entry.controller.shake(intensity: 4.0, duration: const Duration(milliseconds: 200));
      await tester.pump();

      await tester.pumpAndSettle();
      expect(find.text('Deferred Effect Test'), findsOneWidget);
    });
  });

  group('FluentBarWrapper Uncovered Branches Comprehensive Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should handle latestEffect in initState and clear it', (WidgetTester tester) async {
      final FluentBarControllerImpl<dynamic> controller = FluentBarControllerImpl<dynamic>(FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Latest Effect Init Test'));

      controller.shake(intensity: 5.0, duration: const Duration(milliseconds: 300));

      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: controller.itemNotifier.value, controller: controller);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      expect(find.text('Latest Effect Init Test'), findsOneWidget);
      expect(controller.latestEffect, isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('should defer effect and play it when entrance animation completes (_onEntranceStatusChanged)', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Deferred Effect Status Test',
        appearance: const FluentBarAppearance<void>(transitionDuration: Duration(milliseconds: 600)),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));
      entry.controller.bounce(scale: 0.1, duration: const Duration(milliseconds: 300));

      await tester.pumpAndSettle();
      expect(find.text('Deferred Effect Status Test'), findsOneWidget);
    });

    testWidgets('should reset currentEffect to null when effect animation completes (_onEffectStatusChanged)', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Effect Status Reset Test');
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      entry.controller.pulse(scale: 1.1, duration: const Duration(milliseconds: 400));
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Effect Status Reset Test'), findsOneWidget);
    });

    testWidgets('should execute customEffectBuilder successfully and trigger its animation', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Effect Builder Success',
        appearance: FluentBarAppearance<void>(
          customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) => ScaleTransition(key: const Key('custom_effect_builder_widget'), scale: controller, child: child),
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final FluentBarControllerImpl<void> controller = entry.controller as FluentBarControllerImpl<void>;
      controller.changeState(FluentBarLifecycleState.visible);

      entry.controller.customEffect(intensity: 1.0, duration: const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byKey(const Key('custom_effect_builder_widget')), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should handle exception thrown by customEffectBuilder gracefully and fallback to child', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Effect Builder Crash',
        appearance: FluentBarAppearance<void>(customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) => throw Exception('Custom effect builder crash')),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      entry.controller.customEffect(intensity: 1.0, duration: const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Custom Effect Builder Crash'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should use default rendering path when customEffectBuilder is null', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(type: FluentBarType.info, message: 'Null Custom Builder Test', appearance: const FluentBarAppearance<void>(customEffectBuilder: null));
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(item);
      controller.changeState(FluentBarLifecycleState.visible);
      entry.controller.customEffect(intensity: 1.0, duration: const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Null Custom Builder Test'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('should catch exception in customEffectBuilder, invoke error handler and fallback to child', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Effect Builder Catch Test',
        appearance: FluentBarAppearance<void>(
          customEffectBuilder: (BuildContext context, AnimationController controller, Widget child) {
            throw Exception('Simulated custom builder exception');
          },
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final FluentBarControllerImpl<void> controller = FluentBarControllerImpl<void>(item);
      controller.changeState(FluentBarLifecycleState.visible);

      entry.controller.customEffect(intensity: 1.0, duration: const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.text('Custom Effect Builder Catch Test'), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('FluentBarWrapper Tap & Callback Tests', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should invoke onTap callback and pass payload on default widget tap', (WidgetTester tester) async {
      bool wasTapped = false;
      dynamic tappedPayload;

      final FluentBarItem<String> item = FluentBarItem<String>(
        type: FluentBarType.info,
        message: 'Tap Default Test',
        payload: 'test_payload_123',
        callbacks: FluentBarCallbacks<String>(
          onTap: (String? payload) {
            wasTapped = true;
            tappedPayload = payload;
          },
        ),
      );
      final FluentBarEntry<String> entry = FluentBarEntry<String>(item: item);
      entry.internalController.changeState(FluentBarLifecycleState.visible);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<String>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Tap Default Test'), findsOneWidget);

      await tester.tap(find.text('Tap Default Test'));
      await tester.pump();

      expect(wasTapped, isTrue);
      expect(tappedPayload, equals('test_payload_123'));
    });

    testWidgets('should invoke onTap callback when using custom appearance builder', (WidgetTester tester) async {
      bool wasTapped = false;

      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Custom Builder Tap',
        appearance: FluentBarAppearance<dynamic>(
          builder: (BuildContext context, FluentBarEntry<dynamic> entry) => Container(key: const Key('custom_tap_container'), child: Text('Custom Content: ${entry.item.message}')),
        ),
        callbacks: FluentBarCallbacks<dynamic>(
          onTap: (_) {
            wasTapped = true;
          },
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);
      entry.internalController.changeState(FluentBarLifecycleState.visible);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('custom_tap_container')), findsOneWidget);

      await tester.tap(find.byKey(const Key('custom_tap_container')));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should catch exceptions thrown inside onTap callback without crashing', (WidgetTester tester) async {
      final FluentBarItem<dynamic> item = FluentBarItem<dynamic>(
        type: FluentBarType.info,
        message: 'Exception Tap Test',
        callbacks: FluentBarCallbacks<dynamic>(
          onTap: (_) {
            throw Exception('Simulated onTap crash inside callback');
          },
        ),
      );
      final FluentBarEntry<dynamic> entry = FluentBarEntry<dynamic>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig)],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Exception Tap Test'), findsOneWidget);

      await tester.tap(find.text('Exception Tap Test'));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Exception Tap Test'), findsOneWidget);
    });
  });

  group('Swipe & Dismissible Behavior', () {
    const FluentBarConfig dummyConfig = FluentBarConfig();

    testWidgets('should render without Dismissible when swipe is disabled', (WidgetTester tester) async {
      final FluentBarItem<void> item = FluentBarItem<void>(type: FluentBarType.info, message: 'No swipe test', behavior: const FluentBarBehavior(isSwipeEnabled: false));
      final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig),
          ),
        ),
      );

      expect(find.byType(Dismissible), findsNothing);
      expect(find.text('No swipe test'), findsOneWidget);
    });

    testWidgets('should close controller with swipe reason when dismissed', (WidgetTester tester) async {
      final FluentBarItem<void> item = FluentBarItem<void>(
        type: FluentBarType.info,
        message: 'Swipe to dismiss test',
        behavior: const FluentBarBehavior(isSwipeEnabled: true, dismissDirection: DismissDirection.horizontal),
      );
      final FluentBarEntry<void> entry = FluentBarEntry<void>(item: item);

      entry.internalController.changeState(FluentBarLifecycleState.visible);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FluentBarWrapper<dynamic>(entry: entry, config: dummyConfig),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Swipe to dismiss test'), findsOneWidget);

      await tester.drag(find.text('Swipe to dismiss test'), const Offset(500.0, 0.0));
      await tester.pumpAndSettle();

      expect(entry.controller.stateNotifier.value, FluentBarLifecycleState.dismissed);
    });
  });
}

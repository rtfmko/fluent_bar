import 'package:clock/clock.dart';
import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Map<String, FluentBarTheme> themes = <String, FluentBarTheme>{
    'material': FluentBarTheme.material,
    'cupertino': FluentBarTheme.cupertino,
    'liquidGlass': FluentBarTheme.liquidGlass,
    'windows': FluentBarTheme.windows,
    'minimal': FluentBarTheme.minimal,
    'modern': FluentBarTheme.modern,
  };

  const FluentBarThemeMode light = FluentBarThemeMode.light;
  const FluentBarThemeMode dark = FluentBarThemeMode.dark;

  Future<BuildContext> pumpContext(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (BuildContext c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return context;
  }

  FluentBarEntry<void> entryOf({FluentBarType type = FluentBarType.info, FluentBarAppearance<void>? appearance}) => FluentBarEntry<void>(
    item: FluentBarItem<void>(type: type, message: 'Test', appearance: appearance),
  );

  group('isDarkMode', () {
    testWidgets('an explicit mode wins over the app brightness', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester, brightness: Brightness.dark);

      for (final FluentBarTheme theme in themes.values) {
        expect(theme.isDarkMode(context, FluentBarType.info, themeMode: light), isFalse);
        expect(theme.isDarkMode(context, FluentBarType.info, themeMode: dark), isTrue);
      }
    });

    testWidgets('system mode follows the Material theme', (WidgetTester tester) async {
      BuildContext context = await pumpContext(tester, brightness: Brightness.dark);
      expect(FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isTrue);

      context = await pumpContext(tester);
      expect(FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isFalse);
    });

    testWidgets('system mode follows the Cupertino theme when there is no Material theme', (WidgetTester tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        CupertinoTheme(
          data: const CupertinoThemeData(brightness: Brightness.dark),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Builder(
              builder: (BuildContext c) {
                context = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isTrue);
    });

    testWidgets('system mode falls back to the platform brightness', (WidgetTester tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      late BuildContext context;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system), isTrue);
    });

    Future<bool> systemIsDark(WidgetTester tester, Widget Function(Widget child) app) async {
      late BuildContext context;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (BuildContext c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      return FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system);
    }

    testWidgets('system mode in MaterialApp follows theme, darkTheme and themeMode', (WidgetTester tester) async {
      Widget app(ThemeMode mode, Widget child) => MaterialApp(theme: ThemeData.light(), darkTheme: ThemeData.dark(), themeMode: mode, home: child);

      expect(await systemIsDark(tester, (Widget child) => app(ThemeMode.dark, child)), isTrue);
      expect(await systemIsDark(tester, (Widget child) => app(ThemeMode.light, child)), isFalse);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      expect(await systemIsDark(tester, (Widget child) => app(ThemeMode.system, child)), isTrue);
    });

    testWidgets('system mode follows a nested Theme inside MaterialApp', (WidgetTester tester) async {
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData.light(),
            home: Theme(data: ThemeData.dark(), child: child),
          ),
        ),
        isTrue,
      );
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData.dark(),
            home: Theme(data: ThemeData.light(), child: child),
          ),
        ),
        isFalse,
      );
    });

    testWidgets('system mode in CupertinoApp follows the Cupertino theme', (WidgetTester tester) async {
      expect(
        await systemIsDark(
          tester,
          (Widget child) => CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: child,
          ),
        ),
        isTrue,
      );
      expect(
        await systemIsDark(
          tester,
          (Widget child) => CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.light),
            home: child,
          ),
        ),
        isFalse,
      );
    });

    testWidgets('system mode in a bare WidgetsApp (no Material, no Cupertino) follows the platform brightness', (WidgetTester tester) async {
      Widget app(Widget child) => WidgetsApp(color: const Color(0xFF000000), builder: (BuildContext context, Widget? navigator) => child);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      expect(await systemIsDark(tester, app), isTrue);

      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      expect(await systemIsDark(tester, app), isFalse);
    });

    testWidgets('system mode: a WidgetsApp nested inside MaterialApp still sees the Material theme', (WidgetTester tester) async {
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData.dark(),
            home: WidgetsApp(color: const Color(0xFF000000), builder: (BuildContext context, Widget? navigator) => child),
          ),
        ),
        isTrue,
      );
    });

    testWidgets('system mode: the nearest theme wins when Material and Cupertino themes are nested', (WidgetTester tester) async {
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData.light(),
            home: CupertinoTheme(
              data: const CupertinoThemeData(brightness: Brightness.dark),
              child: child,
            ),
          ),
        ),
        isTrue,
      );
      expect(
        await systemIsDark(
          tester,
          (Widget child) => CupertinoApp(
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: Theme(data: ThemeData.light(), child: child),
          ),
        ),
        isTrue,
      );
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData.dark(),
            home: CupertinoTheme(data: const CupertinoThemeData(), child: child),
          ),
        ),
        isTrue,
      );
    });

    testWidgets('system mode: the bar follows a theme change of the app', (WidgetTester tester) async {
      final List<bool> seen = <bool>[];
      Widget app(ThemeData theme) => MaterialApp(
        theme: theme,
        home: Builder(
          builder: (BuildContext context) {
            seen.add(FluentBarTheme.material.isDarkMode(context, FluentBarType.info, themeMode: FluentBarThemeMode.system));
            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(app(ThemeData.light()));
      await tester.pumpAndSettle();
      await tester.pumpWidget(app(ThemeData.dark()));
      await tester.pumpAndSettle();

      expect(seen.first, isFalse);
      expect(seen.last, isTrue, reason: 'the widget was rebuilt because it depends on the theme');
    });

    testWidgets('system mode: in a Material app the Material theme decides, not its cupertinoOverrideTheme', (WidgetTester tester) async {
      expect(
        await systemIsDark(
          tester,
          (Widget child) => MaterialApp(
            theme: ThemeData(
              brightness: Brightness.dark,
              cupertinoOverrideTheme: const CupertinoThemeData(brightness: Brightness.light),
            ),
            home: child,
          ),
        ),
        isTrue,
      );
    });

    test('a failing theme lookup is reported and treated as light', () {
      final List<FluentBarException> errors = <FluentBarException>[];
      void onError(FluentBarException error, StackTrace stackTrace) => errors.add(error);
      FluentBar.addErrorHandler(onError);
      addTearDown(() => FluentBar.removeErrorHandler(onError));

      final bool isDark = FluentBarTheme.material.isDarkMode(_ThrowingBuildContext(), FluentBarType.info, themeMode: FluentBarThemeMode.system);

      expect(isDark, isFalse);
      expect(errors.single.type, FluentBarErrorType.darkMode);
    });
  });

  group('background color', () {
    testWidgets('material colors depend on the kind of the type and the mode', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme theme = FluentBarTheme.material;

      expect(theme.backgroundColor(context, FluentBarType.success, themeMode: light), const Color(0xFF2E7D32));
      expect(theme.backgroundColor(context, FluentBarType.error, themeMode: light), const Color(0xFFC62828));
      expect(theme.backgroundColor(context, FluentBarType.warning, themeMode: light), const Color(0xFFEF6C00));
      expect(theme.backgroundColor(context, FluentBarType.info, themeMode: light), const Color(0xFF1565C0));

      expect(theme.backgroundColor(context, FluentBarType.success, themeMode: dark), const Color(0xFF1B5E20));
      expect(theme.backgroundColor(context, FluentBarType.error, themeMode: dark), const Color(0xFFB71C1C));
      expect(theme.backgroundColor(context, FluentBarType.warning, themeMode: dark), const Color(0xFFE65100));
      expect(theme.backgroundColor(context, FluentBarType.info, themeMode: dark), const Color(0xFF0D47A1));
    });

    testWidgets('a copied type keeps the colors and icon of its kind', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      final FluentBarType customError = FluentBarType.error.copyWith(duration: const Duration(seconds: 1));

      expect(FluentBarTheme.material.backgroundColor(context, customError, themeMode: light), FluentBarTheme.material.backgroundColor(context, FluentBarType.error, themeMode: light));
      expect((FluentBarTheme.material.defaultIcon(context, customError) as Icon).icon, Icons.error_outline);
      expect((FluentBarTheme.cupertino.defaultIcon(context, customError) as Icon).icon, CupertinoIcons.clear_thick_circled);
    });

    for (final MapEntry<String, FluentBarTheme> theme in themes.entries) {
      testWidgets('${theme.key}: the background color of the type wins over the theme', (WidgetTester tester) async {
        final BuildContext context = await pumpContext(tester);
        final FluentBarType type = FluentBarType.info.copyWith(backgroundColor: Colors.pink);

        expect(theme.value.backgroundColor(context, type, themeMode: light), Colors.pink);

        final BoxDecoration decoration = theme.value.boxDecoration(context, type, theme.value, themeMode: light);
        if (decoration.gradient == null) {
          expect(decoration.color, Colors.pink);
        } else {
          final List<Color> colors = (decoration.gradient! as LinearGradient).colors;
          expect(colors.every((Color c) => c.withValues(alpha: 1.0) == Colors.pink.withValues(alpha: 1.0)), isTrue);
        }
      });

      testWidgets('${theme.key}: a local background color is always visible', (WidgetTester tester) async {
        final BuildContext context = await pumpContext(tester);
        final FluentBarEntry<void> entry = entryOf(appearance: const FluentBarAppearance<void>(backgroundColor: Colors.teal));

        final BoxDecoration decoration = entry.resolveDecoration(context, theme.value, light, const FluentBarConfig());

        expect(decoration.color, Colors.teal);
        expect(decoration.gradient, isNull, reason: 'a theme gradient would paint over the local color');
        expect(decoration.borderRadius, theme.value.borderRadius(context, FluentBarType.info, themeMode: light));
      });
    }

    testWidgets('a local gradient is kept as is', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const LinearGradient gradient = LinearGradient(colors: <Color>[Colors.red, Colors.blue]);
      final FluentBarEntry<void> entry = entryOf(
        appearance: const FluentBarAppearance<void>(decoration: BoxDecoration(gradient: gradient)),
      );

      expect(entry.resolveDecoration(context, FluentBarTheme.material, light, const FluentBarConfig()).gradient, gradient);
    });
  });

  group('copyWith', () {
    for (final MapEntry<String, FluentBarTheme> theme in themes.entries) {
      testWidgets('${theme.key}: overridden border radius and background reach the decoration', (WidgetTester tester) async {
        final BuildContext context = await pumpContext(tester);
        final FluentBarTheme custom = theme.value.copyWith(
          borderRadius: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => BorderRadius.circular(3),
          backgroundColor: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => Colors.lime,
        );

        final BoxDecoration decoration = custom.boxDecoration(context, FluentBarType.info, custom, themeMode: light);

        expect(decoration.borderRadius, BorderRadius.circular(3));
        if (decoration.gradient == null) expect(decoration.color, Colors.lime);
      });
    }

    for (final MapEntry<String, FluentBarTheme> theme in themes.entries) {
      testWidgets('${theme.key}: an overridden isDarkMode is the single source of truth for every color and style', (WidgetTester tester) async {
        final BuildContext context = await pumpContext(tester);
        final FluentBarTheme base = theme.value;
        const FluentBarType type = FluentBarType.info;

        for (final bool forcedDark in <bool>[true, false]) {
          final FluentBarTheme forced = base.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => forcedDark);
          final FluentBarThemeMode expected = forcedDark ? dark : light;
          final FluentBarThemeMode requested = forcedDark ? light : dark;

          expect(forced.isDarkMode(context, type, themeMode: requested), forcedDark);
          expect(forced.titleStyle(context, type, themeMode: requested), base.titleStyle(context, type, themeMode: expected));
          expect(forced.messageStyle(context, type, themeMode: requested), base.messageStyle(context, type, themeMode: expected));
          expect(forced.actionStyle(context, type, themeMode: requested), base.actionStyle(context, type, themeMode: expected));
          expect(forced.backgroundColor(context, type, themeMode: requested), base.backgroundColor(context, type, themeMode: expected));
          expect(forced.iconColor(context, type, themeMode: requested), base.iconColor(context, type, themeMode: expected));
          expect(forced.actionLoaderColor(context, type, themeMode: requested), base.actionLoaderColor(context, type, themeMode: expected));
          expect(forced.actionDecoration(context, type, themeMode: requested), base.actionDecoration(context, type, themeMode: expected));
          expect(forced.boxDecoration(context, type, forced, themeMode: requested), base.boxDecoration(context, type, base, themeMode: expected));
        }
      });
    }

    testWidgets('overrides receive the mode already resolved by isDarkMode', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      FluentBarThemeMode? seen;
      final FluentBarTheme theme = FluentBarTheme.material.copyWith(
        isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => true,
        titleStyle: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) {
          seen = m;
          return const TextStyle();
        },
      );

      theme.titleStyle(context, FluentBarType.info, themeMode: light);
      expect(seen, dark);
    });

    testWidgets('without an isDarkMode override the requested mode is passed through untouched', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      FluentBarThemeMode? seen = light;
      final FluentBarTheme theme = FluentBarTheme.material.copyWith(
        titleStyle: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) {
          seen = m;
          return const TextStyle();
        },
      );

      theme.titleStyle(context, FluentBarType.info, themeMode: FluentBarThemeMode.system);
      expect(seen, FluentBarThemeMode.system);
    });

    testWidgets('with nested copies the outermost isDarkMode decides', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme base = FluentBarTheme.modern;
      final FluentBarTheme inner = base.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => true);
      final FluentBarTheme outer = inner.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => false);
      final FluentBarTheme passthrough = inner.copyWith(spacing: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => 1);

      expect(outer.isDarkMode(context, FluentBarType.info, themeMode: dark), isFalse);
      expect(outer.titleStyle(context, FluentBarType.info, themeMode: dark), base.titleStyle(context, FluentBarType.info, themeMode: light));

      expect(passthrough.isDarkMode(context, FluentBarType.info, themeMode: light), isTrue);
      expect(passthrough.titleStyle(context, FluentBarType.info, themeMode: light), base.titleStyle(context, FluentBarType.info, themeMode: dark));
    });

    testWidgets('a throwing isDarkMode falls back to the base theme everywhere', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme base = FluentBarTheme.modern;
      final FluentBarTheme broken = base.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => throw Exception('boom'));

      expect(broken.isDarkMode(context, FluentBarType.info, themeMode: dark), isTrue);
      expect(broken.titleStyle(context, FluentBarType.info, themeMode: dark), base.titleStyle(context, FluentBarType.info, themeMode: dark));
    });

    testWidgets('an overridden isDarkMode is used when building the decoration', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const FluentBarTheme base = FluentBarTheme.material;
      final FluentBarTheme alwaysDark = base.copyWith(isDarkMode: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => true);

      expect(alwaysDark.boxDecoration(context, FluentBarType.info, alwaysDark, themeMode: light).boxShadow, base.boxDecoration(context, FluentBarType.info, base, themeMode: dark).boxShadow);
    });

    testWidgets('a copied theme passes the requested icon size to the base theme', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);

      for (final FluentBarTheme theme in themes.values) {
        final Widget icon = theme.copyWith().defaultIcon(context, FluentBarType.info, overrideSize: 40);
        expect((icon as Icon).size, 40);
      }
    });

    testWidgets('the icon of the type wins over the icon of the theme', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      const Icon typeIcon = Icon(Icons.star);
      final FluentBarType type = FluentBarType.info.copyWith(icon: typeIcon);

      for (final FluentBarTheme theme in themes.values) {
        expect(theme.defaultIcon(context, type), same(typeIcon));
        expect(theme.copyWith().defaultIcon(context, type), same(typeIcon));
      }
    });
  });

  group('timeout bar', () {
    Future<LinearProgressIndicator> pumpBar(
      WidgetTester tester,
      FluentBarTheme theme,
      FluentBarEntry<void> entry, {
      FluentBarType type = FluentBarType.info,
      FluentBarThemeMode mode = FluentBarThemeMode.light,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(builder: (BuildContext context) => theme.buildTimeoutBar(context, entry, theme, type, themeMode: mode)!),
          ),
        ),
      );
      return tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    }

    for (final MapEntry<String, FluentBarTheme> theme in themes.entries) {
      testWidgets('${theme.key}: draws a bar bound to the remaining time', (WidgetTester tester) async {
        final FluentBarEntry<void> entry = entryOf();
        addTearDown(entry.internalController.dispose);

        final LinearProgressIndicator bar = await pumpBar(tester, theme.value, entry);

        expect(bar.value, entry.controller.remainingProgressNotifier.value);
        expect(bar.minHeight, theme.value.timeoutBarMinHeight(tester.element(find.byType(LinearProgressIndicator)), FluentBarType.info));
        expect((bar.valueColor! as AlwaysStoppedAnimation<Color>).value.a, greaterThan(0));
      });

      testWidgets('${theme.key}: the bar color of the type wins over the theme', (WidgetTester tester) async {
        final FluentBarType type = FluentBarType.info.copyWith(timeoutBarColor: Colors.purple);
        final FluentBarEntry<void> entry = entryOf(type: type);
        addTearDown(entry.internalController.dispose);

        final LinearProgressIndicator bar = await pumpBar(tester, theme.value, entry, type: type);

        expect((bar.valueColor! as AlwaysStoppedAnimation<Color>).value, Colors.purple);
      });
    }

    testWidgets('uses the resolved type that was passed in, not the raw type of the item', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      addTearDown(entry.internalController.dispose);
      final FluentBarType overridden = FluentBarType.info.copyWith(timeoutBarColor: Colors.orange);

      for (final FluentBarTheme theme in <FluentBarTheme>[FluentBarTheme.material, FluentBarTheme.modern]) {
        final LinearProgressIndicator bar = await pumpBar(tester, theme, entry, type: overridden);
        expect((bar.valueColor! as AlwaysStoppedAnimation<Color>).value, Colors.orange);
      }
    });

    testWidgets('reverse direction is bound to the elapsed time', (WidgetTester tester) async {
      FluentBarControllerImpl.stopwatchFactory = () => clock.stopwatch();
      addTearDown(() => FluentBarControllerImpl.stopwatchFactory = Stopwatch.new);
      final FluentBarEntry<void> entry = entryOf(appearance: const FluentBarAppearance<void>(timeoutBarDirection: FluentBarTimeoutBarDirection.reverse));
      addTearDown(entry.internalController.dispose);

      entry.internalController
        ..changeState(FluentBarLifecycleState.visible)
        ..startTimersOnShow(const Duration(seconds: 4), FluentBarManager.instance);
      await tester.pump(const Duration(seconds: 1));
      entry.controller.pause();

      final LinearProgressIndicator bar = await pumpBar(tester, FluentBarTheme.material, entry);

      expect(bar.value, 0.25);
    });

    testWidgets('colors and sizes overridden with copyWith are applied, including nested copies', (WidgetTester tester) async {
      final FluentBarEntry<void> entry = entryOf();
      addTearDown(entry.internalController.dispose);
      final FluentBarTheme inner = FluentBarTheme.cupertino.copyWith(timeoutBarMinHeight: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => 7);
      final FluentBarTheme outer = inner.copyWith(
        timeoutBarColor: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => Colors.red,
        timeoutBarBackgroundColor: (BuildContext c, FluentBarType t, FluentBarThemeMode? m) => Colors.green,
      );

      final LinearProgressIndicator bar = await pumpBar(tester, outer, entry);

      expect((bar.valueColor! as AlwaysStoppedAnimation<Color>).value, Colors.red);
      expect(bar.backgroundColor, Colors.green);
      expect(bar.minHeight, 7);
    });

    testWidgets('the whole bar can be replaced with copyWith', (WidgetTester tester) async {
      final BuildContext context = await pumpContext(tester);
      final FluentBarEntry<void> entry = entryOf();
      addTearDown(entry.internalController.dispose);

      final FluentBarTheme theme = FluentBarTheme.material.copyWith(buildTimeoutBar: (BuildContext c, FluentBarEntry<dynamic> e, FluentBarType t, FluentBarThemeMode? m) => const SizedBox.shrink());

      expect(theme.buildTimeoutBar(context, entry, theme, FluentBarType.info), isA<SizedBox>());
    });
  });
}

class _ThrowingBuildContext extends Fake implements BuildContext {
  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) => throw Exception('Simulated theme lookup exception');
}

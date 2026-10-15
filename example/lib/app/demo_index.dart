import 'package:flutter/material.dart';

import '../screens/basics_screen.dart';
import '../screens/behavior_screen.dart';
import '../screens/builders_screen.dart';
import '../screens/config_screen.dart';
import '../screens/diagnostics_screen.dart';
import '../screens/home_screen.dart';
import '../screens/monitor_screen.dart';
import '../screens/overrides_screen.dart';
import '../screens/playground_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/queue_screen.dart';
import '../screens/themes_screen.dart';

class DemoScreenInfo {
  final String id;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final WidgetBuilder builder;

  const DemoScreenInfo(this.id, this.icon, this.color, this.title, this.description, this.builder);
}

class DemoSectionInfo {
  final String code;
  final String title;
  final String keywords;

  const DemoSectionInfo(this.code, this.title, this.keywords);

  String get screenId => code.split('/').first;

  DemoScreenInfo get screen => DemoIndex.screens.firstWhere((DemoScreenInfo s) => s.id == screenId);
}

// Every screen and section of the demo has a short code such as `queue/duplicates`. The code is
// what the search finds, what the documentation points at, and the address of the section:
// `<demo url>/#/queue/duplicates` opens it directly.
abstract final class DemoIndex {
  static final List<DemoScreenInfo> screens = <DemoScreenInfo>[
    DemoScreenInfo(
      'start',
      Icons.rocket_launch_outlined,
      const Color(0xFF4F46E5),
      'Quick start',
      'One-liners, presets (snack, toast, banner, loading), recipes and the .with...() chain.',
      (_) => const BasicsScreen(),
    ),
    DemoScreenInfo(
      'progress',
      Icons.downloading_outlined,
      const Color(0xFF0891B2),
      'Progress & futures',
      'Linear and circular progress, text effects, FluentBar.future, success / failure outcomes.',
      (_) => const ProgressScreen(),
    ),
    DemoScreenInfo(
      'behavior',
      Icons.touch_app_outlined,
      const Color(0xFFEA580C),
      'Behavior & gestures',
      'Positions, insets and live relocation, pause on touch, actions with loaders, effects.',
      (_) => const BehaviorScreen(),
    ),
    DemoScreenInfo(
      'queue',
      Icons.reorder_rounded,
      const Color(0xFF16A34A),
      'Queue & duplicates',
      'Two regions, queue strategies, priorities, forcing and duplicate policies - with a live view of both queues.',
      (_) => const QueueScreen(),
    ),
    DemoScreenInfo(
      'overrides',
      Icons.layers_outlined,
      const Color(0xFF2563EB),
      'Overriding settings',
      'One setting on three levels - the bar, its type, the config. Flip the switches and see who wins.',
      (_) => const OverridesScreen(),
    ),
    DemoScreenInfo(
      'themes',
      Icons.palette_outlined,
      const Color(0xFFDB2777),
      'Themes & types',
      'Built-in themes, light / dark mode, tweaking a theme, custom types and global type overrides.',
      (_) => const ThemesScreen(),
    ),
    DemoScreenInfo(
      'builders',
      Icons.construction_rounded,
      const Color(0xFFCA8A04),
      'Builders',
      'Replace a part of the bar with your own widget: content, position, transition, progress, action, theme hooks.',
      (_) => const BuildersScreen(),
    ),
    DemoScreenInfo(
      'config',
      Icons.settings_suggest_outlined,
      const Color(0xFF475569),
      'Global config',
      'All app-wide defaults in one place: placement, look, gestures, queue. Changes apply live.',
      (_) => const ConfigScreen(),
    ),
    DemoScreenInfo(
      'monitor',
      Icons.radar_rounded,
      const Color(0xFF0D9488),
      'Monitor',
      'A traffic generator, queue stats and the full story of every bar: lifecycle, metrics and all analytics events.',
      (_) => const MonitorScreen(),
    ),
    DemoScreenInfo(
      'analytics',
      Icons.monitor_heart_outlined,
      const Color(0xFFDC2626),
      'Analytics & safety',
      'Event log you can filter and drill into, the error handler, and what happens when your code throws.',
      (_) => const DiagnosticsScreen(),
    ),
    DemoScreenInfo(
      'playground',
      Icons.tune_rounded,
      const Color(0xFF7C3AED),
      'Playground',
      'Configure a bar with switches and sliders, watch it change live and copy the generated code.',
      (_) => const PlaygroundScreen(),
    ),
  ];

  static const List<DemoSectionInfo> sections = <DemoSectionInfo>[
    DemoSectionInfo('start/setup', 'Setup', 'FluentBar FluentBarConfig FluentBarObserver FluentBarScope initialize maxQueueLength navigator overlay showInfo updateConfig'),
    DemoSectionInfo('start/one-liners', 'One-liners', 'FluentBar showError showInfo showSuccess showWarning'),
    DemoSectionInfo('start/presets', 'Presets', 'FluentBar FluentBarEntry FluentBarType completeProgress showBanner showLoading showSnack showToast snack'),
    DemoSectionInfo(
      'start/recipes',
      'Recipes',
      'FluentBar FluentBarDuplicatePolicy FluentBarEntranceAnimation FluentBarEntry FluentBarType atBottom atCenter banner canceledMessage canceledType completeProgress failProgress find forced heartbeat onCancel persistent preset shake showLoading showText showToast snack toast undismissible updateBytes updateFraction updateValue withAction withBackground withCancelButton withDuplicatePolicy withDuration withEntrance withIcon withId withLinearProgress withPreset withTimeoutBar withTitle withoutIcon',
    ),
    DemoSectionInfo(
      'start/the-chain',
      'The chain',
      'FluentBar FluentBarEntranceAnimation FluentBarEntry atBottom atCenter close dismissOnTap persistent showToast swipeable withAction withBackground withContent withDuration withEntrance withIcon withTimeoutBar withTitle',
    ),
    DemoSectionInfo('start/payload-callbacks', 'Typed payload & callbacks', 'FluentBar FluentBarMetrics dismissOnTap dismissReason onDismiss onTap showToast visibleDuration withAction withTitle'),
    DemoSectionInfo('start/closing', 'Closing bars', 'FluentBar clearQueue close closeActive closeAll dismissAndClear showInfo'),
    DemoSectionInfo('progress/look', 'Look of the indicator', 'FluentBarProgressPosition FluentBarProgressState FluentBarProgressStyle FluentBarProgressTextEffect showText successIconDuration'),
    DemoSectionInfo(
      'progress/update',
      'Three ways to update',
      'FluentBar FluentBarProgressState FluentBarType update updateFraction updateProgress updateValue withId withLinearProgress withProgress',
    ),
    DemoSectionInfo(
      'progress/finish',
      'Finishing a progress',
      'FluentBar FluentBarCallbacks FluentBarEntry FluentBarType cancelProgress close completeProgress failProgress onProgressCanceled onProgressCompleted onProgressFailed toast',
    ),
    DemoSectionInfo(
      'progress/cancel-button',
      'Cancel button',
      'FluentBar FluentBarType canceledMessage canceledType onCancel removeWhenProgressEnds showText withCancelButton withCloseButton withId withLinearProgress',
    ),
    DemoSectionInfo(
      'progress/retry',
      'Fail and retry',
      'FluentBar FluentBarType completeProgress failProgress isPersistent onRetry retryLabel showText updateBytes withCancelButton withId withLinearProgress',
    ),
    DemoSectionInfo('progress/bytes', 'Downloads in bytes', 'FluentBar FluentBarBytesLabel showText updateBytes withLinearProgress'),
    DemoSectionInfo('progress/future', 'FluentBar.future', 'FluentBar future'),
    DemoSectionInfo(
      'progress/label',
      'Custom label & colors',
      'FluentBar FluentBarAppearance FluentBarEntry FluentBarOptions FluentBarProgressState FluentBarProgressTextAlign FluentBarProgressTextEffect FluentBarProgressTheme labelBuilder progressColor progressState progressTheme showText successIcon textAlign textEffect textEffectDuration thickness trackDecoration',
    ),
    DemoSectionInfo('themes/theme', 'Theme of one bar', 'FluentBarThemeMode'),
    DemoSectionInfo('themes/tweak', 'Tweak a built-in theme', 'FluentBar FluentBarTheme borderRadius withTheme'),
    DemoSectionInfo('themes/type', 'Type of the bar', 'FluentBar FluentBarItem FluentBarPosition FluentBarTheme FluentBarType backgroundColor currentConfig defaultPosition showTimeoutBar withTheme'),
    DemoSectionInfo('themes/type-overrides', 'Override a built-in type everywhere', 'FluentBar FluentBarType showSuccess showWarning typeOverrides'),
    DemoSectionInfo('behavior/positions', 'Positions', 'FluentBar FluentBarPosition atBottom'),
    DemoSectionInfo(
      'behavior/insets',
      'Below the app bar, above the bottom bar',
      'FluentBar FluentBarBottomInset FluentBarTopInset bottomInset patchConfig persistent snack topInset withId withInsets',
    ),
    DemoSectionInfo('behavior/relocation', 'Moving a bar that is already shown', 'FluentBar FluentBarPosition FluentBarRelocationStrategy patchBehavior relocationStrategy withRelocationStrategy'),
    DemoSectionInfo('behavior/touch', 'Touch', 'FluentBar dismissOnTap pause pauseOnTouch persistent undismissible withAction withId withTimeoutBar withTitle'),
    DemoSectionInfo(
      'behavior/close-button',
      'Close button',
      'FluentBar FluentBarCloseButton FluentBarTheme FluentBarType closeButtonAlignment closeIcon custom defaultShowCloseButton patchConfig persistent snack undismissible withCloseButton withId withTheme withTitle',
    ),
    DemoSectionInfo('behavior/actions', 'Actions', 'FluentBar FluentBarController FluentBarEntry FluentBarType closeOnAction removeAction setLoading showToast update updateContent withAction withId'),
    DemoSectionInfo(
      'behavior/custom-action-swipe-inset',
      'Own action widget, swipe direction, own inset',
      'FluentBar FluentBarActions FluentBarBehavior FluentBarController FluentBarThemeMode FluentBarType close dismissDirection dismissOnTap persistent updateContent withId withInsets',
    ),
    DemoSectionInfo(
      'behavior/live-bar',
      'Control a live bar',
      'FluentBar FluentBarAppearance FluentBarThemeMode FluentBarType addDuration backgroundColor bounce clearTitle find heartbeat makePersistent patchAppearance pause persistent pulse resume shake subtractDuration themeMode update updateContent updateDuration',
    ),
    DemoSectionInfo(
      'behavior/screen-readers',
      'Screen readers',
      'FluentBar FluentBarDismissReason FluentBarSemantics FluentBarType accessibility announceUpdates defaultSemantics patchConfig semantics withLinearProgress withSemantics withTitle',
    ),
    DemoSectionInfo('behavior/entrance-haptics', 'Entrance animations & haptics', 'FluentBar FluentBarEntranceAnimation FluentBarHapticType withEntrance withHaptic withoutAnimations'),
    DemoSectionInfo(
      'builders/content-builder',
      'Content builder',
      'FluentBar FluentBarCloseButton FluentBarConfig FluentBarEntry FluentBarType addDuration close defaultBuilder remainingDurationNotifier showCustom withContent withDuration withId',
    ),
    DemoSectionInfo(
      'builders/standard-parts',
      'Standard parts in your own layout',
      'FluentBar FluentBarEntry FluentBarProgressTheme FluentBarTaskProgressWidget defaultColor progressNotifier progressStateNotifier showText successIcon withContent withLinearProgress',
    ),
    DemoSectionInfo('builders/position-builder', 'Position builder', 'FluentBar FluentBarBehavior FluentBarOptions FluentBarType atBottom positionBuilder withId'),
    DemoSectionInfo(
      'builders/transition-effect',
      'Transition & effect builders',
      'FluentBar FluentBarAppearance FluentBarConfig FluentBarOptions customEffect customEffectBuilder defaultTransitionBuilder patchConfig showInfo transitionBuilder transitionDuration',
    ),
    DemoSectionInfo(
      'builders/progress-label',
      'Progress & label builders',
      'FluentBar FluentBarAppearance FluentBarProgressState FluentBarProgressTextEffect FluentBarProgressTheme labelBuilder progressBuilder progressTheme showText textEffect update withLinearProgress withProgress',
    ),
    DemoSectionInfo(
      'builders/action-builder',
      'Action builder',
      'FluentBar FluentBarActions FluentBarController FluentBarThemeMode FluentBarType close dismissOnTap handleAction isActionExecutingNotifier persistent update updateContent withId',
    ),
    DemoSectionInfo(
      'builders/theme-hooks',
      'Theme hooks',
      'FluentBar FluentBarEntry FluentBarTheme FluentBarThemeMode FluentBarType borderRadius buildTimeoutBar material progressNotifier remainingProgressNotifier themeMode withDuration withId withTheme withTitle wrapContainer',
    ),
    DemoSectionInfo('queue/settings', 'Queue settings', 'FluentBar FluentBarConfig defaultQueueStrategy enableMultiRegion maxQueueLength patchConfig'),
    DemoSectionInfo('queue/fill', 'Fill the queue', 'FluentBar FluentBarPriority atBottom withPriority'),
    DemoSectionInfo('queue/jump', 'Jump the queue', 'FluentBar FluentBarPriority forceItemFromQueue forced updateItemPriority withDuration withId withTitle'),
    DemoSectionInfo(
      'queue/duplicates',
      'Duplicates',
      'FluentBar FluentBarConfig FluentBarDuplicatePolicy defaultDuplicatePolicy duplicateComparator meta patchConfig update withDuplicatePolicy withId withMeta withProgress',
    ),
    DemoSectionInfo('queue/clean-up', 'Clean up', 'FluentBar clearQueue closeActive closeAll dismissAndClear'),
    DemoSectionInfo('queue/tags', 'Tags: bars of one screen', 'FluentBar FluentBarOwner atBottom closeTag findByTag persistent showToast withId withTag withTags withTitle'),
    DemoSectionInfo('monitor/generator', 'Generator', 'forced'),
    DemoSectionInfo('monitor/queues', 'Queues right now', 'FluentBar FluentBarAnalyticsEvent activeItems bottomQueueLength clearQueue closeAll mainQueueLength'),
    DemoSectionInfo('monitor/bars', 'Bars', ''),
    DemoSectionInfo('playground/code', 'Generated code', ''),
    DemoSectionInfo('playground/content', 'Content', 'withIcon'),
    DemoSectionInfo('playground/action', 'Action button', 'closeOnAction withCancelButton'),
    DemoSectionInfo('playground/lifetime', 'Lifetime', 'FluentBarTimeoutBarDirection FluentBarTimeoutBarPosition persistent'),
    DemoSectionInfo('playground/look', 'Placement & look', 'FluentBarEntranceAnimation FluentBarPosition FluentBarThemeMode'),
    DemoSectionInfo('playground/gestures', 'Gestures & feedback', 'FluentBarHapticType FluentBarSemantics pauseOnTouch withCloseButton withSemantics'),
    DemoSectionInfo('playground/queue', 'Queue', 'FluentBarPriority forced'),
    DemoSectionInfo('playground/progress', 'Progress', 'FluentBarProgressPosition FluentBarProgressTextEffect'),
    DemoSectionInfo('playground/runtime', 'Runtime control', 'FluentBar FluentBarEntry addDuration bounce heartbeat pause pulse resume setLoading shake subtractDuration'),
    DemoSectionInfo(
      'analytics/stream',
      'Analytics stream',
      'FluentBar FluentBarAnalyticsEvent FluentBarAnalyticsPayload FluentBarBehavior FluentBarEntry FluentBarPosition FluentBarPriority addAnalyticsListener analyticsName dismissOnTap dismissReason hasMetrics isByUser isFinished isInteraction onTap patchBehavior pause removeAnalyticsListener removeErrorHandler resume showInfo showText toFlatMap visibleDuration wasActionTapped withAction withDuration withId withLinearProgress withMeta withPayload withPriority withTimeoutBar withTitle',
    ),
    DemoSectionInfo(
      'analytics/errors',
      'When your code throws',
      'FluentBar FluentBarAppearance FluentBarErrorSeverity FluentBarErrorType FluentBarException FluentBarProgressTheme addErrorHandler completeProgress displayName failProgress invalidCall isError isWarning onShow progressBuilder progressTheme retryLabel severity showCustom showInfo showText stackTrace subtractDuration withAction withContent withId withLinearProgress withTheme',
    ),
    DemoSectionInfo('config/code', 'Your config as code', 'FluentBar FluentBarScope initialize patchConfig'),
    DemoSectionInfo(
      'config/placement',
      'Placement',
      'FluentBar FluentBarBottomInset FluentBarConfig FluentBarPosition FluentBarRelocationStrategy FluentBarTopInset bottomInset defaultPosition defaultRelocationStrategy defaultUseSafeArea enableMultiRegion measuredBottomInset measuredTopInset topInset withInsets',
    ),
    DemoSectionInfo(
      'config/look',
      'Look',
      'FluentBarConfig FluentBarEntranceAnimation FluentBarThemeMode FluentBarThemeStyle defaultDisableAnimations defaultEntranceAnimation defaultReverseTransitionDuration defaultShowIcons defaultThemeMode defaultTransitionDuration respectSystemReduceMotion themeStyle',
    ),
    DemoSectionInfo(
      'config/lifetime',
      'Lifetime & timeout bar',
      'FluentBarConfig FluentBarTimeoutBarDirection FluentBarTimeoutBarPosition FluentBarUpdateRate defaultDuration defaultShowTimeoutBar defaultTimeoutBarDirection defaultTimeoutBarPosition defaultTimeoutUpdateInterval',
    ),
    DemoSectionInfo(
      'config/gestures',
      'Gestures',
      'FluentBarConfig FluentBarSemantics clearCloseButtonLabel closeButtonLabel defaultDismissOnTap defaultIsSwipeEnabled defaultPauseOnTouch defaultSemantics defaultShowCloseButton enableHaptics',
    ),
    DemoSectionInfo('config/queue', 'Queue & duplicates', 'FluentBarConfig FluentBarDuplicatePolicy defaultDuplicatePolicy defaultQueueStrategy maxQueueLength'),
    DemoSectionInfo('config/analytics-events', 'Analytics events', 'FluentBarAnalyticsEvent FluentBarConfig disabledAnalyticsEvents'),
    DemoSectionInfo(
      'config/progress',
      'Progress indicator',
      'FluentBar FluentBarConfig FluentBarEntry FluentBarProgressStyle FluentBarProgressTextEffect announceUpdates progressTheme showText textEffect thickness withId withLinearProgress',
    ),
    DemoSectionInfo(
      'overrides/who-wins',
      'Who wins?',
      'FluentBarConfig FluentBarType atBottom copyWith defaultDuration defaultPosition defaultShowTimeoutBar defaultThemeMode patchConfig themeMode withDuration withTimeoutBar',
    ),
    DemoSectionInfo(
      'overrides/where',
      'Where to put a setting',
      'FluentBar FluentBarPosition FluentBarTheme FluentBarType atBottom backgroundColor borderRadius clearDefaultTheme copyWith defaultPosition patchAppearance patchBehavior patchConfig typeOverrides withDuration',
    ),
  ];

  static DemoSectionInfo section(String code) =>
      sections.firstWhere((DemoSectionInfo s) => s.code == code, orElse: () => throw ArgumentError.value(code, 'code', 'Add the section to DemoIndex.sections'));

  static DemoScreenInfo? screenOf(String? routeName) {
    final List<String> parts = _parts(routeName);
    if (parts.isEmpty) return null;

    for (final DemoScreenInfo screen in screens) {
      if (screen.id == parts.first) return screen;
    }
    return null;
  }

  static String? sectionOf(String? routeName) {
    final List<String> parts = _parts(routeName);
    if (parts.length < 2) return null;

    final String code = '${parts[0]}/${parts[1]}';
    return sections.any((DemoSectionInfo s) => s.code == code) ? code : null;
  }

  static List<String> _parts(String? routeName) => (routeName ?? '').split('/').where((String part) => part.isNotEmpty).toList();

  static List<DemoSectionInfo> search(String query) {
    final List<String> words = query.toLowerCase().split(RegExp(r'[\s./]+')).where((String word) => word.isNotEmpty).toList();
    if (words.isEmpty) return const <DemoSectionInfo>[];

    final List<(int, DemoSectionInfo)> found = <(int, DemoSectionInfo)>[];
    for (final DemoSectionInfo section in sections) {
      final String head = '${section.title} ${section.code}'.toLowerCase();
      final String all = '$head ${section.screen.title} ${section.keywords}'.toLowerCase();
      if (!words.every(all.contains)) continue;

      found.add((words.every(head.contains) ? 0 : 1, section));
    }

    found.sort(((int, DemoSectionInfo) a, (int, DemoSectionInfo) b) => a.$1.compareTo(b.$1));
    return <DemoSectionInfo>[for (final (int, DemoSectionInfo) entry in found) entry.$2];
  }

  static Route<void> route(RouteSettings settings) {
    final DemoScreenInfo? screen = screenOf(settings.name);
    return MaterialPageRoute<void>(settings: settings, builder: screen?.builder ?? (_) => const HomeScreen());
  }

  static List<Route<void>> initialRoutes(String initialRoute) => <Route<void>>[route(const RouteSettings(name: '/')), if (screenOf(initialRoute) != null) route(RouteSettings(name: initialRoute))];
}

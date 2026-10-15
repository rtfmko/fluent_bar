import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import 'app/app_state.dart';
import 'app/demo_index.dart';
import 'app/telemetry.dart';

void main() {
  // The demo records analytics and errors from the very start (see app/telemetry.dart).
  Telemetry.instance.start();

  // A bar can be requested before runApp: it waits in the queue and appears as soon as the
  // app has an overlay. The config set below still applies to it.
  FluentBar.showInfo<void>(
    'I was requested on the very first line of main() - before the config and before runApp().',
    title: 'Ready before your app is',
    id: 'before_run_app',
    duration: const Duration(seconds: 6),
  );

  // The global config can be set at any time, also before runApp.
  FluentBar.updateConfig(AppState.baseConfig);

  runApp(const FluentBarDemoApp());
}

class FluentBarDemoApp extends StatelessWidget {
  const FluentBarDemoApp({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ThemeMode>(
    valueListenable: AppState.themeMode,
    builder: (BuildContext context, ThemeMode themeMode, _) => MaterialApp(
      title: 'FluentBar Demo',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      // All an app needs is `builder: FluentBarScope.builder()`: bars then live above the navigator
      // and survive route changes. The MediaQuery here only lets the demo simulate the system
      // "reduce motion" setting.
      builder: (BuildContext context, Widget? child) => ValueListenableBuilder<bool>(
        valueListenable: AppState.simulateReduceMotion,
        builder: (BuildContext context, bool simulate, _) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: simulate || MediaQuery.of(context).disableAnimations),
          child: FluentBarScope(child: child ?? const SizedBox.shrink()),
        ),
      ),
      onGenerateRoute: DemoIndex.route,
      onGenerateInitialRoutes: DemoIndex.initialRoutes,
    ),
  );
}

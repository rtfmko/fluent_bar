import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../custom/custom_bar_theme.dart';
import '../custom/random_queue_strategy.dart';

class ThemeOption {
  final String label;
  final FluentBarTheme? theme;

  const ThemeOption(this.label, this.theme);
}

class StrategyOption {
  final String label;
  final String hint;
  final FluentBarQueueStrategy strategy;

  const StrategyOption(this.label, this.hint, this.strategy);
}

abstract final class AppState {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  static final ValueNotifier<bool> simulateReduceMotion = ValueNotifier<bool>(false);

  static const FluentBarConfig baseConfig = FluentBarConfig();

  static void toggleTheme(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
  }

  // Functions are not a part of the equality of a config, so the ones the screens change are compared here.
  static bool isBase(FluentBarConfig config) =>
      config == baseConfig &&
      config.duplicateComparator == baseConfig.duplicateComparator &&
      config.defaultBuilder == baseConfig.defaultBuilder &&
      config.defaultPositionBuilder == baseConfig.defaultPositionBuilder &&
      config.defaultTransitionBuilder == baseConfig.defaultTransitionBuilder;

  static void resetConfig() => FluentBar.updateConfig(baseConfig);

  static const List<ThemeOption> themes = <ThemeOption>[
    ThemeOption('Platform (auto)', null),
    ThemeOption('Material', FluentBarTheme.material),
    ThemeOption('Cupertino', FluentBarTheme.cupertino),
    ThemeOption('Windows', FluentBarTheme.windows),
    ThemeOption('Minimal', FluentBarTheme.minimal),
    ThemeOption('Modern', FluentBarTheme.modern),
    ThemeOption('Liquid glass', FluentBarTheme.liquidGlass),
    ThemeOption('Custom (neon)', CustomBarTheme()),
  ];

  static const List<StrategyOption> strategies = <StrategyOption>[
    StrategyOption('Smart', 'Higher priority first, then in order of arrival. When full, the least important bar is dropped.', SmartQueueStrategy()),
    StrategyOption('FIFO', 'First in, first out. Priorities are ignored.', FifoQueueStrategy()),
    StrategyOption('LIFO', 'The newest bar is shown next.', LifoQueueStrategy()),
    StrategyOption('Random (custom)', 'Your own FluentBarQueueStrategy: see example/lib/custom/random_queue_strategy.dart.', RandomQueueStrategy()),
  ];

  static ThemeOption themeOf(FluentBarConfig config) => themes.firstWhere((ThemeOption o) => identical(o.theme, config.defaultTheme), orElse: () => themes.first);

  static StrategyOption strategyOf(FluentBarConfig config) =>
      strategies.firstWhere((StrategyOption o) => o.strategy.runtimeType == config.defaultQueueStrategy.runtimeType, orElse: () => strategies.first);

  static void setTheme(ThemeOption option) => FluentBar.patchConfig((FluentBarConfig c) => option.theme == null ? c.copyWith(clearDefaultTheme: true) : c.copyWith(defaultTheme: option.theme));
}

ThemeData buildAppTheme(Brightness brightness) {
  final ColorScheme scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5), brightness: brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: scheme.outlineVariant),
      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
      showCheckmark: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      isDense: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withValues(alpha: 0.5), space: 24),
  );
}

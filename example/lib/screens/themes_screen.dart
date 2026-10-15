import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../custom/custom_bar_type.dart';
import '../widgets/demo_kit.dart';

class PromoBarType extends FluentBarType {
  const PromoBarType();

  @override
  String get name => 'promo';

  @override
  Color? get backgroundColor => const Color(0xFFBE185D);

  @override
  Color? get timeoutBarColor => Colors.amberAccent;

  @override
  Widget? get icon => const Icon(Icons.local_offer_rounded, color: Colors.amberAccent);

  @override
  Duration get duration => const Duration(seconds: 6);

  @override
  bool? get showTimeoutBar => true;

  @override
  FluentBarTimeoutBarPosition? get timeoutBarPosition => FluentBarTimeoutBarPosition.top;

  @override
  FluentBarPosition? get position => FluentBarPosition.bottom;

  @override
  FluentBarEntranceAnimation? get entranceAnimation => FluentBarEntranceAnimation.bouncingSlide;
}

class MaintenanceBarType extends FluentBarType {
  const MaintenanceBarType();

  @override
  String get name => 'maintenance';

  @override
  FluentBarType get kind => FluentBarType.warning;

  @override
  Widget? get icon => const Icon(Icons.build_circle_outlined);

  @override
  Duration get duration => const Duration(seconds: 8);

  @override
  bool? get showTimeoutBar => true;

  @override
  bool? get dismissOnTap => false;

  @override
  FluentBarEntranceAnimation? get entranceAnimation => FluentBarEntranceAnimation.scale;
}

class _TypeOption {
  final String label;
  final String code;
  final FluentBarType type;

  final String about;

  const _TypeOption(this.label, this.code, this.type, this.about);
}

class ThemesScreen extends StatefulWidget {
  const ThemesScreen({super.key});

  @override
  State<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends State<ThemesScreen> {
  static final List<_TypeOption> _types = <_TypeOption>[
    const _TypeOption('info', 'FluentBarType.info', FluentBarType.info, 'Built-in type: the theme gives it the info color and icon.'),
    const _TypeOption('success', 'FluentBarType.success', FluentBarType.success, 'Built-in type: the theme gives it the success color and icon.'),
    const _TypeOption('warning', 'FluentBarType.warning', FluentBarType.warning, 'Built-in type: the theme gives it the warning color and icon.'),
    const _TypeOption('error', 'FluentBarType.error', FluentBarType.error, 'Built-in type: the theme gives it the error color and icon.'),
    const _TypeOption(
      'PromoBarType (own class)',
      'const PromoBarType()',
      PromoBarType(),
      'A class of this app (code below): pink background, tag icon, 6 s, timeout bar on top, and it places its bars at the bottom.',
    ),
    const _TypeOption('CustomBarType (own class)', 'const CustomBarType()', CustomBarType(), 'Another class of this app, see lib/custom/custom_bar_type.dart.'),
    _TypeOption(
      'info, tweaked with copyWith',
      "FluentBarType.info.copyWith(\n  icon: const Icon(Icons.bolt_rounded),\n  position: FluentBarPosition.center,\n)",
      FluentBarType.info.copyWith(icon: const Icon(Icons.bolt_rounded), position: FluentBarPosition.center),
      'No class needed: copyWith takes a built-in type and replaces only what you name - here the icon (a bolt) and the position (center). Colors, duration and the rest stay as in info.',
    ),
  ];

  FluentBarPosition? _localPosition;

  FluentBarPosition get _previewPosition => _localPosition ?? _type.type.position ?? FluentBar.currentConfig.defaultPosition;

  ThemeOption _theme = AppState.themes[1];
  FluentBarThemeMode _mode = FluentBarThemeMode.system;
  late _TypeOption _type = _types[1];

  bool _tweak = false;
  double _radius = 24;
  double _margin = 16;

  late final LiveBar _bar = LiveBar(id: 'theme_preview', build: _build);

  @override
  void initState() {
    super.initState();
    _bar.attach();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bar.show());
  }

  @override
  void dispose() {
    _bar.dispose();
    super.dispose();
  }

  FluentBarTheme? _effectiveTheme() {
    final FluentBarTheme? base = _theme.theme;
    if (!_tweak) return base;

    final double radius = _radius;
    final double margin = _margin;
    return (base ?? FluentBarTheme.material).copyWith(
      borderRadius: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => BorderRadius.circular(radius),
      margin: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => EdgeInsets.all(margin),
    );
  }

  FluentBarItem<void> _build() {
    FluentBarItem<void> item = FluentBar.custom<void>(_type.type, 'Theme: ${_theme.label}. Type: ${_type.label}.', title: 'Preview').persistent().withAction('Action', closeOnAction: false);

    final FluentBarTheme? theme = _effectiveTheme();
    if (theme != null) item = item.withTheme(theme);
    if (_mode != FluentBarThemeMode.system) item = item.withThemeMode(_mode);
    if (_localPosition != null) item = item.at(_localPosition!);
    return item;
  }

  void _set(VoidCallback change) {
    setState(change);
    _bar.refresh();
  }

  String get _themeCode => switch (_theme.label) {
    'Platform (auto)' => 'FluentBarTheme.material',
    'Custom (neon)' => 'const CustomBarTheme()',
    'Liquid glass' => 'FluentBarTheme.liquidGlass',
    final String label => 'FluentBarTheme.${label.toLowerCase()}',
  };

  String get _oneBarCode {
    final List<String> lines = <String>[
      "FluentBar.custom(${_type.code}, 'Saved')",
      if (_theme.theme != null && !_tweak) '.withTheme($_themeCode)',
      if (_tweak) '.withTheme(tweaked)',
      if (_mode != FluentBarThemeMode.system) '.${_mode.name}()',
      if (_localPosition != null) '.at(FluentBarPosition.${_localPosition!.name})',
      '.show();',
    ];
    return '${lines.first}\n${lines.skip(1).map((String l) => '    $l').join('\n')}';
  }

  static final FluentBarType _festiveSuccess = FluentBarType.success.copyWith(
    icon: const Icon(Icons.celebration_rounded),
    duration: const Duration(seconds: 6),
    showTimeoutBar: true,
    entranceAnimation: FluentBarEntranceAnimation.elastic,
  );

  bool _isOverridden(FluentBarType type) => FluentBar.currentConfig.typeOverrides?.containsKey(type) ?? false;

  void _setOverride(FluentBarType type, FluentBarType replacement, bool enabled) => FluentBar.patchConfig((FluentBarConfig c) {
    final Map<FluentBarType, FluentBarType> overrides = <FluentBarType, FluentBarType>{...?c.typeOverrides};
    enabled ? overrides[type] = replacement : overrides.remove(type);
    return overrides.isEmpty ? c.copyWith(clearTypeOverrides: true) : c.copyWith(typeOverrides: overrides);
  });

  String get _overrideCode {
    final bool success = _isOverridden(FluentBarType.success);
    final bool warning = _isOverridden(FluentBarType.warning);
    if (!success && !warning) return '// Off: built-in types are used as they are.\nFluentBar.patchConfig((config) => config.copyWith(clearTypeOverrides: true));';

    return '''
FluentBar.patchConfig((config) => config.copyWith(
  typeOverrides: {${success ? '''

    // A built-in type with a few settings changed:
    FluentBarType.success: FluentBarType.success.copyWith(
      icon: const Icon(Icons.celebration_rounded),
      duration: const Duration(seconds: 6),
      showTimeoutBar: true,
      entranceAnimation: FluentBarEntranceAnimation.elastic,
    ),''' : ''}${warning ? '''

    // Your own type, written as a class:
    FluentBarType.warning: const MaintenanceBarType(),''' : ''}
  },
));${warning ? '''

class MaintenanceBarType extends FluentBarType {
  const MaintenanceBarType();

  @override String get name => 'maintenance';
  @override FluentBarType get kind => FluentBarType.warning;   // themes keep the warning colors
  @override Widget? get icon => const Icon(Icons.build_circle_outlined);
  @override Duration get duration => const Duration(seconds: 8);
  @override bool? get showTimeoutBar => true;
  @override bool? get dismissOnTap => false;
}''' : ''}''';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<FluentBarConfig>(
    valueListenable: FluentBar.configNotifier,
    builder: (BuildContext context, FluentBarConfig config, _) => DemoPage(
      title: 'Themes & types',
      subtitle:
          'A theme decides how a bar looks (shape, colors, fonts). A type decides what a bar is (info, success, your own) and how it behaves by default. The preview bar stays on screen and follows every setting below.',
      bottomNavigationBar: DemoLiveBarControl(_bar, showLabel: 'Show preview bar'),
      children: <Widget>[
        const DemoNote(
          'Everything on this screen applies to the preview bar only. The theme of the whole app is set on the Global config screen (tune icon in the top bar).',
          icon: Icons.info_outline,
        ),
        DemoSection(
          icon: Icons.format_color_fill_rounded,
          id: 'themes/theme',
          description: 'A single bar can use any theme and mode without touching the config.',
          code: _oneBarCode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<ThemeOption>(label: 'Theme', values: AppState.themes, selected: _theme, labelOf: (ThemeOption o) => o.label, onChanged: (ThemeOption v) => _set(() => _theme = v)),
              const SizedBox(height: 12),
              DemoChoice<FluentBarThemeMode>(label: 'Mode', values: FluentBarThemeMode.values, selected: _mode, onChanged: (FluentBarThemeMode v) => _set(() => _mode = v)),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.architecture_rounded,
          id: 'themes/tweak',
          description: 'No need to write a theme from scratch: copyWith replaces only the parts you name and keeps the rest. Turn it on and drag - the preview bar changes as you move the sliders.',
          code:
              '''
final FluentBarTheme tweaked = $_themeCode.copyWith(
  borderRadius: (context, type, mode) => BorderRadius.circular(${_radius.round()}),
  margin: (context, type, mode) => const EdgeInsets.all(${_margin.round()}),
);

FluentBar.custom(${_type.code}, 'Saved').withTheme(tweaked).show();''',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoSwitch(label: 'Apply the tweak', hint: 'Uses a copy of the selected theme with the values below', value: _tweak, onChanged: (bool v) => _set(() => _tweak = v)),
              DemoSlider(
                label: 'Corner radius',
                value: _radius,
                min: 0,
                max: 40,
                divisions: 20,
                format: (double v) => '${v.round()} px',
                onChanged: (double v) => _set(() {
                  _radius = v;
                  _tweak = true;
                }),
              ),
              DemoSlider(
                label: 'Margin around the bar',
                value: _margin,
                min: 0,
                max: 48,
                divisions: 12,
                format: (double v) => '${v.round()} px',
                onChanged: (double v) => _set(() {
                  _margin = v;
                  _tweak = true;
                }),
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.category_outlined,
          id: 'themes/type',
          description:
              'A type bundles defaults: color, icon, duration, position, animation, haptics. Declare it once, then use it like the built-in ones. A setting made on the bar itself always beats the type: pick PromoBarType (it says "bottom"), then set a position on the bar - the preview moves.',
          code:
              '''
class PromoBarType extends FluentBarType {
  const PromoBarType();

  @override String get name => 'promo';
  @override Color? get backgroundColor => const Color(0xFFBE185D);
  @override Widget? get icon => const Icon(Icons.local_offer_rounded);
  @override Duration get duration => const Duration(seconds: 6);
  @override FluentBarPosition? get position => FluentBarPosition.bottom;
  @override bool? get showTimeoutBar => true;
}

// Selected now:
FluentBar.custom(${_type.code}, 'Saved')${_localPosition == null ? '' : '\n    .at(FluentBarPosition.${_localPosition!.name})   // beats the position of the type'}
    .show();''',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoChoice<_TypeOption>(label: 'Type', values: _types, selected: _type, labelOf: (_TypeOption o) => o.label, onChanged: (_TypeOption v) => _set(() => _type = v)),
              const SizedBox(height: 8),
              DemoNote(_type.about, icon: Icons.info_outline),
              const SizedBox(height: 12),
              DemoChoice<FluentBarPosition?>(
                label: 'Position set on the bar itself (beats the type)',
                values: const <FluentBarPosition?>[null, FluentBarPosition.top, FluentBarPosition.center, FluentBarPosition.bottom],
                selected: _localPosition,
                labelOf: (FluentBarPosition? p) => p == null ? 'not set: the type decides (${(_type.type.position ?? FluentBar.currentConfig.defaultPosition).name})' : '.at(${p.name})',
                onChanged: (FluentBarPosition? v) => _set(() => _localPosition = v),
              ),
              const SizedBox(height: 12),
              DemoWrap(
                children: <Widget>[
                  DemoButton(
                    'Show all four built-in types',
                    icon: Icons.view_agenda_outlined,
                    onPressed: () {
                      for (final _TypeOption option in _types.take(4)) {
                        final FluentBarItem<void> item = FluentBar.custom<void>(
                          option.type,
                          'This is the ${option.label} type.',
                          title: option.label,
                          id: 'type_${option.label}',
                          duration: const Duration(seconds: 2),
                        );
                        final FluentBarTheme? theme = _effectiveTheme();
                        (theme == null ? item : item.withTheme(theme)).at(_previewPosition == FluentBarPosition.bottom ? FluentBarPosition.top : FluentBarPosition.bottom).show();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        DemoSection(
          icon: Icons.swap_horiz_rounded,
          id: 'themes/type-overrides',
          description:
              'typeOverrides replaces a type for the whole app, so existing calls like FluentBar.showSuccess(...) stay untouched. The replacement can be a tweaked built-in type or a type you wrote yourself. This one is a global setting by nature.',
          code: _overrideCode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DemoSwitch(
                label: 'success -> success.copyWith(...)',
                hint: 'Same type, new icon, 6 s, timeout bar, elastic entrance',
                value: _isOverridden(FluentBarType.success),
                onChanged: (bool v) => _setOverride(FluentBarType.success, _festiveSuccess, v),
              ),
              DemoSwitch(
                label: 'warning -> MaintenanceBarType()',
                hint: 'A custom class: own icon, 8 s, timeout bar, no tap-to-dismiss, scale entrance',
                value: _isOverridden(FluentBarType.warning),
                onChanged: (bool v) => _setOverride(FluentBarType.warning, const MaintenanceBarType(), v),
              ),
              const SizedBox(height: 8),
              DemoWrap(
                children: <Widget>[
                  DemoButton(
                    'FluentBar.showSuccess(...)',
                    tone: DemoTone.success,
                    onPressed: () => FluentBar.showSuccess('The call is the same - the type is not.', id: 'override_success'),
                  ),
                  DemoButton(
                    'FluentBar.showWarning(...)',
                    tone: DemoTone.warning,
                    onPressed: () => FluentBar.showWarning('Scheduled maintenance tonight at 02:00.', title: 'Heads up', id: 'override_warning'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

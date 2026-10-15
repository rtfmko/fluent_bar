import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_kit.dart';

enum _Setting { duration, position, timeoutBar, themeMode }

enum _Level { bar, type, config }

class _Option {
  final String label;
  final Object value;
  final String code;

  const _Option(this.label, this.value, this.code);
}

class _SettingInfo {
  final String title;
  final String onBar;
  final String onType;
  final String inConfig;

  final List<_Option> options;

  const _SettingInfo({required this.title, required this.onBar, required this.onType, required this.inConfig, required this.options});
}

const Map<_Setting, _SettingInfo> _settings = <_Setting, _SettingInfo>{
  _Setting.duration: _SettingInfo(
    title: 'Lifetime',
    onBar: '.withDuration(...)',
    onType: 'Duration? get duration',
    inConfig: 'defaultDuration',
    options: <_Option>[
      _Option('4 s', Duration(seconds: 4), 'const Duration(seconds: 4)'),
      _Option('2 s', Duration(seconds: 2), 'const Duration(seconds: 2)'),
      _Option('8 s', Duration(seconds: 8), 'const Duration(seconds: 8)'),
    ],
  ),
  _Setting.position: _SettingInfo(
    title: 'Position',
    onBar: '.at(...)',
    onType: 'FluentBarPosition? get position',
    inConfig: 'defaultPosition',
    options: <_Option>[
      _Option('top', FluentBarPosition.top, 'FluentBarPosition.top'),
      _Option('bottom', FluentBarPosition.bottom, 'FluentBarPosition.bottom'),
      _Option('center', FluentBarPosition.center, 'FluentBarPosition.center'),
    ],
  ),
  _Setting.timeoutBar: _SettingInfo(
    title: 'Countdown line',
    onBar: '.withTimeoutBar() / .withoutTimeoutBar()',
    onType: 'bool? get showTimeoutBar',
    inConfig: 'defaultShowTimeoutBar',
    options: <_Option>[_Option('off', false, 'false'), _Option('on', true, 'true')],
  ),
  _Setting.themeMode: _SettingInfo(
    title: 'Light / dark',
    onBar: '.withThemeMode(...)',
    onType: 'FluentBarThemeMode? get themeMode',
    inConfig: 'defaultThemeMode',
    options: <_Option>[
      _Option('system', FluentBarThemeMode.system, 'FluentBarThemeMode.system'),
      _Option('light', FluentBarThemeMode.light, 'FluentBarThemeMode.light'),
      _Option('dark', FluentBarThemeMode.dark, 'FluentBarThemeMode.dark'),
    ],
  ),
};

class OverridesScreen extends StatefulWidget {
  const OverridesScreen({super.key});

  @override
  State<OverridesScreen> createState() => _OverridesScreenState();
}

class _OverridesScreenState extends State<OverridesScreen> {
  static const String _barId = 'who_wins';

  // Read in initState: the screen changes the config and must know what to put back.
  late final FluentBarConfig _configBefore;

  _Setting _setting = _Setting.duration;

  _Option? _onBar;
  _Option? _onType;
  late _Option _inConfig = _info.options.first;

  _SettingInfo get _info => _settings[_setting]!;

  _Level get _winner => _onBar != null ? _Level.bar : (_onType != null ? _Level.type : _Level.config);

  _Option get _result => _onBar ?? _onType ?? _inConfig;

  @override
  void initState() {
    super.initState();
    _configBefore = FluentBar.currentConfig;
  }

  @override
  void dispose() {
    FluentBar.close(_barId);
    FluentBar.patchConfig(
      (FluentBarConfig config) => config.copyWith(
        defaultDuration: _configBefore.defaultDuration,
        defaultPosition: _configBefore.defaultPosition,
        defaultShowTimeoutBar: _configBefore.defaultShowTimeoutBar,
        defaultThemeMode: _configBefore.defaultThemeMode,
      ),
    );
    super.dispose();
  }

  void _select(_Setting setting) {
    _applyConfig(_info.options.first);
    setState(() {
      _setting = setting;
      _onBar = null;
      _onType = null;
      _inConfig = _info.options.first;
    });
    _refresh();
  }

  void _set(_Level level, _Option? option) {
    setState(() {
      switch (level) {
        case _Level.bar:
          _onBar = option;
        case _Level.type:
          _onType = option;
        case _Level.config:
          _inConfig = option ?? _info.options.first;
      }
    });
    if (level == _Level.config) _applyConfig(_inConfig);
    _refresh();
  }

  // Level 3: the global config.
  void _applyConfig(_Option option) => FluentBar.patchConfig(
    (FluentBarConfig config) => switch (_setting) {
      _Setting.duration => config.copyWith(defaultDuration: option.value as Duration),
      _Setting.position => config.copyWith(defaultPosition: option.value as FluentBarPosition),
      _Setting.timeoutBar => config.copyWith(defaultShowTimeoutBar: option.value as bool),
      _Setting.themeMode => config.copyWith(defaultThemeMode: option.value as FluentBarThemeMode),
    },
  );

  // Level 2: a type. A value that is not passed stays null and the config is asked.
  FluentBarType _type() {
    final Object? value = _onType?.value;
    return switch (_setting) {
      _Setting.duration => FluentBarType.info.copyWith(duration: value as Duration?),
      _Setting.position => FluentBarType.info.copyWith(position: value as FluentBarPosition?),
      _Setting.timeoutBar => FluentBarType.info.copyWith(showTimeoutBar: value as bool?),
      _Setting.themeMode => FluentBarType.info.copyWith(themeMode: value as FluentBarThemeMode?),
    };
  }

  // Level 1: the bar itself.
  FluentBarItem<void> _bar() {
    FluentBarItem<void> item = FluentBar.custom<void>(_type(), '${_info.title}: ${_result.label}', title: 'Decided by ${_levelName(_winner)}', id: _barId);

    final Object? value = _onBar?.value;
    if (value != null) {
      item = switch (_setting) {
        _Setting.duration => item.withDuration(value as Duration),
        _Setting.position => item.at(value as FluentBarPosition),
        _Setting.timeoutBar => (value as bool) ? item.withTimeoutBar() : item.withoutTimeoutBar(),
        _Setting.themeMode => item.withThemeMode(value as FluentBarThemeMode),
      };
    }

    if (_setting == _Setting.duration) item = item.withTimeoutBar();

    return item.withDuplicatePolicy(FluentBarDuplicatePolicy.updateAndResetTimer);
  }

  void _show() => _bar().show();

  void _refresh() {
    if (FluentBar.find(_barId) != null) _show();
  }

  static String _levelName(_Level level) => switch (level) {
    _Level.bar => 'the bar',
    _Level.type => 'its type',
    _Level.config => 'the config',
  };

  String _code() {
    final StringBuffer code = StringBuffer();
    final _SettingInfo info = _info;

    code.writeln('// 3. The config - for every bar.');
    code.writeln('FluentBar.patchConfig((config) => config.copyWith(${info.inConfig}: ${_inConfig.code}));');
    code.writeln();
    code.writeln('// 2. The type - for one kind of bar.');
    if (_onType == null) {
      code.writeln('const type = FluentBarType.info;   // does not set it: asks the config');
    } else {
      final String field = info.onType.split(' ').last;
      code.writeln('final type = FluentBarType.info.copyWith($field: ${_onType!.code});');
    }
    code.writeln();
    code.writeln('// 1. The bar.');
    code.write("FluentBar.custom(type, 'Hello')");
    if (_onBar != null) {
      code.write(switch (_setting) {
        _Setting.duration => '.withDuration(${_onBar!.code})',
        _Setting.position => '.at(${_onBar!.code})',
        _Setting.timeoutBar => _onBar!.value == true ? '.withTimeoutBar()' : '.withoutTimeoutBar()',
        _Setting.themeMode => '.withThemeMode(${_onBar!.code})',
      });
    }
    code.writeln('.show();');
    code.writeln();
    code.write('// Result: ${_result.label} - decided by ${_levelName(_winner)}.');
    return code.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final _SettingInfo info = _info;

    return DemoPage(
      title: 'Overriding settings',
      subtitle:
          'Every setting is looked up in the same order: the bar, then its type, then the global config. The first level that sets a value wins. '
          'Set the same setting on several levels below and watch which one decides.',
      bottomNavigationBar: DemoBottomBar(
        child: Row(
          children: <Widget>[
            Expanded(
              child: DemoButton('Show the bar', icon: Icons.play_arrow_rounded, tone: DemoTone.primary, onPressed: _show),
            ),
            const SizedBox(width: 12),
            DemoButton('Reset', icon: Icons.restart_alt_rounded, onPressed: () => _select(_setting)),
          ],
        ),
      ),
      children: <Widget>[
        DemoSection(
          id: 'overrides/who-wins',
          icon: Icons.emoji_events_outlined,
          description: 'Pick a setting, then give it a value on any of the three levels. While the bar is on screen it follows every change.',
          code: _code(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DemoChoice<_Setting>(label: 'Setting', values: _Setting.values, selected: _setting, labelOf: (_Setting s) => _settings[s]!.title, onChanged: _select),
              const SizedBox(height: 14),
              _LevelCard(number: 1, title: 'The bar', hint: info.onBar, level: _Level.bar, winner: _winner, options: info.options, selected: _onBar, onChanged: (_Option? o) => _set(_Level.bar, o)),
              const _Arrow(),
              _LevelCard(
                number: 2,
                title: 'Its type',
                hint: info.onType,
                level: _Level.type,
                winner: _winner,
                options: info.options,
                selected: _onType,
                onChanged: (_Option? o) => _set(_Level.type, o),
              ),
              const _Arrow(),
              _LevelCard(
                number: 3,
                title: 'The config',
                hint: info.inConfig,
                level: _Level.config,
                winner: _winner,
                options: info.options,
                selected: _inConfig,
                isRequired: true,
                onChanged: (_Option? o) => _set(_Level.config, o),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.emoji_events_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            TextSpan(text: '${info.title}: '),
                            TextSpan(
                              text: _result.label,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: '  -  decided by ${_levelName(_winner)}'),
                          ],
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const DemoSection(
          id: 'overrides/where',
          icon: Icons.account_tree_outlined,
          description: 'Choose the level by how many bars need the value. If the same .with...() call appears on many bars, move it up a level.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Where('Every bar', 'FluentBar.patchConfig((c) => c.copyWith(defaultPosition: FluentBarPosition.bottom));'),
              _Where('A built-in type everywhere', 'config.copyWith(typeOverrides: {FluentBarType.error: FluentBarType.error.copyWith(duration: ...)})'),
              _Where('A group of bars', 'class SaleType extends FluentBarType { ... }   // or FluentBarType.info.copyWith(...)'),
              _Where('One bar', "FluentBar.info('Saved').atBottom().withDuration(...).show();"),
              _Where('A bar that is on screen', 'entry.patchBehavior((b) => b.copyWith(position: ...));\nentry.patchAppearance((a) => a.copyWith(backgroundColor: ...));'),
              _Where('The look of a theme', 'FluentBarTheme.material.copyWith(borderRadius: (context, type, mode) => ...)'),
              _Where('Back to the default', 'config.copyWith(clearDefaultTheme: true)   // null keeps a value, a clear... flag removes it'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LevelCard extends StatelessWidget {
  final int number;
  final String title;
  final String hint;
  final _Level level;
  final _Level winner;
  final List<_Option> options;
  final _Option? selected;
  final bool isRequired;
  final ValueChanged<_Option?> onChanged;

  const _LevelCard({
    required this.number,
    required this.title,
    required this.hint,
    required this.level,
    required this.winner,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool wins = level == winner;
    final bool isOverridden = level.index > winner.index;
    final Color accent = wins ? scheme.primary : scheme.outlineVariant;

    final String status = wins ? 'WINS' : (isOverridden ? 'overridden by a level above' : 'not set - asks the next level');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: wins ? scheme.primary.withValues(alpha: 0.08) : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: wins ? 2 : 1),
      ),
      child: Opacity(
        opacity: isOverridden ? 0.6 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 11,
                  backgroundColor: wins ? scheme.primary : scheme.surfaceContainerHighest,
                  child: Text(
                    '$number',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: wins ? scheme.onPrimary : scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                Flexible(
                  child: Text(
                    status,
                    textAlign: TextAlign.end,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: wins ? scheme.primary : scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                if (!isRequired) ChoiceChip(label: const Text('not set'), selected: selected == null, selectedColor: scheme.surfaceContainerHighest, onSelected: (_) => onChanged(null)),
                for (final _Option option in options)
                  ChoiceChip(
                    label: Text(isRequired && identical(option, options.first) ? '${option.label} (default)' : option.label),
                    selected: identical(option, selected),
                    selectedColor: scheme.primaryContainer,
                    onSelected: (_) => onChanged(option),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Icon(Icons.arrow_downward_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _Where extends StatelessWidget {
  final String scope;
  final String code;

  const _Where(this.scope, this.code);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(scope, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code,
                style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.4, color: scheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

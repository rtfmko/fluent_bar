import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../widgets/demo_kit.dart';

enum _Kind { info, success, warning, error }

enum _Progress { none, linear, circular }

enum _ProgressKind { percent, fraction, bytes, indeterminate }

enum _Background { theme, purple, teal, black }

class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  final TextEditingController _title = TextEditingController(text: 'Backup finished');
  final TextEditingController _message = TextEditingController(text: 'All 248 files are safely stored.');
  final TextEditingController _action = TextEditingController(text: 'View');

  _Kind _kind = _Kind.success;
  bool _icon = true;
  bool _customIcon = false;

  double _maxLines = 0;
  _Background _background = _Background.theme;

  bool _hasAction = false;
  bool _closeOnAction = false;
  bool _asyncAction = true;
  bool _cancelButton = false;

  double _seconds = 6;
  bool _persistent = false;
  bool _timeoutBar = true;
  FluentBarTimeoutBarPosition _timeoutPosition = FluentBarTimeoutBarPosition.bottom;
  FluentBarTimeoutBarDirection _timeoutDirection = FluentBarTimeoutBarDirection.forward;

  FluentBarPosition _position = FluentBarPosition.top;
  ThemeOption _theme = AppState.themes.first;
  FluentBarThemeMode _mode = FluentBarThemeMode.system;
  FluentBarEntranceAnimation _entrance = FluentBarEntranceAnimation.slide;
  bool _safeArea = true;

  FluentBarPriority _priority = FluentBarPriority.normal;
  bool _forced = false;

  bool _swipe = true;
  bool _tapToClose = true;
  bool _pauseOnTouch = true;
  bool _closeButton = false;
  FluentBarSemantics _semantics = FluentBarSemantics.announce;
  FluentBarHapticType _haptic = FluentBarHapticType.none;

  _Progress _progress = _Progress.none;
  _ProgressKind _progressKind = _ProgressKind.percent;
  double _progressValue = 0.4;
  bool _progressText = true;
  FluentBarProgressPosition _progressPosition = FluentBarProgressPosition.bottom;
  FluentBarProgressTextEffect _progressEffect = FluentBarProgressTextEffect.count;

  bool _hideSuccess = false;
  double _successSeconds = 1.5;

  static const int _bytesTotal = 52428800;
  final DemoProgressRunner _runner = DemoProgressRunner(loop: true);

  bool get _autoProgress => _runner.isRunning;

  Duration? get _successDuration => _hideSuccess ? Duration(milliseconds: (_successSeconds * 1000).round()) : null;

  late final LiveBar _bar = LiveBar(id: 'playground', build: _build);

  @override
  void initState() {
    super.initState();
    _bar.attach();
  }

  @override
  void dispose() {
    _runner.dispose();
    _bar.dispose();
    _title.dispose();
    _message.dispose();
    _action.dispose();
    super.dispose();
  }

  static Color? _colorOf(_Background background) => switch (background) {
    _Background.theme => null,
    _Background.purple => const Color(0xFF6D28D9),
    _Background.teal => const Color(0xFF0F766E),
    _Background.black => const Color(0xFF111827),
  };

  FluentBarProgressState get _progressState => switch (_progressKind) {
    _ProgressKind.percent => FluentBarProgressState.value(_progressValue),
    _ProgressKind.fraction => FluentBarProgressState.fraction((_progressValue * 100).round(), 100),
    _ProgressKind.bytes => FluentBarProgressState.bytes((_progressValue * _bytesTotal).round(), _bytesTotal),
    _ProgressKind.indeterminate => const FluentBarProgressState.indeterminate(),
  };

  String get _messageText => _message.text.isEmpty ? 'Message' : _message.text;

  String get _actionText => _action.text.isEmpty ? 'Action' : _action.text;

  FluentBarItem<void> _build() {
    FluentBarItem<void> item = switch (_kind) {
      _Kind.info => FluentBar.info<void>(_messageText),
      _Kind.success => FluentBar.success<void>(_messageText),
      _Kind.warning => FluentBar.warning<void>(_messageText),
      _Kind.error => FluentBar.error<void>(_messageText),
    };

    if (_maxLines > 0) {
      item = item.copyWith(
        appearance: FluentBarAppearance<void>(maxMessageLines: _maxLines.round(), messageOverflow: TextOverflow.ellipsis),
      );
    }

    if (_title.text.isNotEmpty) item = item.withTitle(_title.text);
    if (!_icon) item = item.withoutIcon();
    if (_icon && _customIcon) item = item.withIcon(const Icon(Icons.rocket_launch_rounded), color: Colors.amberAccent);
    if (_colorOf(_background) != null) item = item.withBackground(_colorOf(_background)!).dark();

    if (_hasAction) {
      item = item.withAction(
        _actionText,
        closeOnAction: _closeOnAction,
        onPressed: (_, _) async {
          if (_asyncAction) await Future<void>.delayed(const Duration(seconds: 2));
          FluentBar.showToast('Action finished', id: 'playground_action');
        },
      );
    }

    item = _persistent ? item.persistent() : item.withDuration(Duration(milliseconds: (_seconds * 1000).round()));
    if (_timeoutBar && !_persistent) item = item.withTimeoutBar(position: _timeoutPosition, direction: _timeoutDirection);

    item = item.at(_position);
    if (_theme.theme != null) item = item.withTheme(_theme.theme!);
    if (_mode != FluentBarThemeMode.system && _colorOf(_background) == null) item = item.withThemeMode(_mode);
    if (_entrance != FluentBarEntranceAnimation.slide) item = item.withEntrance(_entrance);
    if (!_safeArea) item = item.withoutSafeArea();

    if (_priority != FluentBarPriority.normal) item = item.withPriority(_priority);
    if (_forced) item = item.forced();

    if (!_swipe) item = item.swipeable(false);
    if (!_tapToClose) item = item.dismissOnTap(false);
    if (!_pauseOnTouch) item = item.pauseOnTouch(false);
    if (_haptic != FluentBarHapticType.none) item = item.withHaptic(_haptic);
    if (_closeButton) item = item.withCloseButton();
    if (_semantics != FluentBarSemantics.announce) item = item.withSemantics(_semantics);
    if (_cancelButton && _progress != _Progress.none) item = item.withCancelButton('Cancel', onCancel: () => Future<void>.delayed(const Duration(seconds: 1)), canceledMessage: 'Cancelled');

    return switch (_progress) {
      _Progress.none => item,
      _Progress.linear => item.withLinearProgress(state: _progressState, showText: _progressText, position: _progressPosition, textEffect: _progressEffect, successIconDuration: _successDuration),
      _Progress.circular => item.withCircularProgress(state: _progressState, showText: _progressText, position: _progressPosition, textEffect: _progressEffect, successIconDuration: _successDuration),
    };
  }

  String _code() {
    String quote(String text) => "'${text.replaceAll("'", r"\'")}'";

    final List<String> lines = <String>['FluentBar.${_kind.name}(${quote(_messageText)})'];
    void add(String line) => lines.add(line);

    if (_maxLines > 0) add('.copyWith(appearance: const FluentBarAppearance(maxMessageLines: ${_maxLines.round()}, messageOverflow: TextOverflow.ellipsis))');
    if (_title.text.isNotEmpty) add('.withTitle(${quote(_title.text)})');
    if (!_icon) add('.withoutIcon()');
    if (_icon && _customIcon) add('.withIcon(const Icon(Icons.rocket_launch_rounded), color: Colors.amberAccent)');
    if (_colorOf(_background) != null) add('.withBackground(const Color(0x${_colorOf(_background)!.toARGB32().toRadixString(16).toUpperCase()})).dark()');

    if (_hasAction) {
      add('.withAction(${quote(_actionText)}, ${_closeOnAction ? '' : 'closeOnAction: false, '}onPressed: (controller, payload) ${_asyncAction ? 'async { await doWork(); }' : '{ doWork(); }'})');
    }

    if (_persistent) {
      add('.persistent()');
    } else {
      add('.withDuration(const Duration(milliseconds: ${(_seconds * 1000).round()}))');
      if (_timeoutBar) {
        final List<String> args = <String>[
          if (_timeoutPosition != FluentBarTimeoutBarPosition.bottom) 'position: FluentBarTimeoutBarPosition.${_timeoutPosition.name}',
          if (_timeoutDirection != FluentBarTimeoutBarDirection.forward) 'direction: FluentBarTimeoutBarDirection.${_timeoutDirection.name}',
        ];
        add('.withTimeoutBar(${args.join(', ')})');
      }
    }

    if (_position != FluentBarPosition.top) add('.at(FluentBarPosition.${_position.name})');
    if (_theme.theme != null) {
      add(
        '.withTheme(${switch (_theme.label) {
          'Custom (neon)' => 'const CustomBarTheme()',
          'Liquid glass' => 'FluentBarTheme.liquidGlass',
          final String label => 'FluentBarTheme.${label.toLowerCase()}',
        }})',
      );
    }
    if (_mode != FluentBarThemeMode.system && _colorOf(_background) == null) add('.${_mode.name}()');
    if (_entrance != FluentBarEntranceAnimation.slide) add('.withEntrance(FluentBarEntranceAnimation.${_entrance.name})');
    if (!_safeArea) add('.withoutSafeArea()');

    if (_priority != FluentBarPriority.normal) add('.withPriority(FluentBarPriority.${_priority.name})');
    if (_forced) add('.forced()');

    if (!_swipe) add('.swipeable(false)');
    if (!_tapToClose) add('.dismissOnTap(false)');
    if (!_pauseOnTouch) add('.pauseOnTouch(false)');
    if (_haptic != FluentBarHapticType.none) add('.withHaptic(FluentBarHapticType.${_haptic.name})');
    if (_closeButton) add('.withCloseButton()');
    if (_semantics != FluentBarSemantics.announce) add('.withSemantics(FluentBarSemantics.${_semantics.name})');
    if (_cancelButton && _progress != _Progress.none) add(".withCancelButton('Cancel', onCancel: () => task.cancel(), canceledMessage: 'Cancelled')");

    if (_progress != _Progress.none) {
      final bool isLinear = _progress == _Progress.linear;
      final FluentBarProgressPosition defaultPosition = isLinear ? FluentBarProgressPosition.bottom : FluentBarProgressPosition.replaceIcon;
      final List<String> args = <String>[
        switch (_progressKind) {
          _ProgressKind.percent => 'value: ${_progressValue.toStringAsFixed(2)}',
          _ProgressKind.fraction => 'state: const FluentBarProgressState.fraction(${(_progressValue * 100).round()}, 100)',
          _ProgressKind.bytes => 'state: const FluentBarProgressState.bytes(${(_progressValue * _bytesTotal).round()}, $_bytesTotal)',
          _ProgressKind.indeterminate => '',
        },
        if (_progressText) 'showText: true',
        if (_progressPosition != defaultPosition) 'position: FluentBarProgressPosition.${_progressPosition.name}',
        if (_progressEffect != FluentBarProgressTextEffect.count) 'textEffect: FluentBarProgressTextEffect.${_progressEffect.name}',
        if (_hideSuccess) 'successIconDuration: const Duration(milliseconds: ${_successDuration!.inMilliseconds})',
      ].where((String a) => a.isNotEmpty).toList();
      add('.${isLinear ? 'withLinearProgress' : 'withCircularProgress'}(${args.join(', ')})');
    }
    add('.show();');

    return '${lines.first}\n${lines.skip(1).map((String line) => '    $line').join('\n')}';
  }

  void _set(VoidCallback change) {
    setState(change);
    _bar.refresh();
  }

  void _applyProgress(double value) {
    setState(() => _progressValue = value);
    _bar.entry?.controller.updateProgress(_progressState);
  }

  void _onBar(void Function(FluentBarEntry<void> entry) action) {
    final FluentBarEntry<void>? entry = _bar.entry;
    entry == null ? FluentBar.showToast('Show the bar first', id: 'playground_hint') : action(entry);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Playground',
    subtitle: 'While the bar is on screen, every switch below changes it live through its controller. Only the settings that differ from the defaults end up in the generated chain.',
    bottomNavigationBar: DemoLiveBarControl(_bar),
    children: <Widget>[
      DemoSection(icon: Icons.code_rounded, id: 'playground/code', child: DemoCode(_code(), initiallyExpanded: true)),
      DemoSection(
        icon: Icons.text_fields_rounded,
        id: 'playground/content',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (optional)'),
              onChanged: (_) => _set(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              controller: _message,
              decoration: const InputDecoration(labelText: 'Message'),
              onChanged: (_) => _set(() {}),
            ),
            const SizedBox(height: 8),
            DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Paste a long message',
                  icon: Icons.notes_rounded,
                  onPressed: () {
                    _message.text =
                        'Your backup finished, but 3 of the 248 files could not be copied because they were open in another app. Close those apps and run the backup again to include them.';
                    _set(() {});
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            DemoSlider(
              label: 'Max message lines',
              value: _maxLines,
              min: 0,
              max: 6,
              divisions: 6,
              format: (double v) => v == 0 ? 'from the theme' : '${v.round()}',
              onChanged: (double v) => _set(() => _maxLines = v),
            ),
            const SizedBox(height: 6),
            DemoChoice<_Kind>(label: 'Type', values: _Kind.values, selected: _kind, onChanged: (_Kind v) => _set(() => _kind = v)),
            const SizedBox(height: 12),
            DemoChoice<_Background>(
              label: 'Background',
              values: _Background.values,
              selected: _background,
              labelOf: (_Background b) => b == _Background.theme ? 'from theme' : b.name,
              onChanged: (_Background v) => _set(() => _background = v),
            ),
            const SizedBox(height: 8),
            DemoSwitch(label: 'Icon', value: _icon, onChanged: (bool v) => _set(() => _icon = v)),
            if (_icon) DemoSwitch(label: 'Own icon', hint: 'withIcon(...) instead of the icon of the type', value: _customIcon, onChanged: (bool v) => _set(() => _customIcon = v)),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.smart_button_outlined,
        id: 'playground/action',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoSwitch(label: 'Show an action', value: _hasAction, onChanged: (bool v) => _set(() => _hasAction = v)),
            DemoSwitch(
              label: 'Cancel button for the progress',
              hint: 'Takes the place of the action; needs a progress (see below)',
              value: _cancelButton,
              onChanged: (bool v) => _set(() => _cancelButton = v),
            ),
            if (_hasAction) ...<Widget>[
              const SizedBox(height: 6),
              TextField(
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                controller: _action,
                decoration: const InputDecoration(labelText: 'Action label'),
                onChanged: (_) => _set(() {}),
              ),
              const SizedBox(height: 8),
              DemoSwitch(label: 'Close the bar on action', value: _closeOnAction, onChanged: (bool v) => _set(() => _closeOnAction = v)),
              DemoSwitch(label: 'Async action (2 s)', hint: 'Shows a loader on the button and holds the countdown', value: _asyncAction, onChanged: (bool v) => _set(() => _asyncAction = v)),
            ],
          ],
        ),
      ),
      DemoSection(
        icon: Icons.timer_outlined,
        id: 'playground/lifetime',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoSwitch(label: 'Persistent', hint: 'Stays until closed by the user or from code', value: _persistent, onChanged: (bool v) => _set(() => _persistent = v)),
            if (!_persistent) ...<Widget>[
              DemoSlider(label: 'Duration', value: _seconds, min: 1, max: 15, divisions: 28, format: (double v) => '${v.toStringAsFixed(1)} s', onChanged: (double v) => _set(() => _seconds = v)),
              DemoSwitch(label: 'Timeout bar', hint: 'A thin line that shows the time left', value: _timeoutBar, onChanged: (bool v) => _set(() => _timeoutBar = v)),
              if (_timeoutBar) ...<Widget>[
                const SizedBox(height: 8),
                DemoChoice<FluentBarTimeoutBarPosition>(
                  label: 'Timeout bar position',
                  values: FluentBarTimeoutBarPosition.values,
                  selected: _timeoutPosition,
                  onChanged: (FluentBarTimeoutBarPosition v) => _set(() => _timeoutPosition = v),
                ),
                const SizedBox(height: 12),
                DemoChoice<FluentBarTimeoutBarDirection>(
                  label: 'Timeout bar direction',
                  values: FluentBarTimeoutBarDirection.values,
                  selected: _timeoutDirection,
                  onChanged: (FluentBarTimeoutBarDirection v) => _set(() => _timeoutDirection = v),
                ),
              ],
            ],
          ],
        ),
      ),
      DemoSection(
        icon: Icons.place_outlined,
        id: 'playground/look',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarPosition>(label: 'Position', values: FluentBarPosition.values, selected: _position, onChanged: (FluentBarPosition v) => _set(() => _position = v)),
            const SizedBox(height: 12),
            DemoChoice<ThemeOption>(
              label: 'Theme',
              values: AppState.themes,
              selected: _theme,
              labelOf: (ThemeOption o) => o.theme == null ? 'from config' : o.label,
              onChanged: (ThemeOption v) => _set(() => _theme = v),
            ),
            const SizedBox(height: 12),
            if (_colorOf(_background) == null)
              DemoChoice<FluentBarThemeMode>(label: 'Mode', values: FluentBarThemeMode.values, selected: _mode, onChanged: (FluentBarThemeMode v) => _set(() => _mode = v)),
            const SizedBox(height: 12),
            DemoChoice<FluentBarEntranceAnimation>(
              label: 'Entrance (seen on the next show)',
              values: FluentBarEntranceAnimation.values,
              selected: _entrance,
              onChanged: (FluentBarEntranceAnimation v) => _set(() => _entrance = v),
            ),
            const SizedBox(height: 8),
            DemoSwitch(label: 'Respect safe area', value: _safeArea, onChanged: (bool v) => _set(() => _safeArea = v)),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.touch_app_outlined,
        id: 'playground/gestures',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoSwitch(label: 'Swipe to dismiss', value: _swipe, onChanged: (bool v) => _set(() => _swipe = v)),
            DemoSwitch(label: 'Tap to dismiss', value: _tapToClose, onChanged: (bool v) => _set(() => _tapToClose = v)),
            DemoSwitch(label: 'Pause while touched', value: _pauseOnTouch, onChanged: (bool v) => _set(() => _pauseOnTouch = v)),
            DemoSwitch(label: 'Close button', value: _closeButton, onChanged: (bool v) => _set(() => _closeButton = v)),
            const SizedBox(height: 8),
            DemoChoice<FluentBarSemantics>(label: 'For a screen reader', values: FluentBarSemantics.values, selected: _semantics, onChanged: (FluentBarSemantics v) => _set(() => _semantics = v)),
            const SizedBox(height: 8),
            DemoChoice<FluentBarHapticType>(
              label: 'Haptic on show (real device)',
              values: FluentBarHapticType.values,
              selected: _haptic,
              onChanged: (FluentBarHapticType v) => _set(() => _haptic = v),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.reorder_rounded,
        id: 'playground/queue',
        description: 'Matters when other bars are waiting: priority decides the order, a forced bar replaces the one on screen. Applied on the next show.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarPriority>(label: 'Priority', values: FluentBarPriority.values, selected: _priority, onChanged: (FluentBarPriority v) => _set(() => _priority = v)),
            const SizedBox(height: 8),
            DemoSwitch(label: 'Forced', value: _forced, onChanged: (bool v) => _set(() => _forced = v)),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.downloading_rounded,
        id: 'playground/progress',
        description: 'A bar with unfinished progress stays on screen whatever the duration is. Drag the value to 100% to see it complete.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<_Progress>(
              label: 'Indicator',
              values: _Progress.values,
              selected: _progress,
              onChanged: (_Progress v) => _set(() {
                _progress = v;
                if (v == _Progress.none) _runner.stop();
                _progressPosition = v == _Progress.circular ? FluentBarProgressPosition.replaceIcon : FluentBarProgressPosition.bottom;
              }),
            ),
            if (_progress != _Progress.none) ...<Widget>[
              const SizedBox(height: 12),
              DemoChoice<_ProgressKind>(
                label: 'State',
                values: _ProgressKind.values,
                selected: _progressKind,
                onChanged: (_ProgressKind v) => _set(() {
                  _progressKind = v;
                  if (v == _ProgressKind.indeterminate) _runner.stop();
                }),
              ),
              if (_progressKind != _ProgressKind.indeterminate) ...<Widget>[
                const SizedBox(height: 12),
                DemoSlider(
                  label: 'Value',
                  value: _progressValue,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  format: (double v) => switch (_progressKind) {
                    _ProgressKind.fraction => '${(v * 100).round()} / 100',
                    _ProgressKind.bytes => FluentBarProgressState.bytes((v * _bytesTotal).round(), _bytesTotal).format(),
                    _ => '${(v * 100).round()}%',
                  },
                  onChanged: _applyProgress,
                ),
                DemoSwitch(
                  label: 'Auto progress',
                  hint: 'The value runs to 100% by itself, shows the result and starts over',
                  value: _autoProgress,
                  onChanged: (bool v) {
                    v ? _runner.start(_applyProgress, from: _progressValue) : _runner.stop();
                    setState(() {});
                  },
                ),
                if (_autoProgress)
                  DemoChoice<DemoProgressMotion>(
                    label: 'Motion',
                    values: DemoProgressMotion.values,
                    selected: _runner.motion,
                    labelOf: (DemoProgressMotion m) => m == DemoProgressMotion.smooth ? 'smoothly (1% at a time)' : 'in jumps (5-20% at a time)',
                    onChanged: (DemoProgressMotion v) => setState(() => _runner.motion = v),
                  ),
                const SizedBox(height: 8),
              ],
              DemoChoice<FluentBarProgressPosition>(
                label: 'Position',
                values: FluentBarProgressPosition.values,
                selected: _progressPosition,
                onChanged: (FluentBarProgressPosition v) => _set(() => _progressPosition = v),
              ),
              const SizedBox(height: 8),
              DemoSwitch(label: 'Show text', value: _progressText, onChanged: (bool v) => _set(() => _progressText = v)),
              if (_progressText && _progressPosition == FluentBarProgressPosition.replaceIcon && _progressKind != _ProgressKind.percent) ...<Widget>[
                const DemoNote('In place of the icon the text is always a percent: a fraction or bytes would not fit there. Bytes without a total show no text.'),
                const SizedBox(height: 8),
              ],
              DemoSwitch(
                label: 'Hide the success icon after a while',
                hint: 'Off: it stays until the bar closes. On: the indicator collapses, or the regular icon returns if it replaced the icon',
                value: _hideSuccess,
                onChanged: (bool v) => _set(() => _hideSuccess = v),
              ),
              if (_hideSuccess) ...<Widget>[
                DemoSlider(
                  label: 'Success icon stays for',
                  value: _successSeconds,
                  min: 0.5,
                  max: 5,
                  divisions: 9,
                  format: (double v) => '${v.toStringAsFixed(1)} s',
                  onChanged: (double v) => _set(() => _successSeconds = v),
                ),
                DemoWrap(
                  children: <Widget>[
                    DemoButton(
                      'Complete the progress now',
                      icon: Icons.check,
                      tone: DemoTone.success,
                      onPressed: () => _set(() {
                        _progressKind = _ProgressKind.percent;
                        _progressValue = 1;
                      }),
                    ),
                    DemoButton('Start over', icon: Icons.replay, onPressed: () => _set(() => _progressValue = 0.4)),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (_progressText)
                DemoChoice<FluentBarProgressTextEffect>(
                  label: 'Text effect',
                  values: FluentBarProgressTextEffect.values,
                  selected: _progressEffect,
                  onChanged: (FluentBarProgressTextEffect v) => _set(() => _progressEffect = v),
                ),
            ],
          ],
        ),
      ),
      DemoSection(
        icon: Icons.sports_esports_outlined,
        id: 'playground/runtime',
        description: 'One-off commands to the bar that is on screen. They are not part of the chain: you call them on the entry returned by show().',
        code: '''
final entry = FluentBar.success('Saved').show();

entry?.shake();
entry?.heartbeat(repeat: true);
entry?.pause();
entry?.resume();
entry?.addDuration(const Duration(seconds: 5));
entry?.controller.setLoading(isLoading: true);''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DemoLabel('Effects'),
            const SizedBox(height: 6),
            DemoWrap(
              children: <Widget>[
                DemoButton('Shake', onPressed: () => _onBar((FluentBarEntry<void> e) => e.shake())),
                DemoButton('Bounce', onPressed: () => _onBar((FluentBarEntry<void> e) => e.bounce())),
                DemoButton('Pulse', onPressed: () => _onBar((FluentBarEntry<void> e) => e.pulse())),
                DemoButton('Heartbeat (loop)', onPressed: () => _onBar((FluentBarEntry<void> e) => e.heartbeat(repeat: true))),
                DemoButton('Stop loop', onPressed: () => _onBar((FluentBarEntry<void> e) => e.pulse(scale: 1.0))),
              ],
            ),
            const SizedBox(height: 12),
            const DemoLabel('Time & state'),
            const SizedBox(height: 6),
            DemoWrap(
              children: <Widget>[
                DemoButton('Pause', icon: Icons.pause, onPressed: () => _onBar((FluentBarEntry<void> e) => e.pause())),
                DemoButton('Resume', icon: Icons.play_arrow, onPressed: () => _onBar((FluentBarEntry<void> e) => e.resume())),
                DemoButton('+5 s', onPressed: () => _onBar((FluentBarEntry<void> e) => e.addDuration(const Duration(seconds: 5)))),
                DemoButton('-2 s', onPressed: () => _onBar((FluentBarEntry<void> e) => e.subtractDuration(const Duration(seconds: 2)))),
                if (_hasAction)
                  DemoButton(
                    'Loading for 2 s',
                    onPressed: () => _onBar((FluentBarEntry<void> e) {
                      e.controller.setLoading(isLoading: true);
                      Future<void>.delayed(const Duration(seconds: 2), () => e.controller.setLoading(isLoading: false));
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

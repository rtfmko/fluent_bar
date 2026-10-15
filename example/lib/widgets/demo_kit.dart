import 'dart:async';
import 'dart:math';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_state.dart';
import '../app/demo_index.dart';
import '../app/telemetry.dart';

class DemoPage extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? bottomNavigationBar;
  final Widget? header;
  final bool showConfigAction;

  const DemoPage({super.key, required this.title, this.subtitle, required this.children, this.bottomNavigationBar, this.header, this.showConfigAction = true});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final Map<String, GlobalKey> _sectionKeys = <String, GlobalKey>{};
  final ValueNotifier<String?> _highlighted = ValueNotifier<String?>(null);

  bool _didJump = false;

  GlobalKey _keyOf(String code) => _sectionKeys.putIfAbsent(code, GlobalKey.new);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didJump) return;
    _didJump = true;

    final String? target = DemoIndex.sectionOf(ModalRoute.of(context)?.settings.name);
    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final BuildContext? section = _sectionKeys[target]?.currentContext;
      if (section == null || !mounted) return;

      _highlighted.value = target;
      await Scrollable.ensureVisible(section, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.05);
      await Future<void>.delayed(const Duration(milliseconds: 1800));
      if (mounted) _highlighted.value = null;
    });
  }

  @override
  void dispose() {
    _highlighted.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return _DemoPageScope(
      keyOf: _keyOf,
      highlighted: _highlighted,
      child: Scaffold(
        appBar: FluentBarTopInset(
          child: AppBar(
            title: Text(widget.title),
            actions: <Widget>[DemoAppBarActions(showConfig: widget.showConfigAction)],
          ),
        ),
        bottomNavigationBar: widget.bottomNavigationBar,
        body: Column(
          children: <Widget>[
            if (widget.header != null)
              Center(
                child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 792), child: widget.header),
              ),
            Expanded(
              // Sections are built all at once (not lazily) so that a link can scroll to any of them.
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (widget.subtitle != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
                            child: Text(widget.subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                          ),
                        for (final Widget child in widget.children) Padding(padding: const EdgeInsets.only(bottom: 16), child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoPageScope extends InheritedWidget {
  final GlobalKey Function(String code) keyOf;
  final ValueNotifier<String?> highlighted;

  const _DemoPageScope({required this.keyOf, required this.highlighted, required super.child});

  @override
  bool updateShouldNotify(_DemoPageScope oldWidget) => false;
}

// A focused field takes the focus back when its route is shown again, and the keyboard reopens.
// Dropping the focus before leaving the screen prevents that.
void openDemo(BuildContext context, String route) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.of(context).pushNamed(route);
}

class DemoAppBarActions extends StatelessWidget {
  final bool showConfig;

  const DemoAppBarActions({super.key, this.showConfig = true});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(tooltip: 'Close all bars', icon: const Icon(Icons.layers_clear_outlined), onPressed: FluentBar.closeAll),
        if (showConfig)
          ValueListenableBuilder<FluentBarConfig>(
            valueListenable: FluentBar.configNotifier,
            builder: (BuildContext context, FluentBarConfig config, _) => IconButton(
              tooltip: 'Global config',
              icon: Badge(isLabelVisible: !AppState.isBase(config), smallSize: 8, child: const Icon(Icons.tune_rounded)),
              onPressed: () => openDemo(context, '/config'),
            ),
          ),
        IconButton(tooltip: 'Toggle app theme', icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined), onPressed: () => AppState.toggleTheme(context)),
        const SizedBox(width: 4),
      ],
    );
  }
}

class DemoBottomBar extends StatelessWidget {
  final Widget child;

  const DemoBottomBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return FluentBarBottomInset(
      child: Material(
        color: scheme.surfaceContainer,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 792),
              child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class LiveBar extends ChangeNotifier {
  final String id;

  final FluentBarItem<void> Function() build;

  bool autoShow;

  bool Function() isOnTop = () => true;

  FluentBarEntry<void>? _entry;
  bool _wasActive = false;
  bool _hiddenByUser = false;

  LiveBar({required this.id, required this.build, this.autoShow = true});

  FluentBarEntry<void>? get entry => isActive ? _entry : null;

  bool get isActive => _entry != null && identical(FluentBar.find(id), _entry);

  void attach() => Telemetry.instance.addListener(_onTelemetry);

  @override
  void dispose() {
    Telemetry.instance.removeListener(_onTelemetry);
    _entry?.close();
    super.dispose();
  }

  void _onTelemetry() {
    final bool active = isActive;
    if (_wasActive && !active && autoShow && !_hiddenByUser && isOnTop()) {
      show();
      return;
    }
    _wasActive = active;
    notifyListeners();
  }

  void show() {
    _hiddenByUser = false;
    _entry = build().withId(id).show();
    _wasActive = isActive;
    notifyListeners();
  }

  void hide() {
    _hiddenByUser = true;
    _entry?.close();
  }

  void setAutoShow(bool value) {
    autoShow = value;
    notifyListeners();
  }

  void refresh() {
    if (!isActive) return;

    final FluentBarItem<void> next = build();
    final FluentBarController<void> controller = _entry!.controller;

    controller
      ..updateContent(title: next.title, message: next.message, type: next.type)
      ..updateBehavior(behavior: next.behavior)
      ..updateAppearance(next.appearance)
      ..updateActions(next.actions);

    if (next.isPersistent ?? false) {
      controller.updateDuration(null);
    } else if (next.duration != null) {
      controller.updateDuration(next.duration);
    }

    if (next.progressState != null) {
      controller.updateProgress(next.progressState!);
    } else if (_entry!.item.progressState != null) {
      controller.cancelProgress();
    }
  }
}

enum DemoProgressMotion { smooth, jumps }

class DemoProgressRunner extends ChangeNotifier {
  static const Duration smoothTick = Duration(milliseconds: 50);

  static const Duration jumpTick = Duration(milliseconds: 700);

  static const Duration resultPause = Duration(seconds: 2);

  static final Map<String, DemoProgressRunner> _oneShots = <String, DemoProgressRunner>{};
  static final Random _random = Random();

  DemoProgressMotion _motion;
  bool _loop;

  Timer? _timer;
  void Function(double value)? _onValue;
  double _value = 0;

  DemoProgressRunner({DemoProgressMotion motion = DemoProgressMotion.smooth, bool loop = false}) : _motion = motion, _loop = loop;

  bool get isRunning => _timer != null;

  double get value => _value;

  DemoProgressMotion get motion => _motion;

  bool get loop => _loop;

  set loop(bool value) {
    _loop = value;
    notifyListeners();
  }

  set motion(DemoProgressMotion value) {
    _motion = value;
    if (_timer != null && _value < 1) _schedule();
    notifyListeners();
  }

  void start(void Function(double value) onValue, {double from = 0}) {
    _onValue = onValue;
    _value = from >= 1 ? 0 : from;
    onValue(_value);
    _schedule();
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _onValue = null;
    notifyListeners();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(_motion == DemoProgressMotion.smooth ? smoothTick : jumpTick, (_) => _tick());
  }

  void _tick() {
    final double step = _motion == DemoProgressMotion.smooth ? 0.01 : _random.nextInt(8) / 100;
    _value = min(1, ((_value + step) * 100).round() / 100);
    _onValue?.call(_value);
    if (_value < 1) return;

    _timer?.cancel();
    if (!_loop) {
      stop();
      return;
    }

    final void Function(double value) onValue = _onValue!;
    _timer = Timer(resultPause, () => _loop ? start(onValue) : stop());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static void stopOn(String id) => _oneShots.remove(id)?.dispose();

  static void playOn(FluentBarEntry<dynamic>? entry, {required String completedMessage, DemoProgressMotion motion = DemoProgressMotion.smooth}) {
    final String? id = entry?.item.id;
    if (entry == null || id == null) return;

    _oneShots.remove(id)?.dispose();

    final DemoProgressRunner runner = DemoProgressRunner(motion: motion);
    _oneShots[id] = runner;
    runner.start((double value) {
      if (!identical(FluentBar.find(id), entry)) {
        if (identical(_oneShots[id], runner)) _oneShots.remove(id);
        scheduleMicrotask(runner.dispose);
        return;
      }
      entry.updateValue(value, completedMessage: completedMessage, completedType: FluentBarType.success);
      if (value >= 1 && identical(_oneShots[id], runner)) _oneShots.remove(id);
    });
  }
}

class DemoLiveBarControl extends StatelessWidget {
  final LiveBar bar;
  final String showLabel;
  final List<Widget> trailing;

  const DemoLiveBarControl(this.bar, {super.key, this.showLabel = 'Show bar', this.trailing = const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    bar.isOnTop = () => ModalRoute.of(context)?.isCurrent ?? true;

    return DemoBottomBar(
      child: ListenableBuilder(
        listenable: bar,
        builder: (BuildContext context, _) => Row(
          children: <Widget>[
            Expanded(
              child: bar.isActive
                  ? DemoButton('On screen - tap to hide', icon: Icons.visibility_off_outlined, tone: DemoTone.success, onPressed: bar.hide)
                  : DemoButton(showLabel, icon: Icons.play_arrow_rounded, tone: DemoTone.primary, onPressed: bar.show),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Bring the bar back when it times out or is dismissed by hand',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Auto re-show', style: Theme.of(context).textTheme.labelMedium),
                  Switch(value: bar.autoShow, onChanged: bar.setAutoShow),
                ],
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
  }
}

class DemoSection extends StatelessWidget {
  final String id;
  final IconData icon;
  final String? description;
  final Widget child;
  final String? code;
  final Color? color;

  const DemoSection({super.key, required this.id, required this.icon, this.description, required this.child, this.code, this.color});

  static String linkOf(String code) => kIsWeb ? Uri.base.replace(fragment: '/$code').toString() : code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final Color accent = color ?? scheme.primary;
    final DemoSectionInfo info = DemoIndex.section(id);
    final _DemoPageScope? scope = context.getInheritedWidgetOfExactType<_DemoPageScope>();

    final Widget content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(info.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Tooltip(
                      message: kIsWeb ? 'Copy a link to this section' : 'Copy the code of this section',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: linkOf(id)));
                          FluentBar.showToast(kIsWeb ? 'Link copied' : 'Code copied', id: 'code_copied');
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6, top: 2, bottom: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.link_rounded, size: 14, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (description != null) ...<Widget>[const SizedBox(height: 10), Text(description!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.45))],
          const SizedBox(height: 14),
          child,
          if (code != null) ...<Widget>[const SizedBox(height: 12), DemoCode(code!)],
        ],
      ),
    );

    if (scope == null) return Card(child: content);

    return ValueListenableBuilder<String?>(
      key: scope.keyOf(id),
      valueListenable: scope.highlighted,
      builder: (BuildContext context, String? highlighted, Widget? child) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[if (highlighted == id) BoxShadow(color: accent.withValues(alpha: 0.55), blurRadius: 0, spreadRadius: 2)],
        ),
        child: child,
      ),
      child: Card(child: content),
    );
  }
}

class DemoWrap extends StatelessWidget {
  final List<Widget> children;

  const DemoWrap({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: children);
}

enum DemoTone { primary, neutral, success, warning, danger }

class DemoButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DemoTone tone;

  const DemoButton(this.label, {super.key, this.icon, required this.onPressed, this.tone = DemoTone.neutral});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;

    final (Color background, Color foreground) = switch (tone) {
      DemoTone.primary => (scheme.primary, scheme.onPrimary),
      DemoTone.neutral => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      DemoTone.success => (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7), isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534)),
      DemoTone.warning => (isDark ? const Color(0xFF713F12) : const Color(0xFFFEF3C7), isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E)),
      DemoTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    final ButtonStyle style = FilledButton.styleFrom(backgroundColor: background, foregroundColor: foreground);

    return icon == null ? FilledButton(onPressed: onPressed, style: style, child: Text(label)) : FilledButton.icon(onPressed: onPressed, style: style, icon: Icon(icon, size: 18), label: Text(label));
  }
}

class DemoChoice<T> extends StatelessWidget {
  final String label;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;

  const DemoChoice({super.key, required this.label, required this.values, required this.selected, required this.onChanged, this.labelOf});

  static String _defaultLabel(Object? value) => value is Enum ? value.name : value.toString();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DemoLabel(label),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: <Widget>[
            for (final T value in values)
              ChoiceChip(label: Text((labelOf ?? _defaultLabel)(value)), selected: value == selected, selectedColor: theme.colorScheme.primaryContainer, onSelected: (_) => onChanged(value)),
          ],
        ),
      ],
    );
  }
}

class DemoLabel extends StatelessWidget {
  final String text;

  const DemoLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Text(
      text.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.8, fontWeight: FontWeight.w700),
    );
  }
}

class DemoSwitch extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const DemoSwitch({super.key, required this.label, this.hint, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  if (hint != null) Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class DemoSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double value)? format;
  final ValueChanged<double> onChanged;

  const DemoSlider({super.key, required this.label, required this.value, required this.min, required this.max, this.divisions, this.format, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: DemoLabel(label)),
            Text(
              format?.call(value) ?? value.toStringAsFixed(1),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
            ),
          ],
        ),
        Slider(value: value.clamp(min, max), min: min, max: max, divisions: divisions, onChanged: onChanged),
      ],
    );
  }
}

class DemoCode extends StatefulWidget {
  final String code;
  final bool initiallyExpanded;

  const DemoCode(this.code, {super.key, this.initiallyExpanded = false});

  @override
  State<DemoCode> createState() => _DemoCodeState();
}

class _DemoCodeState extends State<DemoCode> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              child: Row(
                children: <Widget>[
                  Icon(Icons.code, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_expanded ? 'Hide code' : 'Show code', style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.code));
                      FluentBar.showToast('Code copied', id: 'code_copied');
                    },
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SelectableText(
                  widget.code,
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5, color: scheme.onSurface),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DemoStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;

  const DemoStat(this.label, this.value, {super.key, this.color, this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = color ?? theme.colorScheme.primary;

    return InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap, child: _body(theme, accent));
  }

  Widget _body(ThemeData theme, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isSelected ? 0.28 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? accent : Colors.transparent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: accent),
          ),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class DemoNote extends StatelessWidget {
  final String text;
  final IconData icon;

  const DemoNote(this.text, {super.key, this.icon = Icons.lightbulb_outline});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onTertiaryContainer, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class DemoLogLine {
  final DateTime time = DateTime.now();
  final String tag;
  final String text;
  final Color color;

  DemoLogLine(this.tag, this.text, this.color);

  String get clock => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
}

class DemoLog extends StatelessWidget {
  final List<DemoLogLine> lines;
  final double height;
  final String emptyText;

  const DemoLog({super.key, required this.lines, this.height = 260, this.emptyText = 'Nothing yet - trigger something above.'});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
      child: lines.isEmpty
          ? Center(
              child: Text(emptyText, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: lines.length,
              itemBuilder: (BuildContext context, int index) {
                final DemoLogLine line = lines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text.rich(
                    TextSpan(
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.35, color: scheme.onSurface),
                      children: <InlineSpan>[
                        TextSpan(
                          text: '${line.clock}  ',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        TextSpan(
                          text: line.tag.padRight(18),
                          style: TextStyle(color: line.color, fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: line.text),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

import 'dart:math' as math;

import 'package:fluent_bar/src/internal.dart';

/// The progress text ("42%", "3 / 5") with an animated change.
///
/// [FluentBarProgressTextEffect.count] looks like [FluentBarProgressTextEffect.none] here:
/// counting percents changes the string itself, which [FluentBarTaskProgressWidget] does.
class FluentBarProgressLabel extends StatefulWidget {
  /// The text to show.
  final String text;

  /// The style of the text.
  final TextStyle style;

  /// How the text changes.
  final FluentBarProgressTextEffect effect;

  /// How long the change takes.
  final Duration duration;

  /// The numeric progress. It gives the direction for [FluentBarProgressTextEffect.roll] and
  /// [FluentBarProgressTextEffect.flip]: up when it grows, down when it shrinks.
  final double? value;

  /// Creates a progress label.
  const FluentBarProgressLabel({super.key, required this.text, required this.style, this.effect = FluentBarProgressTextEffect.count, this.duration = const Duration(milliseconds: 300), this.value});

  @override
  State<FluentBarProgressLabel> createState() => _FluentBarProgressLabelState();
}

class _FluentBarProgressLabelState extends State<FluentBarProgressLabel> with SingleTickerProviderStateMixin {
  /// Changes start at most this often, whatever the duration: quicker ones only flicker.
  static const Duration _minInterval = Duration(milliseconds: 120);

  late String _text;
  double? _value;
  bool _increasing = true;
  bool _isReducedMotion = false;

  /// Runs while a change plays, on the same frames as the animation of the text. A change never
  /// stops half way: a text that arrives meanwhile waits, and only the latest one plays next.
  /// Created on the first change.
  AnimationController? _change;
  bool _hasPending = false;

  bool get _isChanging => _change?.isAnimating ?? false;

  bool get _animates => !_isReducedMotion && widget.duration > Duration.zero && widget.effect != FluentBarProgressTextEffect.none && widget.effect != FluentBarProgressTextEffect.count;

  @override
  void initState() {
    super.initState();
    _text = widget.text;
    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant FluentBarProgressLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_animates) {
      _showAtOnce();
    } else if (widget.text == _text) {
      _hasPending = false;
    } else if (_isChanging) {
      _hasPending = true;
    } else {
      _startChange();
    }
  }

  @override
  void dispose() {
    _change?.dispose();
    super.dispose();
  }

  void _showAtOnce() {
    _change?.stop();
    _hasPending = false;
    _text = widget.text;
    _value = widget.value;
  }

  void _startChange() {
    final double? previous = _value;
    final double? current = widget.value;
    if (previous != null && current != null && previous != current) _increasing = current > previous;

    _text = widget.text;
    _value = current;
    _hasPending = false;
    final AnimationController change = _change ??= AnimationController(vsync: this)..addStatusListener(_onChangeStatus);
    change
      ..duration = widget.duration < _minInterval ? _minInterval : widget.duration
      ..forward(from: 0);
  }

  void _onChangeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_hasPending || !_animates) return;
    setState(_startChange);
  }

  @override
  Widget build(BuildContext context) {
    _isReducedMotion = FluentBarManager.instance.config.reducesMotion(context);
    if (!_animates) {
      _showAtOnce();
      return Text(widget.text, style: widget.style);
    }

    return switch (widget.effect) {
      FluentBarProgressTextEffect.roll || FluentBarProgressTextEffect.flip => _buildPerCharacter(widget.effect),
      _ => _buildWholeLabel(widget.effect),
    };
  }

  /// Effects that change the text as a whole. The new text is fully visible after the first
  /// third of the change and the old one fades out over it, so the label never dims.
  Widget _buildWholeLabel(FluentBarProgressTextEffect effect) {
    final Key currentKey = ValueKey<String>(_text);

    return AnimatedSwitcher(
      duration: widget.duration,
      layoutBuilder: _stackLayout,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final bool incoming = child.key == currentKey;
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (BuildContext context, Widget? face) {
            // The outgoing child runs its animation backwards: 1 - value is the time since the change.
            final double time = incoming ? animation.value : 1.0 - animation.value;
            final double opacity = incoming ? _fadeIn.transform(time) : 1.0 - _fadeOut.transform(time);
            final Widget faded = Opacity(opacity: opacity, child: face);
            if (effect != FluentBarProgressTextEffect.pop || !incoming) return faded;
            return Transform.scale(scale: _popScale.transform(time), child: faded);
          },
        );
      },
      child: Text(_text, key: currentKey, style: widget.style),
    );
  }

  static const Curve _fadeIn = Interval(0.0, 0.3, curve: Curves.easeOut);
  static const Curve _fadeOut = Interval(0.15, 0.45, curve: Curves.easeIn);
  static final Animatable<double> _popScale = Tween<double>(begin: 0.9, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack));

  /// Effects that animate only the characters that changed.
  ///
  /// Cells are keyed by their position from the right edge: on "9%" -> "10%" the digits stay in
  /// place and the new one appears on the left.
  Widget _buildPerCharacter(FluentBarProgressTextEffect effect) {
    final List<String> characters = _text.characters.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[for (int i = 0; i < characters.length; i++) _buildCharacterCell(effect, characters[i], positionFromEnd: characters.length - 1 - i)],
    );
  }

  Widget _buildCharacterCell(FluentBarProgressTextEffect effect, String character, {required int positionFromEnd}) {
    final Key currentKey = ValueKey<String>(character);
    final double direction = _increasing ? 1.0 : -1.0;

    return ClipRect(
      key: ValueKey<int>(positionFromEnd),
      child: AnimatedSwitcher(
        duration: widget.duration,
        // A flip hands one face over to the other at the middle, so both run on the same clock and
        // ease inside their own half.
        switchInCurve: effect == FluentBarProgressTextEffect.flip ? Curves.linear : Curves.easeOutCubic,
        switchOutCurve: effect == FluentBarProgressTextEffect.flip ? Curves.linear : Curves.easeInCubic,
        layoutBuilder: _stackLayout,
        // AnimatedSwitcher rebuilds the transitions of all its children when the builder changes, so
        // the key tells the incoming character from the outgoing one and each gets its own motion.
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool incoming = child.key == currentKey;
          return effect == FluentBarProgressTextEffect.flip ? _flip(child, animation, incoming: incoming, direction: direction) : _roll(child, animation, incoming: incoming, direction: direction);
        },
        child: Text(character, key: currentKey, style: widget.style),
      ),
    );
  }

  /// The incoming character arrives from one side, the outgoing one leaves to the other. No
  /// fading: the cell clips both, so they never overlap and stay fully visible.
  Widget _roll(Widget child, Animation<double> animation, {required bool incoming, required double direction}) => SlideTransition(
    position: Tween<Offset>(begin: Offset(0, incoming ? direction : -direction), end: Offset.zero).animate(animation),
    child: child,
  );

  /// First half: the outgoing character turns away. Second half: the incoming one turns in.
  Widget _flip(Widget child, Animation<double> animation, {required bool incoming, required double direction}) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (BuildContext context, Widget? face) {
      final double value = animation.value;
      final double phase = incoming ? ((value - 0.5) * 2.0).clamp(0.0, 1.0) : ((1.0 - value) * 2.0).clamp(0.0, 1.0);
      final bool hidden = incoming ? value < 0.5 : phase >= 1.0;
      final double eased = incoming ? Curves.easeOut.transform(phase) : Curves.easeIn.transform(phase);
      final double angle = (incoming ? (1.0 - eased) : -eased) * math.pi / 2 * direction;

      return Opacity(
        opacity: hidden ? 0.0 : 1.0,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(angle),
          child: face,
        ),
      );
    },
  );

  static Widget _stackLayout(Widget? currentChild, List<Widget> previousChildren) => Stack(alignment: Alignment.center, children: <Widget>[...previousChildren, ?currentChild]);
}

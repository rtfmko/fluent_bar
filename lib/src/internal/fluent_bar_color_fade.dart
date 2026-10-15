import 'package:fluent_bar/src/internal.dart';

/// How long the look of a visible bar (background, border, shadow, text and icon colors) takes
/// to reach a new one, for example when the type changes from info to success.
const Duration kFluentBarRestyleDuration = Duration(milliseconds: 300);

/// Fades a color to a new value.
///
/// On the first build the color is used at once; only a change from one color to another is
/// animated. A color that appears or goes away (`null` means "not set, inherited") is not faded.
/// With a zero [duration] the change is instant.
class FluentBarColorFade extends ImplicitlyAnimatedWidget {
  /// The color to fade to; `null` means "not set".
  final Color? color;

  /// Builds the subtree with the color of the current frame.
  final Widget Function(BuildContext context, Color? color) builder;

  /// Creates a fade to [color].
  const FluentBarColorFade({super.key, required this.color, required this.builder, super.duration = kFluentBarRestyleDuration}) : super(curve: Curves.easeInOut);

  @override
  AnimatedWidgetBaseState<FluentBarColorFade> createState() => _FluentBarColorFadeState();
}

class _FluentBarColorFadeState extends AnimatedWidgetBaseState<FluentBarColorFade> {
  ColorTween? _color;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(_color, widget.color, (dynamic value) => ColorTween(begin: value as Color)) as ColorTween?;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _color?.evaluate(animation) ?? widget.color);
}

/// The container of a bar whose decoration blends into the new one instead of snapping.
///
/// Only what blends without surprises is animated: background, border and shadow colors,
/// gradient, corner radius. Sizes ([constraints], [padding]) change at once: a bounded
/// constraint cannot be interpolated with an unbounded one. A decoration of another build
/// (another shape, a border with different sides) is also applied at once, because the frames
/// in between would be invalid.
class FluentBarDecorationFade extends ImplicitlyAnimatedWidget {
  /// The decoration to blend to.
  final BoxDecoration? decoration;

  /// The size limits; applied at once.
  final BoxConstraints? constraints;

  /// The inner padding; applied at once.
  final EdgeInsetsGeometry? padding;

  /// The content of the container.
  final Widget child;

  /// Creates a container that blends to [decoration].
  const FluentBarDecorationFade({super.key, required this.decoration, required this.child, this.constraints, this.padding, super.duration = kFluentBarRestyleDuration})
    : super(curve: Curves.easeInOut);

  @override
  AnimatedWidgetBaseState<FluentBarDecorationFade> createState() => _FluentBarDecorationFadeState();
}

class _FluentBarDecorationFadeState extends AnimatedWidgetBaseState<FluentBarDecorationFade> {
  _DecorationFadeTween? _decoration;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _decoration = visitor(_decoration, widget.decoration, (dynamic value) => _DecorationFadeTween(begin: value as BoxDecoration)) as _DecorationFadeTween?;
  }

  @override
  Widget build(BuildContext context) => Container(constraints: widget.constraints, padding: widget.padding, decoration: _decoration?.evaluate(animation) ?? widget.decoration, child: widget.child);
}

class _DecorationFadeTween extends Tween<BoxDecoration> {
  _DecorationFadeTween({super.begin});

  @override
  BoxDecoration lerp(double t) {
    final BoxDecoration from = begin!;
    final BoxDecoration to = end!;

    return _blendsCleanly(from, to) ? BoxDecoration.lerp(from, to, t)! : to;
  }

  /// The frames in between are valid only if the shape is the same and the borders are simple:
  /// none, or with equal sides. Flutter does not paint a corner radius together with a border
  /// whose sides differ, and blending such a decoration with a rounded one produces exactly that.
  static bool _blendsCleanly(BoxDecoration a, BoxDecoration b) => a.shape == b.shape && ((_isSimple(a.border) && _isSimple(b.border)) || a.border == b.border);

  static bool _isSimple(BoxBorder? border) => border == null || (border is Border && border.isUniform);
}

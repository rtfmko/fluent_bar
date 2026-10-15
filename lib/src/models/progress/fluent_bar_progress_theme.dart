import 'package:fluent_bar/src/internal.dart';

/// The look of the progress indicator.
///
/// It can be set on three levels - the bar, its type and the global config - and the levels
/// merge field by field: the bar overrides only what it set itself, the rest comes from the
/// type, then from the config, then from the defaults. So "not set" and "set to the default
/// value" must be told apart: getters always return a ready value, while what was set
/// explicitly is kept separately and used for merging (see [mergedOver]).
class FluentBarProgressTheme {
  final FluentBarProgressStyle? _style;
  final FluentBarProgressPosition? _position;
  final BoxDecoration? _trackDecoration;
  final Color? _progressColor;
  final double? _thickness;
  final double? _size;
  final bool? _showText;

  /// See [announceUpdates].
  final bool? _announceUpdates;
  final FluentBarProgressTextAlign? _textAlign;
  final FluentBarProgressTextEffect? _textEffect;
  final Duration? _textEffectDuration;
  final Duration? _animationDuration;
  final Color? _successIconColor;
  final Widget? _successIcon;
  final Duration? _successIconDuration;
  final TextStyle? _textStyle;
  final String Function(FluentBarProgressState state)? _labelBuilder;
  final Widget Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? _progressBuilder;

  /// Creates a look for the progress indicator; everything left out comes from the lower levels.
  ///
  /// ```dart
  /// const FluentBarProgressTheme(
  ///   style: FluentBarProgressStyle.linear,
  ///   showText: true,
  ///   thickness: 6,
  ///   textEffect: FluentBarProgressTextEffect.roll,
  /// );
  /// ```
  const FluentBarProgressTheme({
    FluentBarProgressStyle? style,
    FluentBarProgressPosition? position,
    BoxDecoration? trackDecoration,
    Color? progressColor,
    double? thickness,
    double? size,
    bool? showText,
    bool? announceUpdates,
    FluentBarProgressTextAlign? textAlign,
    FluentBarProgressTextEffect? textEffect,
    Duration? textEffectDuration,
    Duration? animationDuration,
    Color? successIconColor,
    Widget? successIcon,
    Duration? successIconDuration,
    TextStyle? textStyle,
    String Function(FluentBarProgressState state)? labelBuilder,
    Widget Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? progressBuilder,
  }) : _style = style,
       _position = position,
       _trackDecoration = trackDecoration,
       _progressColor = progressColor,
       _thickness = thickness,
       _size = size,
       _showText = showText,
       _announceUpdates = announceUpdates,
       _textAlign = textAlign,
       _textEffect = textEffect,
       _textEffectDuration = textEffectDuration,
       _animationDuration = animationDuration,
       _successIconColor = successIconColor,
       _successIcon = successIcon,
       _successIconDuration = successIconDuration,
       _textStyle = textStyle,
       _labelBuilder = labelBuilder,
       _progressBuilder = progressBuilder;

  /// A line or a ring.
  FluentBarProgressStyle get style => _style ?? FluentBarProgressStyle.linear;

  /// Where the indicator sits inside the bar.
  FluentBarProgressPosition get position => _position ?? FluentBarProgressPosition.bottom;

  /// A decoration drawn around the track of a linear indicator.
  BoxDecoration? get trackDecoration => _trackDecoration;

  /// The color of the indicator; by default the icon color of the bar.
  Color? get progressColor => _progressColor;

  /// The thickness of the line or of the ring stroke.
  double get thickness => _thickness ?? 4.0;

  /// The diameter of a circular indicator.
  double? get size => _size ?? 24.0;

  /// Whether the value is shown as text next to the indicator.
  bool get showText => _showText ?? false;

  /// Whether a screen reader announces every change of the progress (`42%`, `43%`...). Off by
  /// default: the bar is announced when it appears and when its title or message changes, and the
  /// progress can still be read by moving to it.
  bool get announceUpdates => _announceUpdates ?? false;

  /// Where the text sits relative to the indicator.
  FluentBarProgressTextAlign get textAlign => _textAlign ?? FluentBarProgressTextAlign.right;

  /// How the text changes when the value updates.
  FluentBarProgressTextEffect get textEffect => _textEffect ?? FluentBarProgressTextEffect.count;

  /// The duration of the text change effect.
  ///
  /// A change always plays to the end, and changes start at most every 120 ms. A text that
  /// arrives meanwhile waits; when several arrive, only the latest one plays.
  Duration get textEffectDuration => _textEffectDuration ?? const Duration(milliseconds: 300);

  /// How long the indicator takes to reach a new value on a jump across the whole scale (0 -> 100%).
  ///
  /// A smaller jump takes proportionally less: a small step about 300 ms, a jump over half the
  /// scale halfway between the two. Big jumps also start more softly. This keeps the indicator
  /// responsive on frequent small updates and smooth on rare sharp ones.
  /// A value up to 300 ms gives every jump the same duration; zero turns the animation off.
  Duration get animationDuration => _animationDuration ?? const Duration(milliseconds: 800);

  /// The color of the default success icon.
  Color? get successIconColor => _successIconColor;

  /// A custom icon shown when the progress completes.
  Widget? get successIcon => _successIcon;

  /// How long the success icon stays after the progress completes. Then it is removed: the
  /// indicator collapses, or the regular icon returns if the indicator replaced it.
  /// `null` (default) keeps the success icon until the bar closes.
  Duration? get successIconDuration => _successIconDuration;

  /// The style of the progress text.
  TextStyle? get textStyle => _textStyle;

  /// Builds the progress text instead of the default "42%" or "3 / 8". Not used in place of the
  /// icon (`FluentBarProgressPosition.replaceIcon`), which always shows the percent.
  String Function(FluentBarProgressState state)? get labelBuilder => _labelBuilder;

  /// A custom indicator widget instead of the standard one.
  Widget Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? get progressBuilder => _progressBuilder;

  /// This theme over [lower]: what is set here stays, the rest comes from [lower].
  @internal
  FluentBarProgressTheme mergedOver(FluentBarProgressTheme? lower) => lower == null
      ? this
      : FluentBarProgressTheme(
          style: _style ?? lower._style,
          position: _position ?? lower._position,
          trackDecoration: _trackDecoration ?? lower._trackDecoration,
          progressColor: _progressColor ?? lower._progressColor,
          thickness: _thickness ?? lower._thickness,
          size: _size ?? lower._size,
          showText: _showText ?? lower._showText,
          announceUpdates: _announceUpdates ?? lower._announceUpdates,
          textAlign: _textAlign ?? lower._textAlign,
          textEffect: _textEffect ?? lower._textEffect,
          textEffectDuration: _textEffectDuration ?? lower._textEffectDuration,
          animationDuration: _animationDuration ?? lower._animationDuration,
          successIconColor: _successIconColor ?? lower._successIconColor,
          successIcon: _successIcon ?? lower._successIcon,
          successIconDuration: _successIconDuration ?? lower._successIconDuration,
          textStyle: _textStyle ?? lower._textStyle,
          labelBuilder: _labelBuilder ?? lower._labelBuilder,
          progressBuilder: _progressBuilder ?? lower._progressBuilder,
        );

  /// A copy with the given fields replaced; `null` keeps a field.
  FluentBarProgressTheme copyWith({
    FluentBarProgressStyle? style,
    FluentBarProgressPosition? position,
    BoxDecoration? trackDecoration,
    Color? progressColor,
    double? thickness,
    double? size,
    bool? showText,
    bool? announceUpdates,
    FluentBarProgressTextAlign? textAlign,
    FluentBarProgressTextEffect? textEffect,
    Duration? textEffectDuration,
    Duration? animationDuration,
    Color? successIconColor,
    Widget? successIcon,
    Duration? successIconDuration,
    TextStyle? textStyle,
    String Function(FluentBarProgressState state)? labelBuilder,
    Widget Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? progressBuilder,
  }) => FluentBarProgressTheme(
    style: style ?? _style,
    position: position ?? _position,
    trackDecoration: trackDecoration ?? _trackDecoration,
    progressColor: progressColor ?? _progressColor,
    thickness: thickness ?? _thickness,
    size: size ?? _size,
    showText: showText ?? _showText,
    announceUpdates: announceUpdates ?? _announceUpdates,
    textAlign: textAlign ?? _textAlign,
    textEffect: textEffect ?? _textEffect,
    textEffectDuration: textEffectDuration ?? _textEffectDuration,
    animationDuration: animationDuration ?? _animationDuration,
    successIconColor: successIconColor ?? _successIconColor,
    successIcon: successIcon ?? _successIcon,
    successIconDuration: successIconDuration ?? _successIconDuration,
    textStyle: textStyle ?? _textStyle,
    labelBuilder: labelBuilder ?? _labelBuilder,
    progressBuilder: progressBuilder ?? _progressBuilder,
  );

  // Only explicitly set values are compared: a default theme and a theme with the same values
  // set explicitly behave differently when merged.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FluentBarProgressTheme &&
          runtimeType == other.runtimeType &&
          _style == other._style &&
          _position == other._position &&
          _trackDecoration == other._trackDecoration &&
          _progressColor == other._progressColor &&
          _thickness == other._thickness &&
          _size == other._size &&
          _showText == other._showText &&
          _announceUpdates == other._announceUpdates &&
          _textAlign == other._textAlign &&
          _textEffect == other._textEffect &&
          _textEffectDuration == other._textEffectDuration &&
          _animationDuration == other._animationDuration &&
          _successIconColor == other._successIconColor &&
          _successIcon == other._successIcon &&
          _successIconDuration == other._successIconDuration &&
          _textStyle == other._textStyle;

  @override
  int get hashCode => Object.hash(
    _style,
    _position,
    _trackDecoration,
    _progressColor,
    _thickness,
    _size,
    _showText,
    _announceUpdates,
    _textAlign,
    _textEffect,
    _textEffectDuration,
    _animationDuration,
    _successIconColor,
    _successIcon,
    _successIconDuration,
    _textStyle,
  );
}

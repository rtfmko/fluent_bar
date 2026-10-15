import 'dart:ui' show lerpDouble;

import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';

/// The motion curve of the indicator. For a small step it is a pure ease-out: steps come often
/// and the indicator must respond at once. The bigger the jump, the more of a soft start is
/// blended in: a big jump sets off gently instead of jerking, without lingering at the start.
/// The transition between the two curves is continuous.
class _JumpCurve extends Curve {
  const _JumpCurve(this.blend);

  /// 0 is ease-out only, 1 is a soft start with a long ease-out.
  final double blend;

  @override
  double transformInternal(double t) => lerpDouble(Curves.easeOutCubic.transform(t), Curves.fastOutSlowIn.transform(t), blend)!;
}

/// The standard progress indicator of a bar: a line or a circle, an optional text and the success icon.
///
/// It listens to [progressNotifier] itself, so the bar is not rebuilt on every update. Reuse it
/// inside a custom content builder to keep the standard indicator.
///
/// ```dart
/// FluentBarTaskProgressWidget(
///   progressNotifier: entry.controller.progressStateNotifier,
///   theme: const FluentBarProgressTheme(showText: true),
///   defaultColor: Colors.white,
///   successIcon: const Icon(Icons.check_circle),
/// );
/// ```
class FluentBarTaskProgressWidget extends StatefulWidget {
  /// The progress to show; `null` hides the indicator.
  final ValueListenable<FluentBarProgressState?> progressNotifier;

  /// The look of the indicator.
  final FluentBarProgressTheme theme;

  /// The color used when [theme] sets none.
  final Color defaultColor;

  /// The icon shown when the progress completes.
  final Widget successIcon;

  /// The text change effect. Taken from [theme] when not set.
  final FluentBarProgressTextEffect? textEffect;

  /// What to show in place of the success icon when `theme.successIconDuration` runs out.
  /// `null`: the indicator collapses.
  final Widget? afterSuccess;

  /// Creates a progress indicator.
  const FluentBarTaskProgressWidget({super.key, required this.progressNotifier, required this.theme, required this.defaultColor, required this.successIcon, this.textEffect, this.afterSuccess});

  @override
  State<FluentBarTaskProgressWidget> createState() => _FluentBarTaskProgressWidgetState();
}

class _FluentBarTaskProgressWidgetState extends State<FluentBarTaskProgressWidget> with SingleTickerProviderStateMixin {
  /// The duration of a small step. A jump across the whole scale takes `theme.animationDuration`;
  /// everything in between is proportional to the size of the jump.
  static const Duration _stepDuration = Duration(milliseconds: 300);

  /// Up to which jump size the curve stays "quick" and from which it is fully soft.
  static const double _smallJump = 0.1;
  static const double _bigJump = 0.5;

  Timer? _successTimer;
  bool _isSuccessHidden = false;

  late final AnimationController _valueController;
  double _from = 0;
  double _to = 0;
  Curve _curve = Curves.easeOutCubic;
  FluentBarProgressState? _seenState;

  ValueListenable<FluentBarProgressState?> get progressNotifier => widget.progressNotifier;

  FluentBarProgressTheme get theme => widget.theme;

  Color get defaultColor => widget.defaultColor;

  Widget get successIcon => widget.successIcon;

  FluentBarProgressTextEffect get _textEffect => widget.textEffect ?? theme.textEffect;

  double get _displayed {
    final double t = _valueController.value;
    // At the end of the way: exactly the target, without the rounding error of the sum.
    if (t >= 1.0) return _to;

    return _from + (_to - _from) * _curve.transform(t);
  }

  @override
  void initState() {
    super.initState();
    _valueController = AnimationController(vsync: this, value: 1.0);
    progressNotifier.addListener(_onProgressChanged);
    _onProgressChanged();
  }

  @override
  void didUpdateWidget(covariant FluentBarTaskProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.progressNotifier, progressNotifier)) {
      oldWidget.progressNotifier.removeListener(_onProgressChanged);
      progressNotifier.addListener(_onProgressChanged);
      _syncValue();
    }
    if (oldWidget.theme.successIconDuration != theme.successIconDuration) {
      _successTimer?.cancel();
      _successTimer = null;
      _isSuccessHidden = false;
    }
    _syncSuccessTimer();
  }

  @override
  void dispose() {
    progressNotifier.removeListener(_onProgressChanged);
    _successTimer?.cancel();
    _valueController.dispose();
    super.dispose();
  }

  void _onProgressChanged() {
    _syncValue();
    _syncSuccessTimer();
  }

  /// Starts moving the indicator to the new value.
  ///
  /// Duration and curve depend on how far it has to go: a small step is quick, a big jump takes
  /// longer and starts softly, so the indicator is smooth on frequent small updates and on rare
  /// sharp ones alike.
  void _syncValue() {
    final FluentBarProgressState? state = progressNotifier.value;
    final FluentBarProgressState? previous = _seenState;
    _seenState = state;

    final double? target = state?.progress;
    if (state == null || target == null) {
      _valueController.value = 1.0;
      _from = _to = 0;
      return;
    }

    // A new run (first show, after indeterminate progress, after a completed one) starts from zero
    // instead of rewinding from the previous value.
    final bool startsOver = previous?.progress == null || (previous!.isCompleted && !state.isCompleted);
    final double from = startsOver ? 0.0 : _displayed;
    if (!startsOver && target == _to) return;

    final double distance = (target - from).abs();
    final Duration duration = _durationFor(distance);

    _from = from;
    _to = target;
    _curve = _JumpCurve(((distance - _smallJump) / (_bigJump - _smallJump)).clamp(0.0, 1.0).toDouble());

    if (distance == 0 || duration <= Duration.zero) {
      _valueController.value = 1.0;
    } else {
      _valueController
        ..duration = duration
        ..forward(from: 0.0);
    }
  }

  Duration _durationFor(double distance) {
    final Duration full = theme.animationDuration;
    // Shorter than a regular step means "one short duration for everything" (zero: no animation).
    if (full <= _stepDuration) return full;

    return _stepDuration + (full - _stepDuration) * distance.clamp(0.0, 1.0);
  }

  /// The success icon is shown for `theme.successIconDuration` after completion, then removed.
  /// If the progress starts again, everything returns to the initial state.
  void _syncSuccessTimer() {
    final bool isCompleted = progressNotifier.value?.isCompleted ?? false;
    final Duration? duration = theme.successIconDuration;

    if (!isCompleted || duration == null) {
      _successTimer?.cancel();
      _successTimer = null;
      if (_isSuccessHidden && mounted) setState(() => _isSuccessHidden = false);
      return;
    }

    if (_successTimer != null || _isSuccessHidden) return;
    _successTimer = Timer(duration, () {
      _successTimer = null;
      if (mounted) setState(() => _isSuccessHidden = true);
    });
  }

  Alignment _resolveAlignment() {
    if (theme.position == FluentBarProgressPosition.top || theme.position == FluentBarProgressPosition.bottom) {
      return Alignment.center;
    }

    if (theme.isCircular) {
      return Alignment.centerLeft;
    }

    if (theme.position == FluentBarProgressPosition.left || theme.position == FluentBarProgressPosition.replaceIcon) {
      return Alignment.centerLeft;
    }

    return Alignment.center;
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = FluentBarManager.instance.config.reducesMotion(context);

    return ValueListenableBuilder<FluentBarProgressState?>(
      valueListenable: progressNotifier,
      builder: (BuildContext context, FluentBarProgressState? state, Widget? child) {
        if (state == null) return const SizedBox.shrink();

        final Alignment effectiveAlignment = _resolveAlignment();

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: effectiveAlignment,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) => Stack(alignment: effectiveAlignment, children: <Widget>[...previousChildren, ?currentChild]),
            transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(
              opacity: animation,
              child: reduceMotion ? child : ScaleTransition(scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation), child: child),
            ),
            child: state.isCompleted && _isSuccessHidden
                ? KeyedSubtree(key: const ValueKey<String>('success_hidden'), child: widget.afterSuccess ?? const SizedBox.shrink())
                : state.isCompleted
                ? KeyedSubtree(key: const ValueKey<String>('success_icon'), child: _buildSuccess(context, state, effectiveAlignment))
                : KeyedSubtree(key: const ValueKey<String>('progress_loader'), child: _buildLoader(context, state)),
          ),
        );
      },
    );
  }

  /// The success icon. Where a linear indicator had a line with a label, the icon takes exactly
  /// their place: the size of the bar does not change on completion, so the bar does not jump.
  Widget _buildSuccess(BuildContext context, FluentBarProgressState state, Alignment alignment) {
    final bool keepsLayout = !theme.isCircular && theme.showText && theme.position != FluentBarProgressPosition.replaceIcon;
    if (!keepsLayout) return _buildSuccessIconContainer(alignment);

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // An invisible copy of the indicator keeps the previous size.
        Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: _buildLoader(context, state)),
        Positioned.fill(
          child: FittedBox(fit: BoxFit.scaleDown, child: successIcon),
        ),
      ],
    );
  }

  Widget _buildSuccessIconContainer(Alignment alignment) {
    final double targetSize = theme.size ?? 24.0;

    return SizedBox(
      width: targetSize,
      height: targetSize,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: alignment,
        child: Center(child: successIcon),
      ),
    );
  }

  /// A label that is a percent and nothing else: only that one can be counted up.
  static final RegExp _percentOnly = RegExp(r'^\d+%$');

  Widget _buildLoader(BuildContext context, FluentBarProgressState state) {
    final double? progress = state.progress;
    final bool isIndeterminate = progress == null;
    // In place of the icon there is room for a percent and nothing else: bytes and fractions
    // would shrink to an unreadable size, so they and custom labels show their percent there.
    final bool isInIcon = theme.position == FluentBarProgressPosition.replaceIcon;
    final String targetLabel = isInIcon
        ? (isIndeterminate ? '' : '${progressPercentOf(progress)}%')
        : theme.labelBuilder != null
        ? FluentBarErrorHandler.instance.executeSafe<String>(
            overrideCall: () => theme.labelBuilder!(state),
            fallbackCall: () => state.format(),
            type: FluentBarErrorType.fluentBarResolver,
            debugContext: 'labelBuilder',
          )
        : state.format();

    if (isIndeterminate) {
      return _buildLayout(_buildIndicator(null), targetLabel, null);
    }

    // Counting percents changes the string itself. With other effects the string is left alone:
    // FluentBarProgressLabel animates its change.
    final bool countPercent = _textEffect == FluentBarProgressTextEffect.count && (isInIcon || theme.labelBuilder == null) && _percentOnly.hasMatch(targetLabel);

    return AnimatedBuilder(
      animation: _valueController,
      builder: (BuildContext context, Widget? child) {
        final double animatedValue = _displayed;
        final String displayLabel = countPercent ? '${progressPercentOf(animatedValue)}%' : targetLabel;

        return _buildLayout(_buildIndicator(animatedValue), displayLabel, progress);
      },
    );
  }

  Widget _buildLabel(String text, double? value, {required double fontSize, required FontWeight fontWeight}) => FluentBarProgressLabel(
    text: text,
    style: (theme.textStyle ?? TextStyle(color: defaultColor, fontSize: fontSize, fontWeight: fontWeight)).copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
    effect: _textEffect,
    duration: theme.textEffectDuration,
    value: value,
  );

  Widget _buildLayout(Widget loader, String text, double? value) {
    if (!theme.showText || text.isEmpty) return loader;

    // A linear indicator in the icon slot occupies a square the size of the icon. The label (a
    // percent, see _buildLoader) goes under the line and shrinks if the square is smaller.
    if (!theme.isCircular && theme.position == FluentBarProgressPosition.replaceIcon) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          loader,
          const SizedBox(height: 2),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildLabel(text, value, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    }

    if (theme.isCircular) {
      if (theme.shouldCenterText) {
        final double indicatorSize = theme.size ?? 24.0;
        return SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              loader,
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: _buildLabel(text, value, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }

      final Widget label = _buildLabel(text, value, fontSize: 12, fontWeight: FontWeight.w600);

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: theme.textAlign == FluentBarProgressTextAlign.left ? <Widget>[label, const SizedBox(width: 8), loader] : <Widget>[loader, const SizedBox(width: 8), label],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: theme.linearCrossAxisAlignment,
      children: <Widget>[
        Flexible(fit: FlexFit.loose, child: loader),
        const SizedBox(height: 4),
        _buildLabel(text, value, fontSize: 12, fontWeight: FontWeight.w600),
      ],
    );
  }

  Widget _buildIndicator(double? value) {
    final Color color = theme.progressColor ?? defaultColor;
    final double targetSize = theme.size ?? 24.0;

    if (theme.style == FluentBarProgressStyle.circular) {
      return SizedBox(
        width: targetSize,
        height: targetSize,
        child: CircularProgressIndicator(value: value, strokeWidth: theme.thickness, valueColor: AlwaysStoppedAnimation<Color>(color), backgroundColor: color.withValues(alpha: 0.2)),
      );
    }

    final Widget content = LinearProgressIndicator(
      value: value,
      minHeight: theme.thickness,
      valueColor: AlwaysStoppedAnimation<Color>(color),
      backgroundColor: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(theme.thickness / 2),
    );

    if (theme.trackDecoration != null) {
      return DecoratedBox(decoration: theme.trackDecoration!, child: content);
    }
    return content;
  }
}

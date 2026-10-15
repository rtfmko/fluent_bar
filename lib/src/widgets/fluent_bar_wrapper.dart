import 'dart:math' as math;

import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';

/// Everything around the content of a bar: position, insets, entrance and exit, gestures, attention effects and semantics.
class FluentBarWrapper<T> extends StatefulWidget {
  /// The bar to show.
  final FluentBarEntry<T> entry;

  /// The global config in effect.
  final FluentBarConfig config;

  /// Creates the wrapper for [entry].
  const FluentBarWrapper({super.key, required this.entry, required this.config});

  @override
  State<FluentBarWrapper<T>> createState() => _FluentBarWrapperState<T>();
}

class _FluentBarWrapperState<T> extends State<FluentBarWrapper<T>> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animController;
  late final AnimationController _effectAnimController;

  /// Fades the bar in at its new place when a bar on screen changes position. Without it the
  /// bar would jump there in one frame.
  late final AnimationController _moveController;
  late final CurvedAnimation _moveFade;
  FluentBarPosition? _shownPosition;
  StreamSubscription<FluentBarEffectEvent>? _effectSubscription;

  FluentBarEffectEvent? _currentEffect;
  FluentBarEffectEvent? _deferredEffect;

  /// The system asks to reduce motion and the app follows the setting. Updated on build.
  bool _reduceMotion = false;

  /// The content of the bar is held by a global key. Gesture wrappers around it come and go on a
  /// visible bar (swipe is turned off while loading, the error type does not allow it), and
  /// without the key every such change would build the content anew: running animations would
  /// be cut off and the progress indicator would start from zero.
  final GlobalKey _contentKey = GlobalKey();

  CurvedAnimation? _entranceCurve;
  FluentBarEntranceAnimation? _entranceCurveType;

  /// The animations built from the entrance curve, kept like the curve itself: a rebuild of the
  /// bar (new text, type, look) reuses them instead of creating new ones every time.
  late final Animation<double> _fadeIn = _animController.drive(CurveTween(curve: Curves.easeInOut));
  Animation<Offset>? _slide;
  (CurvedAnimation, Offset)? _slideKey;
  Animation<double>? _scale;
  CurvedAnimation? _scaleCurve;

  // While the bar is held (or hovered) the countdown stands still: the person is reading or
  // about to tap. Pointers are counted instead of keeping a flag: a finger and the cursor may
  // be there at the same time.
  int _pointersDown = 0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    final Duration duration = widget.entry.resolveTransitionDuration(widget.config);
    final Duration reverseDuration = widget.entry.resolveReverseTransitionDuration(widget.config);

    _animController = AnimationController(vsync: this, duration: duration, reverseDuration: reverseDuration);
    _animController.addStatusListener(_onEntranceStatusChanged);
    _animController.forward();

    widget.entry.controller.stateNotifier.addListener(_onStateChanged);

    if (widget.entry.controller.stateNotifier.value == FluentBarLifecycleState.hiding) {
      _runDismissAnimation();
    }

    _effectAnimController = AnimationController(vsync: this);
    _effectAnimController.addStatusListener(_onEffectStatusChanged);

    _moveController = AnimationController(vsync: this, duration: kFluentBarRestyleDuration, value: 1);
    _moveFade = CurvedAnimation(parent: _moveController, curve: Curves.easeOut);

    WidgetsBinding.instance.addObserver(this);

    _subscribeToEffects();

    if (widget.entry.controller is FluentBarControllerImpl<T>) {
      final FluentBarControllerImpl<T> ctrl = widget.entry.controller as FluentBarControllerImpl<T>;
      if (ctrl.latestEffect != null) {
        final FluentBarEffectEvent missedEffect = ctrl.latestEffect!;
        ctrl.clearLatestEffect();
        _handleEffect(missedEffect);
      }
    }
  }

  @override
  void didUpdateWidget(covariant FluentBarWrapper<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entry.controller != widget.entry.controller) {
      if (!oldWidget.entry.internalController.isDisposed) {
        oldWidget.entry.controller.stateNotifier.removeListener(_onStateChanged);
      }
      _effectSubscription?.cancel();

      widget.entry.controller.stateNotifier.addListener(_onStateChanged);
      _subscribeToEffects();
    }

    final Duration newDuration = widget.entry.resolveTransitionDuration(widget.config);
    if (_animController.duration != newDuration) {
      _animController.duration = newDuration;
    }

    final Duration newReverseDuration = widget.entry.resolveReverseTransitionDuration(widget.config);
    if (_animController.reverseDuration != newReverseDuration) {
      _animController.reverseDuration = newReverseDuration;
    }
  }

  /// "Reduce Motion" on iOS is not part of MediaQuery, so its change is observed directly.
  @override
  void didChangeAccessibilityFeatures() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!widget.entry.internalController.isDisposed) {
      widget.entry.controller.stateNotifier.removeListener(_onStateChanged);
    }
    _releaseTouchHold();
    _entranceCurve?.dispose();
    _animController.dispose();
    _deferredEffect = null;
    _entranceCurveType = null;
    _currentEffect = null;
    _effectAnimController.dispose();
    _moveFade.dispose();
    _moveController.dispose();
    _effectSubscription?.cancel();

    // Normally the manager has already taken the bar off screen by now. If not, the overlay itself
    // is gone and the bar must go back to the queue. Checked after the frame: the tree is locked now.
    final FluentBarEntry<T> entry = widget.entry;
    scheduleMicrotask(() => FluentBarManager.instance.recoverDetached(entry));

    super.dispose();
  }

  void _subscribeToEffects() {
    if (widget.entry.controller is FluentBarControllerImpl) {
      final FluentBarControllerImpl<T> controller = widget.entry.controller as FluentBarControllerImpl<T>;
      _effectSubscription = controller.effectStream.listen(_handleEffect);
    }
  }

  void _handleEffect(FluentBarEffectEvent event) {
    if (!mounted) return;

    if (_reduceMotion) return;

    if (!_animController.isCompleted) {
      _deferredEffect = event;
      return;
    }

    // An effect that is already playing ignores new calls. An endless (repeat) effect is replaced
    // by a new call, otherwise there would be no way to stop it.
    if (_effectAnimController.isAnimating && _currentEffect?.repeat != true) {
      return;
    }

    _currentEffect = event;
    _effectAnimController.duration = event.duration;

    if (event.repeat) {
      _effectAnimController.repeat();
    } else {
      _effectAnimController.forward(from: 0.0);
    }
  }

  void _onEffectStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted && _currentEffect != null) {
      if (_currentEffect?.repeat != true) {
        _currentEffect = null;
      }
    }
  }

  void _onEntranceStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) widget.entry.internalController.markEntranceCompleted();

    if (status == AnimationStatus.completed && _deferredEffect != null) {
      final FluentBarEffectEvent effectToPlay = _deferredEffect!;
      _deferredEffect = null;
      _handleEffect(effectToPlay);
    }
  }

  void _onStateChanged() {
    if (widget.entry.controller.stateNotifier.value == FluentBarLifecycleState.hiding) {
      _runDismissAnimation();
    }
  }

  Future<void> _runDismissAnimation() async {
    try {
      if (mounted && !widget.entry.resolveDisableAnimations(widget.config)) {
        await _animController.reverse().orCancel;
      }
    } on TickerCanceled {
      // Ignore: standard animation interruption during a swipe or widget dispose
    } finally {
      widget.entry.internalController.notifyDismissCompleted();
    }
  }

  Offset _getBeginOffset(FluentBarPosition position) => switch (position) {
    FluentBarPosition.top => const Offset(0, -1.5),
    FluentBarPosition.bottom => const Offset(0, 1.5),
    FluentBarPosition.left => const Offset(-1.5, 0),
    FluentBarPosition.right => const Offset(1.5, 0),
    FluentBarPosition.center => Offset.zero,
  };

  Alignment _getAlignment(FluentBarPosition position) => switch (position) {
    FluentBarPosition.top => Alignment.topCenter,
    FluentBarPosition.bottom => Alignment.bottomCenter,
    FluentBarPosition.left => Alignment.centerLeft,
    FluentBarPosition.right => Alignment.centerRight,
    FluentBarPosition.center => Alignment.center,
  };

  Widget _buildTransition(BuildContext context, FluentBarEntry<T> entry, Widget child) {
    if (_reduceMotion) return _buildEntranceTransition(child, FluentBarEntranceAnimation.fade, entry.resolvePosition(widget.config));

    final Widget Function(BuildContext, Animation<double>, Widget)? transitionBuilder = entry.resolveTransitionBuilder(widget.config);

    if (transitionBuilder != null) {
      return transitionBuilder(context, _animController, child);
    }

    final FluentBarPosition effectivePosition = entry.resolvePosition(widget.config);
    final FluentBarEntranceAnimation animationType = entry.resolveEntranceAnimation(widget.config);

    return _buildEntranceTransition(child, animationType, effectivePosition);
  }

  CurvedAnimation _entranceCurveFor(FluentBarEntranceAnimation type) {
    final CurvedAnimation? cached = _entranceCurve;
    if (cached != null && _entranceCurveType == type) return cached;

    cached?.dispose();

    final CurvedAnimation created = switch (type) {
      FluentBarEntranceAnimation.bouncingSlide => CurvedAnimation(parent: _animController, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic),
      FluentBarEntranceAnimation.fadeSlide => CurvedAnimation(parent: _animController, curve: Curves.easeOutQuad, reverseCurve: Curves.easeIn),
      FluentBarEntranceAnimation.scale => CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn),
      FluentBarEntranceAnimation.elastic => CurvedAnimation(parent: _animController, curve: Curves.elasticOut, reverseCurve: Curves.easeIn),
      FluentBarEntranceAnimation.flip3d => CurvedAnimation(parent: _animController, curve: Curves.easeOutBack, reverseCurve: Curves.easeIn),
      _ => CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic),
    };

    _entranceCurve = created;
    _entranceCurveType = type;
    return created;
  }

  Animation<Offset> _slideFor(CurvedAnimation curve, Offset begin) {
    final (CurvedAnimation, Offset) key = (curve, begin);
    if (_slide != null && _slideKey == key) return _slide!;
    _slideKey = key;
    return _slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(curve);
  }

  Animation<double> _scaleFor(CurvedAnimation curve) {
    if (_scale != null && identical(_scaleCurve, curve)) return _scale!;
    _scaleCurve = curve;
    return _scale = Tween<double>(begin: 0.5, end: 1.0).animate(curve);
  }

  Widget _buildEntranceTransition(Widget child, FluentBarEntranceAnimation type, FluentBarPosition position) {
    final Offset beginOffset = _getBeginOffset(position);

    switch (type) {
      case FluentBarEntranceAnimation.bouncingSlide:
      case FluentBarEntranceAnimation.elastic:
        final CurvedAnimation curve = _entranceCurveFor(type);
        return SlideTransition(position: _slideFor(curve, beginOffset), child: child);

      case FluentBarEntranceAnimation.fadeSlide:
        final CurvedAnimation curve = _entranceCurveFor(type);
        final Offset shortOffset = Offset(beginOffset.dx / 3, beginOffset.dy / 3);
        return SlideTransition(
          position: _slideFor(curve, shortOffset),
          child: FadeTransition(opacity: curve, child: child),
        );

      case FluentBarEntranceAnimation.fade:
        return FadeTransition(opacity: _fadeIn, child: child);

      case FluentBarEntranceAnimation.scale:
        final CurvedAnimation curve = _entranceCurveFor(type);
        return ScaleTransition(
          scale: _scaleFor(curve),
          child: FadeTransition(opacity: curve, child: child),
        );

      case FluentBarEntranceAnimation.flip3d:
        final CurvedAnimation curve = _entranceCurveFor(type);
        final bool isTop = position == FluentBarPosition.top;

        final Alignment alignment = isTop ? Alignment.topCenter : (position == FluentBarPosition.bottom ? Alignment.bottomCenter : Alignment.center);

        return AnimatedBuilder(
          animation: curve,
          builder: (BuildContext context, Widget? childWidget) {
            final bool isReversing = _animController.status == AnimationStatus.reverse || _animController.status == AnimationStatus.dismissed;

            double beginAngle;
            if (isTop) {
              beginAngle = isReversing ? -math.pi / 2 : math.pi / 2;
            } else {
              beginAngle = isReversing ? math.pi / 2 : -math.pi / 2;
            }

            final Tween<double> angleTween = Tween<double>(begin: beginAngle, end: 0.0);

            final Matrix4 transform = Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateX(angleTween.evaluate(curve));

            return Transform(
              transform: transform,
              alignment: alignment,
              child: FadeTransition(opacity: curve, child: childWidget),
            );
          },
          child: child,
        );
      case FluentBarEntranceAnimation.slide:
        final CurvedAnimation curve = _entranceCurveFor(type);
        return SlideTransition(
          position: _slideFor(curve, beginOffset),
          child: FadeTransition(opacity: curve, child: child),
        );
    }
  }

  Widget _buildEffectTransition(Widget child) => AnimatedBuilder(
    animation: _effectAnimController,
    builder: (BuildContext context, Widget? animatedChild) {
      Matrix4 transform = Matrix4.identity();

      if (_currentEffect != null) {
        final double value = _effectAnimController.value;
        final double intensity = _currentEffect!.intensity;

        switch (_currentEffect!.type) {
          case FluentBarEffect.shake:
            final double offset = math.sin(value * math.pi * 4) * intensity;
            transform = Matrix4.translationValues(offset, 0, 0);
            break;
          case FluentBarEffect.bounce:
            final double scale = 1.0 + math.sin(value * math.pi) * intensity;
            transform = Matrix4.diagonal3Values(scale, scale, 1.0);
            break;
          case FluentBarEffect.pulse:
            final double scale = 1.0 + math.sin(value * math.pi) * (intensity - 1.0);
            transform = Matrix4.diagonal3Values(scale, scale, 1.0);
            break;
          case FluentBarEffect.heartbeat:
            final double curve = math.pow(math.sin(value * math.pi * 2), 2).toDouble();
            final double scale = 1.0 + curve * (intensity - 1.0);
            transform = Matrix4.diagonal3Values(scale, scale, 1.0);
            break;
          case FluentBarEffect.custom:
            final Widget? Function(BuildContext context, AnimationController controller, Widget child)? customBuilder = widget.entry.resolveCustomEffectBuilder(widget.config);
            if (customBuilder != null) {
              final Widget? builtWidget = customBuilder(context, _effectAnimController, animatedChild!);
              if (builtWidget != null) {
                return builtWidget;
              }
            }
            break;
        }
      }

      return Transform(transform: transform, alignment: Alignment.center, child: animatedChild);
    },
    child: child,
  );

  Widget _buildContent(FluentBarEntry<T> entry) {
    final Widget? Function(BuildContext context, FluentBarEntry<T> entry)? customBuilder = entry.resolveBuilder(widget.config);

    if (customBuilder != null) {
      final Widget? builtWidget = customBuilder(context, entry);
      if (builtWidget != null) {
        return builtWidget;
      }
    }

    return DefaultFluentBarWidget<T>(entry: entry, config: widget.config);
  }

  Widget _buildTapHandler(BuildContext context, FluentBarEntry<T> entry, Widget child) {
    final FluentBarCallbacks<T>? callbacks = entry.currentItem.callbacks;
    final bool dismissOnTap = entry.resolveDismissOnTap(widget.config);
    final bool hasOnTap = callbacks?.onTap != null;

    if (!hasOnTap && !dismissOnTap) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () async {
        final FluentBarLifecycleState state = entry.controller.stateNotifier.value;
        if (state != FluentBarLifecycleState.visible && state != FluentBarLifecycleState.showing) return;

        entry.internalController.recordInteraction(FluentBarInteraction.tap);
        FluentBarManager.instance.notifyAnalytics(FluentBarAnalyticsEvent.tapped, entry.currentItem);

        if (hasOnTap) {
          await FluentBarErrorHandler.instance.executeSafeAsync(overrideCall: () => callbacks!.onTap!(entry.currentItem.payload), type: FluentBarErrorType.callbackTap);
        }

        if (dismissOnTap) {
          entry.controller.close(reason: FluentBarDismissReason.tap);
        }
      },
      child: child,
    );
  }

  Widget _buildSwipeHandler(BuildContext context, FluentBarEntry<T> entry, Widget child) {
    final bool isSwipeEnabled = entry.resolveIsSwipeEnabled(widget.config);
    final DismissDirection dismissDirection = entry.resolveDismissDirection(widget.config);

    if (!isSwipeEnabled) {
      return child;
    }

    return Dismissible(
      key: Key(entry.currentItem.uuid),
      direction: dismissDirection,
      resizeDuration: null,
      onDismissed: (_) {
        entry.controller.close(reason: FluentBarDismissReason.swipe);
      },
      child: child,
    );
  }

  void _syncTouchHold() => widget.entry.internalController.setTouchHold(isHeld: _pointersDown > 0 || _isHovered);

  void _releaseTouchHold() {
    _pointersDown = 0;
    _isHovered = false;
    _syncTouchHold();
  }

  Widget _buildTouchHold(FluentBarEntry<T> entry, Widget child) {
    if (!entry.resolvePauseOnTouch(widget.config)) {
      // The setting may have been turned off while the bar was held.
      if (_pointersDown > 0 || _isHovered) _releaseTouchHold();
      return child;
    }

    return MouseRegion(
      onEnter: (_) {
        _isHovered = true;
        _syncTouchHold();
      },
      onExit: (_) {
        _isHovered = false;
        _syncTouchHold();
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _pointersDown++;
          _syncTouchHold();
        },
        onPointerUp: (_) => _onPointerGone(),
        onPointerCancel: (_) => _onPointerGone(),
        child: child,
      ),
    );
  }

  void _onPointerGone() {
    if (_pointersDown > 0) _pointersDown--;
    _syncTouchHold();
  }

  /// To a screen reader the bar is a live region by default: its appearance and text changes are
  /// announced by themselves. [FluentBarSemantics] can make it silent or hide it. The dismiss
  /// gesture of the reader closes a bar that can be swiped or tapped away.
  ///
  /// The widgets are the same in every mode, only their flags change: switching the mode of a
  /// visible bar keeps the state of everything below.
  Widget _buildSemantics(FluentBarEntry<T> entry, Widget child) {
    final bool canDismiss = entry.resolveIsSwipeEnabled(widget.config) || entry.resolveDismissOnTap(widget.config);
    final FluentBarSemantics mode = entry.resolveSemantics(widget.config);

    return ExcludeSemantics(
      excluding: mode == FluentBarSemantics.hidden,
      child: Semantics(
        container: true,
        liveRegion: mode == FluentBarSemantics.announce,
        onDismiss: canDismiss ? () => entry.controller.close(reason: FluentBarDismissReason.accessibility) : null,
        child: child,
      ),
    );
  }

  /// Insets from the screen edges. They come from two independent things:
  ///
  /// * the inset of an app panel: a top bar goes below the app bar, a bottom bar above the bottom
  ///   navigation. The resolver gives the value: the bar, its type, the config, then what the
  ///   wrapping widget of the panel measured;
  /// * the system safe area (notch, status bar, home gesture), applied with `useSafeArea`.
  ///
  /// The larger of the two is used, not the sum: the app bar and the bottom navigation already
  /// include the system inset. Side positions and bars with their own `positionBuilder` do not
  /// use the panel inset.
  ///
  /// The on-screen keyboard is always taken into account: bars live in an overlay above the
  /// screens, and a screen that shrinks for the keyboard does not move them. A bottom bar goes
  /// above the keyboard, a centered or side bar is centered in the visible part that is left.
  /// With a custom `positionBuilder` the builder alone decides.
  Widget _buildSafeArea(FluentBarEntry<T> entry, Widget child, {required bool useSafeArea, required FluentBarPosition position, required bool hasPositionBuilder}) {
    final bool isTop = position == FluentBarPosition.top;
    final bool isBottom = position == FluentBarPosition.bottom;
    if (hasPositionBuilder) return useSafeArea ? SafeArea(child: child) : child;

    if (!isTop && !isBottom) {
      // A separate Builder: while the keyboard moves only the inset is rebuilt, not the whole bar.
      return Builder(
        builder: (BuildContext context) {
          final EdgeInsets keyboard = EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom);
          return useSafeArea ? SafeArea(minimum: keyboard, child: child) : Padding(padding: keyboard, child: child);
        },
      );
    }

    return ValueListenableBuilder<double>(
      valueListenable: isTop ? FluentBarManager.instance.topInsetNotifier : FluentBarManager.instance.bottomInsetNotifier,
      child: child,
      builder: (BuildContext context, double measured, Widget? content) {
        final double inset = isTop
            ? entry.resolveTopInset(widget.config, measured: measured)
            // With the keyboard open the bottom panel of the app is hidden under it, so the larger inset wins.
            : math.max(entry.resolveBottomInset(widget.config, measured: measured), MediaQuery.viewInsetsOf(context).bottom);
        final EdgeInsets padding = isTop ? EdgeInsets.only(top: inset) : EdgeInsets.only(bottom: inset);

        return useSafeArea ? SafeArea(minimum: padding, child: content!) : Padding(padding: padding, child: content);
      },
    );
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<FluentBarItem<T>>(
    valueListenable: widget.entry.controller.itemNotifier,
    builder: (BuildContext context, FluentBarItem<T> currentItem, Widget? child) {
      final FluentBarEntry<T> currentEntry = widget.entry;

      final bool useSafeArea = currentEntry.resolveUseSafeArea(widget.config);
      final FluentBarPosition effectivePosition = currentEntry.resolvePosition(widget.config);
      final bool disableAnimations = currentEntry.resolveDisableAnimations(widget.config);

      if (_shownPosition != null && _shownPosition != effectivePosition && !disableAnimations) _moveController.forward(from: 0);
      _shownPosition = effectivePosition;

      final bool reduceMotion = widget.config.reducesMotion(context);
      if (reduceMotion && !_reduceMotion) {
        // The setting was turned on while the bar was visible: stop the running effect where it is.
        _deferredEffect = null;
        _currentEffect = null;
        _effectAnimController
          ..stop()
          ..value = 0;
      }
      _reduceMotion = reduceMotion;

      Widget content = _buildContent(currentEntry);

      final TextStyle baseTextStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
      content = DefaultTextStyle(
        style: baseTextStyle.copyWith(decoration: TextDecoration.none),
        child: content,
      );
      content = RepaintBoundary(key: _contentKey, child: content);
      content = _buildTapHandler(context, currentEntry, content);

      content = _buildSwipeHandler(context, currentEntry, content);
      content = _buildTouchHold(currentEntry, content);
      content = _buildSemantics(currentEntry, content);

      content = _buildEffectTransition(content);

      if (!disableAnimations) {
        content = FadeTransition(opacity: _moveFade, child: content);
        content = _buildTransition(context, currentEntry, content);
      }

      final Widget Function(BuildContext context, Widget child)? positionBuilder = currentEntry.resolvePositionBuilder(widget.config);

      content = _buildSafeArea(currentEntry, content, useSafeArea: useSafeArea, position: effectivePosition, hasPositionBuilder: positionBuilder != null);

      if (positionBuilder != null) {
        return positionBuilder(context, content);
      }

      return Align(alignment: _getAlignment(effectivePosition), child: content);
    },
  );
}

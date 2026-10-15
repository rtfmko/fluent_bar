import 'package:fluent_bar/src/internal.dart';

/// Maps a position to the region it belongs to.
extension FluentBarPositionX on FluentBarPosition {
  /// The region of this position: bottom for `bottom`, main for everything else.
  FluentBarRegion toRegion() => switch (this) {
    FluentBarPosition.top || FluentBarPosition.left || FluentBarPosition.right || FluentBarPosition.center => FluentBarRegion.main,
    FluentBarPosition.bottom => FluentBarRegion.bottom,
  };
}

/// Resolves the settings of an action button against a theme.
extension FluentBarActionsExtensionX<T> on FluentBarActions<T> {
  /// How many lines the action label may take: the action, then the theme.
  int resolveActionMaxLines(BuildContext context, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      maxActionLines ?? theme.actionMaxLines(context, type, themeMode: themeMode);

  /// How an action label that does not fit is cut: the action, then the theme.
  TextOverflow? resolveActionOverflow(BuildContext context, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      actionOverflow ?? theme.actionOverflow(context, type, themeMode: themeMode);
}

/// Layout helpers for a progress theme.
extension FluentBarProgressThemeExtensionX on FluentBarProgressTheme {
  /// Whether the indicator is a ring.
  bool get isCircular => style == FluentBarProgressStyle.circular;

  /// Whether the indicator sits beside the content or in place of the icon, where space is tight.
  bool get isCompactPosition => position == FluentBarProgressPosition.replaceIcon || position == FluentBarProgressPosition.left || position == FluentBarProgressPosition.right;

  /// The horizontal alignment of the text under a linear indicator.
  CrossAxisAlignment get linearCrossAxisAlignment {
    switch (textAlign) {
      case FluentBarProgressTextAlign.left:
        return CrossAxisAlignment.start;
      case FluentBarProgressTextAlign.right:
        return CrossAxisAlignment.end;
      case FluentBarProgressTextAlign.center:
        return CrossAxisAlignment.center;
    }
  }

  /// Whether the text is drawn inside a circular indicator.
  bool get shouldCenterText {
    if (textAlign == FluentBarProgressTextAlign.center) return true;
    if (isCircular && isCompactPosition) return true;
    return false;
  }
}

/// Access to the internal side of the controller of an entry.
extension FluentBarEntryExtensionX<T> on FluentBarEntry<T> {
  /// The controller of the entry as the library sees it.
  FluentBarInternalController<T> get internalController => controller as FluentBarInternalController<T>;
}

/// Resolves every setting of a bar in one order: the bar, then its type, then the config.
extension FluentBarEntryResolution<T> on FluentBarEntry<T> {
  /// The current content of the bar.
  FluentBarItem<T> get currentItem => controller.itemNotifier.value;

  /// The type of the bar with global overrides applied, guarded against throwing getters.
  FluentBarType resolvedType(FluentBarConfig config) => config.resolveType(currentItem.type);

  /// Whether the bar can be swiped away. Resolved from the bar, then its type, then the config.
  bool resolveIsSwipeEnabled(FluentBarConfig config) => currentItem.behavior.isSwipeEnabled ?? resolvedType(config).isSwipeEnabled ?? config.defaultIsSwipeEnabled;

  /// Whether a tap closes the bar. Resolved from the bar, then its type, then the config.
  bool resolveDismissOnTap(FluentBarConfig config) => currentItem.behavior.dismissOnTap ?? resolvedType(config).dismissOnTap ?? config.defaultDismissOnTap;

  /// Whether the countdown stops while the bar is held or hovered. Resolved from the bar, then its type, then the config.
  bool resolvePauseOnTouch(FluentBarConfig config) => currentItem.behavior.pauseOnTouch ?? resolvedType(config).pauseOnTouch ?? config.defaultPauseOnTouch;

  /// How the bar is presented to a screen reader: the bar, then its type, then the config.
  FluentBarSemantics resolveSemantics(FluentBarConfig config) => currentItem.behavior.semantics ?? resolvedType(config).semantics ?? config.defaultSemantics;

  /// Resolution order: the bar, its type, the config, then [measured] - the height of the app bar
  /// reported by `FluentBarTopInset` (0 if there is none).
  double resolveTopInset(FluentBarConfig config, {required double measured}) => (currentItem.behavior.topInset ?? resolvedType(config).topInset ?? config.topInset ?? measured).nonNegative;

  /// Resolution order: the bar, its type, the config, then [measured] (see `FluentBarBottomInset`).
  double resolveBottomInset(FluentBarConfig config, {required double measured}) => (currentItem.behavior.bottomInset ?? resolvedType(config).bottomInset ?? config.bottomInset ?? measured).nonNegative;

  /// Whether the bar keeps clear of the system safe area. Resolved from the bar, then its type, then the config.
  bool resolveUseSafeArea(FluentBarConfig config) => currentItem.behavior.useSafeArea ?? resolvedType(config).useSafeArea ?? config.defaultUseSafeArea;

  /// Whether the countdown line is shown. Resolved from the bar, then its type, then the config.
  bool resolveShowTimeoutBar(FluentBarConfig config) => currentItem.appearance.showTimeoutBar ?? resolvedType(config).showTimeoutBar ?? config.defaultShowTimeoutBar;

  /// Whether the close button is shown: the bar, then its type, then the config.
  bool resolveShowCloseButton(FluentBarConfig config) => currentItem.appearance.showCloseButton ?? resolvedType(config).showCloseButton ?? config.defaultShowCloseButton;

  /// Where the countdown line sits inside the bar. Resolved from the bar, then its type, then the config.
  FluentBarTimeoutBarPosition resolveTimeoutBarPosition(FluentBarConfig config) =>
      currentItem.appearance.timeoutBarPosition ?? resolvedType(config).timeoutBarPosition ?? config.defaultTimeoutBarPosition;

  /// Whether the icon is shown. Resolved from the bar, then its type, then the config.
  bool resolveShowIcon(FluentBarConfig config) => currentItem.appearance.showIcon ?? resolvedType(config).showIcon ?? config.defaultShowIcons;

  /// Whether the animations of the bar are turned off. Resolved from the bar, then its type, then the config.
  bool resolveDisableAnimations(FluentBarConfig config) => currentItem.appearance.disableAnimations ?? resolvedType(config).disableAnimations ?? config.defaultDisableAnimations;

  /// Whether the bar stays until closed (see `FluentBarItemResolution.resolveIsPersistent`).
  bool resolveIsPersistent(FluentBarConfig config) => currentItem.resolveIsPersistent(config);

  /// How many lines the title may take. Resolved from the bar, then the theme.
  int resolveMaxTitleLines(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.maxTitleLines ?? theme.maxTitleLines(context, resolvedType(config), themeMode: themeMode);

  /// How many lines the message may take. Resolved from the bar, then the theme.
  int resolveMaxMessageLines(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.maxMessageLines ?? theme.maxMessageLines(context, resolvedType(config), themeMode: themeMode);

  /// How a title that does not fit is cut. Resolved from the bar, then the theme.
  TextOverflow? resolveTitleOverflow(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.titleOverflow ?? theme.titleOverflow(context, resolvedType(config), themeMode: themeMode);

  /// How a message that does not fit is cut. Resolved from the bar, then the theme.
  TextOverflow? resolveMessageOverflow(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.messageOverflow ?? theme.messageOverflow(context, resolvedType(config), themeMode: themeMode);

  /// The size of the icon. Resolved from the bar, then the theme.
  double resolveIconSize(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.iconSize ?? theme.iconSize(context, resolvedType(config), themeMode: themeMode);

  /// The color of the icon. Resolved from the bar, then the theme.
  Color? resolveIconColor(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.iconColor ?? theme.iconColor(context, resolvedType(config), themeMode: themeMode);

  /// The icon of the bar. Resolved from the bar, then its type, then the theme: a theme with its own
  /// `defaultIcon` does not hide the icon of a type.
  Widget resolveIcon(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config, {required double size}) {
    final FluentBarType type = resolvedType(config);
    return currentItem.appearance.icon ?? type.icon ?? theme.defaultIcon(context, type, themeMode: themeMode, overrideSize: size);
  }

  /// The icon of the close button. Resolved from the bar, then its type, then the theme.
  Widget resolveCloseIcon(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) {
    final FluentBarType type = resolvedType(config);
    return currentItem.appearance.closeIcon ?? type.closeIcon ?? theme.closeIcon(context, type, themeMode: themeMode);
  }

  /// The decoration of the bar: the decoration of the theme with the overrides of the bar applied.
  BoxDecoration resolveDecoration(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) {
    BoxDecoration themeDecoration = theme.boxDecoration(context, resolvedType(config), theme, themeMode: themeMode);

    final BoxDecoration? customDecoration = currentItem.appearance.decoration;
    if (customDecoration != null) {
      themeDecoration = themeDecoration.copyWith(
        color: customDecoration.color ?? currentItem.appearance.backgroundColor ?? themeDecoration.color,
        image: customDecoration.image,
        border: customDecoration.border,
        borderRadius: customDecoration.borderRadius,
        boxShadow: customDecoration.boxShadow,
        gradient: customDecoration.gradient,
        backgroundBlendMode: customDecoration.backgroundBlendMode,
        shape: customDecoration.shape,
      );
    } else if (currentItem.appearance.backgroundColor != null) {
      themeDecoration = themeDecoration.copyWith(color: currentItem.appearance.backgroundColor);
    }

    // A gradient is painted over the color. If the color is set on the bar and the gradient came
    // from the theme, the gradient is dropped, or the color of the bar would not be visible.
    final bool hasLocalColor = customDecoration?.color != null || currentItem.appearance.backgroundColor != null;
    if (hasLocalColor && customDecoration?.gradient == null && themeDecoration.gradient != null) {
      themeDecoration = BoxDecoration(
        color: themeDecoration.color,
        image: themeDecoration.image,
        border: themeDecoration.border,
        borderRadius: themeDecoration.borderRadius,
        boxShadow: themeDecoration.boxShadow,
        backgroundBlendMode: themeDecoration.backgroundBlendMode,
        shape: themeDecoration.shape,
      );
    }

    return themeDecoration;
  }

  /// The corner radius of the bar, taken from its resolved decoration.
  BorderRadius resolveBorderRadius(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) {
    final BorderRadiusGeometry? radius = resolveDecoration(context, theme, themeMode, config).borderRadius;
    if (radius == null) return theme.borderRadius(context, resolvedType(config), themeMode: themeMode);
    if (radius is BorderRadius) return radius;
    return radius.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr);
  }

  /// The size limits of the bar. Resolved from the bar, then the theme.
  BoxConstraints resolveConstraints(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.constraints ?? theme.constraints(context, resolvedType(config), themeMode: themeMode);

  /// The size limits of the action button. Resolved from the bar, then the theme.
  BoxConstraints resolveActionsConstraints(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.actionsConstraints ?? theme.actionsConstraints(context, resolvedType(config), themeMode: themeMode);

  /// The space around the bar. Resolved from the bar, then the theme.
  EdgeInsets resolveMargin(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.margin ?? theme.margin(context, resolvedType(config), themeMode: themeMode);

  /// The space inside the bar. Resolved from the bar, then the theme.
  EdgeInsets resolvePadding(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.padding ?? theme.padding(context, resolvedType(config), themeMode: themeMode);

  /// How the title is aligned. Resolved from the bar, then the theme.
  TextAlign? resolveTitleTextAlign(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.titleTextAlign ?? theme.titleTextAlign(context, resolvedType(config), themeMode: themeMode);

  /// How the message is aligned. Resolved from the bar, then the theme.
  TextAlign? resolveMessageTextAlign(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.messageTextAlign ?? theme.messageTextAlign(context, resolvedType(config), themeMode: themeMode);

  /// How the action label is aligned. Resolved from the bar, then the theme.
  TextAlign? resolveActionTextAlign(BuildContext context, FluentBarTheme theme, FluentBarThemeMode themeMode, FluentBarConfig config) =>
      currentItem.appearance.actionTextAlign ?? theme.actionTextAlign(context, resolvedType(config), themeMode: themeMode);

  /// How long the bar takes to appear. Resolved from the bar, then its type, then the config.
  Duration resolveTransitionDuration(FluentBarConfig config) {
    final Duration raw = currentItem.appearance.transitionDuration ?? resolvedType(config).transitionDuration ?? config.defaultTransitionDuration;
    return raw.nonNegative;
  }

  /// How long the bar takes to leave. Resolved from the bar, then its type, then the config.
  Duration resolveReverseTransitionDuration(FluentBarConfig config) {
    final Duration raw = currentItem.appearance.reverseTransitionDuration ?? resolvedType(config).reverseTransitionDuration ?? config.defaultReverseTransitionDuration;
    return raw.nonNegative;
  }

  /// The planned lifetime of the bar, ignoring persistence.
  Duration resolveDuration(FluentBarConfig config) => currentItem.resolveDuration(config);

  /// The lifetime of the bar; `null` when it is persistent.
  Duration? resolveEffectiveDuration(FluentBarConfig config) => currentItem.resolveEffectiveDuration(config);

  /// Where the bar appears. Resolved from the bar, then its type, then the config.
  FluentBarPosition resolvePosition(FluentBarConfig config) => currentItem.resolvePosition(config);

  /// The guarded position builder of the bar, if one applies.
  ///
  /// An explicit position set closer to the bar cancels a builder set further away.
  Widget Function(BuildContext context, Widget child)? resolvePositionBuilder(FluentBarConfig config) {
    if (currentItem.behavior.positionBuilder != null) {
      return _wrapPositionBuilder(currentItem.behavior.positionBuilder!, config);
    }

    if (currentItem.behavior.position != null) {
      return null;
    }

    final FluentBarType resolvedTypeData = resolvedType(config);
    if (resolvedTypeData.positionBuilder != null) {
      return _wrapPositionBuilder(resolvedTypeData.positionBuilder!, config);
    }
    if (resolvedTypeData.position != null) {
      return null;
    }

    if (config.defaultPositionBuilder != null) {
      return _wrapPositionBuilder(config.defaultPositionBuilder!, config);
    }

    return null;
  }

  /// The guarded transition builder of the bar, if one applies.
  ///
  /// An explicit entrance animation set closer to the bar cancels a builder set further away.
  Widget Function(BuildContext context, Animation<double> animation, Widget child)? resolveTransitionBuilder(FluentBarConfig config) {
    if (currentItem.appearance.transitionBuilder != null) {
      return _wrapTransitionBuilder(currentItem.appearance.transitionBuilder!, config);
    }

    if (currentItem.appearance.entranceAnimation != null) {
      return null;
    }

    final FluentBarType resolvedTypeData = resolvedType(config);
    if (resolvedTypeData.transitionBuilder != null) {
      return _wrapTransitionBuilder(resolvedTypeData.transitionBuilder!, config);
    }
    if (resolvedTypeData.entranceAnimation != null) {
      return null;
    }

    if (config.defaultTransitionBuilder != null) {
      return _wrapTransitionBuilder(config.defaultTransitionBuilder!, config);
    }

    return null;
  }

  Widget Function(BuildContext context, Widget child) _wrapPositionBuilder(Widget Function(BuildContext context, Widget child) builder, FluentBarConfig config) {
    return (BuildContext context, Widget child) => FluentBarErrorHandler.instance.executeSafe<Widget>(
      overrideCall: () => builder(context, child),
      fallbackCall: () => child,
      type: FluentBarErrorType.fluentBarResolver,
      debugContext: 'resolvePositionBuilder',
    );
  }

  Widget Function(BuildContext context, Animation<double> animation, Widget child) _wrapTransitionBuilder(
    Widget Function(BuildContext context, Animation<double> animation, Widget child) builder,
    FluentBarConfig config,
  ) {
    return (BuildContext context, Animation<double> animation, Widget child) => FluentBarErrorHandler.instance.executeSafe<Widget>(
      overrideCall: () => builder(context, animation, child),
      fallbackCall: () => child,
      type: FluentBarErrorType.customBuilderTransition,
      debugContext: 'resolveTransitionBuilder',
    );
  }

  /// Which way the bar can be swiped away; without an explicit value it follows the position.
  DismissDirection resolveDismissDirection(FluentBarConfig config) {
    final DismissDirection? explicitDirection = currentItem.behavior.dismissDirection ?? resolvedType(config).dismissDirection ?? config.defaultDismissDirection;

    if (explicitDirection != null) {
      return explicitDirection;
    }

    return switch (resolvePosition(config)) {
      FluentBarPosition.top => DismissDirection.up,
      FluentBarPosition.right => DismissDirection.horizontal,
      FluentBarPosition.bottom => DismissDirection.down,
      FluentBarPosition.left => DismissDirection.horizontal,
      FluentBarPosition.center => DismissDirection.horizontal,
    };
  }

  /// What happens when the bar is shown again with the same id. Resolved from the bar, then its type, then the config.
  FluentBarDuplicatePolicy resolveDuplicatePolicy(FluentBarConfig config) => currentItem.behavior.duplicatePolicy ?? resolvedType(config).duplicatePolicy ?? config.defaultDuplicatePolicy;

  /// What happens when the bar moves into a busy region. Resolved from the bar, then its type, then the config.
  FluentBarRelocationStrategy resolveRelocationStrategy(FluentBarConfig config) => currentItem.resolveRelocationStrategy(config);

  /// The light or dark look of the bar. Resolved from the bar, then its type, then the config.
  FluentBarThemeMode resolveThemeMode(FluentBarConfig config) => currentItem.appearance.themeMode ?? resolvedType(config).themeMode ?? config.defaultThemeMode;

  /// The priority of the bar: the bar, then its type.
  FluentBarPriority resolvePriority(FluentBarConfig config) => currentItem.behavior.priority ?? resolvedType(config).priority;

  /// The haptic feedback played when the bar appears: the bar, then its type.
  FluentBarHapticType resolveHaptic(FluentBarConfig config) => currentItem.behavior.haptic ?? resolvedType(config).haptic;

  /// Which way the countdown line moves. Resolved from the bar, then its type, then the config.
  FluentBarTimeoutBarDirection resolveTimeoutBarDirection(FluentBarConfig config) =>
      currentItem.appearance.timeoutBarDirection ?? resolvedType(config).timeoutBarDirection ?? config.defaultTimeoutBarDirection;

  /// The levels merge field by field: the bar overrides only what it set itself, the rest comes
  /// from the type, then from the config.
  FluentBarProgressTheme resolveProgressTheme(FluentBarConfig config) =>
      (currentItem.appearance.progressTheme ?? const FluentBarProgressTheme()).mergedOver(resolvedType(config).progressTheme).mergedOver(config.progressTheme);

  /// How the progress text changes when the value updates.
  FluentBarProgressTextEffect resolveProgressTextEffect(FluentBarConfig config) => resolveProgressTheme(config).textEffect;

  /// The guarded custom progress indicator of the bar, if there is one.
  Widget? Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? resolveProgressBuilder(FluentBarConfig config) {
    final Widget Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? userBuilder = resolveProgressTheme(config).progressBuilder;

    if (userBuilder == null) return null;

    return (BuildContext context, ValueListenable<FluentBarProgressState?> notifier) => FluentBarErrorHandler.instance.executeSafe<Widget?>(
      overrideCall: () => userBuilder(context, notifier),
      fallbackCall: () => null,
      type: FluentBarErrorType.customProgressBuilder,
      debugContext: 'resolveProgressBuilder',
    );
  }

  /// The guarded content builder of the bar, if there is one. Resolved from the bar, then its type, then the config.
  Widget? Function(BuildContext context, FluentBarEntry<T> entry)? resolveBuilder(FluentBarConfig config) {
    final Widget Function(BuildContext context, FluentBarEntry<T> entry)? userBuilder = currentItem.appearance.builder ?? resolvedType(config).builder ?? config.defaultBuilder;

    if (userBuilder == null) return null;

    return (BuildContext context, FluentBarEntry<T> entry) => FluentBarErrorHandler.instance.executeSafe<Widget?>(
      overrideCall: () => userBuilder(context, entry),
      fallbackCall: () => null,
      type: FluentBarErrorType.customBuilderAppearance,
      debugContext: 'resolveBuilder',
    );
  }

  /// A custom haptic (the bar, then its type) always wins over the [FluentBarHapticType] value.
  FutureOr<void> Function()? resolveHapticCallback(FluentBarConfig config) => currentItem.callbacks?.haptic ?? resolvedType(config).customHaptic;

  /// The guarded custom effect builder of the bar, if there is one: the bar, then its type.
  Widget? Function(BuildContext context, AnimationController controller, Widget child)? resolveCustomEffectBuilder(FluentBarConfig config) {
    final Widget Function(BuildContext context, AnimationController controller, Widget child)? userBuilder = currentItem.appearance.customEffectBuilder ?? resolvedType(config).customEffectBuilder;

    if (userBuilder == null) return null;

    return (BuildContext context, AnimationController controller, Widget child) => FluentBarErrorHandler.instance.executeSafe<Widget?>(
      overrideCall: () => userBuilder(context, controller, child),
      fallbackCall: () => null,
      type: FluentBarErrorType.customBuilderEffect,
      debugContext: 'resolveCustomEffectBuilder',
    );
  }

  /// How the bar enters and leaves the screen. Resolved from the bar, then its type, then the config.
  FluentBarEntranceAnimation resolveEntranceAnimation(FluentBarConfig config) => currentItem.appearance.entranceAnimation ?? resolvedType(config).entranceAnimation ?? config.defaultEntranceAnimation;
}

/// The duplicate rule.
extension FluentBarItemDuplicateX<T> on FluentBarItem<T> {
  /// Whether this bar and [other] are the same bar: the custom rule of the config, otherwise equal ids, otherwise equal bars.
  bool isDuplicateOf(FluentBarItem<dynamic> other, FluentBarConfig config) {
    if (config.duplicateComparator != null) {
      return FluentBarErrorHandler.instance.executeSafe<bool>(
        overrideCall: () => config.duplicateComparator!(this as FluentBarItem<dynamic>, other),
        fallbackCall: () => false,
        type: FluentBarErrorType.callbackDuplicateComparator,
        debugContext: 'isDuplicateOf',
      );
    }

    if (id != null && other.id != null) {
      return id == other.id;
    }

    return this == other;
  }
}

/// Resolves a type against the global overrides.
extension FluentBarConfigResolution on FluentBarConfig {
  /// The type with `typeOverrides` applied, wrapped in a guard: from here on the library reads its
  /// getters without fearing exceptions from a user subclass of [FluentBarType].
  FluentBarType resolveType(FluentBarType type) => FluentBarType.guard(typeOverrides?[type] ?? type);
}

/// Comparing and merging items.
extension FluentBarItemMerging<T> on FluentBarItem<T> {
  /// A progress update by "the same" bar: progress, texts and type come from [incoming], the rest
  /// (action, callbacks, behavior, look, duration) stays. The title changes only if it is set.
  FluentBarItem<T> withProgressFrom(FluentBarItem<dynamic> incoming) =>
      copyWith(type: incoming.type, title: incoming.title, message: incoming.message, progressState: incoming.progressState, clearProgressState: incoming.progressState == null);

  /// Equality by everything except progress.
  ///
  /// Progress is a part of the item, but it updates much more often than the rest and is drawn
  /// by a separate widget from its own notifier, so the controller must tell "only the progress
  /// changed" from "the bar itself changed".
  bool isSameIgnoringProgress(FluentBarItem<dynamic> other) =>
      identical(this, other) ||
      runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          title == other.title &&
          message == other.message &&
          duration == other.duration &&
          payload == other.payload &&
          isPersistent == other.isPersistent &&
          mapEquals(meta, other.meta) &&
          behavior == other.behavior &&
          actions == other.actions &&
          appearance == other.appearance &&
          preset == other.preset &&
          setEquals(tags, other.tags);
}

/// Settings that are resolved on the item itself, before it is bound to an entry.
extension FluentBarItemResolution<T> on FluentBarItem<T> {
  /// The type of the bar with global overrides applied, guarded against throwing getters.
  FluentBarType resolvedType(FluentBarConfig config) => config.resolveType(type);

  /// Where the bar appears. Resolved from the bar, then its type, then the config.
  FluentBarPosition resolvePosition(FluentBarConfig config) => behavior.position ?? resolvedType(config).position ?? config.defaultPosition;

  /// What happens when the bar moves into a busy region. Resolved from the bar, then its type, then the config.
  FluentBarRelocationStrategy resolveRelocationStrategy(FluentBarConfig config) => behavior.relocationStrategy ?? resolvedType(config).relocationStrategy ?? config.defaultRelocationStrategy;

  /// Persistent if it says so (the item, then its type) or while it has unfinished progress.
  bool resolveIsPersistent(FluentBarConfig config) {
    if (isPersistent ?? resolvedType(config).isPersistent ?? false) return true;

    return progressState != null && !progressState!.isCompleted;
  }

  /// The planned lifetime of the bar, ignoring persistence. Resolved from the bar, then its type, then the config.
  Duration resolveDuration(FluentBarConfig config) => (duration ?? resolvedType(config).duration ?? config.defaultDuration).nonNegative;

  /// `null` means persistent.
  Duration? resolveEffectiveDuration(FluentBarConfig config) => resolveIsPersistent(config) ? null : resolveDuration(config);

  /// The color of the loader on the action button: the action, then the theme.
  Color resolveActionLoaderColor(BuildContext context, FluentBarTheme theme, FluentBarType type, FluentBarThemeMode themeMode) =>
      actions?.actionLoaderColor ?? theme.actionLoaderColor(context, type, themeMode: themeMode);

  /// What happens when the bar is shown again with the same id. Resolved from the bar, then its type, then the config.
  FluentBarDuplicatePolicy resolveDuplicatePolicy(FluentBarConfig config) => behavior.duplicatePolicy ?? resolvedType(config).duplicatePolicy ?? config.defaultDuplicatePolicy;

  /// The haptic feedback played when the progress completes: the bar, then its type.
  FluentBarHapticType resolveProgressCompletedHaptic(FluentBarConfig config) => behavior.progressCompletedHaptic ?? resolvedType(config).progressCompletedHaptic;

  /// A custom haptic (the bar, then its type) always wins over the [FluentBarHapticType] value.
  FutureOr<void> Function()? resolveProgressCompletedHapticCallback(FluentBarConfig config) => callbacks?.progressCompletedHaptic ?? resolvedType(config).customProgressCompletedHaptic;

  /// The widget shown on the action button while its handler runs: the action, then the theme.
  Widget? resolveActionLoadingWidget(BuildContext context, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      actions?.actionLoadingWidget ?? theme.actionLoadingWidget(context, type, themeMode: themeMode);
}

/// A whole percent for display. Rounded down (99.6% is not "100%" yet), with a correction for
/// binary arithmetic: `0.29 * 100` is 28.999999999999996 and would otherwise show as "28%".
int progressPercentOf(double fraction) => fraction.isFinite ? (fraction * 100 + 1e-9).floor() : 0;

/// Keeps an inset usable.
extension SafeInsetExtension on double {
  /// This value, or zero if it is negative or not a number.
  double get nonNegative => isNaN || this < 0 ? 0 : this;
}

/// Keeps a duration usable.
extension SafeDurationExtension on Duration {
  /// This duration, or zero if it is negative.
  Duration get nonNegative => isNegative ? Duration.zero : this;
}

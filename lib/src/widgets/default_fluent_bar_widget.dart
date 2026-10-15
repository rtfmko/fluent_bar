import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';

/// The standard content of a bar: icon, title, message, action, progress and countdown line, drawn with the resolved theme.
class DefaultFluentBarWidget<T> extends StatelessWidget {
  /// The bar to draw.
  final FluentBarEntry<T> entry;

  /// The global config in effect.
  final FluentBarConfig config;

  /// Creates the standard content for [entry].
  const DefaultFluentBarWidget({super.key, required this.entry, required this.config});

  @override
  Widget build(BuildContext context) {
    final FluentBarType resolvedType = config.resolveType(entry.currentItem.type);
    final FluentBarTheme builtInTheme = _resolvePlatformTheme(context, config.themeStyle);
    final FluentBarTheme theme = entry.currentItem.appearance.theme ?? config.defaultTheme ?? builtInTheme;
    final FluentBarThemeMode themeMode = entry.resolveThemeMode(config);

    // A theme may be user code and its methods may throw. The bar must survive that: report the
    // error and draw the bar with the built-in platform theme.
    return FluentBarErrorHandler.instance.executeSafe<Widget>(
      overrideCall: () => _buildBar(context, resolvedType, theme, themeMode),
      fallbackCall: () => _buildBar(context, resolvedType, builtInTheme, themeMode),
      type: FluentBarErrorType.fluentBarTheme,
      debugContext: 'DefaultFluentBarWidget.build',
    );
  }

  Widget _buildBar(BuildContext context, FluentBarType resolvedType, FluentBarTheme theme, FluentBarThemeMode themeMode) =>
      Padding(padding: entry.resolveMargin(context, theme, themeMode, config), child: _buildContent(context, resolvedType, theme, themeMode));

  FluentBarTheme _resolvePlatformTheme(BuildContext context, FluentBarThemeStyle style) {
    if (style == FluentBarThemeStyle.cupertino) return FluentBarTheme.cupertino;
    if (style == FluentBarThemeStyle.material) return FluentBarTheme.material;
    if (style == FluentBarThemeStyle.windows) return FluentBarTheme.windows;

    final TargetPlatform platform = Theme.of(context).platform;
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return FluentBarTheme.cupertino;
    } else if (platform == TargetPlatform.windows) {
      return FluentBarTheme.windows;
    }

    return FluentBarTheme.material;
  }

  Widget _buildContent(BuildContext context, FluentBarType resolvedType, FluentBarTheme theme, FluentBarThemeMode themeMode) {
    final FluentBarAppearance<T> appearance = entry.currentItem.appearance;
    final FluentBarProgressState? progressState = entry.currentItem.progressState;
    final FluentBarProgressTheme progressTheme = entry.resolveProgressTheme(config);

    // The theme is user code and these values are needed in several places: compute each one once,
    // and only if it is needed.
    late final double spacing = theme.spacing(context, resolvedType, themeMode: themeMode);
    late final double iconSize = entry.resolveIconSize(context, theme, themeMode, config);
    late final BoxDecoration decoration = entry.resolveDecoration(context, theme, themeMode, config);

    // Theme values are read here, inside the guarded build, and not in the builder below, which
    // runs later and on every step of a color fade.
    final bool showCloseButton = entry.resolveShowCloseButton(config);
    final Widget? closeIcon = showCloseButton ? entry.resolveCloseIcon(context, theme, themeMode, config) : null;
    final double closeIconSize = showCloseButton ? theme.closeIconSize(context, resolvedType, themeMode: themeMode) : 0;
    final EdgeInsets closePadding = showCloseButton ? theme.closeButtonPadding(context, resolvedType, themeMode: themeMode) : EdgeInsets.zero;
    final Color? closeColor = showCloseButton ? theme.closeIconColor(context, resolvedType, themeMode: themeMode) : null;
    final CrossAxisAlignment closeAlignment = showCloseButton ? theme.closeButtonAlignment(context, resolvedType, themeMode: themeMode) : CrossAxisAlignment.center;

    final bool shouldShowProgress = entry.resolveShowTimeoutBar(config);
    final FluentBarTimeoutBarPosition timeoutPosition = entry.resolveTimeoutBarPosition(config);

    final bool noAnimations = entry.resolveDisableAnimations(config);
    final Duration restyle = noAnimations ? Duration.zero : kFluentBarRestyleDuration;
    // With "reduce motion" the icon switch (a scale) is instant; colors still fade.
    // Not zero: an AnimatedSize with a zero duration completes during layout and fails an assert.
    final Duration iconSwitch = noAnimations || config.reducesMotion(context) ? const Duration(milliseconds: 1) : const Duration(milliseconds: 300);

    Widget? taskProgressWidget;

    if (progressState != null) {
      final Widget? Function(BuildContext context, ValueListenable<FluentBarProgressState?> notifier)? customBuilder = entry.resolveProgressBuilder(config);

      if (customBuilder != null) {
        taskProgressWidget = customBuilder(context, entry.internalController.progressStateNotifier);
      }

      final bool successFitsIcon = progressTheme.position == FluentBarProgressPosition.replaceIcon || !progressTheme.isCircular;
      final double effectiveSuccessIconSize = successFitsIcon ? iconSize : (progressTheme.size ?? iconSize);

      if (taskProgressWidget == null) {
        final FluentBarProgressTextEffect textEffect = entry.resolveProgressTextEffect(config);
        final Widget? afterSuccess = progressTheme.position == FluentBarProgressPosition.replaceIcon && entry.resolveShowIcon(config)
            ? entry.resolveIcon(context, theme, themeMode, config, size: iconSize)
            : null;
        final Widget successIcon =
            progressTheme.successIcon ??
            Icon(
              Icons.check_circle,
              color: progressTheme.successIconColor ?? theme.iconColor(context, config.resolveType(FluentBarType.success), themeMode: themeMode),
              size: effectiveSuccessIconSize,
            );

        taskProgressWidget = FluentBarColorFade(
          color: entry.resolveIconColor(context, theme, themeMode, config) ?? Colors.white,
          duration: restyle,
          builder: (BuildContext context, Color? color) => FluentBarTaskProgressWidget(
            progressNotifier: entry.internalController.progressStateNotifier,
            theme: progressTheme,
            textEffect: textEffect,
            afterSuccess: afterSuccess,
            defaultColor: color ?? Colors.white,
            successIcon: successIcon,
          ),
        );
      }

      // Its own semantics node: the bar is a live region, and a percent merged into it would be
      // read out on every update.
      final Widget progressLoader = taskProgressWidget;
      taskProgressWidget = Semantics(
        container: !progressTheme.announceUpdates,
        child: RepaintBoundary(child: progressLoader),
      );
    }

    // What sits in the icon slot and whether it is "the same icon" as before decides whether the
    // switch animation plays. See [_iconIdentity].
    Widget? activeIcon;
    Key? iconKey;
    if (taskProgressWidget != null && progressTheme.position == FluentBarProgressPosition.replaceIcon) {
      activeIcon = SizedBox(
        width: iconSize,
        height: iconSize,
        child: Center(child: taskProgressWidget),
      );
      // An indicator in the icon slot stays the same widget whatever happens to the type of the bar:
      // it plays the switch to the success icon itself.
      iconKey = const ValueKey<String>('progress_in_icon_slot');
      taskProgressWidget = null;
    } else if (entry.resolveShowIcon(config)) {
      final Widget? ownIcon = appearance.icon;
      activeIcon = entry.resolveIcon(context, theme, themeMode, config, size: iconSize);
      iconKey = ValueKey<Object>(ownIcon != null ? _iconIdentity(ownIcon) : (resolvedType.name, _iconIdentity(activeIcon)));
    }

    final TextDirection textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final List<Widget> rowChildren = <Widget>[];

    if (taskProgressWidget != null && progressTheme.position == FluentBarProgressPosition.left) {
      rowChildren.addAll(<Widget>[Flexible(fit: FlexFit.loose, child: taskProgressWidget), SizedBox(width: spacing)]);
    }

    Widget? activeIconWidget;
    if (activeIcon != null) {
      final Widget icon = activeIcon;
      // Read here, in the guarded build: the color fade calls its builder later.
      final double size = iconSize;

      activeIconWidget = KeyedSubtree(
        key: iconKey,
        child: Padding(
          padding: EdgeInsetsDirectional.only(end: spacing),
          child: FluentBarColorFade(
            color: entry.resolveIconColor(context, theme, themeMode, config),
            duration: restyle,
            builder: (BuildContext context, Color? color) => IconTheme(
              data: IconThemeData(color: color, size: size),
              child: SizedBox(
                width: size,
                height: size,
                child: Center(child: icon),
              ),
            ),
          ),
        ),
      );
    }
    rowChildren.add(
      AnimatedSize(
        duration: iconSwitch,
        curve: Curves.easeInOutCubic,
        child: AnimatedSwitcher(
          duration: iconSwitch,
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          // The children go into the stack as they are: a wrapper around the leaving ones would
          // move them in the tree and reset their state for the time of the exit.
          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) => Stack(alignment: Alignment.center, children: <Widget>[...previousChildren, ?currentChild]),
          child: activeIconWidget ?? const SizedBox.shrink(key: ValueKey<String>('no_icon')),
        ),
      ),
    );

    rowChildren.add(
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (entry.currentItem.title != null) ...<Widget>[
              _fadingText(
                entry.currentItem.title!,
                theme.titleStyle(context, resolvedType, themeMode: themeMode),
                restyle,
                textAlign: entry.resolveTitleTextAlign(context, theme, themeMode, config),
                maxLines: entry.resolveMaxTitleLines(context, theme, themeMode, config),
                overflow: entry.resolveTitleOverflow(context, theme, themeMode, config),
              ),
              SizedBox(height: theme.titleSpacing(context, resolvedType, themeMode: themeMode)),
            ],
            _fadingText(
              entry.currentItem.message,
              theme.messageStyle(context, resolvedType, themeMode: themeMode),
              restyle,
              textAlign: entry.resolveMessageTextAlign(context, theme, themeMode, config),
              maxLines: entry.resolveMaxMessageLines(context, theme, themeMode, config),
              overflow: entry.resolveMessageOverflow(context, theme, themeMode, config),
            ),
          ],
        ),
      ),
    );

    if (taskProgressWidget != null && progressTheme.position == FluentBarProgressPosition.right) {
      rowChildren.addAll(<Widget>[SizedBox(width: spacing), Flexible(fit: FlexFit.loose, child: taskProgressWidget)]);
    }

    rowChildren.add(
      // AnimatedSize clips only a child larger than its box, and a leaving button takes no room.
      ClipRect(
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          alignment: AlignmentDirectional.centerStart,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child),
            // Only the new child takes space: the room of a leaving button closes while it fades,
            // in one motion. Both kinds of children sit in the same slot widget under their own key,
            // so a button keeps its state when it turns from the current child into a leaving one.
            layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) => Stack(
              alignment: AlignmentDirectional.centerStart,
              clipBehavior: Clip.none,
              children: <Widget>[
                for (final Widget previous in previousChildren) FluentBarSwitcherSlot(key: previous.key, isLeaving: true, textDirection: textDirection, child: previous),
                if (currentChild != null) FluentBarSwitcherSlot(key: currentChild.key, isLeaving: false, textDirection: textDirection, child: currentChild),
              ],
            ),
            child: _buildActions(context, resolvedType, theme, themeMode),
          ),
        ),
      ),
    );

    // Always the same two-level row, with or without the button: turning the button on for a
    // visible bar must not rebuild the content next to it.
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      // Only the three placements make sense here; stretch and baseline would break the bar.
      crossAxisAlignment: closeAlignment == CrossAxisAlignment.start || closeAlignment == CrossAxisAlignment.end ? closeAlignment : CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Row(mainAxisSize: MainAxisSize.min, children: rowChildren),
        ),
        if (showCloseButton)
          Padding(
            padding: EdgeInsetsDirectional.only(start: spacing / 2),
            child: FluentBarColorFade(
              color: closeColor,
              duration: restyle,
              builder: (BuildContext context, Color? color) =>
                  FluentBarCloseButton(controller: entry.controller, icon: closeIcon, size: closeIconSize, color: color, padding: closePadding, semanticLabel: config.closeButtonLabel),
            ),
          ),
      ],
    );

    if (taskProgressWidget != null && (progressTheme.position == FluentBarProgressPosition.top || progressTheme.position == FluentBarProgressPosition.bottom)) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (progressTheme.position == FluentBarProgressPosition.top) ...<Widget>[taskProgressWidget, SizedBox(height: spacing)],
          content,
          if (progressTheme.position == FluentBarProgressPosition.bottom) ...<Widget>[SizedBox(height: spacing), taskProgressWidget],
        ],
      );
    }

    Widget? animatedProgressBar;

    if (shouldShowProgress) {
      final Widget? durationProgressBar = theme.buildTimeoutBar(context, entry, theme, resolvedType, themeMode: themeMode);

      if (durationProgressBar != null) {
        final bool isPersistent = entry.resolveIsPersistent(config);
        animatedProgressBar = AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            opacity: isPersistent ? 0.0 : 1.0,
            child: isPersistent ? const SizedBox(width: double.infinity, height: 0) : RepaintBoundary(child: durationProgressBar),
          ),
        );
      }
    }

    Widget innerContent = Padding(padding: entry.resolvePadding(context, theme, themeMode, config), child: content);

    if (animatedProgressBar != null) {
      innerContent = ClipRRect(
        borderRadius: decoration.borderRadius?.resolve(Directionality.maybeOf(context) ?? TextDirection.ltr) ?? theme.borderRadius(context, resolvedType, themeMode: themeMode),
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            innerContent,
            Positioned(
              top: timeoutPosition == FluentBarTimeoutBarPosition.top ? 0 : null,
              bottom: timeoutPosition == FluentBarTimeoutBarPosition.bottom ? 0 : null,
              left: 0,
              right: 0,
              child: animatedProgressBar,
            ),
          ],
        ),
      );
    }

    content = FluentBarDecorationFade(duration: restyle, constraints: entry.resolveConstraints(context, theme, themeMode, config), decoration: decoration, child: innerContent);

    final Widget wrappedContainer = theme.wrapContainer(context, content, entry, resolvedType, themeMode: themeMode);
    return theme.wrapInteractiveContainer(context, wrappedContainer, resolvedType, themeMode: themeMode);
  }

  /// "Which icon this is", to tell whether it changed. Widgets cannot be compared directly: an
  /// `Icon(Icons.star)` created again is another instance, and the bar would replay the switch
  /// animation on every update. So an icon is the same if the widget type and key match, and
  /// for an `Icon` also the glyph and the color. Two different widgets of one type need different keys.
  static Object _iconIdentity(Widget icon) => icon is Icon ? (Icon, icon.icon, icon.color, icon.key) : (icon.runtimeType, icon.key);

  /// A text whose color fades to the new value. Everything else in the style changes at once.
  Widget _fadingText(String text, TextStyle style, Duration duration, {TextAlign? textAlign, int? maxLines, TextOverflow? overflow, bool? softWrap}) => FluentBarColorFade(
    color: style.color,
    duration: duration,
    builder: (BuildContext context, Color? color) => Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      style: color == null ? style : style.copyWith(color: color),
    ),
  );

  Widget _buildActions(BuildContext context, FluentBarType type, FluentBarTheme theme, FluentBarThemeMode themeMode) {
    final FluentBarItem<T> item = entry.currentItem;
    final FluentBarActions<T>? actions = item.actions;

    if (actions == null) return const SizedBox.shrink(key: ValueKey<String>('no_actions'));

    if (actions.builder != null) {
      return Padding(
        key: const ValueKey<String>('custom_actions'),
        padding: EdgeInsetsDirectional.only(start: theme.spacing(context, type, themeMode: themeMode)),
        child: FluentBarErrorHandler.instance.executeSafe<Widget>(
          overrideCall: () => actions.builder!(context, entry.controller, type, themeMode),
          fallbackCall: () => const SizedBox.shrink(key: ValueKey<String>('error_actions')),
          type: FluentBarErrorType.customButtonBuilder,
          debugContext: '_buildActions.builder',
        ),
      );
    }

    return Padding(
      key: ValueKey<String>('default_actions_${actions.label}'),
      padding: EdgeInsetsDirectional.only(start: theme.spacing(context, type, themeMode: themeMode)),
      child: _buildDefaultActionButton(
        context,
        theme,
        type,
        actions,
        item.resolveActionLoaderColor(context, theme, type, themeMode),
        item.resolveActionLoadingWidget(context, theme, type, themeMode: themeMode),
        themeMode,
      ),
    );
  }

  Widget _buildDefaultActionButton(
    BuildContext context,
    FluentBarTheme theme,
    FluentBarType type,
    FluentBarActions<T> actions,
    Color loaderColor,
    Widget? loadingWidget,
    FluentBarThemeMode themeMode,
  ) {
    final Duration restyle = entry.resolveDisableAnimations(config) ? Duration.zero : kFluentBarRestyleDuration;

    final Widget innerChild =
        actions.child ??
        _fadingText(
          actions.label ?? '',
          theme.actionStyle(context, type, themeMode: themeMode),
          restyle,
          textAlign: entry.resolveActionTextAlign(context, theme, themeMode, config),
          maxLines: actions.resolveActionMaxLines(context, theme, type, themeMode: themeMode),
          overflow: actions.resolveActionOverflow(context, theme, type, themeMode: themeMode),
          softWrap: true,
        );

    final Widget buttonContent = FluentBarDecorationFade(
      duration: restyle,
      constraints: entry.resolveActionsConstraints(context, theme, themeMode, config),
      padding: theme.actionInternalPadding(context, type, themeMode: themeMode),
      decoration: theme.actionDecoration(context, type, themeMode: themeMode),
      child: innerChild,
    );

    return FluentBarAction<T>(
      controller: entry.controller,
      onPressed: actions.onPressed,
      closeOnAction: actions.closeOnAction,
      throttleDuration: actions.throttleDuration,
      loaderColor: loaderColor,
      loadingWidget: loadingWidget,
      child: buttonContent,
    );
  }
}

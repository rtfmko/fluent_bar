part of '../fluent_bar_theme.dart';

class _ProxyFluentBarTheme extends FluentBarTheme {
  final FluentBarTheme baseType;
  final bool Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenDarkMode;
  final BoxConstraints Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenConstraints;
  final BoxConstraints Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionsConstraints;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenBackgroundColor;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenIconColor;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTimeoutBarColor;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTimeoutBarBackgroundColor;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionLoaderColor;
  final EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionInternalPadding;
  final EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenPadding;
  final EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMargin;
  final BoxDecoration Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenBoxDecoration;
  final BoxDecoration Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionDecoration;
  final TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTitleStyle;
  final TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMessageStyle;
  final TextStyle Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionStyle;
  final TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTitleTextAlign;
  final TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMessageTextAlign;
  final TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionTextAlign;
  final TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTitleOverflow;
  final TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMessageOverflow;
  final TextOverflow Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionOverflow;
  final int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMaxTitleLines;
  final int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenMaxMessageLines;
  final int Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionMaxLines;
  final double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenIconSize;
  final double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenSpacing;
  final double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTitleSpacing;
  final double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTimeoutBarMinHeight;
  final BorderRadius Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenTimeoutBarBorderRadius;
  final BorderRadius Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenBorderRadius;
  final Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode, double? overrideSize)? overriddenDefaultIcon;
  final Widget Function(BuildContext context, Widget child, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenInteractiveContainer;
  final Widget Function(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenWrapContainer;
  final Widget Function(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenBuildTimeoutBar;
  final Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenActionLoadingWidget;
  final Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenCloseIcon;
  final double Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenCloseIconSize;
  final Color Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenCloseIconColor;
  final EdgeInsets Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenCloseButtonPadding;
  final CrossAxisAlignment Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? overriddenCloseButtonAlignment;

  const _ProxyFluentBarTheme({
    required this.baseType,
    this.overriddenDarkMode,
    this.overriddenConstraints,
    this.overriddenActionsConstraints,
    this.overriddenBackgroundColor,
    this.overriddenIconColor,
    this.overriddenTimeoutBarColor,
    this.overriddenTimeoutBarBackgroundColor,
    this.overriddenActionLoaderColor,
    this.overriddenActionInternalPadding,
    this.overriddenPadding,
    this.overriddenMargin,
    this.overriddenBoxDecoration,
    this.overriddenActionDecoration,
    this.overriddenTitleStyle,
    this.overriddenMessageStyle,
    this.overriddenActionStyle,
    this.overriddenTitleTextAlign,
    this.overriddenMessageTextAlign,
    this.overriddenActionTextAlign,
    this.overriddenTitleOverflow,
    this.overriddenMessageOverflow,
    this.overriddenActionOverflow,
    this.overriddenMaxTitleLines,
    this.overriddenMaxMessageLines,
    this.overriddenActionMaxLines,
    this.overriddenIconSize,
    this.overriddenSpacing,
    this.overriddenTitleSpacing,
    this.overriddenTimeoutBarMinHeight,
    this.overriddenTimeoutBarBorderRadius,
    this.overriddenBorderRadius,
    this.overriddenDefaultIcon,
    this.overriddenInteractiveContainer,
    this.overriddenWrapContainer,
    this.overriddenBuildTimeoutBar,
    this.overriddenActionLoadingWidget,
    this.overriddenCloseIcon,
    this.overriddenCloseIconSize,
    this.overriddenCloseIconColor,
    this.overriddenCloseButtonPadding,
    this.overriddenCloseButtonAlignment,
  });

  /// A copy without its own isDarkMode. Needed when copyWith with a new isDarkMode is called over
  /// this theme: the outermost one must decide, or the inner one would override its answer.
  _ProxyFluentBarTheme _withoutDarkMode() => _ProxyFluentBarTheme(
    baseType: baseType,
    overriddenConstraints: overriddenConstraints,
    overriddenActionsConstraints: overriddenActionsConstraints,
    overriddenBackgroundColor: overriddenBackgroundColor,
    overriddenIconColor: overriddenIconColor,
    overriddenTimeoutBarColor: overriddenTimeoutBarColor,
    overriddenTimeoutBarBackgroundColor: overriddenTimeoutBarBackgroundColor,
    overriddenActionLoaderColor: overriddenActionLoaderColor,
    overriddenActionInternalPadding: overriddenActionInternalPadding,
    overriddenPadding: overriddenPadding,
    overriddenMargin: overriddenMargin,
    overriddenBoxDecoration: overriddenBoxDecoration,
    overriddenActionDecoration: overriddenActionDecoration,
    overriddenTitleStyle: overriddenTitleStyle,
    overriddenMessageStyle: overriddenMessageStyle,
    overriddenActionStyle: overriddenActionStyle,
    overriddenTitleTextAlign: overriddenTitleTextAlign,
    overriddenMessageTextAlign: overriddenMessageTextAlign,
    overriddenActionTextAlign: overriddenActionTextAlign,
    overriddenTitleOverflow: overriddenTitleOverflow,
    overriddenMessageOverflow: overriddenMessageOverflow,
    overriddenActionOverflow: overriddenActionOverflow,
    overriddenMaxTitleLines: overriddenMaxTitleLines,
    overriddenMaxMessageLines: overriddenMaxMessageLines,
    overriddenActionMaxLines: overriddenActionMaxLines,
    overriddenIconSize: overriddenIconSize,
    overriddenSpacing: overriddenSpacing,
    overriddenTitleSpacing: overriddenTitleSpacing,
    overriddenTimeoutBarMinHeight: overriddenTimeoutBarMinHeight,
    overriddenTimeoutBarBorderRadius: overriddenTimeoutBarBorderRadius,
    overriddenBorderRadius: overriddenBorderRadius,
    overriddenDefaultIcon: overriddenDefaultIcon,
    overriddenInteractiveContainer: overriddenInteractiveContainer,
    overriddenWrapContainer: overriddenWrapContainer,
    overriddenBuildTimeoutBar: overriddenBuildTimeoutBar,
    overriddenActionLoadingWidget: overriddenActionLoadingWidget,
    overriddenCloseIcon: overriddenCloseIcon,
    overriddenCloseIconSize: overriddenCloseIconSize,
    overriddenCloseIconColor: overriddenCloseIconColor,
    overriddenCloseButtonPadding: overriddenCloseButtonPadding,
    overriddenCloseButtonAlignment: overriddenCloseButtonAlignment,
  );

  /// The mode this theme passes to the base theme and to the overrides.
  ///
  /// An overridden isDarkMode is the single source of truth: its answer becomes an explicit
  /// light / dark, and the base theme builds every color and style from it instead of deciding itself.
  FluentBarThemeMode? _mode(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode) {
    if (overriddenDarkMode == null) return themeMode;
    return isDarkMode(context, type, themeMode: themeMode) ? FluentBarThemeMode.dark : FluentBarThemeMode.light;
  }

  /// The guard for every copyWith override.
  ///
  /// Without an override the value comes straight from the base theme. An override is called
  /// under protection: if user code throws, the error goes to the error handler
  /// ([FluentBarErrorType.fluentBarTheme]) and the base theme provides the value.
  T _resolve<T>(String name, T Function()? override, T Function() base) {
    if (override == null) return base();

    return FluentBarErrorHandler.instance.executeSafe<T>(overrideCall: override, fallbackCall: base, type: FluentBarErrorType.fluentBarTheme, debugContext: name);
  }

  T _simple<T>(
    String name,
    BuildContext context,
    FluentBarType type,
    FluentBarThemeMode? themeMode,
    T Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? override,
    T Function(FluentBarThemeMode? mode) base,
  ) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    return _resolve<T>(name, override == null ? null : () => override(context, type, mode), () => base(mode));
  }

  TextAlign? _textAlign(
    String name,
    BuildContext context,
    FluentBarType type,
    FluentBarThemeMode? themeMode,
    TextAlign Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? override,
    TextAlign? Function(FluentBarThemeMode? mode) base,
  ) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    return _resolve<TextAlign?>(name, override == null ? null : () => override(context, type, mode), () => base(mode));
  }

  // isDarkMode is the source of the mode itself, so it does not go through _mode.
  @override
  bool isDarkMode(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final bool Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode)? override = overriddenDarkMode;
    return _resolve<bool>('isDarkMode', override == null ? null : () => override(context, type, themeMode), () => baseType.isDarkMode(context, type, themeMode: themeMode));
  }

  @override
  BoxConstraints constraints(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('constraints', context, type, themeMode, overriddenConstraints, (FluentBarThemeMode? mode) => baseType.constraints(context, type, themeMode: mode));

  @override
  BoxConstraints actionsConstraints(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('actionsConstraints', context, type, themeMode, overriddenActionsConstraints, (FluentBarThemeMode? mode) => baseType.actionsConstraints(context, type, themeMode: mode));

  @override
  Color backgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('backgroundColor', context, type, themeMode, overriddenBackgroundColor, (FluentBarThemeMode? mode) => baseType.backgroundColor(context, type, themeMode: mode));

  @override
  Color? iconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<Color?>('iconColor', context, type, themeMode, overriddenIconColor, (FluentBarThemeMode? mode) => baseType.iconColor(context, type, themeMode: mode));

  @override
  Color? timeoutBarColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<Color?>('timeoutBarColor', context, type, themeMode, overriddenTimeoutBarColor, (FluentBarThemeMode? mode) => baseType.timeoutBarColor(context, type, themeMode: mode));

  @override
  Color timeoutBarBackgroundColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => _simple(
    'timeoutBarBackgroundColor',
    context,
    type,
    themeMode,
    overriddenTimeoutBarBackgroundColor,
    (FluentBarThemeMode? mode) => baseType.timeoutBarBackgroundColor(context, type, themeMode: mode),
  );

  @override
  Color actionLoaderColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('actionLoaderColor', context, type, themeMode, overriddenActionLoaderColor, (FluentBarThemeMode? mode) => baseType.actionLoaderColor(context, type, themeMode: mode));

  @override
  EdgeInsets? actionInternalPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => _simple<EdgeInsets?>(
    'actionInternalPadding',
    context,
    type,
    themeMode,
    overriddenActionInternalPadding,
    (FluentBarThemeMode? mode) => baseType.actionInternalPadding(context, type, themeMode: mode),
  );

  @override
  EdgeInsets padding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('padding', context, type, themeMode, overriddenPadding, (FluentBarThemeMode? mode) => baseType.padding(context, type, themeMode: mode));

  @override
  EdgeInsets margin(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('margin', context, type, themeMode, overriddenMargin, (FluentBarThemeMode? mode) => baseType.margin(context, type, themeMode: mode));

  @override
  BoxDecoration boxDecoration(BuildContext context, FluentBarType type, FluentBarTheme theme, {FluentBarThemeMode? themeMode}) =>
      _simple('boxDecoration', context, type, themeMode, overriddenBoxDecoration, (FluentBarThemeMode? mode) => baseType.boxDecoration(context, type, theme, themeMode: mode));

  @override
  BoxDecoration? actionDecoration(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<BoxDecoration?>('actionDecoration', context, type, themeMode, overriddenActionDecoration, (FluentBarThemeMode? mode) => baseType.actionDecoration(context, type, themeMode: mode));

  @override
  TextStyle titleStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('titleStyle', context, type, themeMode, overriddenTitleStyle, (FluentBarThemeMode? mode) => baseType.titleStyle(context, type, themeMode: mode));

  @override
  TextStyle messageStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('messageStyle', context, type, themeMode, overriddenMessageStyle, (FluentBarThemeMode? mode) => baseType.messageStyle(context, type, themeMode: mode));

  @override
  TextStyle actionStyle(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('actionStyle', context, type, themeMode, overriddenActionStyle, (FluentBarThemeMode? mode) => baseType.actionStyle(context, type, themeMode: mode));

  @override
  TextAlign? titleTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _textAlign('titleTextAlign', context, type, themeMode, overriddenTitleTextAlign, (FluentBarThemeMode? mode) => baseType.titleTextAlign(context, type, themeMode: mode));

  @override
  TextAlign? messageTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _textAlign('messageTextAlign', context, type, themeMode, overriddenMessageTextAlign, (FluentBarThemeMode? mode) => baseType.messageTextAlign(context, type, themeMode: mode));

  @override
  TextAlign? actionTextAlign(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _textAlign('actionTextAlign', context, type, themeMode, overriddenActionTextAlign, (FluentBarThemeMode? mode) => baseType.actionTextAlign(context, type, themeMode: mode));

  @override
  TextOverflow? titleOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<TextOverflow?>('titleOverflow', context, type, themeMode, overriddenTitleOverflow, (FluentBarThemeMode? mode) => baseType.titleOverflow(context, type, themeMode: mode));

  @override
  TextOverflow? messageOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<TextOverflow?>('messageOverflow', context, type, themeMode, overriddenMessageOverflow, (FluentBarThemeMode? mode) => baseType.messageOverflow(context, type, themeMode: mode));

  @override
  TextOverflow? actionOverflow(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<TextOverflow?>('actionOverflow', context, type, themeMode, overriddenActionOverflow, (FluentBarThemeMode? mode) => baseType.actionOverflow(context, type, themeMode: mode));

  @override
  int maxTitleLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('maxTitleLines', context, type, themeMode, overriddenMaxTitleLines, (FluentBarThemeMode? mode) => baseType.maxTitleLines(context, type, themeMode: mode));

  @override
  int maxMessageLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('maxMessageLines', context, type, themeMode, overriddenMaxMessageLines, (FluentBarThemeMode? mode) => baseType.maxMessageLines(context, type, themeMode: mode));

  @override
  int actionMaxLines(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('actionMaxLines', context, type, themeMode, overriddenActionMaxLines, (FluentBarThemeMode? mode) => baseType.actionMaxLines(context, type, themeMode: mode));

  @override
  double iconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('iconSize', context, type, themeMode, overriddenIconSize, (FluentBarThemeMode? mode) => baseType.iconSize(context, type, themeMode: mode));

  @override
  double spacing(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('spacing', context, type, themeMode, overriddenSpacing, (FluentBarThemeMode? mode) => baseType.spacing(context, type, themeMode: mode));

  @override
  double titleSpacing(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('titleSpacing', context, type, themeMode, overriddenTitleSpacing, (FluentBarThemeMode? mode) => baseType.titleSpacing(context, type, themeMode: mode));

  @override
  double timeoutBarMinHeight(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('timeoutBarMinHeight', context, type, themeMode, overriddenTimeoutBarMinHeight, (FluentBarThemeMode? mode) => baseType.timeoutBarMinHeight(context, type, themeMode: mode));

  @override
  BorderRadius? timeoutBarBorderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) => _simple<BorderRadius?>(
    'timeoutBarBorderRadius',
    context,
    type,
    themeMode,
    overriddenTimeoutBarBorderRadius,
    (FluentBarThemeMode? mode) => baseType.timeoutBarBorderRadius(context, type, themeMode: mode),
  );

  @override
  BorderRadius borderRadius(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('borderRadius', context, type, themeMode, overriddenBorderRadius, (FluentBarThemeMode? mode) => baseType.borderRadius(context, type, themeMode: mode));

  @override
  Widget? actionLoadingWidget(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<Widget?>('actionLoadingWidget', context, type, themeMode, overriddenActionLoadingWidget, (FluentBarThemeMode? mode) => baseType.actionLoadingWidget(context, type, themeMode: mode));

  @override
  Widget defaultIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode, double? overrideSize}) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    final Widget Function(BuildContext context, FluentBarType type, FluentBarThemeMode? themeMode, double? overrideSize)? override = overriddenDefaultIcon;

    return _resolve<Widget>(
      'defaultIcon',
      override == null ? null : () => override(context, type, mode, overrideSize),
      () => baseType.defaultIcon(context, type, themeMode: mode, overrideSize: overrideSize),
    );
  }

  @override
  Widget wrapInteractiveContainer(BuildContext context, Widget child, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    final Widget Function(BuildContext context, Widget child, FluentBarType type, FluentBarThemeMode? themeMode)? override = overriddenInteractiveContainer;

    return _resolve<Widget>(
      'wrapInteractiveContainer',
      override == null ? null : () => override(context, child, type, mode),
      () => baseType.wrapInteractiveContainer(context, child, type, themeMode: mode),
    );
  }

  @override
  Widget wrapContainer(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    final Widget Function(BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? override = overriddenWrapContainer;

    return _resolve<Widget>('wrapContainer', override == null ? null : () => override(context, child, entry, type, mode), () => baseType.wrapContainer(context, child, entry, type, themeMode: mode));
  }

  @override
  Widget? buildTimeoutBar(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarTheme theme, FluentBarType type, {FluentBarThemeMode? themeMode}) {
    final FluentBarThemeMode? mode = _mode(context, type, themeMode);
    final Widget Function(BuildContext context, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode)? override = overriddenBuildTimeoutBar;

    // The base theme gets the outer theme, not this one: with nested copyWith the outermost provides the values.
    return _resolve<Widget?>('buildTimeoutBar', override == null ? null : () => override(context, entry, type, mode), () => baseType.buildTimeoutBar(context, entry, theme, type, themeMode: mode));
  }

  @override
  Widget closeIcon(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('closeIcon', context, type, themeMode, overriddenCloseIcon, (FluentBarThemeMode? mode) => baseType.closeIcon(context, type, themeMode: mode));

  @override
  double closeIconSize(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('closeIconSize', context, type, themeMode, overriddenCloseIconSize, (FluentBarThemeMode? mode) => baseType.closeIconSize(context, type, themeMode: mode));

  @override
  Color? closeIconColor(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple<Color?>('closeIconColor', context, type, themeMode, overriddenCloseIconColor, (FluentBarThemeMode? mode) {
        final Color? base = baseType.closeIconColor(context, type, themeMode: mode);
        if (overriddenMessageStyle == null) return base;

        // The default color follows the message. With a message style overridden here the default
        // must follow that one; a color the base theme chose itself stays.
        final Color? baseDefault = baseType.messageStyle(context, type, themeMode: mode).color?.withValues(alpha: 0.7);
        return base == baseDefault ? messageStyle(context, type, themeMode: themeMode).color?.withValues(alpha: 0.7) : base;
      });

  @override
  EdgeInsets closeButtonPadding(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('closeButtonPadding', context, type, themeMode, overriddenCloseButtonPadding, (FluentBarThemeMode? mode) => baseType.closeButtonPadding(context, type, themeMode: mode));

  @override
  CrossAxisAlignment closeButtonAlignment(BuildContext context, FluentBarType type, {FluentBarThemeMode? themeMode}) =>
      _simple('closeButtonAlignment', context, type, themeMode, overriddenCloseButtonAlignment, (FluentBarThemeMode? mode) => baseType.closeButtonAlignment(context, type, themeMode: mode));
}

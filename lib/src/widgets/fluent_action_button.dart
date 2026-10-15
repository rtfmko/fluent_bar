import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';

/// The action button of a bar: runs the handler, shows a loader meanwhile and ignores repeated taps.
class FluentBarAction<T> extends StatelessWidget {
  /// The controller of the bar the button belongs to.
  final FluentBarController<T> controller;

  /// Called when the button is pressed.
  final FutureOr<void> Function(FluentBarController<T> controller, T? payload)? onPressed;

  /// Whether pressing the button closes the bar.
  final bool closeOnAction;

  /// A second press within this time is ignored.
  final Duration throttleDuration;

  /// The color of the default loader.
  final Color loaderColor;

  /// The content of the button.
  final Widget child;

  /// A widget shown instead of the default loader.
  final Widget? loadingWidget;

  /// Creates an action button around [child].
  const FluentBarAction({
    super.key,
    required this.controller,
    required this.child,
    this.onPressed,
    this.closeOnAction = true,
    required this.loaderColor,
    this.throttleDuration = const Duration(milliseconds: 400),
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: controller.isActionExecutingNotifier,
    builder: (BuildContext context, bool isExecuting, Widget? cachedChild) {
      final Widget loader = isExecuting ? (loadingWidget ?? _buildDefaultLoader(context)) : const SizedBox.shrink();

      return Semantics(
        button: true,
        enabled: !isExecuting,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // While the action runs the tap is still consumed, or it would reach the parent and close the bar (dismissOnTap).
          onTap: isExecuting ? () {} : () => controller.handleAction(onPressed: onPressed, closeOnAction: closeOnAction, throttleDuration: throttleDuration),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              AnimatedOpacity(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, opacity: isExecuting ? 0.0 : 1.0, child: cachedChild!),
              // The loader is in the tree only while the action runs: an indicator hidden with opacity would
              // keep ticking and repainting for the whole life of the bar.
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    child: isExecuting ? Center(key: const ValueKey<String>('action_loader'), child: loader) : const SizedBox.shrink(key: ValueKey<String>('no_action_loader')),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
    child: child,
  );

  Widget _buildDefaultLoader(BuildContext context) => SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(loaderColor)));
}

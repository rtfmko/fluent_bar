import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';

/// A button that closes a bar with [FluentBarDismissReason.closeButton].
///
/// The standard content of a bar adds it by itself when the close button is turned on
/// (`.withCloseButton()`, [FluentBarType.showCloseButton], [FluentBarConfig.defaultShowCloseButton]).
/// Use this widget in your own content builder, which replaces the standard content:
///
/// ```dart
/// FluentBar.info('Custom').withContent((context, entry) => Row(children: [
///   const Expanded(child: Text('My own layout')),
///   FluentBarCloseButton(controller: entry.controller),
/// ])).show();
/// ```
class FluentBarCloseButton extends StatelessWidget {
  /// The controller of the bar to close.
  final FluentBarController<dynamic> controller;

  /// The icon; a cross by default.
  final Widget? icon;

  /// The size of the icon.
  final double size;

  /// The color of the icon; `null` keeps the color of the surrounding [IconTheme].
  final Color? color;

  /// The space around the icon that also reacts to the tap.
  final EdgeInsetsGeometry padding;

  /// What a screen reader says; by default the "Close" label of the app localization.
  final String? semanticLabel;

  /// Creates a close button for the bar of [controller].
  const FluentBarCloseButton({super.key, required this.controller, this.icon, this.size = 18, this.color, this.padding = const EdgeInsets.all(6), this.semanticLabel});

  void _close() {
    // Also while the bar is loading or its action runs: the cross is the way out of a bar whose
    // task hangs.
    if (!controller.stateNotifier.value.isInteractive) return;
    controller.close(reason: FluentBarDismissReason.closeButton);
  }

  @override
  Widget build(BuildContext context) {
    final String label = semanticLabel ?? Localizations.of<MaterialLocalizations>(context, MaterialLocalizations)?.closeButtonLabel ?? 'Close';

    return Semantics(
      container: true,
      button: true,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _close,
          child: Padding(
            padding: padding,
            child: IconTheme.merge(
              data: IconThemeData(size: size, color: color),
              child: ExcludeSemantics(child: icon ?? const Icon(Icons.close_rounded)),
            ),
          ),
        ),
      ),
    );
  }
}

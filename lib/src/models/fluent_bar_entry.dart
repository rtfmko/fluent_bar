import 'package:fluent_bar/src/internal.dart';

/// A bar that was shown or queued: its current content and its controller.
///
/// Returned by every `show` call and by `FluentBar.find`.
///
/// ```dart
/// final FluentBarEntry<void>? entry = FluentBar.info<void>('Saving').persistent().show();
/// entry?.update(message: 'Saved');
/// entry?.close();
/// ```
class FluentBarEntry<T> {
  static int _nextSequence = 0;

  /// Changes and closes the bar.
  final FluentBarController<T> controller;

  /// The creation order of the entry; breaks ties between bars of the same priority.
  final int sequence;

  /// Creates an entry for [item]. Used by the library; apps get entries from `show()`.
  @internal
  FluentBarEntry({required FluentBarItem<T> item, FluentBarController<T>? controller, int? sequence})
    : controller = controller ?? FluentBarControllerImpl<T>(item),
      sequence = sequence ?? _nextSequence++;

  /// The current content of the bar: after `updateContent`, `updateProgress`, a duplicate merge and
  /// so on, the new values are already here.
  FluentBarItem<T> get item => controller.itemNotifier.value;

  /// The widget of the bar with the real `T`.
  ///
  /// The manager keeps entries as `FluentBarEntry<dynamic>`. A wrapper created from there would
  /// get `T = dynamic`, and reading typed callbacks and builders (`onTap`, `onPressed`,
  /// `builder`...) would fail a type check. An instance method knows the real `T`.
  @internal
  Widget buildWidget(FluentBarConfig config) => FluentBarWrapper<T>(entry: this, config: config);
}

import 'package:fluent_bar/src/internal.dart';

/// The optional settings of the full `FluentBar.show` call, grouped by purpose.
///
/// ```dart
/// FluentBar.show<void>(
///   message: 'Ready',
///   options: const FluentBarOptions<void>(
///     behavior: FluentBarBehavior(position: FluentBarPosition.bottom),
///     appearance: FluentBarAppearance<void>(showTimeoutBar: true),
///   ),
/// );
/// ```
class FluentBarOptions<T> {
  /// Free-form data for analytics and for a custom duplicate rule.
  final Map<String, dynamic>? meta;

  /// Labels that group bars, see `FluentBar.closeTag`.
  final Set<String>? tags;

  /// Position, gestures, priority and other behavior.
  final FluentBarBehavior? behavior;

  /// The action button.
  final FluentBarActions<T>? actions;

  /// Theme, colors, icon, animations and other look.
  final FluentBarAppearance<T>? appearance;

  /// Callbacks for the life of the bar.
  final FluentBarCallbacks<T>? callbacks;

  /// The initial progress, if the bar shows progress.
  final FluentBarProgressState? progressState;

  /// Creates a set of options; everything left out comes from the type and the config.
  const FluentBarOptions({this.meta, this.tags, this.behavior, this.actions, this.appearance, this.callbacks, this.progressState});
}

import 'package:fluent_bar/src/internal.dart';

/// A request to play an attention effect on a bar.
class FluentBarEffectEvent {
  /// Which effect to play.
  final FluentBarEffect type;

  /// The strength of the effect: an offset for a shake, a scale for the others.
  final double intensity;

  /// How long one run of the effect takes.
  final Duration duration;

  /// Whether the effect loops until another one replaces it.
  final bool repeat;

  /// Creates an effect request.
  FluentBarEffectEvent({required this.type, required this.intensity, required this.duration, required this.repeat});
}

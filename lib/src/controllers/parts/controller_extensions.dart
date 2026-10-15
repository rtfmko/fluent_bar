part of '../fluent_bar_controller_impl.dart';

extension _FluentBarItemControllerX<T> on FluentBarItem<T> {
  Duration resolveProgressInterval(FluentBarConfig config) =>
      (behavior.timeoutUpdateInterval ?? resolvedType(config).timeoutUpdateInterval ?? config.defaultTimeoutUpdateInterval).interval.nonNegative;
}

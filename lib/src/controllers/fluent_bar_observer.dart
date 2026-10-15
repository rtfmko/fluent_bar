import 'package:fluent_bar/src/internal.dart';

/// Gives the manager the overlay of the navigator when the app is not wrapped in [FluentBarScope].
///
/// Add it with `navigatorObservers: [FluentBarObserver.instance]`.
class FluentBarObserver extends NavigatorObserver {
  /// The single instance to pass to `navigatorObservers`.
  static final FluentBarObserver instance = FluentBarObserver._();

  FluentBarObserver._();

  /// Read from the navigator every time instead of being cached: after the navigator is
  /// recreated, a cached overlay would point at a disposed one.
  @internal
  OverlayState? get overlay {
    final OverlayState? current = navigator?.overlay;
    return current != null && current.mounted ? current : null;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // The first route is pushed before the overlay of the navigator is built, so wait for the frame to end.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FluentBarManager.instance.tryDequeuePending();
    });
  }
}

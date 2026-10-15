import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/rendering.dart';

/// Reports the height of the bottom panel of the app to the library so that bottom bars appear
/// above it, like a SnackBar above a BottomNavigationBar.
///
/// Bars live in an overlay above the navigator and cannot know about the panel of a particular
/// screen, so wrap the panel once:
///
/// ```dart
/// Scaffold(
///   bottomNavigationBar: FluentBarBottomInset(child: NavigationBar(destinations: destinations)),
/// );
/// ```
///
/// The height is measured and kept up to date automatically. When the screen with the panel is
/// covered by another screen or removed, the inset is withdrawn.
class FluentBarBottomInset extends StatelessWidget {
  /// The bottom panel to measure, for example a `NavigationBar`.
  final Widget child;

  /// Wraps the bottom panel [child].
  const FluentBarBottomInset({super.key, required this.child});

  @override
  Widget build(BuildContext context) => _InsetReporter(isTop: false, child: child);
}

/// Reports the height of the app bar to the library so that top bars appear below it instead of
/// over the title and buttons.
///
/// It can go straight into `Scaffold.appBar`:
///
/// ```dart
/// Scaffold(
///   appBar: FluentBarTopInset(child: AppBar(title: const Text('Inbox'))),
/// );
/// ```
///
/// The whole app bar is measured, status bar included. When the screen is covered by another
/// screen or removed, the inset is withdrawn.
class FluentBarTopInset extends StatelessWidget implements PreferredSizeWidget {
  /// The app bar to measure.
  final PreferredSizeWidget child;

  /// Wraps the app bar [child].
  const FluentBarTopInset({super.key, required this.child});

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) => _InsetReporter(isTop: true, child: child);
}

class _InsetReporter extends StatefulWidget {
  final bool isTop;
  final Widget child;

  const _InsetReporter({required this.isTop, required this.child});

  @override
  State<_InsetReporter> createState() => _InsetReporterState();
}

class _InsetReporterState extends State<_InsetReporter> {
  double _height = 0;
  bool _isCurrent = true;

  /// The height becomes known during layout and the inset is withdrawn during dispose; in both
  /// cases the notifier cannot change at once (the tree is locked), so it is published after the frame.
  void _publish(double? height) {
    final bool isTop = widget.isTop;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final FluentBarManager manager = FluentBarManager.instance;
      isTop ? manager.setTopInset(this, height) : manager.setBottomInset(this, height);
    });
  }

  void _onSize(Size size) {
    _height = size.height;
    _publish(_isCurrent ? _height : 0);
  }

  @override
  void dispose() {
    _publish(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A screen with a panel may be covered by another screen while staying in the tree. The panel
    // is then not on screen, and bars must return to their usual place.
    final bool isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    if (isCurrent != _isCurrent) {
      _isCurrent = isCurrent;
      _publish(_isCurrent ? _height : 0);
    }

    return _SizeReporter(onSize: _onSize, child: widget.child);
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  final ValueChanged<Size> onSize;

  const _SizeReporter({required this.onSize, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, covariant _RenderSizeReporter renderObject) => renderObject.onSize = onSize;
}

class _RenderSizeReporter extends RenderProxyBox {
  ValueChanged<Size> onSize;
  Size? _reported;

  _RenderSizeReporter(this.onSize);

  @override
  void performLayout() {
    super.performLayout();
    if (size != _reported) {
      _reported = size;
      onSize(size);
    }
  }
}

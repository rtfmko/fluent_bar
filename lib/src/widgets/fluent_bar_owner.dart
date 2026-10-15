import 'package:fluent_bar/src/internal.dart';

/// Ties bars to a part of the app: when this widget leaves the tree, every bar with [tag] that
/// is shown or queued at that moment is closed. A bar shown after that is not touched.
///
/// Bars live in an overlay above the navigator and do not know which screen showed them. The
/// link is the tag, set on the bar by hand:
///
/// ```dart
/// class CheckoutScreen extends StatelessWidget {
///   const CheckoutScreen({super.key});
///
///   @override
///   Widget build(BuildContext context) => FluentBarOwner(
///     tag: 'checkout',
///     child: Scaffold(
///       body: FilledButton(
///         onPressed: () => FluentBar.error('Card declined').withTag('checkout').show(),
///         child: const Text('Pay'),
///       ),
///     ),
///   );
/// }
/// ```
///
/// Bars without the tag stay. With several owners of one tag (the same screen opened twice) the
/// bars are closed when the last of them goes away.
class FluentBarOwner extends StatefulWidget {
  /// The tag of the bars this widget owns.
  final String tag;

  /// The part of the app the bars belong to.
  final Widget child;

  /// Creates an owner of the bars with [tag].
  const FluentBarOwner({super.key, required this.tag, required this.child});

  @override
  State<FluentBarOwner> createState() => _FluentBarOwnerState();
}

class _FluentBarOwnerState extends State<FluentBarOwner> {
  static final Map<String, int> _owners = <String, int>{};

  late String _tag;

  static void _retain(String tag) => _owners[tag] = (_owners[tag] ?? 0) + 1;

  static void _release(String tag) {
    final int left = (_owners[tag] ?? 1) - 1;
    if (left > 0) {
      _owners[tag] = left;
      return;
    }

    _owners.remove(tag);
    // The bars are picked now, so one shown later is not touched. They are closed after dispose:
    // closing a queued bar calls analytics listeners of the app, and the widget tree is locked
    // here. By then another owner may have taken the tag over.
    final List<FluentBarEntry<dynamic>> owned = FluentBar.findByTag(tag);
    if (owned.isEmpty) return;

    scheduleMicrotask(() {
      if (_owners.containsKey(tag)) return;
      for (final FluentBarEntry<dynamic> entry in owned) {
        entry.controller.close();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _tag = widget.tag;
    _retain(_tag);
  }

  @override
  void didUpdateWidget(FluentBarOwner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tag == _tag) return;

    _retain(widget.tag);
    _release(_tag);
    _tag = widget.tag;
  }

  @override
  void dispose() {
    _release(_tag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

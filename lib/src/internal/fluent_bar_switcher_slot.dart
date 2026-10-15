import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A child of an `AnimatedSwitcher` whose leaving children must free their room at once.
///
/// The current child takes its own size; a leaving one takes none and is painted from the start
/// edge at its last size, vertically centered. Current and leaving children use this same widget
/// under the key of the child, so a child keeps its state when it starts to leave.
class FluentBarSwitcherSlot extends SingleChildRenderObjectWidget {
  /// Whether the child is on its way out.
  final bool isLeaving;

  /// Decides which edge is the start.
  final TextDirection textDirection;

  /// Creates a slot for [child].
  const FluentBarSwitcherSlot({super.key, required this.isLeaving, required this.textDirection, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSwitcherSlot(isLeaving: isLeaving, textDirection: textDirection);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderSwitcherSlot)
      ..isLeaving = isLeaving
      ..textDirection = textDirection;
  }
}

class _RenderSwitcherSlot extends RenderShiftedBox {
  bool _isLeaving;
  TextDirection _textDirection;
  Size? _lastSize;

  _RenderSwitcherSlot({required bool isLeaving, required TextDirection textDirection}) : _isLeaving = isLeaving, _textDirection = textDirection, super(null);

  set isLeaving(bool value) {
    if (_isLeaving == value) return;
    _isLeaving = value;
    markNeedsLayout();
  }

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _isLeaving ? 0 : super.computeMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) => _isLeaving ? 0 : super.computeMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _isLeaving ? 0 : super.computeMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _isLeaving ? 0 : super.computeMaxIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) => _isLeaving ? constraints.constrain(Size.zero) : (child?.getDryLayout(constraints) ?? constraints.smallest);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) => _isLeaving ? null : super.computeDistanceToActualBaseline(baseline);

  @override
  void performLayout() {
    final RenderBox? child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    final BoxParentData childParentData = child.parentData! as BoxParentData;

    if (!_isLeaving) {
      child.layout(constraints, parentUsesSize: true);
      size = child.size;
      _lastSize = size;
      childParentData.offset = Offset.zero;
      return;
    }

    final Size? last = _lastSize;
    child.layout(last == null ? constraints.loosen() : BoxConstraints.tight(last), parentUsesSize: true);
    size = constraints.constrain(Size.zero);
    childParentData.offset = Offset(_textDirection == TextDirection.rtl ? size.width - child.size.width : 0, (size.height - child.size.height) / 2);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => !_isLeaving && super.hitTest(result, position: position);
}

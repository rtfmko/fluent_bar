import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives its child all the height it wants and is itself no higher than its constraints allow.
///
/// What does not fit is clipped. Unlike a scroll view it adds nothing to the semantics tree and
/// reacts to no gesture: a bar on a screen smaller than its content is cut off instead of
/// overflowing.
class FluentBarClampedHeight extends SingleChildRenderObjectWidget {
  /// Creates a clamp around [child].
  const FluentBarClampedHeight({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderClampedHeight();
}

class _RenderClampedHeight extends RenderProxyBox {
  @override
  void performLayout() {
    final RenderBox? content = child;
    if (content == null) {
      size = constraints.smallest;
      return;
    }
    content.layout(constraints.copyWith(maxHeight: double.infinity), parentUsesSize: true);
    size = constraints.constrain(content.size);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? content = child;
    if (content == null) return;
    if (content.size.height > size.height) {
      context.pushClipRect(needsCompositing, offset, Offset.zero & size, super.paint);
    } else {
      super.paint(context, offset);
    }
  }
}

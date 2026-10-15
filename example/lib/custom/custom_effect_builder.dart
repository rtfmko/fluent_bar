import 'package:flutter/widgets.dart';

Widget customEffectBuilder(BuildContext context, AnimationController controller, Widget child) {
  return AnimatedBuilder(
    animation: controller,
    builder: (context, childWidget) {
      final double scale = 1.0 + (controller.value * 0.03);
      return Transform.scale(scale: scale, child: childWidget);
    },
    child: child,
  );
}

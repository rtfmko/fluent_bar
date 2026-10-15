import 'package:flutter/widgets.dart';

Widget customTransitionBuilder(BuildContext context, Animation<double> animation, Widget child) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, childWidget) {
      return Transform.scale(
        scale: animation.value,
        child: Transform.rotate(
          angle: (1.0 - animation.value) * 3.14159,
          child: Opacity(opacity: animation.value.clamp(0.0, 1.0), child: childWidget),
        ),
      );
    },
    child: child,
  );
}

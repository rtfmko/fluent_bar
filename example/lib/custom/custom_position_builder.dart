import 'dart:math' as math;

import 'package:flutter/widgets.dart';

Widget customPositionBuilder(BuildContext context, Widget child) {
  return Align(
    alignment: const Alignment(-0.8, -0.5),
    child: Transform.rotate(angle: 4 * math.pi / 180, child: child),
  );
}

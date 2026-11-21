import 'dart:math' as math;

import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  testWidgets('the action of the windows theme is readable on its background in the dark variant', (WidgetTester tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    const FluentBarTheme theme = FluentBarTheme.windows;

    for (final FluentBarThemeMode mode in <FluentBarThemeMode>[FluentBarThemeMode.light, FluentBarThemeMode.dark]) {
      final Color text = theme.actionStyle(context, FluentBarType.info, themeMode: mode).color!;
      final Color background = Color.alphaBlend(theme.backgroundColor(context, FluentBarType.info, themeMode: mode), mode == FluentBarThemeMode.dark ? Colors.black : Colors.white);
      expect(_contrast(text, background), greaterThanOrEqualTo(4.5), reason: mode.name);
    }
  });
}

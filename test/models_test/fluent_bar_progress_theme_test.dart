import 'package:fluent_bar/src/internal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentBarProgressTheme Tests', () {
    test('should initialize with correct default values', () {
      const FluentBarProgressTheme theme = FluentBarProgressTheme();

      expect(theme.style, FluentBarProgressStyle.linear);
      expect(theme.position, FluentBarProgressPosition.bottom);
      expect(theme.trackDecoration, isNull);
      expect(theme.progressColor, isNull);
      expect(theme.thickness, 4.0);
      expect(theme.size, 24.0);
      expect(theme.showText, isFalse);
      expect(theme.textAlign, FluentBarProgressTextAlign.right);
      expect(theme.textEffect, FluentBarProgressTextEffect.count);
      expect(theme.textEffectDuration, const Duration(milliseconds: 300));
      expect(theme.successIconColor, isNull);
      expect(theme.successIcon, isNull);
      expect(theme.textStyle, isNull);
      expect(theme.labelBuilder, isNull);
      expect(theme.progressBuilder, isNull);
    });

    test('should support copyWith for empty, partial and full updates', () {
      const FluentBarProgressTheme theme = FluentBarProgressTheme();

      final FluentBarProgressTheme copiedEmpty = theme.copyWith();
      expect(copiedEmpty, equals(theme));

      const BoxDecoration trackDeco = BoxDecoration(color: Colors.black);
      const Color progressColor = Colors.blue;
      const Color successIconColor = Colors.green;
      const SizedBox successIcon = SizedBox();
      const TextStyle textStyle = TextStyle(fontSize: 14);
      String dummyLabelBuilder(FluentBarProgressState state) => 'Progress Label';
      Widget dummyProgressBuilder(BuildContext context, ValueListenable<FluentBarProgressState?> notifier) => const SizedBox();

      expect(theme.copyWith(style: FluentBarProgressStyle.circular).style, FluentBarProgressStyle.circular);
      expect(theme.copyWith(position: FluentBarProgressPosition.top).position, FluentBarProgressPosition.top);
      expect(theme.copyWith(trackDecoration: trackDeco).trackDecoration, trackDeco);
      expect(theme.copyWith(progressColor: progressColor).progressColor, progressColor);
      expect(theme.copyWith(thickness: 8.0).thickness, 8.0);
      expect(theme.copyWith(size: 32.0).size, 32.0);
      expect(theme.copyWith(showText: true).showText, isTrue);
      expect(theme.copyWith(successIconColor: successIconColor).successIconColor, successIconColor);
      expect(theme.copyWith(successIcon: successIcon).successIcon, successIcon);
      expect(theme.copyWith(textStyle: textStyle).textStyle, textStyle);
      expect(theme.copyWith(labelBuilder: dummyLabelBuilder).labelBuilder, dummyLabelBuilder);
      expect(theme.copyWith(progressBuilder: dummyProgressBuilder).progressBuilder, dummyProgressBuilder);

      expect(theme.copyWith(textAlign: FluentBarProgressTextAlign.center).textAlign, FluentBarProgressTextAlign.center);
      expect(theme.copyWith(textEffect: FluentBarProgressTextEffect.roll).textEffect, FluentBarProgressTextEffect.roll);
      expect(theme.copyWith(textEffectDuration: const Duration(seconds: 1)).textEffectDuration, const Duration(seconds: 1));
      expect(theme.copyWith(textEffect: FluentBarProgressTextEffect.roll) == theme, isFalse);
      expect(theme.copyWith(textEffectDuration: const Duration(seconds: 1)) == theme, isFalse);

      final FluentBarProgressTheme fullModified = theme.copyWith(
        style: FluentBarProgressStyle.circular,
        position: FluentBarProgressPosition.top,
        trackDecoration: trackDeco,
        progressColor: progressColor,
        thickness: 6.0,
        size: 30.0,
        showText: true,
        successIconColor: successIconColor,
        successIcon: successIcon,
        textStyle: textStyle,
        labelBuilder: dummyLabelBuilder,
        progressBuilder: dummyProgressBuilder,
      );

      expect(fullModified.style, FluentBarProgressStyle.circular);
      expect(fullModified.position, FluentBarProgressPosition.top);
      expect(fullModified.trackDecoration, trackDeco);
      expect(fullModified.progressColor, progressColor);
      expect(fullModified.thickness, 6.0);
      expect(fullModified.size, 30.0);
      expect(fullModified.showText, isTrue);
      expect(fullModified.successIconColor, successIconColor);
      expect(fullModified.successIcon, successIcon);
      expect(fullModified.textStyle, textStyle);
      expect(fullModified.labelBuilder, dummyLabelBuilder);
      expect(fullModified.progressBuilder, dummyProgressBuilder);
    });

    test('should correctly implement equality and hashCode contract', () {
      const FluentBarProgressTheme theme1 = FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.top, thickness: 5.0, size: 28.0, showText: true);

      const FluentBarProgressTheme theme2 = FluentBarProgressTheme(style: FluentBarProgressStyle.circular, position: FluentBarProgressPosition.top, thickness: 5.0, size: 28.0, showText: true);

      const FluentBarProgressTheme themeDifferent = FluentBarProgressTheme(thickness: 10.0);

      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
      expect(theme1 == theme1, isTrue);

      const Object otherObject = 'some string';
      expect(theme1 == otherObject, isFalse);

      expect(theme1 == themeDifferent, isFalse);
      expect(theme1.hashCode == themeDifferent.hashCode, isFalse);
    });
  });
}

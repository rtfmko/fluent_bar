import 'package:fluent_bar/src/internal.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FluentBarManager manager;

  setUp(() {
    manager = FluentBarManager.instance;
    manager.resetForTesting();
  });

  group('setTopInset', () {
    test('one owner sets the notifier, null withdraws it', () {
      final Object owner = Object();

      manager.setTopInset(owner, 56);
      expect(manager.topInsetNotifier.value, 56);

      manager.setTopInset(owner, null);
      expect(manager.topInsetNotifier.value, 0);
    });

    test('several owners: the largest active inset is used', () {
      final Object first = Object();
      final Object second = Object();

      manager.setTopInset(first, 50);
      manager.setTopInset(second, 90);
      expect(manager.topInsetNotifier.value, 90);

      manager.setTopInset(second, null);
      expect(manager.topInsetNotifier.value, 50);

      manager.setTopInset(first, null);
      expect(manager.topInsetNotifier.value, 0);
    });

    test('a height of 0 counts as a reported owner and changes nothing', () {
      final Object first = Object();
      final Object second = Object();

      manager.setTopInset(first, 40);
      manager.setTopInset(second, 0);
      expect(manager.topInsetNotifier.value, 40);

      manager.setTopInset(first, 0);
      expect(manager.topInsetNotifier.value, 0);
    });

    test('removing an owner that never reported is harmless', () {
      manager.setTopInset(Object(), 30);
      manager.setTopInset(Object(), null);
      expect(manager.topInsetNotifier.value, 30);
    });

    test('repeated null for the same owner is harmless', () {
      final Object owner = Object();

      manager.setTopInset(owner, 24);
      manager.setTopInset(owner, null);
      manager.setTopInset(owner, null);
      expect(manager.topInsetNotifier.value, 0);
    });

    test('a new height from the same owner replaces the old one', () {
      final Object owner = Object();

      manager.setTopInset(owner, 56);
      manager.setTopInset(owner, 48);
      expect(manager.topInsetNotifier.value, 48);
    });

    test('listeners hear about a change only when the value changes', () {
      final Object owner = Object();
      int calls = 0;
      manager.topInsetNotifier.addListener(() => calls++);

      manager.setTopInset(owner, 56);
      manager.setTopInset(owner, 56);
      manager.setTopInset(owner, null);
      manager.setTopInset(owner, null);

      expect(calls, 2);
    });

    test('top and bottom insets are independent', () {
      final Object top = Object();
      final Object bottom = Object();

      manager.setTopInset(top, 56);
      manager.setBottomInset(bottom, 80);
      expect(manager.topInsetNotifier.value, 56);
      expect(manager.bottomInsetNotifier.value, 80);

      manager.setTopInset(top, null);
      expect(manager.topInsetNotifier.value, 0);
      expect(manager.bottomInsetNotifier.value, 80);
    });

    test('NaN and negative heights are ignored, other owners still count', () {
      final Object good = Object();
      final Object nan = Object();
      final Object negative = Object();

      manager.setTopInset(good, 40);
      manager.setTopInset(nan, double.nan);
      manager.setTopInset(negative, -20);
      expect(manager.topInsetNotifier.value, 40);

      manager.setTopInset(good, null);
      expect(manager.topInsetNotifier.value, 0);
    });

    test('a NaN owner alone gives 0, not NaN', () {
      manager.setTopInset(Object(), double.nan);
      expect(manager.topInsetNotifier.value.isNaN, isFalse);
      expect(manager.topInsetNotifier.value, 0);
    });
  });
}

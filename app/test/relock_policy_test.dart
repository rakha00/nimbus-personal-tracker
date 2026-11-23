import 'package:flutter_test/flutter_test.dart';
import 'package:nimbus/features/auth/relock_policy.dart';

void main() {
  final t0 = DateTime(2026, 11, 24, 8);
  DateTime at(int seconds) => t0.add(Duration(seconds: seconds));

  test('short absence does not lock', () {
    final p = RelockPolicy();
    p.onBackground(at(0), busy: false);
    expect(p.onForeground(at(30), busy: false), isFalse);
  });

  test('phone sleeps, wakes, user enters PIN: locks once, not again', () {
    final p = RelockPolicy();
    p.onBackground(at(0), busy: false); // screen off
    expect(p.onForeground(at(600), busy: false), isTrue); // wake: lock and prompt

    // The PIN screen pauses the app while we're locked/authenticating.
    p.onBackground(at(601), busy: true);
    expect(p.onForeground(at(610), busy: true), isFalse);
    // A late resume after unlocking must not count the old sleep again (the old bug).
    expect(p.onForeground(at(611), busy: false), isFalse);
  });

  test('later long absence locks again', () {
    final p = RelockPolicy();
    p.onBackground(at(0), busy: false);
    expect(p.onForeground(at(600), busy: false), isTrue);
    p.onBackground(at(700), busy: false);
    expect(p.onForeground(at(800), busy: false), isTrue);
  });
}

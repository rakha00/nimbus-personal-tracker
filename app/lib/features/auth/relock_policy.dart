/// Decides when the app locks again after being in the background.
///
/// Bug it fixes: the old code never cleared the "went to background" time, and the device's own
/// PIN screen also sends the app to the background. So after one sleep longer than a minute, every
/// return from the PIN screen looked like another long absence and asked again, forever.
class RelockPolicy {
  RelockPolicy({this.after = const Duration(minutes: 1)});
  final Duration after;
  DateTime? _since;

  /// The app left the screen. Ignored while locked or authenticating: that's the PIN prompt itself.
  void onBackground(DateTime now, {required bool busy}) {
    if (!busy) _since ??= now;
  }

  /// The app came back. Returns true when it should lock. Each absence is counted once.
  bool onForeground(DateTime now, {required bool busy}) {
    final since = _since;
    _since = null;
    return !busy && since != null && now.difference(since) > after;
  }
}

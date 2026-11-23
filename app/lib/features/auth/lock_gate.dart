import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import 'relock_policy.dart';

/// Locks the app on launch and after it has been away for over a minute.
/// Uses the device's own fingerprint / PIN / pattern.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final auth = LocalAuthentication();
  final policy = RelockPolicy();
  bool locked = true;
  bool authenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final busy = locked || authenticating; // the PIN prompt itself sends us to the background
    final now = DateTime.now();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      policy.onBackground(now, busy: busy);
    } else if (state == AppLifecycleState.resumed && policy.onForeground(now, busy: busy)) {
      setState(() => locked = true);
      unlock();
    }
  }

  Future<void> unlock() async {
    if (authenticating) return;
    authenticating = true;
    final reason = AppLocalizations.of(context).unlockReason;
    try {
      // A phone with no screen lock at all can't be protected here; let it through.
      final ok = !await auth.isDeviceSupported() || await auth.authenticate(localizedReason: reason);
      if (ok && mounted) {
        setState(() => locked = false);
        pb.collection('users').authRefresh().ignore(); // keep the server token alive
      }
    } catch (_) {
      // Cancelled or too many attempts: stay locked, the button retries.
    } finally {
      authenticating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!locked) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Spacer(),
            const NimbusMark(size: 56),
            const SizedBox(height: 16),
            Text('Nimbus', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
            const Spacer(),
            FilledButton.icon(
              onPressed: unlock,
              icon: const Icon(Icons.fingerprint),
              label: Text(AppLocalizations.of(context).unlock),
            ),
          ]),
        ),
      ),
    );
  }
}

/// The product's mark: a cloud outline in ink on the surface.
class NimbusMark extends StatelessWidget {
  const NimbusMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = Ledger.of(context);
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: l.primary, borderRadius: BorderRadius.circular(size * .28)),
        child: Icon(Icons.cloud_outlined, color: l.onPrimary, size: size * .55),
      ),
    );
  }
}

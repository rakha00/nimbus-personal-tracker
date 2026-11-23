import 'package:flutter/material.dart';

import '../../core/backend.dart';
import '../../core/theme.dart';
import 'lock_gate.dart';
import '../../l10n/app_localizations.dart';

/// Shown once per install: signs in to PocketBase and keeps the token in secure storage.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? error;

  Future<void> connect() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await pb.collection('users').authWithPassword(email.text.trim(), password.text);
      widget.onDone();
    } catch (_) {
      if (mounted) setState(() => error = AppLocalizations.of(context).loginFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(24), children: [
          const SizedBox(height: 48),
          const NimbusMark(size: 56),
          const SizedBox(height: 12),
          Text(t.setupTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          Labeled(
            t.email,
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
          ),
          const SizedBox(height: 16),
          Labeled(
            t.password,
            TextField(controller: password, obscureText: true, onSubmitted: (_) => connect()),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: busy ? null : connect, child: Text(t.connect)),
        ]),
      ),
    );
  }
}

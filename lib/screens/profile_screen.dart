import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.auth});
  final AuthService auth;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<String?> _ask(String title, String label) {
    final c = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: c, obscureText: true, decoration: InputDecoration(labelText: label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _changePassword() async {
    final pw = await _ask('New password', 'New password (6+ characters)');
    if (pw == null) return;
    if (pw.length < 6) return _toast('Use at least 6 characters.');
    setState(() => _busy = true);
    try {
      try {
        await widget.auth.updatePassword(pw);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'requires-recent-login') rethrow;
        // Stale session: confirm identity, then retry once.
        final current = await _ask(authErrorMessage(e), 'Current password');
        if (current == null) return;
        await widget.auth.reauthenticate(current);
        await widget.auth.updatePassword(pw);
      }
      _toast('Password updated.');
    } catch (e) {
      _toast(authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.auth.currentUser?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Signed in as'),
            Text(email, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            if (_busy)
              const CircularProgressIndicator()
            else ...[
              FilledButton(onPressed: _changePassword, child: const Text('Update password')),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: widget.auth.signOut, child: const Text('Sign out')),
            ],
          ],
        ),
      ),
    );
  }
}
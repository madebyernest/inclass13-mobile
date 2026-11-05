import 'package:firebase_auth/firebase_auth.dart';

/// All Firebase Authentication calls live here; widgets never touch FirebaseAuth.
class AuthService {
  AuthService([FirebaseAuth? auth]) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  // Stable stream: created once so rebuilds don't resubscribe.
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  Future<void> register(String email, String password) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  /// Throws FirebaseAuthException(code: 'requires-recent-login') for stale sessions;
  /// the caller reauthenticates with [reauthenticate] and retries.
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-current-user');
    await user.updatePassword(newPassword);
  }

  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(code: 'no-current-user');
    }
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: currentPassword),
    );
  }
}

/// Turns Firebase error codes into safe, actionable text (never raw exceptions).
String authErrorMessage(Object e) {
  if (e is! FirebaseAuthException) return 'Something went wrong. Please try again.';
  switch (e.code) {
    case 'invalid-email':
      return 'That email address is not valid. Check it and try again.';
    case 'email-already-in-use':
      return 'An account already exists for that email. Try signing in instead.';
    case 'weak-password':
      return 'Password is too weak. Use at least 6 characters.';
    // Newer Firebase projects return invalid-credential for both cases,
    // which avoids revealing whether an account exists.
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email or password is incorrect.';
    case 'user-disabled':
      return 'This account has been disabled. Contact support.';
    case 'too-many-requests':
      return 'Too many attempts. Wait a moment and try again.';
    case 'network-request-failed':
      return 'No connection. Check your internet and try again.';
    case 'requires-recent-login':
      return 'For security, please confirm your current password first.';
    default:
      return 'Could not complete that request. Please try again.';
  }
}
import 'package:alita_pricelist/core/logging/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Initializes an anonymous Firebase Auth user *after* a successful REST
/// login — needed only for Data Connect/App Check, never as the main login
/// mechanism (SPEC.md §5.1).
///
/// This must never be able to fail the REST login: every error is caught
/// and logged as non-fatal. Callers should invoke [ensureSignedIn] without
/// awaiting it on the login critical path (fire-and-forget), so a slow or
/// failing Firebase call never blocks the user from reaching the app.
class FirebaseAnonymousAuth {
  FirebaseAnonymousAuth({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> ensureSignedIn() async {
    try {
      if (_auth.currentUser != null) return;
      await _auth.signInAnonymously();
    } catch (error, stackTrace) {
      AppLogger.recordError(
        error,
        stackTrace,
        reason: 'Firebase anonymous sign-in failed after login (non-fatal, login still succeeds)',
      );
    }
  }
}

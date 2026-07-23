import 'package:alita_pricelist/core/network/api_client_provider.dart';
import 'package:alita_pricelist/features/auth/data/services/auth_repository.dart';
import 'package:alita_pricelist/features/auth/data/services/firebase_anonymous_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manual (non-generated) Riverpod providers — see the note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
///
/// [AuthRepository]'s constructor calls `ApiClient.attachAuth`, which must
/// happen exactly once for the whole app lifetime — a plain (non-disposed)
/// `Provider` guarantees that as long as this provider stays watched.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final firebaseAnonymousAuthProvider = Provider<FirebaseAnonymousAuth>((ref) => FirebaseAnonymousAuth());

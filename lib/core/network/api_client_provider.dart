import 'package:alita_pricelist/core/network/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single [ApiClient] instance for the whole app, so `attachAuth` (called
/// once by the auth module) actually affects every feature's requests.
///
/// Manual (non-generated) Riverpod provider — see the note in
/// `bootstrap_provider.dart` for why `riverpod_generator` isn't used here.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

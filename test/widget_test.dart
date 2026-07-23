// Skeleton smoke test: verifies the app boots, bootstrap resolves, and the
// router redirects past the splash screen to the (placeholder) home page
// without throwing. Real feature widget tests are added per-step as
// features land (see SPEC.md §7).

import 'package:alita_pricelist/core/config/app_config.dart';
import 'package:alita_pricelist/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots and redirects past splash to home', (tester) async {
    await AppConfig.load();

    await tester.pumpWidget(const ProviderScope(child: AlitaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Skeleton OK — fitur belum diimplementasikan.'), findsOneWidget);
  });
}

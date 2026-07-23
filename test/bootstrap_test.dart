// Regression test for: AppConfig.load() failing before runApp() left the
// app on a blank screen with no on-screen message and no Crashlytics trace
// (Crashlytics isn't initialized yet at that point either), because the
// only thing that ran was runZonedGuarded's logging-only error handler.
//
// bootstrap() must always call runApp() with *some* UI, even when config
// loading fails — see lib/main.dart for the guardrail this protects.

import 'package:alita_pricelist/core/widgets/bootstrap_error_page.dart';
import 'package:alita_pricelist/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'bootstrap renders an error screen (not a blank screen) when '
    'AppConfig.load() throws',
    (tester) async {
      await bootstrap(
        loadConfig: () async {
          throw Exception('.env not found (simulated)');
        },
      );
      await tester.pump();

      expect(find.byType(BootstrapErrorPage), findsOneWidget);
      // A blank screen would show neither of these.
      expect(find.byType(MaterialApp), findsOneWidget);
    },
  );
}

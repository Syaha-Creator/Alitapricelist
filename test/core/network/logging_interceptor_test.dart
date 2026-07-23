import 'package:alita_pricelist/core/network/interceptors/logging_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('redactSensitiveQueryParams', () {
    test('redacts access_token, client_id, and client_secret', () {
      final uri = Uri.parse(
        'https://example.test/sign_in'
        '?access_token=super-secret-token'
        '&client_id=my-client-id'
        '&client_secret=super-secret-client-secret'
        '&harmless=kept-as-is',
      );

      final result = redactSensitiveQueryParams(uri);

      expect(result.contains('super-secret-token'), isFalse);
      expect(result.contains('my-client-id'), isFalse);
      expect(result.contains('super-secret-client-secret'), isFalse);
      expect(result.contains('kept-as-is'), isTrue);
    });

    test('leaves a URI with no query parameters unchanged', () {
      final uri = Uri.parse('https://example.test/sign_in');

      expect(redactSensitiveQueryParams(uri), 'https://example.test/sign_in');
    });

    test('leaves non-sensitive query parameters untouched', () {
      final uri = Uri.parse('https://example.test/orders?page=1&limit=20');

      final result = redactSensitiveQueryParams(uri);

      expect(result, contains('page=1'));
      expect(result, contains('limit=20'));
    });
  });
}

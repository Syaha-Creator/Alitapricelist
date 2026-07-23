import 'package:alita_pricelist/features/auth/data/models/login_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResponse.fromJson', () {
    test('parses a full, well-formed response', () {
      final json = {
        'token': 'abc123',
        'user': {
          'id': 42,
          'email': 'budi@massindo.com',
          'name': 'Budi Santoso',
          'area_id': 7,
          'image': {'url': 'https://example.com/avatar.png'},
          'address_number': 'SC-001',
        },
      };

      final result = LoginResponse.fromJson(json);

      expect(result.token, 'abc123');
      expect(result.user.id, 42);
      expect(result.user.email, 'budi@massindo.com');
      expect(result.user.name, 'Budi Santoso');
      expect(result.user.areaId, 7);
      expect(result.user.imageUrl, 'https://example.com/avatar.png');
      expect(result.user.addressNumber, 'SC-001');
    });

    test('falls back to user_name when name is absent', () {
      final json = {
        'token': 'abc123',
        'user': {'id': 1, 'user_name': 'Legacy Name'},
      };

      final result = LoginResponse.fromJson(json);

      expect(result.user.name, 'Legacy Name');
    });

    test('falls back through sales_code / salesCode / code_sales for addressNumber', () {
      expect(
        LoginResponse.fromJson({
          'token': 't',
          'user': {'sales_code': 'A'},
        }).user.addressNumber,
        'A',
      );
      expect(
        LoginResponse.fromJson({
          'token': 't',
          'user': {'salesCode': 'B'},
        }).user.addressNumber,
        'B',
      );
      expect(
        LoginResponse.fromJson({
          'token': 't',
          'user': {'code_sales': 'C'},
        }).user.addressNumber,
        'C',
      );
    });

    test('addressNumber is null (not empty string) when nothing is present', () {
      final result = LoginResponse.fromJson({
        'token': 't',
        'user': {'id': 1},
      });

      expect(result.user.addressNumber, isNull);
    });

    test('defaults every field instead of throwing when user is missing entirely', () {
      final result = LoginResponse.fromJson({'token': 'only-token'});

      expect(result.token, 'only-token');
      expect(result.user.id, 0);
      expect(result.user.email, '');
      expect(result.user.name, '');
      expect(result.user.areaId, 0);
      expect(result.user.imageUrl, '');
      expect(result.user.addressNumber, isNull);
    });

    test('defaults token to empty string instead of throwing when token is missing', () {
      final result = LoginResponse.fromJson({
        'user': {'id': 1},
      });

      expect(result.token, '');
    });

    test('ignores a malformed (non-map) image field instead of throwing', () {
      final result = LoginResponse.fromJson({
        'token': 't',
        'user': {'id': 1, 'image': 'not-a-map'},
      });

      expect(result.user.imageUrl, '');
    });

    test('completely empty JSON produces all-defaults instead of throwing', () {
      final result = LoginResponse.fromJson(const {});

      expect(result.token, '');
      expect(result.user.id, 0);
    });
  });
}

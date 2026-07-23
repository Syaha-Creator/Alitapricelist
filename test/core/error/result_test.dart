import 'package:alita_pricelist/core/error/app_exception.dart';
import 'package:alita_pricelist/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('success exposes data via when()', () {
      const result = Result<int>.success(42);

      final value = result.when(
        success: (data) => data,
        failure: (_) => -1,
      );

      expect(value, 42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('failure exposes error via when()', () {
      const error = NetworkException();
      const result = Result<int>.failure(error);

      final value = result.when(
        success: (_) => -1,
        failure: (err) => err.message,
      );

      expect(value, error.message);
      expect(result.isFailure, isTrue);
    });

    test('map transforms success without touching failure', () {
      const success = Result<int>.success(2);
      const failure = Result<int>.failure(UnknownAppException());

      expect(success.map((v) => v * 10).getOrElse(-1), 20);
      expect(failure.map((v) => v * 10).getOrElse(-1), -1);
    });

    test('getOrElse falls back on failure without throwing', () {
      const result = Result<String>.failure(ParsingException());

      expect(result.getOrElse('fallback'), 'fallback');
    });

    test('fold calls the correct callback exactly once', () {
      var successCalls = 0;
      var failureCalls = 0;

      const Result<int>.success(1).fold(
        onSuccess: (_) => successCalls++,
        onFailure: (_) => failureCalls++,
      );

      expect(successCalls, 1);
      expect(failureCalls, 0);
    });
  });
}

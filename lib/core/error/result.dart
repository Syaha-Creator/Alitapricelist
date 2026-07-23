import 'package:alita_pricelist/core/error/app_exception.dart';

/// Explicit success/failure wrapper returned by every repository method that
/// can fail (network, storage, parsing).
///
/// UI code must always destructure this via [when]/[fold] — never call a
/// getter that could throw. This is what keeps a raw [AppException] (or a
/// worse, un-mapped exception) from ever reaching a widget tree.
sealed class Result<T> {
  const Result();

  const factory Result.success(T data) = Success<T>;

  const factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  /// Exhaustive pattern match — the compiler enforces both branches are
  /// handled, so there is no "in-between" state left untreated by the UI.
  R when<R>({
    required R Function(T data) success,
    required R Function(AppException error) failure,
  }) {
    return switch (this) {
      Success<T>(data: final data) => success(data),
      Failure<T>(error: final error) => failure(error),
    };
  }

  /// Same as [when] but without forcing both branches to return the same
  /// type eagerly — useful for side effects (logging, navigation).
  void fold({
    required void Function(T data) onSuccess,
    required void Function(AppException error) onFailure,
  }) {
    switch (this) {
      case Success<T>(data: final data):
        onSuccess(data);
      case Failure<T>(error: final error):
        onFailure(error);
    }
  }

  /// Transforms the success value, leaving a failure untouched.
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(transform(data)),
      Failure<T>(error: final error) => Result.failure(error),
    };
  }

  /// Returns the success value, or [fallback] if this is a [Failure].
  /// Prefer this over any kind of force-unwrap.
  T getOrElse(T fallback) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Failure<T>() => fallback,
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppException error;
}

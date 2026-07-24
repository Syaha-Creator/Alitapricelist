/// Sealed hierarchy of exceptions the app can reason about explicitly.
///
/// Every network/storage/parsing failure MUST be mapped into one of these
/// concrete types before it reaches a repository boundary. UI code should
/// never receive a raw [Exception]/[Error] — see [Result].
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  /// Human-readable message, safe to show to the user or log.
  final String message;

  /// The original error that caused this, kept for logging/Crashlytics.
  final Object? cause;

  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// No network connectivity, DNS failure, socket errors, etc.
final class NetworkException extends AppException {
  const NetworkException({
    String message = 'Tidak ada koneksi internet. Periksa jaringan Anda.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Request timed out (connect/send/receive).
final class TimeoutAppException extends AppException {
  const TimeoutAppException({
    String message = 'Koneksi timeout. Silakan coba lagi.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// 401/403 — session invalid or expired. Callers should trigger logout.
final class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Sesi Anda telah berakhir. Silakan login kembali.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// 4xx (other than 401/403) — request rejected by server with a known reason.
final class BadRequestException extends AppException {
  const BadRequestException({
    required String message,
    this.fieldErrors = const {},
    super.cause,
    super.stackTrace,
  }) : super(message);

  final Map<String, List<String>> fieldErrors;
}

/// 5xx — server-side failure.
final class ServerException extends AppException {
  const ServerException({
    String message = 'Terjadi kesalahan pada server. Silakan coba lagi nanti.',
    this.statusCode,
    super.cause,
    super.stackTrace,
  }) : super(message);

  final int? statusCode;
}

/// Response body could not be decoded into the expected model.
///
/// This is the explicit alternative to letting a raw `as Map<String, dynamic>`
/// cast or a null-assertion (`!`) throw uncaught somewhere in the UI tree.
final class ParsingException extends AppException {
  const ParsingException({
    String message = 'Format data dari server tidak dikenali.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Local storage / cache read-write failure (SharedPreferences, secure
/// storage, file cache).
final class CacheException extends AppException {
  const CacheException({
    String message = 'Gagal membaca data lokal.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Required app configuration (env var) is missing or invalid — e.g.
/// `API_CLIENT_ID_ANDROID` absent from `.env`. This is a setup/deployment
/// problem, not something the user caused or can fix by retrying.
final class ConfigException extends AppException {
  const ConfigException({
    String message = 'Konfigurasi aplikasi tidak lengkap. Hubungi admin.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

/// Catch-all for anything that doesn't fit the categories above. Kept
/// deliberately narrow in scope — new call sites should prefer adding a new
/// concrete [AppException] subtype instead of reaching for this.
final class UnknownAppException extends AppException {
  const UnknownAppException({
    String message = 'Terjadi kesalahan yang tidak diketahui.',
    super.cause,
    super.stackTrace,
  }) : super(message);
}

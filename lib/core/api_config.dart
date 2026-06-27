// Conditional import: on web, dart:io is unavailable, so we swap in a web stub.
// The default (`_platform_io.dart`) is used everywhere `dart.library.io` exists
// (Android, iOS, desktop); `_platform_web.dart` is used when `dart.library.html`
// is present (web). This keeps `dart:io` out of web builds entirely.
import '_platform_io.dart'
    if (dart.library.html) '_platform_web.dart' as platform;

/// Central place for backend connection settings.
///
/// The host differs by where the app runs, which trips people up constantly:
///   * Android emulator  → `10.0.2.2` is the host machine's loopback
///     (`localhost` inside the emulator is the emulator itself).
///   * iOS simulator / desktop / web → `localhost` reaches the host directly.
///   * Physical device → neither works; you need the dev machine's LAN IP
///     (e.g. `192.168.1.20`). Override the host for that case.
///
/// The backend (ASP.NET Core) serves auth under `/api/auth/...` and runs over
/// HTTPS in real use. During local dev it's commonly HTTP on a Kestrel port;
/// adjust [_scheme] and [_port] to match how you launch `dotnet run` (read the
/// "Now listening on" line in its console).
class ApiConfig {
  ApiConfig._();

  // --- Tune these two to match your running backend ------------------------
  static const String _scheme = 'https';
  static const int _port = 7161; // typical Kestrel HTTPS dev port; change me
  // -------------------------------------------------------------------------

  /// Resolved host for the current platform (see conditional import above).
  static String get _host => platform.resolveHost();

  /// Base origin, e.g. `https://10.0.2.2:7174`.
  static String get baseUrl => '$_scheme://$_host:$_port';

  static Uri get login => Uri.parse('$baseUrl/api/auth/login');
  static Uri get refresh => Uri.parse('$baseUrl/api/auth/refresh');
  static Uri get logout => Uri.parse('$baseUrl/api/auth/logout');

  /// How long to wait before giving up on a request.
  static const Duration timeout = Duration(seconds: 15);
}

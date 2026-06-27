import 'dart:io' show Platform;

/// Host for native (non-web) platforms. Android emulator needs 10.0.2.2 to
/// reach the host machine's loopback; everything else can use localhost.
String resolveHost() {
  if (Platform.isAndroid) return '10.0.2.2';
  return 'localhost';
}

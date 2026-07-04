import 'dart:io' show Platform;

/// Host for native (non-web) platforms.
/// - Android emulator: 10.0.2.2 trỏ về loopback máy host
/// - Android physical device: dùng LAN IP của máy dev (cùng WiFi)
/// - Các nền tảng khác: localhost
String resolveHost() {
  if (Platform.isAndroid) return '10.0.2.2'; // emulator → host loopback; đổi thành LAN IP khi dùng điện thoại thật
  return 'localhost';
}

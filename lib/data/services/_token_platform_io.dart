import 'dart:io' show Platform;

/// true trên Windows desktop — nơi `flutter_secure_storage` được xác nhận
/// không bao giờ persist xuống đĩa thật (xem token_storage.dart).
bool laWindowsDesktop() => Platform.isWindows;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Lưu trữ token xác thực vào bộ nhớ an toàn của thiết bị.
///
/// Trên Android → EncryptedSharedPreferences (mã hóa AES-256)
/// Trên iOS/macOS → Keychain
///
/// KHÔNG BAO GIỜ dùng SharedPreferences thông thường để lưu token —
/// nó không được mã hóa và bất kỳ app nào cũng có thể đọc được.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  // ── Keys ────────────────────────────────────────────────────────────────────
  // Mỗi key là 1 "tên ô" trong bộ nhớ an toàn, giống như tên biến.
  // Đặt là static const vì chúng không thay đổi bao giờ.
  static const _kAccessToken  = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRoles        = 'roles';         // THÊM MỚI

  // ── Ghi ─────────────────────────────────────────────────────────────────────

  /// Lưu cặp token + danh sách role sau khi đăng nhập thành công.
  ///
  /// Tại sao lưu roles?
  /// Khi app khởi động lại, chúng ta cần biết user có role gì để
  /// điều hướng đúng màn hình — không cần hỏi server.
  ///
  /// Tại sao dùng Future.wait?
  /// Để 3 lệnh ghi chạy SONG SONG thay vì tuần tự — nhanh hơn.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required List<String> roles,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken,  value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      // List<String> không lưu trực tiếp được → join thành 1 chuỗi
      // Ví dụ: ["Student", "Lecturer"] → "Student,Lecturer"
      _storage.write(key: _kRoles, value: roles.join(',')),
    ]);
  }

  // ── Đọc ─────────────────────────────────────────────────────────────────────

  Future<String?> readAccessToken()  => _storage.read(key: _kAccessToken);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  /// Đọc danh sách role đã lưu.
  ///
  /// "Student,Lecturer" → split(',') → ["Student", "Lecturer"]
  /// Nếu chưa có gì → trả về list rỗng (không throw lỗi).
  Future<List<String>> readRoles() async {
    final raw = await _storage.read(key: _kRoles);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }

  /// Kiểm tra nhanh xem có session đang active không.
  ///
  /// Chỉ cần check refresh token tồn tại là đủ — nếu có refresh token
  /// nghĩa là user đã đăng nhập lần trước và chưa logout.
  /// Access token có thể hết hạn nhưng AuthenticatedClient sẽ tự gia hạn.
  Future<bool> hasSession() async =>
      (await _storage.read(key: _kRefreshToken)) != null;

  // ── Xóa ─────────────────────────────────────────────────────────────────────

  /// Xóa toàn bộ dữ liệu auth — dùng khi logout hoặc refresh thất bại.
  ///
  /// Xóa cả 3 ô cùng lúc (song song) để đảm bảo không còn dữ liệu nào sót lại.
  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kRoles),      // THÊM MỚI — xóa roles khi logout
    ]);
  }
}

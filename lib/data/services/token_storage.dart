import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

// Conditional import — xem lib/core/api_config.dart cho pattern gốc: web
// không có dart:io nên phải tách hàm phát hiện platform ra file riêng.
import '_token_platform_io.dart'
    if (dart.library.html) '_token_platform_web.dart' as platform;

/// Lưu trữ token xác thực vào bộ nhớ an toàn của thiết bị.
///
/// Trên Android → EncryptedSharedPreferences (mã hóa AES-256)
/// Trên iOS/macOS/Web → Keychain / implementation an toàn riêng của
/// `flutter_secure_storage` cho từng nền tảng.
///
/// Trên WINDOWS DESKTOP → **KHÔNG dùng `flutter_secure_storage`**. Đã xác
/// nhận bằng debug log qua nhiều bước (xem CONTEXT.md mục 3.23–3.24): trên
/// máy dev, `write()` không throw lỗi nhưng giá trị KHÔNG BAO GIỜ đọc lại
/// được — kể cả đợi 30 giây, kể cả đọc thẳng qua object gốc bỏ qua mọi
/// cache. Đây không phải race condition (chậm flush) mà là ghi thất bại
/// thật sự của bản `flutter_secure_storage_windows` hiện có (nâng cấp lên
/// bản mới hơn (4.2.2) đã thử nhưng xung đột `win32` với `file_picker`,
/// bản mới của `file_picker` lại đổi API breaking — không khả thi lúc
/// này). Giải pháp: Windows dùng riêng 1 file JSON cục bộ trong thư mục dữ
/// liệu riêng của app (`getApplicationSupportDirectory()` — chỉ user hiện
/// tại trên máy đọc được, không phải plaintext-trong-SharedPreferences công
/// khai, nhưng cũng KHÔNG mã hoá bằng DPAPI/Credential Manager như secure
/// storage thật — chấp nhận được cho 1 app nội bộ chạy trên máy cá nhân,
/// không phải mức bảo mật production-grade cho dữ liệu nhạy cảm hơn).
///
/// KHÔNG BAO GIỜ dùng SharedPreferences thông thường để lưu token trên các
/// nền tảng còn lại — nó không được mã hóa và bất kỳ app nào cũng có thể
/// đọc được.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        // Chỉ dùng file backend khi KHÔNG bị inject storage giả cho test
        // (giữ hành vi test cũ) và đang chạy Windows desktop thật.
        _dungFileBackend = storage == null && platform.laWindowsDesktop();

  final FlutterSecureStorage _storage;
  final bool _dungFileBackend;
  final _WindowsFileTokenStore _fileStore = _WindowsFileTokenStore();

  // ── Cache trong bộ nhớ ────────────────────────────────────────────────────
  //
  // Giữ lại cache này dù đã có file backend cho Windows — vẫn có lợi cho
  // hiệu năng (khỏi đọc file/gọi platform channel mỗi lần) và làm lớp
  // phòng ngừa chung nếu sau này phát hiện thêm race tương tự trên nền
  // tảng khác.
  String? _cachedAccessToken;
  String? _cachedRefreshToken;
  String? _cachedRolesRaw;

  // ── Keys ────────────────────────────────────────────────────────────────────
  static const _kAccessToken  = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kRoles        = 'roles';

  // ── Ghi ─────────────────────────────────────────────────────────────────────

  /// Lưu cặp token + danh sách role sau khi đăng nhập thành công.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required List<String> roles,
  }) async {
    final rolesRaw = roles.join(',');

    _cachedAccessToken  = accessToken;
    _cachedRefreshToken = refreshToken;
    _cachedRolesRaw     = rolesRaw;

    await Future.wait([
      _ghi(_kAccessToken, accessToken),
      _ghi(_kRefreshToken, refreshToken),
      _ghi(_kRoles, rolesRaw),
    ]);
  }

  // ── Đọc ─────────────────────────────────────────────────────────────────────

  Future<String?> readAccessToken() async =>
      _cachedAccessToken ??= await _doc(_kAccessToken);

  Future<String?> readRefreshToken() async =>
      _cachedRefreshToken ??= await _doc(_kRefreshToken);

  /// Đọc danh sách role đã lưu.
  Future<List<String>> readRoles() async {
    final raw = _cachedRolesRaw ??= await _doc(_kRoles);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }

  /// Kiểm tra nhanh xem có session đang active không.
  Future<bool> hasSession() async => (await readRefreshToken()) != null;

  // ── Xóa ─────────────────────────────────────────────────────────────────────

  /// Xóa toàn bộ dữ liệu auth — dùng khi logout hoặc refresh thất bại.
  Future<void> clear() async {
    _cachedAccessToken  = null;
    _cachedRefreshToken = null;
    _cachedRolesRaw     = null;
    await Future.wait([
      _xoa(_kAccessToken),
      _xoa(_kRefreshToken),
      _xoa(_kRoles),
    ]);
  }

  // ── Chọn backend: file cục bộ (Windows) hay FlutterSecureStorage thật ──────

  Future<void> _ghi(String key, String value) => _dungFileBackend
      ? _fileStore.write(key, value)
      : _storage.write(key: key, value: value);

  Future<String?> _doc(String key) => _dungFileBackend
      ? _fileStore.read(key)
      : _storage.read(key: key);

  Future<void> _xoa(String key) => _dungFileBackend
      ? _fileStore.delete(key)
      : _storage.delete(key: key);
}

// ── Backend file JSON cục bộ — chỉ dùng trên Windows desktop ─────────────────

class _WindowsFileTokenStore {
  Map<String, String>? _cache;
  File? _file;

  Future<File> _layFile() async {
    final daCo = _file;
    if (daCo != null) return daCo;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}auth_session.json');
    _file = file;
    return file;
  }

  Future<Map<String, String>> _taiDuLieu() async {
    final daCo = _cache;
    if (daCo != null) return daCo;

    final file = await _layFile();
    if (!await file.exists()) {
      return _cache = {};
    }
    try {
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _cache = json.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      // File hỏng/không đọc được → coi như trống, không throw để không
      // chặn luồng đăng nhập lại.
      return _cache = {};
    }
  }

  Future<void> _luuXuongDia(Map<String, String> data) async {
    final file = await _layFile();
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  }

  Future<String?> read(String key) async => (await _taiDuLieu())[key];

  Future<void> write(String key, String value) async {
    final data = await _taiDuLieu();
    data[key] = value;
    await _luuXuongDia(data);
  }

  Future<void> delete(String key) async {
    final data = await _taiDuLieu();
    data.remove(key);
    await _luuXuongDia(data);
  }
}

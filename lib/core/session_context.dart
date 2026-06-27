import 'package:flutter/foundation.dart';

import 'package:smart_university_management_platform/data/models/login_response.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';

// ============================================================================
// SESSION CONTEXT
//
// Khái niệm cần hiểu trước khi đọc file này:
//
// 1. STATE là gì?
//    State = dữ liệu có thể thay đổi theo thời gian.
//    Ví dụ: "user đã đăng nhập chưa?" là state — lúc đầu là false,
//    sau khi đăng nhập là true, sau khi logout lại là false.
//
// 2. ChangeNotifier là gì?
//    Là một class của Flutter. Khi bạn extends nó và gọi
//    notifyListeners(), tất cả widget đang "lắng nghe" sẽ tự rebuild.
//    Giống như một cái loa: thay đổi state → bấm còi → mọi người cập nhật.
//
// 3. Tại sao cần file này?
//    Hiện tại, mỗi màn hình phải nhận dữ liệu qua constructor:
//      WorkspaceScreen(activeRole: role)
//    Khi app lớn hơn, dữ liệu phải truyền qua rất nhiều tầng widget.
//    SessionContext giải quyết: lưu state ở 1 chỗ, widget nào cần thì đọc.
// ============================================================================

class SessionContext extends ChangeNotifier {
  // ── Private state ──────────────────────────────────────────────────────────
  // Dấu _ trước tên biến = private (chỉ class này đọc/ghi được trực tiếp)
  // Bên ngoài chỉ đọc được qua getters bên dưới → tránh bị thay đổi bừa bãi

  List<String> _roles     = [];      // roles thật từ JWT, ví dụ: ["Student"]
  AppRole?     _activeRole;          // role đang dùng trong session này
  String?      _loginCode;           // lưu để hiển thị UI (KHÔNG dùng cho auth)

  // ── Getters — đọc state từ bên ngoài ──────────────────────────────────────

  /// Danh sách role thật của tài khoản (từ JWT).
  /// List.unmodifiable → widget bên ngoài không thể gọi roles.add() hay .clear()
  List<String> get roles => List.unmodifiable(_roles);

  /// Role đang active trong phiên này (do user chọn hoặc tự động).
  /// Nullable vì user chưa chọn role khi có nhiều role.
  AppRole? get activeRole => _activeRole;

  /// Tên đăng nhập — chỉ để hiển thị UI, không có giá trị bảo mật.
  String? get loginCode => _loginCode;

  /// true = đã đăng nhập (có ít nhất 1 role).
  bool get isLoggedIn => _roles.isNotEmpty;

  /// true = có nhiều role VÀ chưa chọn → cần hiện RolePickerScreen.
  bool get needsRolePicker => _roles.length > 1 && _activeRole == null;

  // ── Methods — thay đổi state ──────────────────────────────────────────────
  // Sau mỗi thay đổi đều gọi notifyListeners() để báo cho widget biết
  // state đã thay đổi và cần rebuild.

  /// Gọi ngay sau khi server trả về LoginResponse thành công.
  ///
  /// Nếu chỉ có 1 role → tự chọn luôn (không cần màn chọn role).
  /// Nếu có nhiều role → để _activeRole = null → needsRolePicker = true.
  void login(LoginResponse response, {String? loginCode}) {
    _roles     = List.of(response.roles); // List.of = tạo bản copy, không tham chiếu
    _loginCode = loginCode;
    _activeRole = _roles.length == 1
        ? AppRole.fromBackendId(_roles.first)
        : null;
    notifyListeners();
  }

  /// Gọi khi app khởi động lại và đọc được roles từ TokenStorage.
  ///
  /// Tương tự login() nhưng không có LoginResponse — chỉ có roles từ bộ nhớ.
  void restore(List<String> storedRoles) {
    _roles      = List.of(storedRoles);
    _loginCode  = null; // không có trong storage
    _activeRole = _roles.length == 1
        ? AppRole.fromBackendId(_roles.first)
        : null;
    notifyListeners();
  }

  /// Gọi khi user chọn 1 role trong RolePickerScreen.
  void selectRole(AppRole role) {
    _activeRole = role;
    notifyListeners();
  }

  /// Gọi khi user đăng xuất — xóa sạch toàn bộ state.
  void logout() {
    _roles      = [];
    _activeRole = null;
    _loginCode  = null;
    notifyListeners();
  }
}

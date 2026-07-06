import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/session_context.dart';
import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/services/authenticated_client.dart';
import 'package:smart_university_management_platform/data/services/token_storage.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/auth/screens/splash_screen.dart';

/// Navigator key dùng chung — cho phép code ngoài widget (như
/// [AuthenticatedClient]) điều hướng mà không cần BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

/// Trạng thái phiên đăng nhập dùng chung toàn app.
///
/// Bất kỳ file nào cũng có thể import main.dart và dùng:
///   session.login(response)   — sau khi đăng nhập thành công
///   session.restore(roles)    — khi app khởi động lại
///   session.selectRole(role)  — khi user chọn role
///   session.logout()          — khi đăng xuất
///   session.activeRole        — đọc role hiện tại
///   session.isLoggedIn        — kiểm tra trạng thái
final session = SessionContext();

/// Instance TokenStorage DUY NHẤT dùng cho toàn app.
///
/// QUAN TRỌNG: không được tạo `TokenStorage()` rải rác ở nơi khác — trên
/// Windows, nhiều instance `FlutterSecureStorage` độc lập không nhìn thấy
/// dữ liệu của nhau (ghi bằng 1 instance, đọc bằng instance khác luôn ra
/// null), gây bug "đăng nhập xong gọi API nào cũng 401 rồi bị đá về màn
/// đăng nhập". Luôn dùng lại biến `tokenStorage` này.
final tokenStorage = TokenStorage();

/// HTTP client xác thực dùng chung — tự gắn token và tự refresh.
final authenticatedClient = AuthenticatedClient(
  storage: tokenStorage,
  onUnauthenticated: () {
    // Token hết hạn và refresh thất bại → xóa session + về login
    session.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  },
);

void main() => runApp(const SmartUniversityApp());

class SmartUniversityApp extends StatelessWidget {
  const SmartUniversityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart University',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
    );
  }
}
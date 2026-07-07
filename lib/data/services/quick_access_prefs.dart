import 'package:shared_preferences/shared_preferences.dart';

/// Lưu cục bộ trên máy (không qua backend) danh sách id chức năng người
/// dùng đã ghim thêm lên Dashboard, theo từng vai trò (Student/Lecturer/Admin
/// có thể tùy chỉnh độc lập nếu sau này mở rộng).
class QuickAccessPrefs {
  const QuickAccessPrefs();

  String _key(String vaiTro) => 'quick_access_pinned_$vaiTro';

  /// Danh sách id đã ghim của [vaiTro]. Rỗng nếu chưa từng tùy chỉnh.
  Future<Set<String>> layDaGhim(String vaiTro) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key(vaiTro)) ?? const []).toSet();
  }

  Future<void> ghim(String vaiTro, String id) async {
    final daGhim = await layDaGhim(vaiTro);
    daGhim.add(id);
    await _luu(vaiTro, daGhim);
  }

  Future<void> boGhim(String vaiTro, String id) async {
    final daGhim = await layDaGhim(vaiTro);
    daGhim.remove(id);
    await _luu(vaiTro, daGhim);
  }

  Future<void> _luu(String vaiTro, Set<String> daGhim) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(vaiTro), daGhim.toList());
  }
}

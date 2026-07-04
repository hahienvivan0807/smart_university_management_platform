import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/admin_class.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

class AdminClassService {
  AdminClassService(this._client);

  final http.Client _client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Lấy danh sách lớp hành chính, có thể lọc theo chương trình đào tạo.
  Future<({PagedResult<AdminClassItem>? data, String? error})> layDanhSach({
    int? programId,
    int trang = 1,
    int soLuong = 20,
  }) async {
    try {
      final uri = ApiConfig.adminClasses(
          programId: programId, page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, AdminClassItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới lớp hành chính — POST /api/admin-classes.
  Future<({AdminClassItem? data, String? error})> taoMoi(
      CreateAdminClassRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.adminClasses(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: AdminClassItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật lớp hành chính (tên hoặc cố vấn) — PUT /api/admin-classes/{id}.
  Future<({AdminClassItem? data, String? error})> capNhat(
      int maLop, UpdateAdminClassRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.adminClass(maLop),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: AdminClassItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa lớp hành chính — DELETE /api/admin-classes/{id}.
  /// Backend chặn nếu lớp còn sinh viên.
  Future<({bool ok, String? error})> voHieuHoa(int maLop) async {
    try {
      final res = await _client
          .delete(ApiConfig.adminClass(maLop))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  /// Gán sinh viên vào lớp hành chính — POST /api/admin-classes/{id}/students.
  Future<({bool ok, String? error})> ganSinhVien(
      int maLop, int studentUserId) async {
    try {
      final res = await _client
          .post(
            ApiConfig.adminClassStudents(maLop),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'studentUserId': studentUserId}),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['message'] as String? ??
          body['title'] as String? ??
          'Lỗi ${res.statusCode}';
    } catch (_) {
      return 'Lỗi ${res.statusCode}';
    }
  }
}

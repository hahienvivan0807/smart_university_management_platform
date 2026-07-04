import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/department.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

// ============================================================================
// DEPARTMENT SERVICE
//
// Giao tiếp với /api/departments trên backend.
// Dùng [authenticatedClient] (từ main.dart) để tự gắn JWT và tự refresh token.
//
// Kết quả trả về dùng record Dart 3 dạng `({bool ok, T? data, String? error})`.
// Gọn, không cần class Result riêng — đủ dùng cho Flutter layer.
// ============================================================================

class DepartmentService {
  DepartmentService(this._client);

  final http.Client _client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Lấy danh sách bộ môn, có thể lọc theo khoa.
  /// Backend trả `PagedResult<DepartmentListDto>`.
  Future<({PagedResult<DepartmentItem>? data, String? error})> layDanhSach({
    int? facultyId,
    int trang = 1,
    int soLuong = 20,
  }) async {
    try {
      final uri = ApiConfig.departments(
          facultyId: facultyId, page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, DepartmentItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy chi tiết 1 bộ môn theo id.
  Future<({DepartmentItem? data, String? error})> layChiTiet(int maBM) async {
    try {
      final res = await _client
          .get(ApiConfig.department(maBM))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: DepartmentItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      if (res.statusCode == 404) {
        return (data: null, error: 'Không tìm thấy bộ môn.');
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới bộ môn — POST /api/departments.
  Future<({DepartmentItem? data, String? error})> taoMoi(
      CreateDepartmentRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.departments(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: DepartmentItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật tên bộ môn — PUT /api/departments/{id}.
  Future<({DepartmentItem? data, String? error})> capNhat(
      int maBM, UpdateDepartmentRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.department(maBM),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: DepartmentItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa bộ môn (soft delete) — DELETE /api/departments/{id}.
  /// Backend chặn nếu còn giảng viên thuộc bộ môn này.
  Future<({bool ok, String? error})> voHieuHoa(int maBM) async {
    try {
      final res = await _client
          .delete(ApiConfig.department(maBM))
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

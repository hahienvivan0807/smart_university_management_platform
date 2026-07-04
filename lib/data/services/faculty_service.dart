import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/faculty.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

// ============================================================================
// FACULTY SERVICE
//
// Mục đích: giao tiếp với /api/faculties trên backend.
//
// Tại sao tách service riêng (không gọi http thẳng trong screen)?
//   → Screen chỉ biết "tôi cần danh sách khoa" — không biết URL là gì,
//     response parse như thế nào, lỗi 5xx xử lý ra sao.
//     Service đóng gói tất cả phần đó; screen chỉ nhận ({data, error}).
//     Nếu sau này backend đổi route, chỉ sửa ở đây, không đụng đến screen.
//
// Client được inject vào constructor (không new trong service):
//   → Dùng [authenticatedClient] từ main.dart — tự gắn JWT + tự refresh.
//   → Có thể inject http.Client giả (mock) khi viết test.
//
// ============================================================================

class FacultyService {
  FacultyService(this._client);

  final http.Client _client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Lấy danh sách khoa — GET /api/faculties.
  ///
  /// Trả về record `({data, error})`:
  ///   • data != null  → thành công, dùng data.items
  ///   • error != null → thất bại, hiện thông báo lỗi cho user
  Future<({PagedResult<FacultyItem>? data, String? error})> layDanhSach({
    int trang = 1,
    int soLuong = 20,
  }) async {
    try {
      final uri = ApiConfig.faculties(page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, FacultyItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      // Lỗi mạng (timeout, no internet, DNS fail, v.v.)
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới khoa — POST /api/faculties.
  Future<({FacultyItem? data, String? error, bool isConflict})> taoMoi(
      CreateFacultyRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.faculties(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: FacultyItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
          isConflict: false,
        );
      }
      return (
        data: null,
        error: _extractError(res),
        isConflict: res.statusCode == 409,
      );
    } catch (_) {
      return (
        data: null,
        error: 'Không thể kết nối đến server.',
        isConflict: false,
      );
    }
  }

  /// Cập nhật tên khoa — PUT /api/faculties/{id}.
  Future<({FacultyItem? data, String? error, bool isConflict})> capNhat(
      int maKhoa, UpdateFacultyRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.faculty(maKhoa),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: FacultyItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
          isConflict: false,
        );
      }
      return (
        data: null,
        error: _extractError(res),
        isConflict: res.statusCode == 409,
      );
    } catch (_) {
      return (
        data: null,
        error: 'Không thể kết nối đến server.',
        isConflict: false,
      );
    }
  }

  /// Vô hiệu hóa khoa (soft delete) — DELETE /api/faculties/{id}.
  Future<({bool ok, String? error})> voHieuHoa(int maKhoa) async {
    try {
      final res = await _client
          .delete(ApiConfig.faculty(maKhoa))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

  /// Trích xuất message lỗi từ body JSON của backend.
  /// Backend trả { "message": "..." } hoặc ASP.NET ProblemDetails { "title": "..." }.
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

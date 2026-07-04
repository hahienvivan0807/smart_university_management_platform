import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/course.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

// ============================================================================
// COURSE SERVICE
//
// Giao tiếp với /api/courses trên backend.
// ============================================================================

class CourseService {
  CourseService(this._client);

  final http.Client _client;

  /// Lấy danh sách môn học, có thể lọc theo khoa hoặc bộ môn.
  /// Backend trả `PagedResult<CourseListDto>`.
  Future<({PagedResult<CourseItem>? data, String? error})> layDanhSach({
    int? facultyId,
    int? departmentId,
    int trang = 1,
    int soLuong = 20,
  }) async {
    try {
      final uri = ApiConfig.courses(
        facultyId: facultyId,
        departmentId: departmentId,
        page: trang,
        pageSize: soLuong,
      );
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, CourseItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới môn học — POST /api/courses.
  Future<({CourseItem? data, String? error})> taoMoi(
      CreateCourseRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.courses(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: CourseItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật môn học — PUT /api/courses/{id}.
  Future<({CourseItem? data, String? error})> capNhat(
      int courseId, UpdateCourseRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.course(courseId),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: CourseItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa môn học — DELETE /api/courses/{id}.
  Future<({bool ok, String? error})> voHieuHoa(int courseId) async {
    try {
      final res = await _client
          .delete(ApiConfig.course(courseId))
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

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';
import 'package:smart_university_management_platform/data/models/program.dart';

class ProgramService {
  ProgramService(this._client);

  final http.Client _client;

  /// Lấy danh sách chương trình đào tạo, có thể lọc theo ngành.
  Future<({PagedResult<ProgramItem>? data, String? error})> layDanhSach(
      {int? majorId, int trang = 1, int soLuong = 20}) async {
    try {
      final uri = ApiConfig.programs(
          majorId: majorId, page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, ProgramItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy chi tiết 1 chương trình đào tạo, gồm cả danh sách môn (curriculum).
  Future<({ProgramDetail? data, String? error})> layChiTiet(
      int programId) async {
    try {
      final res = await _client
          .get(ApiConfig.program(programId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: ProgramDetail.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới chương trình đào tạo — POST /api/programs.
  Future<({ProgramItem? data, String? error})> taoMoi(
      CreateProgramRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.programs(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: ProgramItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật chương trình đào tạo — PUT /api/programs/{id}.
  Future<({ProgramItem? data, String? error})> capNhat(
      int programId, UpdateProgramRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.program(programId),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: ProgramItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa chương trình đào tạo — DELETE /api/programs/{id}.
  Future<({bool ok, String? error})> voHieuHoa(int programId) async {
    try {
      final res = await _client
          .delete(ApiConfig.program(programId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  /// Thêm môn học vào curriculum — POST /api/programs/{id}/courses.
  Future<({ProgramCourseItem? data, String? error})> themMonHoc(
      int programId, AddCourseToProgramRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.programCourses(programId),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200 || res.statusCode == 201) {
        return (
          data: ProgramCourseItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Gỡ môn học khỏi curriculum — DELETE /api/programs/{id}/courses/{courseId}.
  Future<({bool ok, String? error})> xoaMonHoc(
      int programId, int courseId) async {
    try {
      final res = await _client
          .delete(ApiConfig.programCourse(programId, courseId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

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

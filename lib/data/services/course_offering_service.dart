import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/course_offering.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

class CourseOfferingService {
  CourseOfferingService(this._client);

  final http.Client _client;

  /// Lấy danh sách lớp HP, có thể lọc theo học kỳ, hoặc [dangMoDangKy]=true để
  /// lấy thẳng các lớp đang trong cửa sổ đăng ký ngay bây giờ (không cần biết
  /// trước học kỳ nào — dùng cho màn "Đăng ký học phần" của sinh viên).
  Future<({PagedResult<CourseOfferingItem>? data, String? error})>
      layDanhSach({
    int? termId,
    int trang = 1,
    int soLuong = 20,
    bool? dangMoDangKy,
  }) async {
    try {
      final uri = ApiConfig.courseOfferings(
        termId: termId,
        page: trang,
        pageSize: soLuong,
        dangMoDangKy: dangMoDangKy,
      );
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, CourseOfferingItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới lớp học phần — POST /api/course-offerings.
  Future<({CourseOfferingItem? data, String? error})> taoMoi(
      CreateCourseOfferingRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.courseOfferings(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: CourseOfferingItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật sức chứa / lịch học lớp học phần — PUT /api/course-offerings/{id}.
  Future<({CourseOfferingItem? data, String? error})> capNhat(
      int maLHP, UpdateCourseOfferingRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.courseOffering(maLHP),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: CourseOfferingItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Hủy lớp học phần (soft cancel) — POST /api/course-offerings/{id}/cancel.
  Future<({bool ok, String? error})> huyLop(int maLHP) async {
    try {
      final res = await _client
          .post(ApiConfig.courseOfferingCancel(maLHP))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  /// Đổi giảng viên phụ trách — PUT /api/course-offerings/{id}/lecturer.
  Future<({bool ok, String? error})> doiGiangVien(
      int maLHP, int lecturerUserId) async {
    try {
      final res = await _client
          .put(
            ApiConfig.courseOfferingLecturer(maLHP),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(
                DoiGiangVienRequest(lecturerUserId: lecturerUserId).toJson()),
          )
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

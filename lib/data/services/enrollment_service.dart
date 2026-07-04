import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';


class EnrollmentService {
  EnrollmentService(this._client);

  final http.Client _client;

  /// Đăng ký lớp học phần. Trả về EnrollmentItem khi thành công.
  Future<({EnrollmentItem? data, String? error})> dangKy(
      int courseOfferingId) async {
    try {
      final res = await _client
          .post(
            ApiConfig.enrollments,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'courseOfferingId': courseOfferingId}),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: EnrollmentItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Hủy đăng ký học phần theo enrollmentId.
  Future<({bool ok, String? error})> huyDangKy(int enrollmentId) async {
    try {
      final res = await _client
          .delete(ApiConfig.enrollment(enrollmentId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 204) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy danh sách môn đã đăng ký của sinh viên hiện tại.
  Future<({List<EnrollmentItem>? data, String? error})> layDanhSachCuaToi(
      {int? termId}) async {
    try {
      final res = await _client
          .get(ApiConfig.myEnrollments(termId: termId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return (
          data: list
              .map((e) => EnrollmentItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy danh sách sinh viên trong lớp học phần (roster).
  /// Dùng cho giảng viên phụ trách hoặc staff.
  Future<({List<RosterItem>? data, String? error})> layRoster(
      int courseOfferingId) async {
    try {
      final res = await _client
          .get(ApiConfig.offeringRoster(courseOfferingId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return (
          data: list
              .map((e) => RosterItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy thời khóa biểu của sinh viên hiện tại trong 1 học kỳ.
  Future<({List<TimetableEntry>? data, String? error})> layThoiKhoaBieu(
      int termId) async {
    try {
      final res = await _client
          .get(ApiConfig.myTimetable(termId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return (
          data: list
              .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
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

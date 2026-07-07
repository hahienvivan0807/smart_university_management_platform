import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/leave_request.dart';

class LeaveRequestService {
  LeaveRequestService(this._client);

  final http.Client _client;

  /// Giảng viên tạo phiếu xin tạm ngưng buổi học — POST /api/leave-requests.
  Future<({LeaveRequestItem? data, String? error})> taoMoi(
      CreateLeaveRequestPayload yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.leaveRequests,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: LeaveRequestItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Giảng viên tự thu hồi phiếu đang Chờ duyệt — PUT /api/leave-requests/{id}/revoke.
  Future<({bool ok, String? error})> thuHoi(int leaveRequestId) async {
    try {
      final res = await _client
          .put(ApiConfig.leaveRequestRevoke(leaveRequestId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) return (ok: true, error: null);
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lịch sử toàn bộ phiếu xin nghỉ của giảng viên đang đăng nhập — GET /api/me/leave-requests.
  Future<({List<LeaveRequestItem>? data, String? error})>
      layLichSuCuaToi() async {
    try {
      final res = await _client
          .get(ApiConfig.myLeaveRequests)
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return (
          data: list
              .map((e) => LeaveRequestItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Các khoảng ngày đã bị chiếm (Chờ duyệt/Đã duyệt) của 1 lớp học phần — để làm mờ date-picker.
  Future<({List<BlockedDateRange>? data, String? error})> layNgayDaChiem(
      int courseOfferingId) async {
    try {
      final res = await _client
          .get(ApiConfig.leaveRequestBlockedDates(courseOfferingId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return (
          data: list
              .map((e) => BlockedDateRange.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Trong số các lớp học phần truyền vào, lớp nào đang tạm ngưng đúng hôm nay — để hiện badge đỏ hàng loạt.
  Future<({List<ActiveSuspension>? data, String? error})> layTamNgungHomNay(
      List<int> courseOfferingIds) async {
    if (courseOfferingIds.isEmpty) return (data: <ActiveSuspension>[], error: null);
    try {
      final res = await _client
          .get(ApiConfig.leaveRequestActiveSuspensions(courseOfferingIds))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return (
          data: list
              .map((e) => ActiveSuspension.fromJson(e as Map<String, dynamic>))
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
      return body['error'] as String? ??
          body['message'] as String? ??
          body['title'] as String? ??
          'Lỗi ${res.statusCode}';
    } catch (_) {
      return 'Lỗi ${res.statusCode}';
    }
  }
}

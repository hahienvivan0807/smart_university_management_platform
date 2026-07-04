import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/attendance.dart';

class AttendanceService {
  const AttendanceService(this._client);
  final http.Client _client;

  /// GV mở buổi điểm danh cho lớp HP, gửi kèm tọa độ GPS phòng học.
  Future<({AttendanceSession? data, String? error})> moBuoi(
    int courseOfferingId, {
    double? lat,
    double? lng,
    int radiusMeters = 100,
  }) async {
    try {
      final res = await _client
          .post(
            ApiConfig.moBuoiDiemDanh(courseOfferingId),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'latitude': lat,
              'longitude': lng,
              'radiusMeters': radiusMeters,
            }),
          )
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        return (
          data: AttendanceSession.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        data: null,
        error: body['error'] as String? ?? 'Lỗi ${res.statusCode}'
      );
    } catch (_) {
      return (data: null, error: 'Không kết nối được server');
    }
  }

  /// Lấy QR token hiện tại; backend tự xoay nếu hết hạn 30s.
  Future<({QrTokenData? data, String? error})> layQrToken(
      int sessionId) async {
    try {
      final res = await _client
          .get(ApiConfig.qrToken(sessionId))
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        return (
          data: QrTokenData.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        data: null,
        error: body['error'] as String? ?? 'Lỗi ${res.statusCode}'
      );
    } catch (_) {
      return (data: null, error: 'Không kết nối được server');
    }
  }

  /// GV đóng buổi điểm danh. Trả về null nếu thành công, chuỗi lỗi nếu thất bại.
  Future<String?> dongBuoi(int sessionId) async {
    try {
      final res = await _client
          .put(ApiConfig.dongBuoi(sessionId))
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Lỗi ${res.statusCode}';
    } catch (_) {
      return 'Không kết nối được server';
    }
  }

  /// SV check-in bằng token QR và tọa độ GPS hiện tại.
  Future<String?> checkIn(String token, {double? lat, double? lng}) async {
    try {
      final res = await _client
          .post(
            ApiConfig.checkIn,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
                {'token': token, 'latitude': lat, 'longitude': lng}),
          )
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return body['error'] as String? ?? 'Lỗi ${res.statusCode}';
    } catch (_) {
      return 'Không kết nối được server';
    }
  }

  /// GV lấy danh sách SV đã check-in trong buổi (dùng để hiển thị live count).
  Future<({List<AttendanceRecord>? data, String? error})> layDanhSachCheckIn(
      int sessionId) async {
    try {
      final res = await _client
          .get(ApiConfig.attendanceRecords(sessionId))
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((e) =>
                AttendanceRecord.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        data: null,
        error: body['error'] as String? ?? 'Lỗi ${res.statusCode}'
      );
    } catch (_) {
      return (data: null, error: 'Không kết nối được server');
    }
  }

  /// SV xem lịch sử điểm danh của mình trong 1 lớp HP.
  Future<({List<MyAttendanceItem>? data, String? error})> layLichSuCuaToi(
      int courseOfferingId) async {
    try {
      final res = await _client
          .get(ApiConfig.myAttendance(courseOfferingId))
          .timeout(ApiConfig.timeout);
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List)
            .map((e) =>
                MyAttendanceItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return (data: list, error: null);
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      return (
        data: null,
        error: body['error'] as String? ?? 'Lỗi ${res.statusCode}'
      );
    } catch (_) {
      return (data: null, error: 'Không kết nối được server');
    }
  }
}
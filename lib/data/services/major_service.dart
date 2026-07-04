import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/major.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

class MajorService {
  MajorService(this._client);

  final http.Client _client;

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Lấy danh sách ngành, có thể lọc theo khoa.
  Future<({PagedResult<MajorItem>? data, String? error})> layDanhSach({
    int? khoaId,
    int trang = 1,
    int soLuong = 20,
  }) async {
    try {
      final uri =
          ApiConfig.majors(khoaId: khoaId, page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, MajorItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Lấy chi tiết 1 ngành, gồm danh sách chương trình đào tạo.
  Future<({MajorDetail? data, String? error})> layChiTiet(int maNganh) async {
    try {
      final res = await _client
          .get(ApiConfig.major(maNganh))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: MajorDetail.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      if (res.statusCode == 404) {
        return (data: null, error: 'Không tìm thấy ngành.');
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới ngành — POST /api/majors.
  Future<({MajorItem? data, String? error})> taoMoi(
      CreateMajorRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.majors(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: MajorItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật tên ngành — PUT /api/majors/{id}.
  Future<({MajorItem? data, String? error})> capNhat(
      int maNganh, UpdateMajorRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.major(maNganh),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: MajorItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa ngành (soft delete) — DELETE /api/majors/{id}.
  /// Backend chặn nếu ngành còn chương trình đào tạo đang hoạt động.
  Future<({bool ok, String? error})> voHieuHoa(int maNganh) async {
    try {
      final res = await _client
          .delete(ApiConfig.major(maNganh))
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

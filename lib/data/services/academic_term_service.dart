import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/academic_term.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';

class AcademicTermService {
  AcademicTermService(this._client);

  final http.Client _client;

  Future<({PagedResult<AcademicTermItem>? data, String? error})>
      layDanhSach({int trang = 1, int soLuong = 20}) async {
    try {
      final uri =
          ApiConfig.academicTerms(page: trang, pageSize: soLuong);
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        return (
          data: PagedResult.fromJson(json, AcademicTermItem.fromJson),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  // ── WRITE (chỉ Admin / AcademicOffice) ───────────────────────────────────

  /// Tạo mới học kỳ — POST /api/academic-terms.
  Future<({AcademicTermItem? data, String? error})> taoMoi(
      CreateAcademicTermRequest yeuCau) async {
    try {
      final res = await _client
          .post(
            ApiConfig.academicTerms(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 201) {
        return (
          data: AcademicTermItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Cập nhật học kỳ — PUT /api/academic-terms/{id}.
  Future<({AcademicTermItem? data, String? error})> capNhat(
      int maHK, UpdateAcademicTermRequest yeuCau) async {
    try {
      final res = await _client
          .put(
            ApiConfig.academicTerm(maHK),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(yeuCau.toJson()),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (
          data: AcademicTermItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
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

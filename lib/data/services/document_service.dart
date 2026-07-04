import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/document.dart';

// ============================================================================
// DOCUMENT SERVICE
//
// Giao tiếp với /api/documents trên backend.
// ============================================================================

class DocumentService {
  DocumentService(this._client);

  final http.Client _client;

  /// Lấy danh sách tài liệu theo đúng 1 scope: courseId hoặc courseOfferingId.
  Future<({List<DocumentItem>? data, String? error})> layDanhSach({
    int? courseId,
    int? courseOfferingId,
  }) async {
    try {
      final uri = ApiConfig.documents(
        courseId: courseId,
        courseOfferingId: courseOfferingId,
      );
      final res = await _client.get(uri).timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        return (
          data: list
              .map((e) => DocumentItem.fromJson(e as Map<String, dynamic>))
              .toList(),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Tải lên tài liệu — POST /api/documents (multipart). Chỉ truyền đúng
  /// 1 trong 2: [courseId] (staff, tài liệu chung) hoặc [courseOfferingId]
  /// (giảng viên phụ trách lớp đó, hoặc staff).
  Future<({DocumentItem? data, String? error})> upload({
    int? courseId,
    int? courseOfferingId,
    required String fileName,
    required List<int> fileBytes,
    String? description,
  }) async {
    try {
      final request = http.MultipartRequest('POST', ApiConfig.documentsUpload);
      if (courseId != null) request.fields['CourseId'] = '$courseId';
      if (courseOfferingId != null) {
        request.fields['CourseOfferingId'] = '$courseOfferingId';
      }
      if (description != null && description.isNotEmpty) {
        request.fields['Description'] = description;
      }
      request.files.add(
        http.MultipartFile.fromBytes('File', fileBytes, filename: fileName),
      );

      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200) {
        return (
          data: DocumentItem.fromJson(
              jsonDecode(res.body) as Map<String, dynamic>),
          error: null,
        );
      }
      return (data: null, error: _extractError(res));
    } catch (_) {
      return (data: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Tải file tài liệu về dạng bytes để lưu ra đĩa.
  Future<({List<int>? bytes, String? error})> taiVe(int documentId) async {
    try {
      final res = await _client
          .get(ApiConfig.documentDownload(documentId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200) {
        return (bytes: res.bodyBytes, error: null);
      }
      return (bytes: null, error: _extractError(res));
    } catch (_) {
      return (bytes: null, error: 'Không thể kết nối đến server.');
    }
  }

  /// Vô hiệu hóa (soft-delete) — chỉ người upload hoặc staff.
  Future<({bool ok, String? error})> voHieuHoa(int documentId) async {
    try {
      final res = await _client
          .put(ApiConfig.documentDeactivate(documentId))
          .timeout(ApiConfig.timeout);

      if (res.statusCode == 200 || res.statusCode == 204) {
        return (ok: true, error: null);
      }
      return (ok: false, error: _extractError(res));
    } catch (_) {
      return (ok: false, error: 'Không thể kết nối đến server.');
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────

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

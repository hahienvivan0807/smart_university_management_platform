import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/refresh_response.dart';
import 'token_storage.dart';

/// HTTP client tự động xử lý auth:
///   1. Gắn `Authorization: Bearer <token>` vào mọi request.
///   2. Gặp 401 → gọi /refresh → thử lại request gốc.
///   3. Refresh thất bại → xóa token → gọi onUnauthenticated().
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({
    required this._storage,
    required this._onUnauthenticated,
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  final TokenStorage _storage;
  final void Function() _onUnauthenticated;
  final http.Client _inner;

  Completer<bool>? _refreshing;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final savedMethod  = request.method;
    final savedUrl     = request.url;
    final savedHeaders = Map<String, String>.from(request.headers);
    final List<int>? savedBody =
        request is http.Request ? List.of(request.bodyBytes) : null;

    await _attachBearer(request);
    final response = await _inner.send(request);

    if (response.statusCode != 401) return response;

    final refreshed = await _ensureRefresh();
    if (!refreshed) {
      await _storage.clear();
      _onUnauthenticated();
      return response;
    }

    final retry = http.Request(savedMethod, savedUrl)
      ..headers.addAll(savedHeaders);
    if (savedBody != null) retry.bodyBytes = savedBody;

    await _attachBearer(retry);
    return _inner.send(retry);
  }

  Future<bool> _ensureRefresh() async {
    if (_refreshing != null) return _refreshing!.future;

    final completer = Completer<bool>();
    _refreshing = completer;
    try {
      final success = await _performRefresh();
      completer.complete(success);
      return success;
    } catch (_) {
      completer.complete(false);
      return false;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final res = await _inner
          .post(
            ApiConfig.refresh,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(ApiConfig.timeout);

      if (res.statusCode != 200) return false;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = RefreshResponse.fromJson(body);
      if (data.accessToken.isEmpty || data.refreshToken.isEmpty) return false;

      final existingRoles = await _storage.readRoles();
      await _storage.saveTokens(
        accessToken:  data.accessToken,
        refreshToken: data.refreshToken,
        roles:        existingRoles,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _attachBearer(http.BaseRequest request) async {
    final token = await _storage.readAccessToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}

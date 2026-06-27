import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:smart_university_management_platform/core/api_config.dart';
import 'package:smart_university_management_platform/data/models/login_response.dart';
import 'token_storage.dart';

/// Outcome of a login attempt. Either [LoginResponse] data on success, or a
/// human-readable [message] to surface in the UI. We deliberately do NOT leak
/// which part failed (username vs password) — the backend is enumeration-
/// resistant and so is this layer.
class LoginResult {
  const LoginResult._({this.data, this.error});

  final LoginResponse? data;
  final String? error;

  bool get isSuccess => data != null;

  factory LoginResult.success(LoginResponse data) =>
      LoginResult._(data: data);
  factory LoginResult.failure(String message) =>
      LoginResult._(error: message);
}

/// Talks to the auth backend and persists tokens on success.
class AuthService {
  AuthService({http.Client? client, TokenStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? TokenStorage();

  final http.Client _client;
  final TokenStorage _storage;

  TokenStorage get storage => _storage;

  /// Attempts a login. On success, tokens are saved to secure storage before
  /// the result is returned, so the caller can route straight to the app.
  Future<LoginResult> login({
    required String loginCode,
    required String password,
  }) async {
    // Cheap client-side guard so we don't fire an obviously-empty request.
    if (loginCode.trim().isEmpty || password.isEmpty) {
      return LoginResult.failure(
          'Please enter both your login code and password.');
    }

    http.Response res;
    try {
      res = await _client
          .post(
            ApiConfig.login,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'loginCode': loginCode.trim(),
              'password': password,
            }),
          )
          .timeout(ApiConfig.timeout);
    } on TimeoutException {
      return LoginResult.failure(
          'The server took too long to respond. Please try again.');
    } on http.ClientException {
      // Covers connection-refused, DNS/socket failures, and dropped requests
      // across both the native and web HTTP clients.
      return LoginResult.failure(
          "Can't reach the server. Check your connection and try again.");
    } catch (_) {
      return LoginResult.failure('Something went wrong. Please try again.');
    }

    return _handleResponse(res);
  }

  Future<LoginResult> _handleResponse(http.Response res) async {
    switch (res.statusCode) {
      case 200:
        try {
          final body = jsonDecode(res.body) as Map<String, dynamic>;
          final data = LoginResponse.fromJson(body);
          if (data.accessToken.isEmpty || data.refreshToken.isEmpty) {
            return LoginResult.failure(
                'Received an unexpected response from the server.');
          }
          await _storage.saveTokens(
            accessToken: data.accessToken,
            refreshToken: data.refreshToken,
            roles: data.roles,
          );
          return LoginResult.success(data);
        } catch (_) {
          return LoginResult.failure(
              'Received an unexpected response from the server.');
        }

      case 400:
      case 401:
        // Backend returns a generic invalid-credentials message for both wrong
        // passwords AND locked accounts (enumeration resistance). We mirror
        // that: one friendly message, no hints about which field was wrong.
        return LoginResult.failure(
            'Invalid login code or password. Please try again.');

      case 429:
        // Rate limited (shared AuthEndpoints budget, per IP). Respect
        // Retry-After if present.
        final retry = res.headers['retry-after'];
        final secs = int.tryParse(retry ?? '');
        return LoginResult.failure(secs != null
            ? 'Too many attempts. Please wait $secs seconds and try again.'
            : 'Too many attempts. Please wait a moment and try again.');

      case 500:
      case 502:
      case 503:
        return LoginResult.failure(
            'The server is having trouble right now. Please try again later.');

      default:
        return LoginResult.failure(
            'Login failed (${res.statusCode}). Please try again.');
    }
  }

  void dispose() => _client.close();
}

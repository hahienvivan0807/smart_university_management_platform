/// Minimal response shape from `POST /api/auth/refresh`.
///
/// The backend rotates the token pair on every call; both fields must be
/// non-empty or we treat the refresh as failed.
class RefreshResponse {
  const RefreshResponse({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  factory RefreshResponse.fromJson(Map<String, dynamic> json) =>
      RefreshResponse(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );
}

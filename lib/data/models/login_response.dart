/// Mirrors the backend `LoginResponse` DTO returned by `POST /api/auth/login`.
///
/// Backend contract (from the project handover/roadmap):
///   {
///     "accessToken":  "<jwt>",
///     "refreshToken": "<opaque raw token, shown once>",
///     "roles":        ["Student", ...],
///     "requiresRoleSelection": <bool>   // == roles.Count > 1
///   }
///
/// Field names use camelCase because ASP.NET Core's default JSON serializer
/// camel-cases property names on the wire. If your API is configured for
/// PascalCase, adjust the keys in [fromJson] accordingly.
class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.roles,
    required this.requiresRoleSelection,
  });

  final String accessToken;
  final String refreshToken;
  final List<String> roles;
  final bool requiresRoleSelection;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'] as List<dynamic>? ?? const [];
    return LoginResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      roles: rawRoles.map((e) => e.toString()).toList(growable: false),
      // Tolerate the field being absent by deriving it from role count,
      // matching the server's own rule (roles.Count > 1).
      requiresRoleSelection:
          json['requiresRoleSelection'] as bool? ?? (rawRoles.length > 1),
    );
  }
}

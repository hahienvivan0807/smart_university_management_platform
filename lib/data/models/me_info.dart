/// Thông tin cơ bản của user đang đăng nhập — trả về từ GET /api/auth/me.
class MeInfo {
  const MeInfo({
    required this.userId,
    required this.loginCode,
    required this.fullName,
    required this.email,
    required this.roles,
  });

  final int userId;
  final String loginCode;
  final String fullName;
  final String? email;
  final List<String> roles;

  factory MeInfo.fromJson(Map<String, dynamic> json) => MeInfo(
        userId: json['userId'] as int,
        loginCode: json['loginCode'] as String,
        fullName: json['fullName'] as String,
        email: json['email'] as String?,
        roles: (json['roles'] as List<dynamic>? ?? [])
            .map((e) => e as String)
            .toList(),
      );
}

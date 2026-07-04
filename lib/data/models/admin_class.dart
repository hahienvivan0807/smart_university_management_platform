class AdminClassItem {
  const AdminClassItem({
    required this.adminClassId,
    required this.programId,
    required this.programName,
    required this.code,
    required this.name,
    required this.intakeYear,
    required this.advisorName,
    required this.soSinhVien,
  });

  final int adminClassId;
  final int programId;
  final String programName;
  final String code;
  final String? name;
  final int intakeYear;
  final String? advisorName;
  final int soSinhVien;

  factory AdminClassItem.fromJson(Map<String, dynamic> json) =>
      AdminClassItem(
        adminClassId: json['adminClassId'] as int,
        programId: json['programId'] as int,
        programName: json['programName'] as String? ?? '',
        code: json['code'] as String,
        name: json['name'] as String?,
        intakeYear: json['intakeYear'] as int,
        advisorName: json['advisorName'] as String?,
        soSinhVien: json['soSinhVien'] as int? ?? 0,
      );
}

class CreateAdminClassRequest {
  const CreateAdminClassRequest({
    required this.programId,
    required this.code,
    this.name,
    required this.intakeYear,
    this.advisorUserId,
  });

  final int programId;
  final String code;
  final String? name;
  final int intakeYear;
  final int? advisorUserId;

  Map<String, dynamic> toJson() => {
        'programId': programId,
        'code': code,
        if (name != null) 'name': name,
        'intakeYear': intakeYear,
        if (advisorUserId != null) 'advisorUserId': advisorUserId,
      };
}

class UpdateAdminClassRequest {
  const UpdateAdminClassRequest({this.name, this.advisorUserId});

  final String? name;
  final int? advisorUserId;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (advisorUserId != null) 'advisorUserId': advisorUserId,
      };
}

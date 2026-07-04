/// Model tương ứng DepartmentListDto / DepartmentDetailDto từ backend.
class DepartmentItem {
  const DepartmentItem({
    required this.departmentId,
    required this.facultyId,
    required this.facultyName,
    required this.code,
    required this.name,
  });

  final int departmentId;
  final int facultyId;
  final String facultyName;
  final String code;
  final String name;

  factory DepartmentItem.fromJson(Map<String, dynamic> json) => DepartmentItem(
        departmentId: json['departmentId'] as int,
        facultyId: json['facultyId'] as int,
        facultyName: json['facultyName'] as String? ?? '',
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

/// Body gửi lên khi tạo mới bộ môn — POST /api/departments.
class CreateDepartmentRequest {
  const CreateDepartmentRequest({
    required this.facultyId,
    required this.code,
    required this.name,
  });

  final int facultyId;
  final String code;
  final String name;

  Map<String, dynamic> toJson() => {
        'facultyId': facultyId,
        'code': code,
        'name': name,
      };
}

/// Body gửi lên khi cập nhật tên bộ môn — PUT /api/departments/{id}.
class UpdateDepartmentRequest {
  const UpdateDepartmentRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

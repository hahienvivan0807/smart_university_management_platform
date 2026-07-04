// ============================================================================
// FACULTY MODEL
//
// Mục đích: ánh xạ JSON từ backend → Dart object để Flutter dùng.
//
// Tại sao cần file riêng (không khai báo trong screen)?
//   → ARCHITECTURE.md quy định: shared types phải nằm trong models/
//     để tránh circular import (nếu 2 screen cùng cần FacultyItem,
//     mỗi screen sẽ import file này thay vì import nhau).
//
// Liên hệ backend: tương ứng FacultyListDto trong FacultyDtos.cs
//   (FacultyDetailDto có thêm List<DepartmentListDto> Departments —
//    chưa cần vì FacultyListScreen chỉ dùng danh sách đơn giản, tap
//    rồi điều hướng sang DepartmentListScreen để tải departments riêng.)
// ============================================================================

class FacultyItem {
  const FacultyItem({
    required this.facultyId,
    required this.code,
    required this.name,
  });

  final int facultyId;
  final String code;
  final String name;

  /// Chuyển JSON từ HTTP response → FacultyItem.
  ///
  /// Dùng `as int? ?? fallback` thay vì `as int` để tránh crash
  /// nếu backend trả về null trên trường không bắt buộc.
  factory FacultyItem.fromJson(Map<String, dynamic> json) => FacultyItem(
        facultyId: json['facultyId'] as int,
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
      );
}

class CreateFacultyRequest {
  const CreateFacultyRequest({required this.code, required this.name});
  final String code;
  final String name;

  Map<String, dynamic> toJson() => {'code': code, 'name': name};
}

class UpdateFacultyRequest {
  const UpdateFacultyRequest({required this.name});
  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

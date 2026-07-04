// ============================================================================
// COURSE MODEL  —  ánh xạ CourseListDto từ backend
//
// Dùng cho: CourseListScreen (danh sách môn học)
// Source:   GET /api/courses → List<CourseListDto>
//
// ownerFacultyName / ownerDepartmentName có thể null nếu môn chưa gắn đơn vị.
// ============================================================================

class CourseItem {
  const CourseItem({
    required this.courseId,
    required this.code,
    required this.name,
    required this.credits,
    this.ownerFacultyName,
    this.ownerDepartmentName,
  });

  final int courseId;
  final String code;
  final String name;
  final int credits;
  final String? ownerFacultyName;
  final String? ownerDepartmentName;

  factory CourseItem.fromJson(Map<String, dynamic> json) => CourseItem(
        courseId: json['courseId'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        credits: json['credits'] as int,
        ownerFacultyName: json['ownerFacultyName'] as String?,
        ownerDepartmentName: json['ownerDepartmentName'] as String?,
      );
}

class CreateCourseRequest {
  const CreateCourseRequest({
    required this.code,
    required this.name,
    required this.credits,
    this.ownerFacultyId,
    this.ownerDepartmentId,
  });

  final String code;
  final String name;
  final int credits;
  final int? ownerFacultyId;
  final int? ownerDepartmentId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'credits': credits,
        if (ownerFacultyId != null) 'ownerFacultyId': ownerFacultyId,
        if (ownerDepartmentId != null) 'ownerDepartmentId': ownerDepartmentId,
      };
}

class UpdateCourseRequest {
  const UpdateCourseRequest({
    required this.name,
    required this.credits,
    this.ownerFacultyId,
    this.ownerDepartmentId,
  });

  final String name;
  final int credits;
  final int? ownerFacultyId;
  final int? ownerDepartmentId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'credits': credits,
        if (ownerFacultyId != null) 'ownerFacultyId': ownerFacultyId,
        if (ownerDepartmentId != null) 'ownerDepartmentId': ownerDepartmentId,
      };
}

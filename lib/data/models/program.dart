class ProgramItem {
  const ProgramItem({
    required this.programId,
    required this.majorId,
    required this.code,
    required this.name,
    required this.curriculumYear,
    required this.totalCredits,
  });

  final int programId;
  final int majorId;
  final String code;
  final String name;
  final int curriculumYear;

  /// Tính động ở backend = tổng tín chỉ các môn trong chương trình (bắt buộc +
  /// tự chọn) — không còn nhập tay, tự đúng khi môn được thêm/gỡ.
  final int totalCredits;

  factory ProgramItem.fromJson(Map<String, dynamic> json) => ProgramItem(
        programId: json['programId'] as int,
        majorId: json['majorId'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        curriculumYear: json['curriculumYear'] as int,
        totalCredits: json['totalCredits'] as int? ?? 0,
      );
}

class ProgramCourseItem {
  const ProgramCourseItem({
    required this.courseId,
    required this.courseCode,
    required this.courseName,
    required this.credits,
    required this.recommendedSemester,
    required this.isRequired,
  });

  final int courseId;
  final String courseCode;
  final String courseName;
  final int credits;
  final int? recommendedSemester;
  final bool isRequired;

  factory ProgramCourseItem.fromJson(Map<String, dynamic> json) =>
      ProgramCourseItem(
        courseId: json['courseId'] as int,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        credits: json['credits'] as int,
        recommendedSemester: json['recommendedSemester'] as int?,
        isRequired: json['isRequired'] as bool,
      );
}

class ProgramDetail extends ProgramItem {
  const ProgramDetail({
    required super.programId,
    required super.majorId,
    required super.code,
    required super.name,
    required super.curriculumYear,
    required super.totalCredits,
    required this.majorName,
    required this.courses,
  });

  final String majorName;
  final List<ProgramCourseItem> courses;

  factory ProgramDetail.fromJson(Map<String, dynamic> json) => ProgramDetail(
        programId: json['programId'] as int,
        majorId: json['majorId'] as int,
        code: json['code'] as String,
        name: json['name'] as String,
        curriculumYear: json['curriculumYear'] as int,
        totalCredits: json['totalCredits'] as int? ?? 0,
        majorName: json['majorName'] as String,
        courses: (json['courses'] as List<dynamic>? ?? [])
            .map((e) => ProgramCourseItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class CreateProgramRequest {
  const CreateProgramRequest({
    required this.majorId,
    required this.code,
    required this.name,
    required this.curriculumYear,
  });

  final int majorId;
  final String code;
  final String name;
  final int curriculumYear;

  Map<String, dynamic> toJson() => {
        'majorId': majorId,
        'code': code,
        'name': name,
        'curriculumYear': curriculumYear,
      };
}

class UpdateProgramRequest {
  const UpdateProgramRequest({required this.name});
  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

class AddCourseToProgramRequest {
  const AddCourseToProgramRequest({
    required this.courseId,
    this.recommendedSemester,
    this.isRequired = true,
  });

  final int courseId;
  final int? recommendedSemester;
  final bool isRequired;

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        if (recommendedSemester != null)
          'recommendedSemester': recommendedSemester,
        'isRequired': isRequired,
      };
}

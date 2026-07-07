class RosterItem {
  const RosterItem({
    required this.enrollmentId,
    required this.studentUserId,
    required this.fullName,
    required this.loginCode,
    required this.adminClassName,
    required this.enrollmentStatus,
    required this.enrolledAtUtc,
  });

  final int enrollmentId;
  final int studentUserId;
  final String fullName;
  final String loginCode;
  final String adminClassName;
  final int enrollmentStatus;
  final DateTime enrolledAtUtc;

  factory RosterItem.fromJson(Map<String, dynamic> json) => RosterItem(
        enrollmentId: (json['enrollmentId'] as num).toInt(),
        studentUserId: json['studentUserId'] as int,
        fullName: json['fullName'] as String,
        loginCode: json['loginCode'] as String,
        adminClassName: json['adminClassName'] as String? ?? '',
        enrollmentStatus: json['enrollmentStatus'] as int,
        enrolledAtUtc: DateTime.parse(json['enrolledAtUtc'] as String),
      );
}

class EnrollmentItem {
  const EnrollmentItem({
    required this.enrollmentId,
    required this.courseOfferingId,
    required this.offeringCode,
    required this.courseCode,
    required this.courseName,
    required this.courseCredits,
    required this.lecturerName,
    required this.termLabel,
    required this.status,
    required this.enrolledAtUtc,
    this.waitlistPosition,
  });

  final int enrollmentId;
  final int courseOfferingId;
  final String offeringCode;
  final String courseCode;
  final String courseName;
  final int courseCredits;
  final String lecturerName;
  final String termLabel;

  /// 1=Đang học, 2=Đang chờ (waitlist), 3=Đã hủy, 4=Đậu, 5=Rớt
  final int status;
  final DateTime enrolledAtUtc;
  final int? waitlistPosition;

  bool get dangHoc => status == 1;
  bool get dangCho => status == 2;
  bool get daHuy => status == 3;
  bool get daDau => status == 4;
  bool get daRot => status == 5;

  /// true = còn có thể hủy (đang học hoặc đang trong hàng đợi).
  bool get coTheHuy => status == 1 || status == 2;

  /// Giữ tương thích ngược cho chỗ nào chỉ cần biết "còn hiệu lực" (đang học).
  bool get daDangKy => status == 1;

  String get trangThaiText => switch (status) {
        1 => 'Đang học',
        2 => 'Đang chờ${waitlistPosition != null ? ' (vị trí $waitlistPosition)' : ''}',
        3 => 'Đã hủy',
        4 => 'Đậu',
        5 => 'Rớt',
        _ => 'Không xác định',
      };

  factory EnrollmentItem.fromJson(Map<String, dynamic> json) => EnrollmentItem(
        enrollmentId: (json['enrollmentId'] as num).toInt(),
        courseOfferingId: json['courseOfferingId'] as int,
        offeringCode: json['offeringCode'] as String,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        courseCredits: json['courseCredits'] as int,
        lecturerName: json['lecturerName'] as String,
        termLabel: json['termLabel'] as String,
        status: json['status'] as int,
        enrolledAtUtc: DateTime.parse(json['enrolledAtUtc'] as String),
        waitlistPosition: json['waitlistPosition'] as int?,
      );
}

/// Trạng thái học tập của tôi với 1 môn học (theo CourseId, gộp mọi lần học lại) —
/// trả về từ GET /api/me/course-status. Dùng cho Chương trình đào tạo & Danh mục
/// môn học để hiện Đậu/Rớt/Đang học/Chưa học (vắng mặt trong danh sách = chưa học).
class CourseStatusItem {
  const CourseStatusItem({required this.courseId, required this.status});

  final int courseId;

  /// 1=Đang học, 2=Đang chờ, 4=Đậu, 5=Rớt
  final int status;

  bool get daDau => status == 4;
  bool get daRot => status == 5;
  bool get dangHocHoacCho => status == 1 || status == 2;

  factory CourseStatusItem.fromJson(Map<String, dynamic> json) =>
      CourseStatusItem(
        courseId: json['courseId'] as int,
        status: json['status'] as int,
      );
}

/// Một lớp học phần trong thời khóa biểu — trả về từ GET /api/me/timetable.
class TimetableEntry {
  const TimetableEntry({
    required this.courseOfferingId,
    required this.courseCode,
    required this.courseName,
    required this.lecturerName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.room,
  });

  final int courseOfferingId;
  final String courseCode;
  final String courseName;
  final String lecturerName;
  final int? dayOfWeek; // 1..7 (quy ước SQL: 1=Chủ nhật, 2=Thứ 2, ..., 7=Thứ 7), null = chưa xếp lịch
  final String? startTime; // "HH:mm:ss"
  final String? endTime;
  final String? room;

  bool get daXepLich => dayOfWeek != null && startTime != null && endTime != null;

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        courseOfferingId: json['courseOfferingId'] as int,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        lecturerName: json['lecturerName'] as String,
        dayOfWeek: json['dayOfWeek'] as int?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        room: json['room'] as String?,
      );
}

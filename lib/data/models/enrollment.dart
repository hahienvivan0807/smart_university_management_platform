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
  });

  final int enrollmentId;
  final int courseOfferingId;
  final String offeringCode;
  final String courseCode;
  final String courseName;
  final int courseCredits;
  final String lecturerName;
  final String termLabel;
  final int status;
  final DateTime enrolledAtUtc;

  bool get daDangKy => status == 1;

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

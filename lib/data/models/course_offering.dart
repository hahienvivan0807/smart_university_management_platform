class CourseOfferingItem {
  const CourseOfferingItem({
    required this.courseOfferingId,
    required this.code,
    required this.courseCode,
    required this.courseName,
    required this.courseCredits,
    required this.lecturerUserId,
    required this.lecturerName,
    required this.capacity,
    required this.enrollmentCount,
    required this.status,
    required this.termName,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.room,
  });

  final int courseOfferingId;
  final String code;
  final String courseCode;
  final String courseName;
  final int courseCredits;
  final int lecturerUserId;
  final String lecturerName;

  /// VD: "HK1 2024-2025" — dùng để gom nhóm khi hiện các lớp đang mở đăng ký
  /// thuộc nhiều học kỳ khác nhau cùng lúc (VD: học lại/học cải thiện).
  final String termName;

  /// Sức chứa tối đa; null = không giới hạn
  final int? capacity;

  /// Số SV đăng ký thực tế từ bảng Enrollments — dùng cho UI và tính chỗ còn lại
  final int enrollmentCount;

  /// 1 = Đang mở, khác = Đã hủy/đóng
  final int status;

  final int? dayOfWeek; // 1..7 (quy ước SQL: 1=Chủ nhật), null = chưa xếp lịch
  final String? startTime; // "HH:mm:ss"
  final String? endTime;
  final String? room;

  bool get dangMo => status == 1;
  int get soChoConLai => (capacity ?? 9999) - enrollmentCount;
  bool get conCho => soChoConLai > 0;

  factory CourseOfferingItem.fromJson(Map<String, dynamic> json) =>
      CourseOfferingItem(
        courseOfferingId: json['courseOfferingId'] as int,
        code: json['code'] as String,
        courseCode: json['courseCode'] as String,
        courseName: json['courseName'] as String,
        courseCredits: json['courseCredits'] as int,
        lecturerUserId: json['lecturerUserId'] as int,
        lecturerName: json['lecturerName'] as String,
        capacity: json['capacity'] as int?,
        enrollmentCount: json['enrollmentCount'] as int? ?? 0,
        status: json['status'] as int,
        termName: json['termName'] as String? ?? '',
        dayOfWeek: json['dayOfWeek'] as int?,
        startTime: json['startTime'] as String?,
        endTime: json['endTime'] as String?,
        room: json['room'] as String?,
      );
}

class CreateCourseOfferingRequest {
  const CreateCourseOfferingRequest({
    required this.courseId,
    required this.academicTermId,
    required this.lecturerUserId,
    required this.code,
    this.capacity,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.room,
  });

  final int courseId;
  final int academicTermId;
  final int lecturerUserId;
  final String code;
  final int? capacity;
  final int? dayOfWeek;
  final String? startTime; // "HH:mm:ss"
  final String? endTime;
  final String? room;

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'academicTermId': academicTermId,
        'lecturerUserId': lecturerUserId,
        'code': code,
        if (capacity != null) 'capacity': capacity,
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (room != null) 'room': room,
      };
}

class UpdateCourseOfferingRequest {
  const UpdateCourseOfferingRequest({
    this.capacity,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.room,
  });

  final int? capacity;
  final int? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final String? room;

  Map<String, dynamic> toJson() => {
        if (capacity != null) 'capacity': capacity,
        if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (room != null) 'room': room,
      };
}

class DoiGiangVienRequest {
  const DoiGiangVienRequest({required this.lecturerUserId});
  final int lecturerUserId;

  Map<String, dynamic> toJson() => {'lecturerUserId': lecturerUserId};
}

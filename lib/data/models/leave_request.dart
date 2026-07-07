/// Phiếu xin tạm ngưng buổi học của giảng viên — trả về từ các API /leave-requests.
class LeaveRequestItem {
  const LeaveRequestItem({
    required this.leaveRequestId,
    required this.courseOfferingId,
    required this.courseOfferingCode,
    required this.courseName,
    required this.lecturerUserId,
    required this.lecturerName,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
    required this.trangThai,
    this.reviewedByName,
    this.reviewNote,
    this.reviewedAtUtc,
    required this.createdAtUtc,
  });

  final int leaveRequestId;
  final int courseOfferingId;
  final String courseOfferingCode;
  final String courseName;
  final int lecturerUserId;
  final String lecturerName;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  /// 1=Chờ duyệt, 2=Đã duyệt, 3=Từ chối, 4=Đã thu hồi
  final int status;
  final String trangThai;
  final String? reviewedByName;
  final String? reviewNote;
  final DateTime? reviewedAtUtc;
  final DateTime createdAtUtc;

  bool get dangChoDuyet => status == 1;

  factory LeaveRequestItem.fromJson(Map<String, dynamic> json) =>
      LeaveRequestItem(
        leaveRequestId: json['leaveRequestId'] as int,
        courseOfferingId: json['courseOfferingId'] as int,
        courseOfferingCode: json['courseOfferingCode'] as String,
        courseName: json['courseName'] as String,
        lecturerUserId: json['lecturerUserId'] as int,
        lecturerName: json['lecturerName'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        reason: json['reason'] as String,
        status: json['status'] as int,
        trangThai: json['trangThai'] as String,
        reviewedByName: json['reviewedByName'] as String?,
        reviewNote: json['reviewNote'] as String?,
        reviewedAtUtc: json['reviewedAtUtc'] != null
            ? DateTime.parse(json['reviewedAtUtc'] as String)
            : null,
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String),
      );
}

/// Yêu cầu tạo mới 1 phiếu xin nghỉ — POST /api/leave-requests.
class CreateLeaveRequestPayload {
  const CreateLeaveRequestPayload({
    required this.courseOfferingId,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  final int courseOfferingId;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;

  static String _dinhDangNgay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'courseOfferingId': courseOfferingId,
        'startDate': _dinhDangNgay(startDate),
        'endDate': _dinhDangNgay(endDate),
        'reason': reason,
      };
}

/// 1 khoảng ngày đã bị chiếm (Chờ duyệt/Đã duyệt) của 1 lớp học phần — dùng để làm mờ date-picker.
class BlockedDateRange {
  const BlockedDateRange({required this.startDate, required this.endDate});

  final DateTime startDate;
  final DateTime endDate;

  /// true nếu [ngay] rơi vào khoảng đã bị chiếm này.
  bool chua(DateTime ngay) {
    final d = DateTime(ngay.year, ngay.month, ngay.day);
    return !d.isBefore(startDate) && !d.isAfter(endDate);
  }

  factory BlockedDateRange.fromJson(Map<String, dynamic> json) =>
      BlockedDateRange(
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
      );
}

/// 1 lớp học phần đang tạm ngưng đúng hôm nay (Đã duyệt) — dùng để hiện badge đỏ.
class ActiveSuspension {
  const ActiveSuspension({
    required this.courseOfferingId,
    required this.startDate,
    required this.endDate,
  });

  final int courseOfferingId;
  final DateTime startDate;
  final DateTime endDate;

  factory ActiveSuspension.fromJson(Map<String, dynamic> json) =>
      ActiveSuspension(
        courseOfferingId: json['courseOfferingId'] as int,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
      );
}

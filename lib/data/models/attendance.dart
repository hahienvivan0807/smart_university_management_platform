class AttendanceSession {
  const AttendanceSession({
    required this.attendanceSessionId,
    required this.courseOfferingId,
    required this.openedAtUtc,
    this.closedAtUtc,
    this.locationLatitude,
    this.locationLongitude,
    required this.radiusMeters,
    required this.status,
    required this.checkedInCount,
  });

  final int attendanceSessionId;
  final int courseOfferingId;
  final DateTime openedAtUtc;
  final DateTime? closedAtUtc;
  final double? locationLatitude;
  final double? locationLongitude;
  final int radiusMeters;

  /// 1 = Đang mở, 2 = Đã đóng
  final int status;
  final int checkedInCount;

  bool get dangMo => status == 1;

  factory AttendanceSession.fromJson(Map<String, dynamic> json) =>
      AttendanceSession(
        attendanceSessionId: json['attendanceSessionId'] as int,
        courseOfferingId: json['courseOfferingId'] as int,
        openedAtUtc: DateTime.parse(json['openedAtUtc'] as String),
        closedAtUtc: json['closedAtUtc'] != null
            ? DateTime.parse(json['closedAtUtc'] as String)
            : null,
        locationLatitude: (json['locationLatitude'] as num?)?.toDouble(),
        locationLongitude: (json['locationLongitude'] as num?)?.toDouble(),
        radiusMeters: json['radiusMeters'] as int? ?? 100,
        status: json['status'] as int,
        checkedInCount: json['checkedInCount'] as int? ?? 0,
      );
}

class QrTokenData {
  const QrTokenData({required this.token, required this.expiresAtUtc});

  final String token;
  final DateTime expiresAtUtc;

  bool get conHan => expiresAtUtc.isAfter(DateTime.now().toUtc());

  factory QrTokenData.fromJson(Map<String, dynamic> json) => QrTokenData(
        token: json['token'] as String,
        expiresAtUtc: DateTime.parse(json['expiresAtUtc'] as String),
      );
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.attendanceRecordId,
    required this.studentUserId,
    required this.fullName,
    required this.loginCode,
    required this.adminClassName,
    required this.checkedInAtUtc,
  });

  final int attendanceRecordId;
  final int studentUserId;
  final String fullName;
  final String loginCode;
  final String adminClassName;
  final DateTime checkedInAtUtc;

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        attendanceRecordId: json['attendanceRecordId'] as int,
        studentUserId: json['studentUserId'] as int,
        fullName: json['fullName'] as String,
        loginCode: json['loginCode'] as String,
        adminClassName: json['adminClassName'] as String? ?? '',
        checkedInAtUtc: DateTime.parse(json['checkedInAtUtc'] as String),
      );
}

class MyAttendanceItem {
  const MyAttendanceItem({
    required this.attendanceSessionId,
    required this.openedAtUtc,
    this.closedAtUtc,
    required this.daMat,
    this.checkedInAtUtc,
  });

  final int attendanceSessionId;
  final DateTime openedAtUtc;
  final DateTime? closedAtUtc;

  /// true = SV đã điểm danh buổi này
  final bool daMat;
  final DateTime? checkedInAtUtc;

  factory MyAttendanceItem.fromJson(Map<String, dynamic> json) =>
      MyAttendanceItem(
        attendanceSessionId: json['attendanceSessionId'] as int,
        openedAtUtc: DateTime.parse(json['openedAtUtc'] as String),
        closedAtUtc: json['closedAtUtc'] != null
            ? DateTime.parse(json['closedAtUtc'] as String)
            : null,
        daMat: json['daMat'] as bool? ?? false,
        checkedInAtUtc: json['checkedInAtUtc'] != null
            ? DateTime.parse(json['checkedInAtUtc'] as String)
            : null,
      );
}

// Conditional import: on web, dart:io is unavailable, so we swap in a web stub.
// The default (`_platform_io.dart`) is used everywhere `dart.library.io` exists
// (Android, iOS, desktop); `_platform_web.dart` is used when `dart.library.html`
// is present (web). This keeps `dart:io` out of web builds entirely.
import '_platform_io.dart'
    if (dart.library.html) '_platform_web.dart' as platform;

/// Central place for backend connection settings.
///
/// The host differs by where the app runs, which trips people up constantly:
///   * Android emulator  → `10.0.2.2` is the host machine's loopback
///     (`localhost` inside the emulator is the emulator itself).
///   * iOS simulator / desktop / web → `localhost` reaches the host directly.
///   * Physical device → neither works; you need the dev machine's LAN IP
///     (e.g. `192.168.1.20`). Override the host for that case.
///
/// The backend (ASP.NET Core) serves auth under `/api/auth/...` and runs over
/// HTTPS in real use. During local dev it's commonly HTTP on a Kestrel port;
/// adjust [_scheme] and [_port] to match how you launch `dotnet run` (read the
/// "Now listening on" line in its console).
class ApiConfig {
  ApiConfig._();

  // --- Tune these two to match your running backend ------------------------
  static const String _scheme = 'http';
  static const int _port = 5102; // HTTP dev port (đổi lại https+7161 khi deploy)
  // -------------------------------------------------------------------------

  /// Resolved host for the current platform (see conditional import above).
  static String get _host => platform.resolveHost();

  /// Base origin, e.g. `https://10.0.2.2:7174`.
  static String get baseUrl => '$_scheme://$_host:$_port';

  static Uri get login => Uri.parse('$baseUrl/api/auth/login');
  static Uri get refresh => Uri.parse('$baseUrl/api/auth/refresh');
  static Uri get logout => Uri.parse('$baseUrl/api/auth/logout');

  /// GET /api/auth/me — thông tin user đang đăng nhập
  static Uri get me => Uri.parse('$baseUrl/api/auth/me');

  /// POST /api/auth/change-password — tự đổi mật khẩu
  static Uri get changePassword =>
      Uri.parse('$baseUrl/api/auth/change-password');

  // ── Academic: Faculties ───────────────────────────────────────────────────

  /// GET /api/faculties?page=&pageSize=
  static Uri faculties({int page = 1, int pageSize = 20}) =>
      Uri.parse('$baseUrl/api/faculties').replace(queryParameters: {
        'trang': '$page',
        'soLuong': '$pageSize',
      });

  /// GET /api/faculties/{id}   (trả về chi tiết + danh sách departments con)
  static Uri faculty(int id) => Uri.parse('$baseUrl/api/faculties/$id');

  // ── Academic: Departments ──────────────────────────────────────────────────

  /// GET /api/departments?facultyId=&page=&pageSize=
  static Uri departments({int? facultyId, int page = 1, int pageSize = 20}) {
    final params = <String, String>{
      'trang': '$page',
      'soLuong': '$pageSize',
    };
    if (facultyId != null) params['facultyId'] = '$facultyId';
    return Uri.parse('$baseUrl/api/departments').replace(queryParameters: params);
  }

  /// GET /api/departments/{id}
  static Uri department(int id) => Uri.parse('$baseUrl/api/departments/$id');

  // ── Academic: Courses ──────────────────────────────────────────────────────

  /// GET /api/courses?facultyId=&departmentId=&page=&pageSize=
  ///
  /// Backend dùng tên tiếng Anh (page/pageSize), KHÁC với Departments (trang/soLuong).
  static Uri courses({
    int? facultyId,
    int? departmentId,
    int page = 1,
    int pageSize = 20,
  }) {
    final params = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (facultyId != null) params['facultyId'] = '$facultyId';
    if (departmentId != null) params['departmentId'] = '$departmentId';
    return Uri.parse('$baseUrl/api/courses').replace(queryParameters: params);
  }

  /// GET /api/courses/{id}
  static Uri course(int id) => Uri.parse('$baseUrl/api/courses/$id');

  // ── Academic: AcademicTerms ───────────────────────────────────────────────

  /// GET /api/academic-terms?trang=&soLuong=
  static Uri academicTerms({int page = 1, int pageSize = 20}) =>
      Uri.parse('$baseUrl/api/academic-terms').replace(queryParameters: {
        'trang': '$page',
        'soLuong': '$pageSize',
      });

  /// GET /api/academic-terms/{id}
  static Uri academicTerm(int id) =>
      Uri.parse('$baseUrl/api/academic-terms/$id');

  // ── Academic: CourseOfferings ─────────────────────────────────────────────

  /// GET /api/course-offerings?academicTermId=&trang=&soLuong=
  static Uri courseOfferings({int? termId, int page = 1, int pageSize = 20}) {
    final params = <String, String>{
      'trang': '$page',
      'soLuong': '$pageSize',
    };
    if (termId != null) params['academicTermId'] = '$termId';
    return Uri.parse('$baseUrl/api/course-offerings')
        .replace(queryParameters: params);
  }

  /// GET /api/course-offerings/{id}
  static Uri courseOffering(int id) =>
      Uri.parse('$baseUrl/api/course-offerings/$id');

  /// POST /api/course-offerings/{id}/cancel — hủy lớp học phần
  static Uri courseOfferingCancel(int id) =>
      Uri.parse('$baseUrl/api/course-offerings/$id/cancel');

  /// PUT /api/course-offerings/{id}/lecturer — đổi giảng viên phụ trách
  static Uri courseOfferingLecturer(int id) =>
      Uri.parse('$baseUrl/api/course-offerings/$id/lecturer');

  // ── Academic: Majors ────────────────────────────────────────────────────────

  /// GET /api/majors?khoaId=&trang=&soLuong=
  static Uri majors({int? khoaId, int page = 1, int pageSize = 20}) {
    final params = <String, String>{
      'trang': '$page',
      'soLuong': '$pageSize',
    };
    if (khoaId != null) params['khoaId'] = '$khoaId';
    return Uri.parse('$baseUrl/api/majors').replace(queryParameters: params);
  }

  /// GET /api/majors/{id}
  static Uri major(int id) => Uri.parse('$baseUrl/api/majors/$id');

  // ── Academic: Programs ─────────────────────────────────────────────────────

  /// GET /api/programs?majorId=&trang=&soLuong=
  static Uri programs({int? majorId, int page = 1, int pageSize = 20}) {
    final params = <String, String>{
      'trang': '$page',
      'soLuong': '$pageSize',
    };
    if (majorId != null) params['majorId'] = '$majorId';
    return Uri.parse('$baseUrl/api/programs').replace(queryParameters: params);
  }

  /// GET /api/programs/{id}
  static Uri program(int id) => Uri.parse('$baseUrl/api/programs/$id');

  /// POST /api/programs/{id}/courses — thêm môn vào curriculum
  static Uri programCourses(int programId) =>
      Uri.parse('$baseUrl/api/programs/$programId/courses');

  /// DELETE /api/programs/{id}/courses/{courseId} — gỡ môn khỏi curriculum
  static Uri programCourse(int programId, int courseId) =>
      Uri.parse('$baseUrl/api/programs/$programId/courses/$courseId');

  // ── Academic: AdminClasses ──────────────────────────────────────────────────

  /// GET /api/admin-classes?programId=&trang=&soLuong=
  static Uri adminClasses({int? programId, int page = 1, int pageSize = 20}) {
    final params = <String, String>{
      'trang': '$page',
      'soLuong': '$pageSize',
    };
    if (programId != null) params['programId'] = '$programId';
    return Uri.parse('$baseUrl/api/admin-classes')
        .replace(queryParameters: params);
  }

  /// GET /api/admin-classes/{id}
  static Uri adminClass(int id) =>
      Uri.parse('$baseUrl/api/admin-classes/$id');

  /// POST /api/admin-classes/{id}/students — gán sinh viên vào lớp
  static Uri adminClassStudents(int id) =>
      Uri.parse('$baseUrl/api/admin-classes/$id/students');

  // ── Enrollments ───────────────────────────────────────────────────────────

  /// POST /api/enrollments  — đăng ký lớp HP
  static Uri get enrollments => Uri.parse('$baseUrl/api/enrollments');

  /// DELETE /api/enrollments/{id}  — hủy đăng ký
  static Uri enrollment(int id) => Uri.parse('$baseUrl/api/enrollments/$id');

  /// GET /api/me/enrollments?termId=  — môn đã đăng ký của tôi
  static Uri myEnrollments({int? termId}) {
    final params = termId != null ? {'termId': '$termId'} : <String, String>{};
    return Uri.parse('$baseUrl/api/me/enrollments')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  /// GET /api/offerings/{offeringId}/enrollments  — roster lớp HP (giảng viên / staff)
  static Uri offeringRoster(int offeringId) =>
      Uri.parse('$baseUrl/api/offerings/$offeringId/enrollments');

  /// GET /api/me/timetable?termId=  — thời khóa biểu của tôi trong 1 học kỳ
  static Uri myTimetable(int termId) =>
      Uri.parse('$baseUrl/api/me/timetable')
          .replace(queryParameters: {'termId': '$termId'});

  // ── Attendance ────────────────────────────────────────────────────────────

  /// POST /api/offerings/{id}/attendance-sessions — GV mở buổi điểm danh
  static Uri moBuoiDiemDanh(int offeringId) =>
      Uri.parse('$baseUrl/api/offerings/$offeringId/attendance-sessions');

  /// PUT /api/attendance-sessions/{id}/close — GV đóng buổi
  static Uri dongBuoi(int sessionId) =>
      Uri.parse('$baseUrl/api/attendance-sessions/$sessionId/close');

  /// GET /api/attendance-sessions/{id}/qr-token — lấy/làm mới QR token
  static Uri qrToken(int sessionId) =>
      Uri.parse('$baseUrl/api/attendance-sessions/$sessionId/qr-token');

  /// GET /api/attendance-sessions/{id}/records — danh sách SV đã check-in
  static Uri attendanceRecords(int sessionId) =>
      Uri.parse('$baseUrl/api/attendance-sessions/$sessionId/records');

  /// POST /api/attendance-sessions/check-in — SV gửi token + GPS
  static Uri get checkIn =>
      Uri.parse('$baseUrl/api/attendance-sessions/check-in');

  /// GET /api/offerings/{id}/my-attendance — SV xem lịch sử điểm danh
  static Uri myAttendance(int offeringId) =>
      Uri.parse('$baseUrl/api/offerings/$offeringId/my-attendance');

  /// How long to wait before giving up on a request.
  static const Duration timeout = Duration(seconds: 15);
}

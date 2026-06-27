import 'package:flutter/material.dart';

/// A selectable role on the role-selection screen.
///
/// [id] matches the seeded Roles table Name column exactly
/// (Student · Lecturer · DepartmentStaff · AcademicOffice · Admin).
///
/// This is UX-only navigation state — never sent to the API or used for
/// authorization. The JWT's real roles decide what a signed-in user can do.
class AppRole {
  const AppRole({
    required this.id,
    required this.label,
    required this.blurb,
    required this.icon,
  });

  final String id;
  final String label;
  final String blurb;
  final IconData icon;

  /// Maps a backend role name (from JWT / LoginResponse.roles) to display info.
  /// Falls back to a generic entry for any unrecognised role string.
  static AppRole fromBackendId(String id) =>
      _backendRoles[id] ??
      AppRole(id: id, label: id, blurb: '', icon: Icons.person_outline);

  static const _backendRoles = <String, AppRole>{
    'Student': AppRole(
      id: 'Student',
      label: 'Sinh Viên',
      blurb: 'Các môn học, điểm số và lịch học',
      icon: Icons.school_outlined,
    ),
    'Lecturer': AppRole(
      id: 'Lecturer',
      label: 'Giảng Viên',
      blurb: 'Lớp học, danh sách sinh viên và điểm',
      icon: Icons.co_present_outlined,
    ),
    'DepartmentStaff': AppRole(
      id: 'DepartmentStaff',
      label: 'Cán bộ Khoa',
      blurb: 'Quản lý khoa và bộ môn',
      icon: Icons.groups_outlined,
    ),
    'AcademicOffice': AppRole(
      id: 'AcademicOffice',
      label: 'Phòng Đào Tạo',
      blurb: 'Quản lý đăng ký và hồ sơ học tập',
      icon: Icons.account_balance_outlined,
    ),
    'Admin': AppRole(
      id: 'Admin',
      label: 'Quản Trị Viên',
      blurb: 'Quản trị hệ thống',
      icon: Icons.shield_outlined,
    ),
  };
}
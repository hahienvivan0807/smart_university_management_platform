import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'academic_term_list_screen.dart';
import 'admin_class_list_screen.dart';
import 'course_list_screen.dart';
import 'course_offering_list_screen.dart';
import 'faculty_list_screen.dart';
import 'major_list_screen.dart';
import 'program_list_screen.dart';

/// Trang chủ tab "Quản trị" — danh sách lối tắt tới các màn CRUD từng entity.
/// Chỉ Admin/AcademicOffice thấy tab này (đã gate ở app_shell.dart).
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <_DashboardItem>[
      _DashboardItem(
        icon: Icons.school_outlined,
        label: 'Khoa',
        builder: (_) => const FacultyListScreen(laManHinhDoc: true),
      ),
      _DashboardItem(
        icon: Icons.category_outlined,
        label: 'Ngành',
        builder: (_) => const MajorListScreen(),
      ),
      _DashboardItem(
        icon: Icons.menu_book_outlined,
        label: 'Chương trình đào tạo',
        builder: (_) => const ProgramListScreen(laManHinhDoc: true),
      ),
      _DashboardItem(
        icon: Icons.book_outlined,
        label: 'Môn học',
        builder: (_) => const CourseListScreen(laManHinhDoc: true),
      ),
      _DashboardItem(
        icon: Icons.calendar_month_outlined,
        label: 'Học kỳ',
        builder: (_) => const AcademicTermListScreen(laManHinhDoc: true),
      ),
      _DashboardItem(
        icon: Icons.groups_outlined,
        label: 'Lớp hành chính',
        builder: (_) => const AdminClassListScreen(),
      ),
      _DashboardItem(
        icon: Icons.class_outlined,
        label: 'Lớp học phần',
        builder: (_) => const CourseOfferingListScreen(laManHinhDoc: true),
      ),
    ];

    return Scaffold(
      backgroundColor: context.canvas,
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _DashboardTile(item: items[i]),
      ),
    );
  }
}

class _DashboardItem {
  const _DashboardItem({
    required this.icon,
    required this.label,
    required this.builder,
  });

  final IconData icon;
  final String label;
  final WidgetBuilder builder;
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.item});
  final _DashboardItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: item.builder),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDark ? 0.0 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(item.icon, color: AppColors.accent, size: 20),
          ),
          title: Text(item.label, style: Theme.of(context).textTheme.titleMedium),
          trailing: Icon(Icons.chevron_right_rounded, color: context.faint),
        ),
      ),
    );
  }
}

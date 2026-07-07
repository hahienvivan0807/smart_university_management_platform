import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/faculty.dart';
import 'package:smart_university_management_platform/data/services/faculty_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';
import 'course_list_screen.dart';

// ============================================================================
// COURSE CATALOG HOME SCREEN  —  cổng vào "Danh mục môn học"
//
// Thay vì hiện luôn tất cả môn học (dễ quá tải khi trường có nhiều khoa),
// màn này hiện danh sách Khoa trước — tap vào 1 khoa để xem môn học của
// khoa đó. Mục "Tất cả môn học" ghim đầu danh sách để không mất khả năng
// duyệt toàn bộ danh mục (kể cả các môn đại cương không gán khoa nào).
// ============================================================================

class CourseCatalogHomeScreen extends StatefulWidget {
  const CourseCatalogHomeScreen({super.key, this.laManHinhDoc = false});

  /// true = màn này được `Navigator.push` như 1 màn độc lập (từ Dashboard)
  /// → cần AppBar + nút quay về riêng. false (mặc định) = nhúng trong tab
  /// AppShell, AppShell đã có AppBar rồi.
  final bool laManHinhDoc;

  @override
  State<CourseCatalogHomeScreen> createState() =>
      _CourseCatalogHomeScreenState();
}

class _CourseCatalogHomeScreenState extends State<CourseCatalogHomeScreen> {
  final _dichVu = FacultyService(authenticatedClient);

  List<FacultyItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiDanhSach();
  }

  Future<void> _taiDanhSach() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    final ketQua = await _dichVu.layDanhSach();

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  void _xemTatCa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CourseListScreen(laManHinhDoc: true),
      ),
    );
  }

  void _xemTheoKhoa(FacultyItem khoa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseListScreen(
          facultyId: khoa.facultyId,
          facultyName: khoa.name,
          laManHinhDoc: true,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: widget.laManHinhDoc
          ? AppBar(
              backgroundColor: context.canvas,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text('Danh mục môn học',
                  style: Theme.of(context).textTheme.headlineSmall),
            )
          : null, // nhúng trong tab AppShell — AppShell đã có AppBar với tên section
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const SkeletonListView();

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDanhSach,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _CatalogTile(
            icon: Icons.apps_rounded,
            label: 'Tất cả môn học',
            subtitle: 'Xem toàn bộ danh mục, không lọc theo khoa',
            onTap: _xemTatCa,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final khoa in _danhSach)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: _CatalogTile(
                icon: Icons.school_outlined,
                label: khoa.name,
                subtitle: 'Mã: ${khoa.code}',
                onTap: () => _xemTheoKhoa(khoa),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: context.isDark ? 0.0 : 0.03),
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
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          title: Text(label, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: context.faint),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                color: AppColors.red
                    .withValues(alpha: context.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 12.5,
                            color: context.isDark
                                ? const Color(0xFFF1B0AC)
                                : const Color(0xFFB23A33),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: context.border),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

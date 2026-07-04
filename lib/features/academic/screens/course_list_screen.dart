import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/course.dart';
import 'package:smart_university_management_platform/data/services/course_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'course_form_screen.dart';
import 'document_list_screen.dart';

// ============================================================================
// COURSE LIST SCREEN  —  danh sách môn học
//
// Đây là màn hình tab 1 trong AppShell ("Danh mục môn học").
// Hiển thị tất cả môn học trong hệ thống; có thể lọc tùy chọn theo khoa
// hoặc bộ môn (dùng khi điều hướng từ DepartmentListScreen sau này).
//
// Phase 2: read-only (tất cả role xem được).
// CRUD môn học (cho Admin/AcademicOffice) sẽ bổ sung ở phase sau.
//
// Lifecycle: nằm trong IndexedStack nên initState() chỉ chạy 1 lần.
// ============================================================================

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({
    super.key,
    this.facultyId,
    this.departmentId,
    this.facultyName,
    this.laManHinhDoc = false,
  });

  /// Lọc theo khoa — null = lấy tất cả
  final int? facultyId;

  /// Lọc theo bộ môn — null = lấy tất cả
  final int? departmentId;

  /// Chỉ dùng để hiện trong tiêu đề khi [laManHinhDoc] == true.
  final String? facultyName;

  /// true = màn này được `Navigator.push` như 1 màn độc lập (từ Admin
  /// Dashboard hoặc Danh mục môn học) → cần AppBar + nút quay về riêng.
  /// false (mặc định) = nhúng trong tab AppShell, AppShell đã có AppBar rồi.
  final bool laManHinhDoc;

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final _dichVu = CourseService(authenticatedClient);

  List<CourseItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  bool get _coQuyenGhi {
    final roles = session.roles;
    return roles.contains('Admin') || roles.contains('AcademicOffice');
  }

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

    final ketQua = await _dichVu.layDanhSach(
      facultyId: widget.facultyId,
      departmentId: widget.departmentId,
    );

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  void _xemTaiLieu(CourseItem mon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentListScreen(
          courseId: mon.courseId,
          tieuDe: 'Tài liệu — ${mon.name}',
          coTheTaiLen: _coQuyenGhi,
        ),
      ),
    );
  }

  Future<void> _moForm({CourseItem? mon}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CourseFormScreen(monCanSua: mon)),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  Future<void> _xacNhanXoa(CourseItem mon) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa môn học',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text('Môn học "${mon.name}" sẽ bị vô hiệu hóa.',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Vô hiệu hóa'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    final ketQua = await _dichVu.voHieuHoa(mon.courseId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ketQua.ok ? 'Đã vô hiệu hóa môn học.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
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
              title: Text(
                widget.facultyName != null
                    ? 'Môn học — ${widget.facultyName}'
                    : 'Tất cả môn học',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            )
          : null,
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'course_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm môn học'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Text(
          'Chưa có môn học nào.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDanhSach,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xl + 56,
        ),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _MonHocTile(
          mon: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onSua: () => _moForm(mon: _danhSach[i]),
          onXoa: () => _xacNhanXoa(_danhSach[i]),
          onXemTaiLieu: () => _xemTaiLieu(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _MonHocTile extends StatelessWidget {
  const _MonHocTile({
    required this.mon,
    required this.coQuyenGhi,
    required this.onSua,
    required this.onXoa,
    required this.onXemTaiLieu,
  });

  final CourseItem mon;
  final bool coQuyenGhi;
  final VoidCallback onSua;
  final VoidCallback onXoa;
  final VoidCallback onXemTaiLieu;

  /// Xây chuỗi phụ đề: code + đơn vị sở hữu (ưu tiên bộ môn, fallback khoa).
  String get _phuDe {
    final parts = <String>['Mã: ${mon.code}'];
    if (mon.ownerDepartmentName != null) {
      parts.add(mon.ownerDepartmentName!);
    } else if (mon.ownerFacultyName != null) {
      parts.add(mon.ownerFacultyName!);
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        leading: _CreditsBadge(credits: mon.credits),
        title: Text(
          mon.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            _phuDe,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Tài liệu',
              icon: const Icon(Icons.folder_open_rounded, size: 20),
              onPressed: onXemTaiLieu,
            ),
            if (coQuyenGhi) _ActionMenu(onSua: onSua, onXoa: onXoa),
          ],
        ),
      ),
    );
  }
}

// ── Action menu (3-dot) ───────────────────────────────────────────────────────

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.onSua, required this.onXoa});

  final VoidCallback onSua;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuAction>(
      icon: Icon(Icons.more_vert_rounded, color: context.muted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: context.border),
      ),
      color: context.canvas,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: _MenuAction.sua,
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 17, color: context.text),
            const SizedBox(width: AppSpacing.sm),
            Text('Sửa', style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
        PopupMenuItem(
          value: _MenuAction.xoa,
          child: Row(children: [
            const Icon(Icons.block_rounded, size: 17, color: AppColors.red),
            const SizedBox(width: AppSpacing.sm),
            Text('Vô hiệu hóa',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.red)),
          ]),
        ),
      ],
      onSelected: (a) {
        if (a == _MenuAction.sua) onSua();
        if (a == _MenuAction.xoa) onXoa();
      },
    );
  }
}

enum _MenuAction { sua, xoa }

// ── Credits badge: ô vuông hiện số tín chỉ ──────────────────────────────────

class _CreditsBadge extends StatelessWidget {
  const _CreditsBadge({required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: context.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$credits',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
          ),
          Text(
            'TC',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
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
                color: AppColors.red.withValues(
                    alpha: context.isDark ? 0.14 : 0.08),
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

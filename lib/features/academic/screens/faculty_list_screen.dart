import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/faculty.dart';
import 'package:smart_university_management_platform/data/services/faculty_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'department_list_screen.dart';
import 'faculty_form_screen.dart';

// ============================================================================
// FACULTY LIST SCREEN  —  danh sách khoa, tap → xem bộ môn
//
// Mục đích: màn hình đầu tiên trong cây "Cơ cấu tổ chức" của AppShell.
//   FacultyListScreen  →  (tap)  →  DepartmentListScreen(facultyId)
//
// Đây là màn hình read-only — mọi user đã đăng nhập đều xem được.
// CRUD faculties sẽ bổ sung ở Module 2.5 Phase 2 khi có FacultyFormScreen.
//
// Điểm quan trọng về vòng đời (lifecycle):
//   Màn hình này được nhúng bên trong AppShell qua IndexedStack.
//   → Nó KHÔNG bị destroy khi user chuyển sang tab khác trong AppShell.
//   → initState() chỉ chạy 1 lần khi app khởi động, không chạy lại.
//   → Nếu muốn reload khi quay lại, gọi _taiDanhSach() từ một nơi khác
//     (ví dụ trong didChangeDependencies hoặc qua callback).
// ============================================================================

class FacultyListScreen extends StatefulWidget {
  const FacultyListScreen({super.key, this.laManHinhDoc = false});

  /// true = màn này được `Navigator.push` như 1 màn độc lập (từ Admin
  /// Dashboard) → cần AppBar + nút quay về riêng. false (mặc định) = nhúng
  /// trong tab AppShell, AppShell đã có AppBar rồi.
  final bool laManHinhDoc;

  @override
  State<FacultyListScreen> createState() => _FacultyListScreenState();
}

class _FacultyListScreenState extends State<FacultyListScreen> {
  // Dùng authenticatedClient từ main.dart:
  //   → client này tự gắn JWT header vào mọi request
  //   → nếu nhận 401, tự gọi /refresh rồi thử lại
  //   → nếu refresh thất bại, tự navigate về login
  final _dichVu = FacultyService(authenticatedClient);

  List<FacultyItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  /// Chỉ Admin hoặc AcademicOffice mới được ghi.
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

    final ketQua = await _dichVu.layDanhSach();

    if (!mounted) return; // guard: widget có thể bị dispose khi await
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _moForm({FacultyItem? khoa}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FacultyFormScreen(khoaCanSua: khoa),
      ),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  Future<void> _xacNhanXoa(FacultyItem khoa) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa khoa',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Khoa "${khoa.name}" sẽ bị vô hiệu hóa.\n'
          'Thao tác bị chặn nếu khoa còn bộ môn đang hoạt động.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
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

    final ketQua = await _dichVu.voHieuHoa(khoa.facultyId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ketQua.ok ? 'Đã vô hiệu hóa khoa.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  /// Điều hướng đến DepartmentListScreen và lọc theo facultyId.
  ///
  /// Dùng Navigator.push (không phải pushReplacement) vì:
  ///   → user cần nhấn back để quay lại danh sách khoa
  ///   → FacultyListScreen vẫn còn trong stack (không bị xóa)
  void _xemBoMon(FacultyItem khoa) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentListScreen(
          facultyId: khoa.facultyId,
          facultyName: khoa.name,
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
              title: Text('Danh sách Khoa',
                  style: Theme.of(context).textTheme.headlineSmall),
            )
          : null, // nhúng trong tab AppShell — AppShell đã có AppBar với tên section
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'faculty_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm khoa'),
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
          'Chưa có khoa nào.',
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
          AppSpacing.xl + 56, // tránh FAB
        ),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _KhoaTile(
          khoa: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onTap: () => _xemBoMon(_danhSach[i]),
          onSua: () => _moForm(khoa: _danhSach[i]),
          onXoa: () => _xacNhanXoa(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _KhoaTile extends StatelessWidget {
  const _KhoaTile({
    required this.khoa,
    required this.coQuyenGhi,
    required this.onTap,
    required this.onSua,
    required this.onXoa,
  });

  final FacultyItem khoa;
  final bool coQuyenGhi;
  final VoidCallback onTap;
  final VoidCallback onSua;
  final VoidCallback onXoa;

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
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          title: Text(
            khoa.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Mã: ${khoa.code} · Tap để xem bộ môn',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // Mũi tên phải: gợi ý user có thể tap để xem chi tiết
          // (Admin/AcademicOffice thấy menu Sửa/Vô hiệu hóa thay vào đó)
          trailing: coQuyenGhi
              ? _ActionMenu(onSua: onSua, onXoa: onXoa)
              : Icon(Icons.chevron_right_rounded, color: context.faint),
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
            Text('Sửa tên', style: Theme.of(context).textTheme.bodyLarge),
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
                border: Border.all(
                    color: AppColors.red.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 16, color: AppColors.red),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      message,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
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

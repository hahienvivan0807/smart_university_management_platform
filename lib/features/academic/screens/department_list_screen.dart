import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/department.dart';
import 'package:smart_university_management_platform/data/services/department_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';
import 'department_form_screen.dart';

// ============================================================================
// DEPARTMENT LIST SCREEN  —  browse + CRUD for Departments
//
// Hiển thị danh sách bộ môn (lọc theo khoa nếu có [facultyId]).
// Mọi user đã đăng nhập đều xem được.
// Admin / AcademicOffice thấy thêm FAB "Thêm" + menu Sửa / Vô hiệu hóa.
//
// State management: StatefulWidget + setState — đủ cho 1 màn hình CRUD đơn,
// nhất quán với các màn hình auth hiện tại; không cần thêm package.
// ============================================================================

class DepartmentListScreen extends StatefulWidget {
  const DepartmentListScreen({
    super.key,
    this.facultyId,
    this.facultyName,
  });

  /// Lọc theo khoa cụ thể — null = hiện tất cả.
  final int? facultyId;

  /// Hiển thị trong AppBar subtitle. Không gửi lên API.
  final String? facultyName;

  @override
  State<DepartmentListScreen> createState() => _DepartmentListScreenState();
}

class _DepartmentListScreenState extends State<DepartmentListScreen> {
  final _dichVu = DepartmentService(authenticatedClient);

  List<DepartmentItem> _danhSach = [];
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

    final ketQua = await _dichVu.layDanhSach(facultyId: widget.facultyId);

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _xacNhanXoa(DepartmentItem boMon) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa bộ môn',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Bộ môn "${boMon.name}" sẽ bị vô hiệu hóa.\n'
          'Thao tác bị chặn nếu bộ môn còn giảng viên.',
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

    final ketQua = await _dichVu.voHieuHoa(boMon.departmentId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          ketQua.ok ? 'Đã vô hiệu hóa bộ môn.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  Future<void> _moForm({DepartmentItem? boMon}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DepartmentFormScreen(
          defaultFacultyId: widget.facultyId,
          boMonCanSua: boMon,
        ),
      ),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppSpacing.md,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.facultyName != null
                  ? 'Bộ môn — ${widget.facultyName}'
                  : 'Danh sách Bộ môn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (!_dangTai && _loi == null)
              Text(
                '${_danhSach.length} bộ môn',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.muted),
            tooltip: 'Tải lại',
            onPressed: _dangTai ? null : _taiDanhSach,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'department_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm bộ môn'),
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
      return const SkeletonListView();
    }

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Text(
          'Chưa có bộ môn nào.',
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
        itemBuilder: (_, i) => _BoMonTile(
          boMon: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onSua: () => _moForm(boMon: _danhSach[i]),
          onXoa: () => _xacNhanXoa(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _BoMonTile extends StatelessWidget {
  const _BoMonTile({
    required this.boMon,
    required this.coQuyenGhi,
    required this.onSua,
    required this.onXoa,
  });

  final DepartmentItem boMon;
  final bool coQuyenGhi;
  final VoidCallback onSua;
  final VoidCallback onXoa;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        title: Text(
          boMon.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${boMon.code} · ${boMon.facultyName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        trailing: coQuyenGhi ? _ActionMenu(onSua: onSua, onXoa: onXoa) : null,
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
            Text('Sửa tên',
                style: Theme.of(context).textTheme.bodyLarge),
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
                color: AppColors.red.withValues(alpha: context.isDark ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.red.withValues(alpha: 0.35)),
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
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

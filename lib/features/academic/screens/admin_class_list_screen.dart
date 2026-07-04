import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/admin_class.dart';
import 'package:smart_university_management_platform/data/services/admin_class_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'admin_class_form_screen.dart';

/// Danh sách lớp hành chính (lọc theo chương trình nếu có [programId]).
/// CRUD + gán sinh viên cho Admin/AcademicOffice.
class AdminClassListScreen extends StatefulWidget {
  const AdminClassListScreen({super.key, this.programId, this.programName});

  final int? programId;
  final String? programName;

  @override
  State<AdminClassListScreen> createState() => _AdminClassListScreenState();
}

class _AdminClassListScreenState extends State<AdminClassListScreen> {
  final _dichVu = AdminClassService(authenticatedClient);

  List<AdminClassItem> _danhSach = [];
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

    final ketQua = await _dichVu.layDanhSach(programId: widget.programId);

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data?.items ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _moForm({AdminClassItem? lop}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminClassFormScreen(
          defaultProgramId: widget.programId,
          lopCanSua: lop,
        ),
      ),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  Future<void> _xacNhanXoa(AdminClassItem lop) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa lớp',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Lớp "${lop.code}" sẽ bị vô hiệu hóa.\n'
          'Thao tác bị chặn nếu lớp còn sinh viên.',
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

    final ketQua = await _dichVu.voHieuHoa(lop.adminClassId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ketQua.ok ? 'Đã vô hiệu hóa lớp.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  Future<void> _ganSinhVien(AdminClassItem lop) async {
    final maSvCtrl = TextEditingController();

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Gán sinh viên vào lớp "${lop.code}"',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: TextField(
          controller: maSvCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'ID Sinh viên (UserId)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Gán'),
          ),
        ],
      ),
    );

    if (xacNhan != true || !mounted) return;

    final studentUserId = int.tryParse(maSvCtrl.text.trim());
    if (studentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID sinh viên không hợp lệ.')),
      );
      return;
    }

    final ketQua = await _dichVu.ganSinhVien(lop.adminClassId, studentUserId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ketQua.ok ? 'Đã gán sinh viên vào lớp.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
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
        title: Text(
          widget.programName != null
              ? 'Lớp hành chính — ${widget.programName}'
              : 'Danh sách Lớp hành chính',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'admin_class_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm lớp'),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 2,
            )
          : null,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Text('Chưa có lớp hành chính nào.',
            style: Theme.of(context).textTheme.bodyMedium),
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
        itemBuilder: (_, i) => _LopTile(
          lop: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onSua: () => _moForm(lop: _danhSach[i]),
          onXoa: () => _xacNhanXoa(_danhSach[i]),
          onGanSv: () => _ganSinhVien(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _LopTile extends StatelessWidget {
  const _LopTile({
    required this.lop,
    required this.coQuyenGhi,
    required this.onSua,
    required this.onXoa,
    required this.onGanSv,
  });

  final AdminClassItem lop;
  final bool coQuyenGhi;
  final VoidCallback onSua;
  final VoidCallback onXoa;
  final VoidCallback onGanSv;

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
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.accentSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.groups_outlined,
              color: AppColors.accent, size: 20),
        ),
        title: Text(lop.name ?? lop.code,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${lop.code} · Khóa ${lop.intakeYear} · ${lop.soSinhVien} SV'
            '${lop.advisorName != null ? ' · CVHT: ${lop.advisorName}' : ''}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        trailing:
            coQuyenGhi ? _ActionMenu(onSua: onSua, onXoa: onXoa, onGanSv: onGanSv) : null,
      ),
    );
  }
}

// ── Action menu (3-dot) ───────────────────────────────────────────────────────

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({
    required this.onSua,
    required this.onXoa,
    required this.onGanSv,
  });

  final VoidCallback onSua;
  final VoidCallback onXoa;
  final VoidCallback onGanSv;

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
          value: _MenuAction.ganSv,
          child: Row(children: [
            Icon(Icons.person_add_rounded, size: 17, color: context.text),
            const SizedBox(width: AppSpacing.sm),
            Text('Gán sinh viên', style: Theme.of(context).textTheme.bodyLarge),
          ]),
        ),
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
        if (a == _MenuAction.ganSv) onGanSv();
      },
    );
  }
}

enum _MenuAction { sua, xoa, ganSv }

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

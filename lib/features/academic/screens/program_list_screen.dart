import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/program.dart';
import 'package:smart_university_management_platform/data/services/auth_service.dart';
import 'package:smart_university_management_platform/data/services/program_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';
import 'program_detail_screen.dart';
import 'program_form_screen.dart';

/// Danh sách chương trình đào tạo (curriculum), tap → xem chi tiết + môn học.
class ProgramListScreen extends StatefulWidget {
  const ProgramListScreen({super.key, this.laManHinhDoc = false});

  /// true = màn này được `Navigator.push` như 1 màn độc lập (từ Admin
  /// Dashboard) → cần AppBar + nút quay về riêng. false (mặc định) = nhúng
  /// trong tab AppShell, AppShell đã có AppBar rồi.
  final bool laManHinhDoc;

  @override
  State<ProgramListScreen> createState() => _ProgramListScreenState();
}

class _ProgramListScreenState extends State<ProgramListScreen> {
  final _dichVu = ProgramService(authenticatedClient);

  List<ProgramItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  /// null = chưa tải xong / đang tải; -1 = tải xong nhưng lỗi hoặc SV không thuộc
  /// chương trình nào; > 0 = programId của chính SV.
  int? _programIdCuaToi;

  bool get _coQuyenGhi {
    final roles = session.roles;
    return roles.contains('Admin') || roles.contains('AcademicOffice');
  }

  /// SV thuần túy đi thẳng vào đúng chương trình của mình — không cần tự tìm
  /// trong danh sách toàn trường (chỉ dành cho nhân viên/giảng viên duyệt).
  bool get _laSinhVienThuanTuy {
    final roles = session.roles;
    return roles.contains('Student') &&
        !roles.contains('Lecturer') &&
        !_coQuyenGhi;
  }

  @override
  void initState() {
    super.initState();
    if (_laSinhVienThuanTuy) {
      _taiChuongTrinhCuaToi();
    } else {
      _taiDanhSach();
    }
  }

  Future<void> _taiChuongTrinhCuaToi() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    // session.me có thể chưa kịp tải xong lúc màn này initState (AppShell gọi
    // taiThongTinCuaToi() kiểu fire-and-forget, chạy song song với IndexedStack
    // dựng tất cả tab cùng lúc) — không dựa vào cache, tự hỏi thẳng server.
    var userId = session.me?.userId;
    if (userId == null) {
      final meKq =
          await AuthService(client: authenticatedClient).layThongTinCuaToi();
      if (!mounted) return;
      userId = meKq.data?.userId;
      if (userId == null) {
        setState(() {
          _dangTai = false;
          _loi = meKq.error ?? 'Không xác định được tài khoản hiện tại.';
        });
        return;
      }
    }

    final ketQua = await _dichVu.layProgramIdCuaSinhVien(userId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _programIdCuaToi = ketQua.data ?? -1;
      _loi = ketQua.error;
    });
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

  Future<void> _moForm({ProgramItem? ct}) async {
    final daThayDoi = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProgramFormScreen(ctCanSua: ct)),
    );
    if (daThayDoi == true) _taiDanhSach();
  }

  Future<void> _xacNhanXoa(ProgramItem ct) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Vô hiệu hóa chương trình',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Chương trình "${ct.name}" sẽ bị vô hiệu hóa.',
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

    final ketQua = await _dichVu.voHieuHoa(ct.programId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ketQua.ok
          ? 'Đã vô hiệu hóa chương trình.'
          : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  void _xemChiTiet(ProgramItem ct) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProgramDetailScreen(programId: ct.programId),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_laSinhVienThuanTuy) {
      if (_dangTai) {
        return Scaffold(
          backgroundColor: context.canvas,
          body: const SkeletonListView(),
        );
      }
      if (_programIdCuaToi != null && _programIdCuaToi! > 0) {
        return ProgramDetailScreen(programId: _programIdCuaToi!);
      }
      return Scaffold(
        backgroundColor: context.canvas,
        appBar: AppBar(
          backgroundColor: context.canvas,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text('Chương trình đào tạo',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        body: _ErrorView(
          message: _loi ?? 'Bạn chưa được gán vào chương trình đào tạo nào.',
          onRetry: _taiChuongTrinhCuaToi,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.canvas,
      appBar: widget.laManHinhDoc
          ? AppBar(
              backgroundColor: context.canvas,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text('Chương trình đào tạo',
                  style: Theme.of(context).textTheme.headlineSmall),
            )
          : null,
      floatingActionButton: _coQuyenGhi
          ? FloatingActionButton.extended(
              heroTag: 'program_list_fab',
              onPressed: () => _moForm(),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('Thêm chương trình'),
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
        child: Text('Chưa có chương trình đào tạo nào.',
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
        itemBuilder: (_, i) => _ProgramTile(
          ct: _danhSach[i],
          coQuyenGhi: _coQuyenGhi,
          onTap: () => _xemChiTiet(_danhSach[i]),
          onSua: () => _moForm(ct: _danhSach[i]),
          onXoa: () => _xacNhanXoa(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({
    required this.ct,
    required this.coQuyenGhi,
    required this.onTap,
    required this.onSua,
    required this.onXoa,
  });

  final ProgramItem ct;
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
            child: const Icon(Icons.menu_book_outlined,
                color: AppColors.accent, size: 20),
          ),
          title: Text(
            ct.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${ct.code} · Khóa ${ct.curriculumYear}'
              '${ct.totalCredits > 0 ? ' · ${ct.totalCredits} TC' : ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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

import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/models/program.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/data/services/program_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';

/// Chi tiết 1 chương trình đào tạo — thông tin chung + curriculum (danh sách môn).
class ProgramDetailScreen extends StatefulWidget {
  const ProgramDetailScreen({super.key, required this.programId});

  final int programId;

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final _dichVu = ProgramService(authenticatedClient);
  final _enrollSv = EnrollmentService(authenticatedClient);

  ProgramDetail? _chiTiet;
  Map<int, int> _trangThaiMonHoc = {}; // courseId -> status (1/2/4/5)
  bool _dangTai = true;
  String? _loi;

  bool get _coQuyenGhi {
    final roles = session.roles;
    return roles.contains('Admin') || roles.contains('AcademicOffice');
  }

  bool get _laSinhVien => session.roles.contains('Student');

  @override
  void initState() {
    super.initState();
    _taiChiTiet();
  }

  Future<void> _taiChiTiet() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    final ketQuaChiTiet = await _dichVu.layChiTiet(widget.programId);
    final trangThai = _laSinhVien
        ? await _enrollSv.layTrangThaiMonHoc()
        : (data: <CourseStatusItem>[], error: null);

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _chiTiet = ketQuaChiTiet.data;
      _trangThaiMonHoc = {
        for (final e in trangThai.data ?? <CourseStatusItem>[])
          e.courseId: e.status,
      };
      _loi = ketQuaChiTiet.error;
    });
  }

  Future<void> _themMonHoc() async {
    final maMonCtrl = TextEditingController();
    final kyCtrl = TextEditingController();
    var batBuoc = true;

    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: context.border),
          ),
          title: Text('Thêm môn học',
              style: Theme.of(ctx).textTheme.headlineSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: maMonCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ID Môn học'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: kyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Kỳ đề nghị học (không bắt buộc)'),
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                value: batBuoc,
                onChanged: (v) => setDialogState(() => batBuoc = v ?? true),
                title: const Text('Môn bắt buộc'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );

    if (xacNhan != true || !mounted) return;

    final courseId = int.tryParse(maMonCtrl.text.trim());
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID môn học không hợp lệ.')),
      );
      return;
    }

    final ketQua = await _dichVu.themMonHoc(
      widget.programId,
      AddCourseToProgramRequest(
        courseId: courseId,
        recommendedSemester: int.tryParse(kyCtrl.text.trim()),
        isRequired: batBuoc,
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ketQua.error ?? 'Đã thêm môn học vào chương trình.'),
    ));
    if (ketQua.error == null) _taiChiTiet();
  }

  Future<void> _xoaMonHoc(ProgramCourseItem mon) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title:
            Text('Gỡ môn học', style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text('Gỡ "${mon.courseName}" khỏi chương trình này?',
            style: Theme.of(ctx).textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Gỡ môn'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    final ketQua = await _dichVu.xoaMonHoc(widget.programId, mon.courseId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ketQua.ok ? 'Đã gỡ môn học.' : (ketQua.error ?? 'Thất bại.')),
    ));
    if (ketQua.ok) _taiChiTiet();
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
          _chiTiet?.name ?? 'Chương trình đào tạo',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      floatingActionButton: (_coQuyenGhi && _chiTiet != null)
          ? FloatingActionButton.extended(
              heroTag: 'program_detail_fab',
              onPressed: _themMonHoc,
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
    if (_dangTai) return const SkeletonListView();

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiChiTiet);
    }

    final ct = _chiTiet!;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiChiTiet,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          _coQuyenGhi ? AppSpacing.xl + 56 : AppSpacing.md,
        ),
        children: [
          _ThongTinCard(ct: ct),
          const SizedBox(height: AppSpacing.md),
          Text('Danh sách môn học (${ct.courses.length})',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          if (ct.courses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text('Chương trình chưa có môn học nào.',
                  style: Theme.of(context).textTheme.bodyMedium),
            )
          else
            for (final mon in ct.courses)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _CourseTile(
                  mon: mon,
                  trangThai:
                      _laSinhVien ? _trangThaiMonHoc[mon.courseId] : null,
                  onXoa: _coQuyenGhi ? () => _xoaMonHoc(mon) : null,
                ),
              ),
        ],
      ),
    );
  }
}

// ── Card thông tin chung ─────────────────────────────────────────────────────

class _ThongTinCard extends StatelessWidget {
  const _ThongTinCard({required this.ct});
  final ProgramDetail ct;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(ct.code, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.school_outlined, size: 14, color: context.muted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(ct.majorName,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event_outlined, size: 14, color: context.muted),
              const SizedBox(width: 4),
              Text('Khóa ${ct.curriculumYear}',
                  style: Theme.of(context).textTheme.bodyMedium),
              if (ct.totalCredits > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.stacked_bar_chart_outlined,
                    size: 14, color: context.muted),
                const SizedBox(width: 4),
                Text('${ct.totalCredits} tín chỉ',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tile môn học trong curriculum ────────────────────────────────────────────

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.mon, this.trangThai, this.onXoa});
  final ProgramCourseItem mon;

  /// null = không áp dụng (không phải SV) hoặc chưa học; 1/2/4/5 = trạng thái enrollment.
  final int? trangThai;
  final VoidCallback? onXoa;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
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
          child: Center(
            child: Text(
              '${mon.credits}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(mon.courseName,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (trangThai != null) _TrangThaiMonBadge(status: trangThai!),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${mon.courseCode}'
            '${mon.recommendedSemester != null ? ' · Kỳ ${mon.recommendedSemester}' : ''}'
            '${mon.isRequired ? ' · Bắt buộc' : ' · Tự chọn'}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        trailing: onXoa != null
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.red),
                tooltip: 'Gỡ môn học',
                onPressed: onXoa,
              )
            : null,
      ),
    );
  }
}

// ── Badge trạng thái môn (Đậu/Rớt/Đang học) trong curriculum ─────────────────

class _TrangThaiMonBadge extends StatelessWidget {
  const _TrangThaiMonBadge({required this.status});

  /// 1=Đang học, 2=Đang chờ, 4=Đậu, 5=Rớt
  final int status;

  @override
  Widget build(BuildContext context) {
    final (nhan, mau) = switch (status) {
      4 => ('Đậu', const Color(0xFF16A34A)),
      5 => ('Rớt', AppColors.red),
      1 => ('Đang học', AppColors.accent),
      2 => ('Đang chờ', const Color(0xFFD97706)),
      _ => ('', context.muted),
    };
    if (nhan.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.xs),
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        nhan,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: mau,
              fontWeight: FontWeight.w600,
              fontSize: 10,
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

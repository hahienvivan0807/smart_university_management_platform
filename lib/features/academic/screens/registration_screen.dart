import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/course_offering.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/models/paged_result.dart';
import 'package:smart_university_management_platform/data/services/course_offering_service.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';
import 'my_enrollments_screen.dart';

// ============================================================================
// REGISTRATION SCREEN — "Đăng ký học phần" cho sinh viên
//
// Không bắt sinh viên tự chọn học kỳ trước: hiện thẳng mọi lớp học phần đang
// trong cửa sổ đăng ký (server tự xác định qua dangMoDangKy=true), gom nhóm
// theo học kỳ chỉ để hiển thị. Đăng ký một lớp đã đầy sẽ được xếp vào hàng
// đợi (waitlist) thay vì bị từ chối — xem EnrollmentService.DangKyAsync.
// ============================================================================

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _offeringSv = CourseOfferingService(authenticatedClient);
  final _enrollSv = EnrollmentService(authenticatedClient);

  final _timKiemCtrl = TextEditingController();

  List<CourseOfferingItem> _danhSach = [];
  Map<int, EnrollmentItem> _dangKyCuaToi = {}; // courseOfferingId -> enrollment
  bool _dangTai = true;
  String? _loi;
  String _tuKhoa = '';

  int get _tongTinChiDangHoc => _dangKyCuaToi.values
      .where((e) => e.dangHoc)
      .fold(0, (tong, e) => tong + e.courseCredits);

  /// Lọc theo tên môn/mã môn/mã lớp — lọc ngay từng ký tự gõ, không cần bấm nút.
  List<CourseOfferingItem> get _danhSachDaLoc {
    final tuKhoa = _tuKhoa.trim().toLowerCase();
    if (tuKhoa.isEmpty) return _danhSach;
    return _danhSach.where((lop) {
      return lop.courseName.toLowerCase().contains(tuKhoa) ||
          lop.courseCode.toLowerCase().contains(tuKhoa) ||
          lop.code.toLowerCase().contains(tuKhoa);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  @override
  void dispose() {
    _timKiemCtrl.dispose();
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });

    final results = await Future.wait([
      _offeringSv.layDanhSach(dangMoDangKy: true, soLuong: 200),
      _enrollSv.layDanhSachCuaToi(),
    ]);

    if (!mounted) return;

    final offeringKq = results[0]
        as ({PagedResult<CourseOfferingItem>? data, String? error});
    final enrollKq =
        results[1] as ({List<EnrollmentItem>? data, String? error});

    setState(() {
      _dangTai = false;
      _danhSach = offeringKq.data?.items ?? [];
      _dangKyCuaToi = {
        for (final e in enrollKq.data ?? <EnrollmentItem>[])
          e.courseOfferingId: e,
      };
      _loi = offeringKq.error ?? enrollKq.error;
    });
  }

  Future<void> _dangKy(CourseOfferingItem lopHP) async {
    final ketQua = await _enrollSv.dangKy(lopHP.courseOfferingId);
    if (!mounted) return;

    if (ketQua.error != null) {
      _showSnackBar(ketQua.error!, mau: AppColors.red);
      return;
    }

    final dk = ketQua.data!;
    if (dk.dangCho) {
      _showSnackBar(
        'Lớp "${lopHP.courseName}" đã đầy — đã thêm bạn vào danh sách chờ'
        '${dk.waitlistPosition != null ? ' (vị trí ${dk.waitlistPosition})' : ''}.',
        mau: const Color(0xFFD97706),
      );
    } else {
      _showSnackBar('Đăng ký "${lopHP.courseName}" thành công!',
          mau: const Color(0xFF16A34A));
    }

    _taiDuLieu();
  }

  void _showSnackBar(String message, {required Color mau}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: mau,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
    );
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
        title: Text('Đăng ký học phần',
            style: Theme.of(context).textTheme.headlineSmall),
        actions: [
          IconButton(
            tooltip: 'Đăng ký của tôi',
            icon: const Icon(Icons.checklist_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyEnrollmentsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_dangTai && _loi == null && _danhSach.isNotEmpty)
            _buildSearchField(context),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      child: TextField(
        controller: _timKiemCtrl,
        onChanged: (v) => setState(() => _tuKhoa = v),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên môn, mã môn...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _tuKhoa.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() {
                    _timKiemCtrl.clear();
                    _tuKhoa = '';
                  }),
                ),
          isDense: true,
          filled: true,
          fillColor: context.panel,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: context.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide(color: context.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const SkeletonListView();

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDuLieu);
    }

    if (_danhSach.isEmpty) {
      return RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _taiDuLieu,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.accentSoft,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(Icons.event_busy_rounded,
                          color: AppColors.accent, size: 28),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Hiện không có lớp học phần nào đang mở đăng ký.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final danhSachDaLoc = _danhSachDaLoc;

    if (danhSachDaLoc.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Không tìm thấy môn học nào khớp "$_tuKhoa".',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Gom nhóm theo học kỳ (thường chỉ 1 nhóm, trừ khi có lớp học lại từ kỳ khác còn mở).
    final nhom = <String, List<CourseOfferingItem>>{};
    for (final lop in danhSachDaLoc) {
      nhom.putIfAbsent(lop.termName, () => []).add(lop);
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDuLieu,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
        children: [
          _TongTinChiCard(tongTinChi: _tongTinChiDangHoc, tranTinChi: 24),
          const SizedBox(height: AppSpacing.md),
          for (final entry in nhom.entries) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(entry.key,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final lop in entry.value) ...[
              _RegisterTile(
                lopHP: lop,
                dangKyHienTai: _dangKyCuaToi[lop.courseOfferingId],
                onDangKy: () => _dangKy(lop),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

// ── Thẻ tổng tín chỉ đã đăng ký ───────────────────────────────────────────────

class _TongTinChiCard extends StatelessWidget {
  const _TongTinChiCard({required this.tongTinChi, required this.tranTinChi});
  final int tongTinChi;
  final int tranTinChi;

  @override
  Widget build(BuildContext context) {
    final vuotTran = tongTinChi > tranTinChi;
    final tiLe = (tongTinChi / tranTinChi).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_outlined, size: 16, color: context.muted),
              const SizedBox(width: AppSpacing.xs),
              Text('Tín chỉ đã đăng ký',
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                '$tongTinChi/$tranTinChi TC',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: vuotTran ? AppColors.red : AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: tiLe,
              minHeight: 6,
              backgroundColor: context.border,
              valueColor: AlwaysStoppedAnimation(
                  vuotTran ? AppColors.red : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile 1 lớp học phần có thể đăng ký ────────────────────────────────────────

class _RegisterTile extends StatefulWidget {
  const _RegisterTile({
    required this.lopHP,
    required this.dangKyHienTai,
    required this.onDangKy,
  });

  final CourseOfferingItem lopHP;

  /// null = chưa đăng ký lớp này; khác null = đã đăng ký/đang chờ/đậu/rớt.
  final EnrollmentItem? dangKyHienTai;
  final VoidCallback onDangKy;

  @override
  State<_RegisterTile> createState() => _RegisterTileState();
}

class _RegisterTileState extends State<_RegisterTile> {
  bool _dangXuLy = false;

  Future<void> _xuLy() async {
    setState(() => _dangXuLy = true);
    widget.onDangKy();
    if (mounted) setState(() => _dangXuLy = false);
  }

  @override
  Widget build(BuildContext context) {
    final lopHP = widget.lopHP;
    final dk = widget.dangKyHienTai;
    final daCoDangKy = dk != null && (dk.dangHoc || dk.dangCho);

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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CreditsBadge(credits: lopHP.courseCredits),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lopHP.courseName,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${lopHP.code} · ${lopHP.courseCode}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12.5),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded,
                              size: 13, color: context.muted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              lopHP.lecturerName,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (lopHP.dayOfWeek != null &&
                          lopHP.startTime != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 13, color: context.muted),
                            const SizedBox(width: 3),
                            Text(
                              '${_tenThu(lopHP.dayOfWeek!)} · ${lopHP.startTime!.substring(0, 5)}-${lopHP.endTime?.substring(0, 5) ?? ''}'
                              '${lopHP.room != null ? ' · ${lopHP.room}' : ''}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                _ChoConLai(lopHP: lopHP),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: _dangXuLy
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: daCoDangKy ? null : _xuLy,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        disabledBackgroundColor: context.border,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Text(
                        daCoDangKy
                            ? dk.trangThaiText
                            : (lopHP.conCho ? 'Đăng ký' : 'Vào danh sách chờ'),
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                              color: daCoDangKy ? context.muted : Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _tenThu(int dayOfWeek) {
    // Quy ước SQL: 1=Chủ nhật, 2=Thứ 2, ..., 7=Thứ 7
    const ten = ['', 'CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return dayOfWeek >= 1 && dayOfWeek <= 7 ? ten[dayOfWeek] : '?';
  }
}

// ── Badge tín chỉ ─────────────────────────────────────────────────────────────

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

// ── Số chỗ còn lại ────────────────────────────────────────────────────────────

class _ChoConLai extends StatelessWidget {
  const _ChoConLai({required this.lopHP});
  final CourseOfferingItem lopHP;

  @override
  Widget build(BuildContext context) {
    final soChoHienThi = lopHP.capacity == null
        ? '∞'
        : '${lopHP.enrollmentCount}/${lopHP.capacity}';

    final mauCho = lopHP.capacity == null
        ? context.muted
        : lopHP.conCho
            ? context.muted
            : const Color(0xFFD97706);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chair_outlined, size: 12, color: mauCho),
        const SizedBox(width: 2),
        Text(
          soChoHienThi,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: mauCho,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
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

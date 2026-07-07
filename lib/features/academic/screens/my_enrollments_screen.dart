import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';
import 'attendance_history_screen.dart';
import 'my_timetable_screen.dart';
import 'qr_scan_screen.dart';

/// Danh sách môn đã đăng ký của sinh viên trong một học kỳ.
/// Cho phép hủy đăng ký từng môn sau khi xác nhận.
class MyEnrollmentsScreen extends StatefulWidget {
  const MyEnrollmentsScreen({
    super.key,
    this.termId,
    this.termLabel,
  });

  /// null = hiện tất cả học kỳ (mỗi dòng tự hiện học kỳ của nó).
  final int? termId;
  final String? termLabel;

  @override
  State<MyEnrollmentsScreen> createState() => _MyEnrollmentsScreenState();
}

class _MyEnrollmentsScreenState extends State<MyEnrollmentsScreen> {
  final _dichVu = EnrollmentService(authenticatedClient);

  List<EnrollmentItem> _danhSach = [];
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
    final ketQua = await _dichVu.layDanhSachCuaToi(termId: widget.termId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data ?? [];
      _loi = ketQua.error;
    });
  }

  Future<void> _huyDangKy(EnrollmentItem mon) async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: Text('Bạn muốn hủy đăng ký môn "${mon.courseName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );

    if (xacNhan != true || !mounted) return;

    final ketQua = await _dichVu.huyDangKy(mon.enrollmentId);
    if (!mounted) return;

    if (ketQua.error != null) {
      _showSnackBar(ketQua.error!, isError: true);
      return;
    }

    _showSnackBar('Đã hủy đăng ký "${mon.courseName}".');
    _taiDanhSach();
  }

  void _quetQr(EnrollmentItem mon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScanScreen(courseName: mon.courseName),
      ),
    );
  }

  void _xemLichSu(EnrollmentItem mon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AttendanceHistoryScreen(
          courseOfferingId: mon.courseOfferingId,
          courseName: mon.courseName,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.red : const Color(0xFF16A34A),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Đăng ký của tôi',
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              widget.termLabel ?? 'Tất cả học kỳ',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11.5, color: context.muted),
            ),
          ],
        ),
        actions: [
          if (widget.termId != null)
            IconButton(
              tooltip: 'Thời khóa biểu',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyTimetableScreen(
                    termId: widget.termId!,
                    termLabel: widget.termLabel ?? 'Học kỳ',
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const SkeletonListView();

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiDanhSach);
    }

    if (_danhSach.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
                child: const Icon(Icons.inbox_outlined,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Bạn chưa đăng ký môn nào.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiDanhSach,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) => _EnrollmentTile(
          mon: _danhSach[i],
          hienThiHocKy: widget.termId == null,
          onHuy: () => _huyDangKy(_danhSach[i]),
          onQuetQr: () => _quetQr(_danhSach[i]),
          onXemLichSu: () => _xemLichSu(_danhSach[i]),
        ),
      ),
    );
  }
}

// ── Tile môn đã đăng ký ───────────────────────────────────────────────────────

class _EnrollmentTile extends StatefulWidget {
  const _EnrollmentTile({
    required this.mon,
    required this.hienThiHocKy,
    required this.onHuy,
    required this.onQuetQr,
    required this.onXemLichSu,
  });

  final EnrollmentItem mon;

  /// true = hiện thêm dòng học kỳ (dùng khi màn đang gộp nhiều học kỳ).
  final bool hienThiHocKy;
  final VoidCallback onHuy;
  final VoidCallback onQuetQr;
  final VoidCallback onXemLichSu;

  @override
  State<_EnrollmentTile> createState() => _EnrollmentTileState();
}

class _EnrollmentTileState extends State<_EnrollmentTile> {
  bool _dangXuLy = false;

  Future<void> _xuLyHuy() async {
    setState(() => _dangXuLy = true);
    widget.onHuy();
    if (mounted) setState(() => _dangXuLy = false);
  }

  @override
  Widget build(BuildContext context) {
    final mon = widget.mon;

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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge tín chỉ
            _CreditsBadge(credits: mon.courseCredits),
            const SizedBox(width: AppSpacing.md),

            // Thông tin môn
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(mon.courseName,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      _TrangThaiBadge(mon: mon),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.hienThiHocKy
                        ? '${mon.offeringCode} · ${mon.courseCode} · ${mon.termLabel}'
                        : '${mon.offeringCode} · ${mon.courseCode}',
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
                          mon.lecturerName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm + 2),

                  // Nút quét QR + lịch sử — chỉ khi đang học chính thức
                  if (mon.dangHoc) ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: FilledButton.icon(
                              onPressed: widget.onQuetQr,
                              icon: const Icon(Icons.qr_code_scanner_rounded,
                                  size: 15),
                              label: const Text('Quét QR'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: OutlinedButton.icon(
                              onPressed: widget.onXemLichSu,
                              icon: const Icon(Icons.history_rounded, size: 15),
                              label: const Text('Lịch sử'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.border),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                  ],

                  // Nút hủy đăng ký
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: _dangXuLy
                        ? const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : OutlinedButton(
                            onPressed: mon.coTheHuy ? _xuLyHuy : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red,
                              side: BorderSide(
                                color: mon.coTheHuy
                                    ? AppColors.red.withValues(alpha: 0.5)
                                    : context.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              mon.coTheHuy
                                  ? (mon.dangCho ? 'Rời hàng chờ' : 'Hủy đăng ký')
                                  : mon.trangThaiText,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: mon.coTheHuy
                                        ? AppColors.red
                                        : context.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge trạng thái (Đang học/Đang chờ/Đậu/Rớt) ─────────────────────────────

class _TrangThaiBadge extends StatelessWidget {
  const _TrangThaiBadge({required this.mon});
  final EnrollmentItem mon;

  Color _mau() {
    if (mon.daDau) return const Color(0xFF16A34A);
    if (mon.daRot) return AppColors.red;
    if (mon.dangCho) return const Color(0xFFD97706);
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    final mau = _mau();
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
      decoration: BoxDecoration(
        color: mau.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        mon.trangThaiText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: mau,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
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

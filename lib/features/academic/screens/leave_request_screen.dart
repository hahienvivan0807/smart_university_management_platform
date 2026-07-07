import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/leave_request.dart';
import 'package:smart_university_management_platform/data/services/leave_request_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'package:smart_university_management_platform/shared/widgets/skeleton.dart';

// ============================================================================
// LEAVE REQUEST SCREEN — "Xin nghỉ dạy" cho 1 lớp học phần cụ thể.
//
// Hiện lịch sử các phiếu giảng viên đã gửi cho ĐÚNG lớp này (lọc client-side
// từ /api/me/leave-requests trả về toàn bộ lớp của giảng viên), + nút "Xin
// nghỉ dạy" mở form tạo mới (date range làm mờ ngày đã chiếm + dialog xác
// nhận trước khi gửi — tính năng cố ý "uy nghiêm", không cho hủy sau khi
// Admin/khoa đã duyệt, chỉ thu hồi được lúc còn Chờ duyệt).
// ============================================================================

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({
    super.key,
    required this.courseOfferingId,
    required this.offeringCode,
  });

  final int courseOfferingId;
  final String offeringCode;

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _dichVu = LeaveRequestService(authenticatedClient);

  List<LeaveRequestItem> _danhSach = [];
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

    final ketQua = await _dichVu.layLichSuCuaToi();

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = (ketQua.data ?? [])
          .where((p) => p.courseOfferingId == widget.courseOfferingId)
          .toList()
        ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
      _loi = ketQua.error;
    });
  }

  Future<void> _thuHoi(LeaveRequestItem phieu) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Thu hồi phiếu xin nghỉ',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Thu hồi phiếu ngày ${_hienThiKhoangNgay(phieu)} — coi như bạn chưa từng gửi yêu cầu này.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: const Text('Thu hồi'),
          ),
        ],
      ),
    );

    if (dongY != true || !mounted) return;

    final ketQua = await _dichVu.thuHoi(phieu.leaveRequestId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ketQua.ok ? 'Đã thu hồi phiếu.' : (ketQua.error ?? 'Thất bại.')),
      backgroundColor: ketQua.ok ? const Color(0xFF16A34A) : AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
    if (ketQua.ok) _taiDanhSach();
  }

  Future<void> _moFormTao() async {
    final blockedKetQua =
        await _dichVu.layNgayDaChiem(widget.courseOfferingId);
    if (!mounted) return;

    if (blockedKetQua.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(blockedKetQua.error!),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final ketQua = await showDialog<bool>(
      context: context,
      builder: (_) => _TaoPhieuDialog(
        courseOfferingId: widget.courseOfferingId,
        ngayDaChiem: blockedKetQua.data ?? [],
        dichVu: _dichVu,
      ),
    );

    if (ketQua == true) _taiDanhSach();
  }

  String _hienThiKhoangNgay(LeaveRequestItem p) => p.startDate == p.endDate
      ? _dinhDangNgay(p.startDate)
      : '${_dinhDangNgay(p.startDate)} → ${_dinhDangNgay(p.endDate)}';

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
            Text('Xin nghỉ dạy', style: Theme.of(context).textTheme.headlineSmall),
            Text(
              widget.offeringCode,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11.5, color: context.muted),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'leave_request_fab',
        onPressed: _moFormTao,
        icon: const Icon(Icons.event_busy_rounded, size: 20),
        label: const Text('Xin nghỉ dạy'),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
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
                child: const Icon(Icons.event_busy_rounded,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Bạn chưa gửi yêu cầu nghỉ dạy nào cho lớp này.',
                  textAlign: TextAlign.center,
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
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl + 56),
        itemCount: _danhSach.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (_, i) {
          final phieu = _danhSach[i];
          return _PhieuTile(
            phieu: phieu,
            khoangNgay: _hienThiKhoangNgay(phieu),
            onThuHoi: phieu.dangChoDuyet ? () => _thuHoi(phieu) : null,
          );
        },
      ),
    );
  }
}

String _dinhDangNgay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

// ── Tile 1 phiếu ──────────────────────────────────────────────────────────────

class _PhieuTile extends StatelessWidget {
  const _PhieuTile({
    required this.phieu,
    required this.khoangNgay,
    required this.onThuHoi,
  });

  final LeaveRequestItem phieu;
  final String khoangNgay;
  final VoidCallback? onThuHoi;

  Color _mauTrangThai(BuildContext context) => switch (phieu.status) {
        1 => AppColors.amber,
        2 => const Color(0xFF16A34A),
        3 => AppColors.red,
        _ => context.muted,
      };

  @override
  Widget build(BuildContext context) {
    final mau = _mauTrangThai(context);

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
          Row(
            children: [
              Expanded(
                child: Text(khoangNgay,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs + 2, vertical: 2),
                decoration: BoxDecoration(
                  color: mau.withValues(alpha: context.isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  phieu.trangThai,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: mau,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(phieu.reason, style: Theme.of(context).textTheme.bodyMedium),
          if (phieu.reviewNote != null && phieu.reviewNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Ghi chú: ${phieu.reviewNote}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12, color: context.muted),
            ),
          ],
          if (onThuHoi != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: onThuHoi,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm)),
                ),
                child: const Text('Thu hồi'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Dialog tạo phiếu mới ──────────────────────────────────────────────────────

class _TaoPhieuDialog extends StatefulWidget {
  const _TaoPhieuDialog({
    required this.courseOfferingId,
    required this.ngayDaChiem,
    required this.dichVu,
  });

  final int courseOfferingId;
  final List<BlockedDateRange> ngayDaChiem;
  final LeaveRequestService dichVu;

  @override
  State<_TaoPhieuDialog> createState() => _TaoPhieuDialogState();
}

class _TaoPhieuDialogState extends State<_TaoPhieuDialog> {
  DateTime? _ngayBatDau;
  DateTime? _ngayKetThuc;
  final _lyDoCtrl = TextEditingController();
  String? _loi;
  bool _dangGui = false;

  bool _ngayBiChan(DateTime ngay) {
    final homNay = DateTime.now();
    final ngayThuan = DateTime(ngay.year, ngay.month, ngay.day);
    if (ngayThuan.isBefore(DateTime(homNay.year, homNay.month, homNay.day))) {
      return true;
    }
    return widget.ngayDaChiem.any((r) => r.chua(ngayThuan));
  }

  Future<void> _chonNgayBatDau() async {
    final chon = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (d) => !_ngayBiChan(d),
    );
    if (chon == null) return;
    setState(() {
      _ngayBatDau = chon;
      if (_ngayKetThuc != null && _ngayKetThuc!.isBefore(chon)) {
        _ngayKetThuc = null;
      }
    });
  }

  Future<void> _chonNgayKetThuc() async {
    if (_ngayBatDau == null) return;
    final chon = await showDatePicker(
      context: context,
      initialDate: _ngayBatDau!,
      firstDate: _ngayBatDau!,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (d) => !_ngayBiChan(d),
    );
    if (chon == null) return;
    setState(() => _ngayKetThuc = chon);
  }

  Future<void> _guiYeuCau() async {
    if (_ngayBatDau == null || _ngayKetThuc == null) {
      setState(() => _loi = 'Vui lòng chọn khoảng ngày nghỉ.');
      return;
    }
    if (_lyDoCtrl.text.trim().isEmpty) {
      setState(() => _loi = 'Vui lòng nhập lý do.');
      return;
    }

    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: context.border),
        ),
        title: Text('Xác nhận xin nghỉ dạy',
            style: Theme.of(ctx).textTheme.headlineSmall),
        content: Text(
          'Bạn có chắc muốn xin tạm ngưng buổi học '
          '${_ngayBatDau == _ngayKetThuc ? _dinhDangNgay(_ngayBatDau!) : '${_dinhDangNgay(_ngayBatDau!)} → ${_dinhDangNgay(_ngayKetThuc!)}'}? '
          'Yêu cầu sẽ được gửi tới cán bộ khoa/Admin để duyệt.',
          style: Theme.of(ctx).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (dongY != true || !mounted) return;

    setState(() {
      _dangGui = true;
      _loi = null;
    });

    final ketQua = await widget.dichVu.taoMoi(CreateLeaveRequestPayload(
      courseOfferingId: widget.courseOfferingId,
      startDate: _ngayBatDau!,
      endDate: _ngayKetThuc!,
      reason: _lyDoCtrl.text.trim(),
    ));

    if (!mounted) return;

    if (ketQua.error != null) {
      setState(() {
        _dangGui = false;
        _loi = ketQua.error;
      });
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _lyDoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: BorderSide(color: context.border),
      ),
      title: Text('Xin nghỉ dạy', style: Theme.of(context).textTheme.headlineSmall),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loi != null) ...[
              Text(_loi!, style: const TextStyle(color: AppColors.red)),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _chonNgayBatDau,
                    child: Text(_ngayBatDau == null
                        ? 'Ngày bắt đầu'
                        : _dinhDangNgay(_ngayBatDau!)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _ngayBatDau == null ? null : _chonNgayKetThuc,
                    child: Text(_ngayKetThuc == null
                        ? 'Ngày kết thúc'
                        : _dinhDangNgay(_ngayKetThuc!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _lyDoCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Lý do',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _guiYeuCau,
          style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
          child: _dangGui
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Gửi yêu cầu'),
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
                color:
                    AppColors.red.withValues(alpha: context.isDark ? 0.14 : 0.08),
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

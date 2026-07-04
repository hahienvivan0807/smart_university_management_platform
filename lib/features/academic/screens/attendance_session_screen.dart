import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/attendance.dart';
import 'package:smart_university_management_platform/data/services/attendance_service.dart';
import 'package:smart_university_management_platform/main.dart';

class AttendanceSessionScreen extends StatefulWidget {
  const AttendanceSessionScreen({
    super.key,
    required this.session,
    required this.offeringCode,
  });

  final AttendanceSession session;
  final String offeringCode;

  @override
  State<AttendanceSessionScreen> createState() =>
      _AttendanceSessionScreenState();
}

class _AttendanceSessionScreenState extends State<AttendanceSessionScreen> {
  final _sv = AttendanceService(authenticatedClient);

  QrTokenData? _qrToken;
  List<AttendanceRecord> _danhSach = [];
  bool _dangDong = false;
  String? _loi;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lamMoiQr();
    // poll QR token + danh sách check-in mỗi 5 giây
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _lamMoiQr());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _lamMoiQr() async {
    final sessionId = widget.session.attendanceSessionId;
    final qrKq = await _sv.layQrToken(sessionId);
    final dsKq = await _sv.layDanhSachCheckIn(sessionId);

    if (!mounted) return;
    setState(() {
      if (qrKq.data != null) {
        _qrToken = qrKq.data;
        _loi = null;
      } else {
        _loi = qrKq.error;
      }
      if (dsKq.data != null) _danhSach = dsKq.data!;
    });
  }

  Future<void> _dongBuoi() async {
    final xacNhan = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đóng buổi điểm danh?'),
        content: Text(
            'Sinh viên sẽ không thể quét QR sau khi đóng.\n'
            'Đã điểm danh: ${_danhSach.length} sinh viên.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Đóng buổi')),
        ],
      ),
    );
    if (xacNhan != true) return;

    setState(() => _dangDong = true);
    final loi = await _sv.dongBuoi(widget.session.attendanceSessionId);
    if (!mounted) return;

    if (loi != null) {
      setState(() => _dangDong = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loi), backgroundColor: AppColors.red),
      );
      return;
    }
    Navigator.pop(context, true); // báo caller là đã đóng thành công
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Điểm danh · ${widget.offeringCode}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: _dangDong
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : FilledButton.icon(
                    onPressed: _dongBuoi,
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('Đóng buổi'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── QR Code ──────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Center(
              child: _loi != null
                  ? _LoiQr(message: _loi!, onRetry: _lamMoiQr)
                  : _qrToken == null
                      ? const CircularProgressIndicator()
                      : _QrCard(qrToken: _qrToken!),
            ),
          ),

          // ── Danh sách đã check-in ─────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: context.panel,
              border: Border(top: BorderSide(color: context.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.how_to_reg_rounded,
                          size: 16, color: AppColors.accent),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Đã điểm danh: ${_danhSach.length} sinh viên',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
                if (_danhSach.isNotEmpty)
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      itemCount: _danhSach.length,
                      itemBuilder: (_, i) {
                        final sv = _danhSach[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Text(
                                '${i + 1}.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: context.muted),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(sv.fullName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                              ),
                              if (sv.treGio)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      right: AppSpacing.xs),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withValues(
                                          alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(AppRadius.sm),
                                    ),
                                    child: Text(
                                      'Trễ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              color: AppColors.amber,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              Text(
                                sv.loginCode,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: context.muted),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.md, top: AppSpacing.xs),
                    child: Text(
                      'Chưa có sinh viên nào quét QR',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: context.muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── QR Card ───────────────────────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qrToken});
  final QrTokenData qrToken;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: qrToken.token,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh_rounded, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              'QR tự đổi mỗi 30 giây',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: context.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Lỗi QR ───────────────────────────────────────────────────────────────────

class _LoiQr extends StatelessWidget {
  const _LoiQr({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.red),
        const SizedBox(height: AppSpacing.sm),
        Text(message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.red)),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
      ],
    );
  }
}
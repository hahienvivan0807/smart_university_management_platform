import 'package:flutter/material.dart';
import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/attendance.dart';
import 'package:smart_university_management_platform/data/services/attendance_service.dart';
import 'package:smart_university_management_platform/main.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({
    super.key,
    required this.courseOfferingId,
    required this.courseName,
  });

  final int courseOfferingId;
  final String courseName;

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _sv = AttendanceService(authenticatedClient);

  List<MyAttendanceItem> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final kq = await _sv.layLichSuCuaToi(widget.courseOfferingId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = kq.data ?? [];
      _loi = kq.error;
    });
  }

  int get _soBuoiCoMat => _danhSach.where((b) => b.daMat).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lịch sử điểm danh',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
              ? _ErrorView(message: _loi!, onRetry: _tai)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_danhSach.isEmpty) {
      return Center(
        child: Text(
          'Chưa có buổi điểm danh nào.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: context.muted),
        ),
      );
    }

    final tongBuoi = _danhSach.length;
    final tyLe = tongBuoi > 0 ? (_soBuoiCoMat / tongBuoi) : 0.0;

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _tai,
      child: CustomScrollView(
        slivers: [
          // ── Tổng kết ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.panel,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.courseName,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _SoKetItem(
                            nhan: 'Có mặt',
                            gia: '$_soBuoiCoMat/$tongBuoi buổi',
                            mau: const Color(0xFF16A34A),
                          ),
                        ),
                        Expanded(
                          child: _SoKetItem(
                            nhan: 'Tỉ lệ',
                            gia: '${(tyLe * 100).toStringAsFixed(0)}%',
                            mau: tyLe >= 0.8
                                ? const Color(0xFF16A34A)
                                : AppColors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: tyLe,
                        minHeight: 6,
                        backgroundColor: context.border,
                        color: tyLe >= 0.8
                            ? const Color(0xFF16A34A)
                            : AppColors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Danh sách buổi ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList.separated(
              itemCount: _danhSach.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.xs),
              itemBuilder: (_, i) => _BuoiTile(
                buoi: _danhSach[i],
                stt: _danhSach.length - i,
              ),
            ),
          ),

          const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl)),
        ],
      ),
    );
  }
}

// ── Tile 1 buổi ───────────────────────────────────────────────────────────────

class _BuoiTile extends StatelessWidget {
  const _BuoiTile({required this.buoi, required this.stt});
  final MyAttendanceItem buoi;
  final int stt;

  @override
  Widget build(BuildContext context) {
    final ngay = _formatNgay(buoi.openedAtUtc.toLocal());
    final gio = _formatGio(buoi.openedAtUtc.toLocal());

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      child: Row(
        children: [
          // Số thứ tự
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(
                '$stt',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Buổi $stt — $ngay',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  buoi.daMat
                      ? 'Có mặt lúc ${_formatGio(buoi.checkedInAtUtc!.toLocal())}'
                      : 'Vắng · Buổi $gio',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: buoi.daMat
                            ? const Color(0xFF16A34A)
                            : context.muted,
                        fontSize: 12.5,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            buoi.daMat
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: buoi.daMat ? const Color(0xFF16A34A) : AppColors.red,
            size: 22,
          ),
        ],
      ),
    );
  }

  String _formatNgay(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  String _formatGio(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Số kết ───────────────────────────────────────────────────────────────────

class _SoKetItem extends StatelessWidget {
  const _SoKetItem({
    required this.nhan,
    required this.gia,
    required this.mau,
  });
  final String nhan;
  final String gia;
  final Color mau;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(nhan,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: context.muted, fontSize: 12)),
        Text(gia,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: mau,
                  fontWeight: FontWeight.w700,
                )),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.red)),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}
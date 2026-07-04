import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';

const _tenThu = {
  2: 'Thứ 2',
  3: 'Thứ 3',
  4: 'Thứ 4',
  5: 'Thứ 5',
  6: 'Thứ 6',
  7: 'Thứ 7',
  1: 'Chủ nhật',
};
const _thuTuTrongTuan = [2, 3, 4, 5, 6, 7, 1];

/// Thời khóa biểu của sinh viên trong một học kỳ, nhóm theo thứ trong tuần.
class MyTimetableScreen extends StatefulWidget {
  const MyTimetableScreen({
    super.key,
    required this.termId,
    required this.termLabel,
  });

  final int termId;
  final String termLabel;

  @override
  State<MyTimetableScreen> createState() => _MyTimetableScreenState();
}

class _MyTimetableScreenState extends State<MyTimetableScreen> {
  final _dichVu = EnrollmentService(authenticatedClient);

  List<TimetableEntry> _danhSach = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiThoiKhoaBieu();
  }

  Future<void> _taiThoiKhoaBieu() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final ketQua = await _dichVu.layThoiKhoaBieu(widget.termId);
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _danhSach = ketQua.data ?? [];
      _loi = ketQua.error;
    });
  }

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
            Text('Thời khóa biểu',
                style: Theme.of(context).textTheme.headlineSmall),
            Text(
              widget.termLabel,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 11.5, color: context.muted),
            ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_dangTai) return const Center(child: CircularProgressIndicator());

    if (_loi != null) {
      return _ErrorView(message: _loi!, onRetry: _taiThoiKhoaBieu);
    }

    final daXepLich =
        _danhSach.where((e) => e.daXepLich).toList();
    final chuaXepLich =
        _danhSach.where((e) => !e.daXepLich).toList();

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
                child: const Icon(Icons.calendar_month_outlined,
                    color: AppColors.accent, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Chưa có lớp học phần nào trong học kỳ này.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    final theoThu = <int, List<TimetableEntry>>{};
    for (final mon in daXepLich) {
      theoThu.putIfAbsent(mon.dayOfWeek!, () => []).add(mon);
    }
    for (final ds in theoThu.values) {
      ds.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _taiThoiKhoaBieu,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final thu in _thuTuTrongTuan)
            if (theoThu.containsKey(thu)) ...[
              Padding(
                padding: const EdgeInsets.only(
                    top: AppSpacing.sm, bottom: AppSpacing.xs),
                child: Text(_tenThu[thu]!,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final mon in theoThu[thu]!)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _TimetableTile(mon: mon),
                ),
            ],
          if (chuaXepLich.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(
                  top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Text('Chưa xếp lịch',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: context.muted)),
            ),
            for (final mon in chuaXepLich)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: _TimetableTile(mon: mon),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Tile lớp học phần ─────────────────────────────────────────────────────────

class _TimetableTile extends StatelessWidget {
  const _TimetableTile({required this.mon});
  final TimetableEntry mon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: context.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  mon.daXepLich ? mon.startTime!.substring(0, 5) : '--:--',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  mon.daXepLich ? mon.endTime!.substring(0, 5) : '--:--',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        fontSize: 10.5,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mon.courseName,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  mon.courseCode,
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
                if (mon.room != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.room_outlined,
                          size: 13, color: context.muted),
                      const SizedBox(width: 3),
                      Text(
                        mon.room!,
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

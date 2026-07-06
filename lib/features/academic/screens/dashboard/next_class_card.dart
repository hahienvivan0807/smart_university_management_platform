import 'dart:async';

import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/academic_term.dart';
import 'package:smart_university_management_platform/data/models/dashboard_mock_data.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/services/academic_term_service.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';
import '../my_timetable_screen.dart';
import 'dashboard_empty_state.dart';

// ============================================================================
// NEXT CLASS CARD — "Focus Mode": DỮ LIỆU THẬT, không mock.
//
// Tái dùng đúng logic đã verify của `_TodayScheduleCard` (dashboard cũ):
// tìm học kỳ hiện tại (so ngày với StartDate/EndDate) → GET /me/timetable →
// lọc đúng thứ hôm nay. Nâng cấp thêm so với bản cũ:
//   • Chỉ lấy buổi CHƯA kết thúc (bản cũ lấy buổi sớm nhất bất kể đã qua
//     hay chưa) — đúng tinh thần "lớp sắp diễn ra".
//   • Đếm ngược sống theo giây tới giờ bắt đầu (Timer.periodic).
//   • Không còn lớp nào hôm nay → hiện quote động lực (mock, xem
//     dashboard_mock_data.dart) thay vì chỉ 1 dòng chữ xám.
// ============================================================================

class NextClassCard extends StatefulWidget {
  const NextClassCard({super.key});

  @override
  State<NextClassCard> createState() => _NextClassCardState();
}

class _NextClassCardState extends State<NextClassCard> {
  bool _dangTai = true;
  TimetableEntry? _buoiSapToi;
  DateTime? _thoiGianBatDau;
  int? _hocKyId;
  String? _hocKyLabel;

  Timer? _dongHo;
  Duration _conLai = Duration.zero;

  @override
  void initState() {
    super.initState();
    _taiLichSapToi();
  }

  @override
  void dispose() {
    _dongHo?.cancel();
    super.dispose();
  }

  Future<void> _taiLichSapToi() async {
    final dichVuHK = AcademicTermService(authenticatedClient);
    final ketQuaHK = await dichVuHK.layDanhSach();
    final hocKyHienTai =
        ketQuaHK.data?.items.cast<AcademicTermItem?>().firstWhere(
      (hk) {
        final now = DateTime.now();
        return hk != null &&
            !now.isBefore(hk.startDate) &&
            !now.isAfter(hk.endDate);
      },
      orElse: () => null,
    );

    if (hocKyHienTai == null) {
      if (mounted) setState(() => _dangTai = false);
      return;
    }

    final dichVuTKB = EnrollmentService(authenticatedClient);
    final ketQuaTKB =
        await dichVuTKB.layThoiKhoaBieu(hocKyHienTai.academicTermId);

    // Quy ước backend: 1=Chủ nhật, 2=Thứ 2, ..., 7=Thứ 7.
    // DateTime.weekday: 1=Thứ 2, ..., 7=Chủ nhật.
    final homNay = DateTime.now();
    final thuHomNay = (homNay.weekday % 7) + 1;

    TimetableEntry? buoiSapToi;
    DateTime? gioBatDau;

    final cacBuoiHomNay = (ketQuaTKB.data ?? [])
        .where((e) => e.daXepLich && e.dayOfWeek == thuHomNay)
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    for (final buoi in cacBuoiHomNay) {
      final gio = _ghepGioVaoHomNay(buoi.endTime!, homNay);
      if (gio.isAfter(homNay)) {
        buoiSapToi = buoi;
        gioBatDau = _ghepGioVaoHomNay(buoi.startTime!, homNay);
        break; // buổi đầu tiên chưa kết thúc = buổi "sắp tới" cần hiện
      }
    }

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _buoiSapToi = buoiSapToi;
      _thoiGianBatDau = gioBatDau;
      _hocKyId = hocKyHienTai.academicTermId;
      _hocKyLabel = hocKyHienTai.label;
    });

    if (gioBatDau != null) _batDauDemNguoc(gioBatDau);
  }

  DateTime _ghepGioVaoHomNay(String hhmmss, DateTime ngay) {
    final parts = hhmmss.split(':').map(int.parse).toList();
    return DateTime(ngay.year, ngay.month, ngay.day, parts[0], parts[1],
        parts.length > 2 ? parts[2] : 0);
  }

  void _batDauDemNguoc(DateTime gioBatDau) {
    void capNhat() {
      final conLai = gioBatDau.difference(DateTime.now());
      if (!mounted) return;
      setState(() => _conLai = conLai.isNegative ? Duration.zero : conLai);
    }

    capNhat();
    _dongHo = Timer.periodic(const Duration(seconds: 1), (_) => capNhat());
  }

  String _dinhDangDemNguoc(Duration d) {
    String hai(int n) => n.toString().padLeft(2, '0');
    final gio = d.inHours;
    final phut = d.inMinutes % 60;
    final giay = d.inSeconds % 60;
    return gio > 0
        ? '${hai(gio)}:${hai(phut)}:${hai(giay)}'
        : '${hai(phut)}:${hai(giay)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTai) {
      return Container(
        height: 132,
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_buoiSapToi == null || _thoiGianBatDau == null) {
      return _KhongCoLopCard(hocKyId: _hocKyId, hocKyLabel: _hocKyLabel);
    }

    final dangDienRa = _conLai == Duration.zero;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MyTimetableScreen(
            termId: _hocKyId!,
            termLabel: _hocKyLabel ?? 'Học kỳ hiện tại',
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6E6ADE), AppColors.accent],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs + 2, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    dangDienRa ? '● ĐANG DIỄN RA' : 'LỚP SẮP TỚI',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _buoiSapToi!.courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.room_outlined,
                    size: 14, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Text(
                  _buoiSapToi!.room ?? 'Chưa rõ phòng',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.schedule_rounded,
                    size: 14, color: Colors.white.withValues(alpha: 0.85)),
                const SizedBox(width: 4),
                Text(
                  '${_buoiSapToi!.startTime!.substring(0, 5)}-${_buoiSapToi!.endTime!.substring(0, 5)}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            if (!dangDienRa)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _dinhDangDemNguoc(_conLai),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'đến giờ học',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.5),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ── Không có lớp hôm nay → quote động lực (mock) ─────────────────────────────

class _KhongCoLopCard extends StatelessWidget {
  const _KhongCoLopCard({required this.hocKyId, required this.hocKyLabel});

  final int? hocKyId;
  final String? hocKyLabel;

  @override
  Widget build(BuildContext context) {
    final quote = MotivationalQuote.ofToday();

    return GestureDetector(
      onTap: hocKyId == null
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyTimetableScreen(
                    termId: hocKyId!,
                    termLabel: hocKyLabel ?? 'Học kỳ hiện tại',
                  ),
                ),
              ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DashboardEmptyState(
              icon: Icons.local_florist_rounded,
              title: 'Không có lớp học nào hôm nay',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '"${quote.text}"',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 4),
            Text('— ${quote.author}',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

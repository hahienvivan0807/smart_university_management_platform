import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/academic_term.dart';
import 'package:smart_university_management_platform/data/models/enrollment.dart';
import 'package:smart_university_management_platform/data/services/academic_term_service.dart';
import 'package:smart_university_management_platform/data/services/enrollment_service.dart';
import 'package:smart_university_management_platform/main.dart';
import 'academic_term_list_screen.dart';
import 'admin_dashboard_screen.dart';
import 'course_catalog_home_screen.dart';
import 'course_offering_list_screen.dart';
import 'faculty_list_screen.dart';
import 'my_timetable_screen.dart';
import 'program_list_screen.dart';

// ============================================================================
// DASHBOARD SCREEN  —  tab đầu tiên, hiện ngay sau đăng nhập cho mọi role.
//
// Lấy tinh thần từ OneUni (header gradient + lưới danh mục nhiều màu +
// thẻ "hôm nay") nhưng giữ bản sắc riêng: màu chủ đạo indigo/tím của app,
// card bo góc mềm thay vì khối màu đặc, và giữ nguyên điều hướng Drawer
// hiện có (app chạy cả desktop lẫn mobile — bottom nav kiểu OneUni chỉ
// hợp mobile, không hợp màn desktop rộng).
//
//   • Header gradient: avatar + lời chào + vai trò.
//   • Thẻ "Lịch học hôm nay" (chỉ Student — chỉ role này có API Timetable):
//     lấy học kỳ hiện tại (so ngày hôm nay với StartDate/EndDate) rồi lọc
//     GET /api/me/timetable theo đúng thứ hôm nay. Dữ liệu thật, không bịa.
//   • Lưới "Danh mục" nhiều màu, tile cuối "Tất cả" mở danh sách tính năng
//     ít dùng (thay cho khu "Xem thêm" thu gọn trước đây).
// ============================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool get _laQuanTri =>
      session.roles.contains('Admin') || session.roles.contains('AcademicOffice');
  bool get _laGiangVien => session.roles.contains('Lecturer');
  bool get _laSinhVien => session.roles.contains('Student');

  List<_FeatureItem> get _tinhNangHayDung {
    if (_laQuanTri) {
      return [
        _FeatureItem(
          icon: Icons.school_rounded,
          label: 'Thêm khoa',
          color: AppColors.blue,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const FacultyListScreen(laManHinhDoc: true))),
        ),
        _FeatureItem(
          icon: Icons.co_present_rounded,
          label: 'Quản lý giảng viên',
          color: AppColors.purple,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const _ComingSoonScreen(
                  label: 'Quản lý giảng viên'))),
        ),
        _FeatureItem(
          icon: Icons.groups_rounded,
          label: 'Quản lý sinh viên',
          color: AppColors.teal,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) =>
                  const _ComingSoonScreen(label: 'Quản lý sinh viên'))),
        ),
        _FeatureItem(
          icon: Icons.class_rounded,
          label: 'Lớp học phần',
          color: AppColors.amber,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) =>
                  const CourseOfferingListScreen(laManHinhDoc: true))),
        ),
      ];
    }
    if (_laGiangVien) {
      return [
        _FeatureItem(
          icon: Icons.class_rounded,
          label: 'Lớp học phần của tôi',
          color: AppColors.blue,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const AcademicTermListScreen(laManHinhDoc: true))),
        ),
      ];
    }
    if (_laSinhVien) {
      return [
        _FeatureItem(
          icon: Icons.class_rounded,
          label: 'Học kỳ & Đăng ký môn',
          color: AppColors.blue,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const AcademicTermListScreen(laManHinhDoc: true))),
        ),
        _FeatureItem(
          icon: Icons.menu_book_rounded,
          label: 'Chương trình đào tạo',
          color: AppColors.purple,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const ProgramListScreen(laManHinhDoc: true))),
        ),
      ];
    }
    return const [];
  }

  List<_FeatureItem> get _tinhNangItDung {
    if (_laQuanTri) {
      return [
        _FeatureItem(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Tất cả tính năng quản trị',
          color: AppColors.accent,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const AdminDashboardScreen())),
        ),
      ];
    }
    return [
      _FeatureItem(
        icon: Icons.book_rounded,
        label: 'Danh mục môn học',
        color: AppColors.teal,
        onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => const CourseCatalogHomeScreen())),
      ),
    ];
  }

  void _moTatCa(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AllFeaturesScreen(items: _tinhNangItDung),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _GreetingHeader(),
            if (_laSinhVien) ...[
              const SizedBox(height: AppSpacing.md),
              const _TodayScheduleCard(),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            _FeatureGrid(
              items: _tinhNangHayDung,
              onTatCa: () => _moTatCa(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header chào (gradient card — bản sắc riêng: indigo/tím thay vì xanh) ─────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String _chuCai(String? ten) {
    if (ten == null || ten.trim().isEmpty) return '?';
    final parts = ten.trim().split(RegExp(r'\s+'));
    return parts.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final ten = session.me?.fullName;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6E6ADE), AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _chuCai(ten),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ten != null ? 'Xin chào, $ten' : 'Xin chào',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.activeRole?.label ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Thẻ "Lịch học hôm nay" (Student, dữ liệu thật từ Timetable API) ──────────

class _TodayScheduleCard extends StatefulWidget {
  const _TodayScheduleCard();

  @override
  State<_TodayScheduleCard> createState() => _TodayScheduleCardState();
}

class _TodayScheduleCardState extends State<_TodayScheduleCard> {
  bool _dangTai = true;
  TimetableEntry? _buoiHomNay;
  int? _hocKyId;
  String? _hocKyLabel;

  @override
  void initState() {
    super.initState();
    _taiLichHomNay();
  }

  Future<void> _taiLichHomNay() async {
    final dichVuHK = AcademicTermService(authenticatedClient);
    final ketQuaHK = await dichVuHK.layDanhSach();
    final hocKyHienTai = ketQuaHK.data?.items.cast<AcademicTermItem?>().firstWhere(
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
    final ketQuaTKB = await dichVuTKB.layThoiKhoaBieu(hocKyHienTai.academicTermId);

    // Quy ước backend: 1=Chủ nhật, 2=Thứ 2, ..., 7=Thứ 7.
    // DateTime.weekday: 1=Thứ 2, ..., 7=Chủ nhật.
    final thuHomNay = (DateTime.now().weekday % 7) + 1;
    final cacBuoiHomNay = (ketQuaTKB.data ?? [])
        .where((e) => e.daXepLich && e.dayOfWeek == thuHomNay)
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    if (!mounted) return;
    setState(() {
      _dangTai = false;
      _buoiHomNay = cacBuoiHomNay.isNotEmpty ? cacBuoiHomNay.first : null;
      _hocKyId = hocKyHienTai.academicTermId;
      _hocKyLabel = hocKyHienTai.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (_hocKyId == null || _dangTai)
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyTimetableScreen(
                    termId: _hocKyId!,
                    termLabel: _hocKyLabel ?? 'Học kỳ hiện tại',
                  ),
                ),
              ),
      child: Container(
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.today_rounded,
                  color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lịch học hôm nay',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    _dangTai
                        ? 'Đang tải...'
                        : _buoiHomNay == null
                            ? 'Không có lớp học nào hôm nay.'
                            : '${_buoiHomNay!.startTime!.substring(0, 5)}'
                                '-${_buoiHomNay!.endTime!.substring(0, 5)} · '
                                '${_buoiHomNay!.courseName}'
                                '${_buoiHomNay!.room != null ? ' · ${_buoiHomNay!.room}' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!_dangTai && _hocKyId != null)
              Icon(Icons.chevron_right_rounded, color: context.faint),
          ],
        ),
      ),
    );
  }
}

// ── Lưới danh mục nhiều màu ───────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items, required this.onTatCa});
  final List<_FeatureItem> items;
  final VoidCallback onTatCa;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: điện thoại 3 cột, màn rộng (tablet/desktop) 4-5 cột.
        final coRong = constraints.maxWidth;
        final soCot = coRong >= 900 ? 5 : (coRong >= 600 ? 4 : 3);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length + 1, // +1 = tile "Tất cả"
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: soCot,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, i) {
            if (i == items.length) {
              return _FeatureTile(
                item: _FeatureItem(
                  icon: Icons.apps_rounded,
                  label: 'Tất cả',
                  color: context.muted,
                  onTap: (_) => onTatCa(),
                ),
              );
            }
            return _FeatureTile(item: items[i]);
          },
        );
      },
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.item});
  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => item.onTap(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: context.isDark ? 0.22 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext context) onTap;
}

// ── Màn "Tất cả" — danh sách tính năng ít dùng ───────────────────────────────

class _AllFeaturesScreen extends StatelessWidget {
  const _AllFeaturesScreen({required this.items});
  final List<_FeatureItem> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Tất cả tính năng',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                decoration: BoxDecoration(
                  color: context.panel,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: context.border),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(item.label,
                      style: Theme.of(context).textTheme.titleMedium),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: context.faint),
                  onTap: () => item.onTap(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Placeholder "Sắp ra mắt" ──────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    color: AppColors.accent, size: 32),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tính năng đang phát triển',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '"$label" sẽ sớm ra mắt trong bản cập nhật tiếp theo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

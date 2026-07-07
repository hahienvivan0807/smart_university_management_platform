import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/models/dashboard_mock_data.dart';
import 'package:smart_university_management_platform/data/services/quick_access_prefs.dart';
import 'package:smart_university_management_platform/main.dart';
import 'admin_dashboard_screen.dart';
import 'academic_term_list_screen.dart';
import 'course_catalog_home_screen.dart';
import 'course_offering_list_screen.dart';
import 'dashboard/bento_grid_menu.dart';
import 'dashboard/customize_quick_access_screen.dart';
import 'dashboard/dashboard_header.dart';
import 'dashboard/lecturer_dashboard_header.dart';
import 'dashboard/next_class_card.dart';
import 'faculty_list_screen.dart';
import 'program_list_screen.dart';
import 'registration_screen.dart';

// ============================================================================
// DASHBOARD SCREEN  —  tab đầu tiên, hiện ngay sau đăng nhập cho mọi role.
//
// Sinh viên (2026-07-05 — thiết kế lại theo tinh thần "Super App" kiểu
// OneUni): Bento Box UI — header động (lời chào theo buổi + chuông thông
// báo + thẻ SV điện tử) → Focus Card "lớp sắp diễn ra" (dữ liệu thật, đếm
// ngược sống) → lưới Bento bất đối xứng, có ô "Sắp ra mắt" cho tính năng
// chưa có backend (Điểm số/Học phí/Tin tức — xem CONTEXT.md, các phase này
// chưa build). Load lần lượt (staggered fade+slide) khi vào màn.
//
// Giảng viên (2026-07-06 — thiết kế lại): cùng tinh thần Bento Box, nhưng
// không có thẻ SV điện tử/đếm ngược lớp học (Focus Card lịch dạy để dành cho
// đợt sau — cần thêm endpoint backend mới). Ô "Lớp học phần của tôi" luôn
// ghim đầu (không tắt được) và giờ chỉ hiện đúng lớp giảng viên phụ trách
// (trước đây hiện cả lớp của giảng viên khác — xem course_offering_list_screen.dart).
// Các ô còn lại (Danh mục môn học/Chương trình đào tạo/Khoa & Bộ môn/Điểm số)
// tự chọn ghim/bỏ ghim qua nút "Tùy chỉnh" — lưu cục bộ trên máy.
//
// Quản trị: giữ nguyên layout gradient-header + lưới danh mục đơn giản của
// bản trước — ngoài phạm vi yêu cầu thiết kế lại lần này.
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

  @override
  Widget build(BuildContext context) {
    if (_laSinhVien) return const _StudentDashboard();
    if (_laGiangVien && !_laQuanTri) return const _LecturerDashboard();
    return _StaffDashboard(laQuanTri: _laQuanTri, laGiangVien: _laGiangVien);
  }
}

// ============================================================================
// STUDENT DASHBOARD — Bento Box + staggered entrance animation
// ============================================================================

class _StudentDashboard extends StatefulWidget {
  const _StudentDashboard();

  @override
  State<_StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<_StudentDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  /// Mỗi section xuất hiện lệch nhau 1 khoảng [Interval] — tạo cảm giác
  /// "lướt lên hiện dần lần lượt" thay vì cả màn bật ra cùng lúc.
  Widget _staggered(int thuTu, Widget child) {
    final batDau = thuTu * 0.12;
    final ket = (batDau + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(batDau, ket, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<DashboardFeatureConfig> _bentoItems(BuildContext context) => [
        DashboardFeatureConfig(
          id: 'course_offerings',
          label: 'Đăng ký học phần',
          icon: Icons.edit_calendar_rounded,
          gradient: const [Color(0xFF4F7CFF), Color(0xFF3A5FE0)],
          status: BentoStatus.active,
          featured: true,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const RegistrationScreen())),
        ),
        DashboardFeatureConfig(
          id: 'programs',
          label: 'Chương trình đào tạo',
          icon: Icons.menu_book_rounded,
          gradient: const [Color(0xFFA070E8), Color(0xFF7E4FD1)],
          status: BentoStatus.active,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const ProgramListScreen(laManHinhDoc: true))),
        ),
        DashboardFeatureConfig(
          id: 'course_catalog',
          label: 'Danh mục môn học',
          icon: Icons.auto_stories_rounded,
          gradient: const [Color(0xFF2DB7A3), Color(0xFF1F9385)],
          status: BentoStatus.active,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const CourseCatalogHomeScreen(laManHinhDoc: true))),
        ),
        const DashboardFeatureConfig(
          id: 'grades',
          label: 'Điểm số',
          icon: Icons.bar_chart_rounded,
          gradient: [Color(0xFFE8A33D), Color(0xFFD1832A)],
          status: BentoStatus.comingSoon,
        ),
        const DashboardFeatureConfig(
          id: 'tuition',
          label: 'Học phí',
          icon: Icons.account_balance_wallet_rounded,
          gradient: [Color(0xFFE5645B), Color(0xFFCC463D)],
          status: BentoStatus.comingSoon,
        ),
        const DashboardFeatureConfig(
          id: 'news',
          label: 'Tin tức',
          icon: Icons.campaign_rounded,
          gradient: [Color(0xFF5B8DEF), Color(0xFF3E6FD4)],
          status: BentoStatus.comingSoon,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _staggered(0, const DashboardHeader()),
            const SizedBox(height: AppSpacing.lg),
            _staggered(1, const NextClassCard()),
            const SizedBox(height: AppSpacing.lg),
            _staggered(
              2,
              Text('Chức năng', style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            _staggered(3, BentoGridMenu(items: _bentoItems(context))),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// LECTURER DASHBOARD — Bento Box, không thẻ SV/Focus Card lịch dạy (để sau).
// "Lớp học phần của tôi" luôn ghim đầu; phần còn lại tự chọn ghim qua "Tùy chỉnh".
// ============================================================================

const _vaiTroGiangVien = 'Lecturer';

class _LecturerDashboard extends StatefulWidget {
  const _LecturerDashboard();

  @override
  State<_LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<_LecturerDashboard>
    with SingleTickerProviderStateMixin {
  final _prefs = const QuickAccessPrefs();

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  Set<String> _daGhimTuyChon = {};

  /// Ô luôn ghim đầu Dashboard, không tắt được.
  DashboardFeatureConfig get _oCoDinh => DashboardFeatureConfig(
        id: 'my_offerings',
        label: 'Lớp học phần của tôi',
        icon: Icons.class_rounded,
        gradient: const [Color(0xFF4F7CFF), Color(0xFF3A5FE0)],
        status: BentoStatus.active,
        featured: true,
        onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => const CourseOfferingListScreen(laManHinhDoc: true))),
      );

  /// Các ô người dùng tự chọn ghim/bỏ ghim qua màn "Tùy chỉnh".
  List<DashboardFeatureConfig> get _oTuyChon => [
        DashboardFeatureConfig(
          id: 'course_catalog',
          label: 'Danh mục môn học',
          icon: Icons.auto_stories_rounded,
          gradient: const [Color(0xFF2DB7A3), Color(0xFF1F9385)],
          status: BentoStatus.active,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const CourseCatalogHomeScreen(laManHinhDoc: true))),
        ),
        DashboardFeatureConfig(
          id: 'programs',
          label: 'Chương trình đào tạo',
          icon: Icons.menu_book_rounded,
          gradient: const [Color(0xFFA070E8), Color(0xFF7E4FD1)],
          status: BentoStatus.active,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const ProgramListScreen(laManHinhDoc: true))),
        ),
        DashboardFeatureConfig(
          id: 'faculties',
          label: 'Khoa & Bộ môn',
          icon: Icons.account_balance_rounded,
          gradient: const [Color(0xFFE8A33D), Color(0xFFD1832A)],
          status: BentoStatus.active,
          onTap: (ctx) => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => const FacultyListScreen(laManHinhDoc: true))),
        ),
        const DashboardFeatureConfig(
          id: 'grades',
          label: 'Điểm số',
          icon: Icons.bar_chart_rounded,
          gradient: [Color(0xFFE5645B), Color(0xFFCC463D)],
          status: BentoStatus.comingSoon,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _taiDaGhim();
  }

  Future<void> _taiDaGhim() async {
    final daGhim = await _prefs.layDaGhim(_vaiTroGiangVien);
    if (!mounted) return;
    setState(() => _daGhimTuyChon = daGhim);
  }

  Future<void> _moTuyChinh(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => CustomizeQuickAccessScreen(
        vaiTro: _vaiTroGiangVien,
        chucNangCoDinh: [_oCoDinh],
        chucNangTuyChon: _oTuyChon,
      ),
    ));
    _taiDaGhim();
  }

  Widget _staggered(int thuTu, Widget child) {
    final batDau = thuTu * 0.12;
    final ket = (batDau + 0.5).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _controller,
      curve: Interval(batDau, ket, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _oCoDinh,
      for (final cfg in _oTuyChon)
        if (_daGhimTuyChon.contains(cfg.id)) cfg,
    ];

    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _staggered(0, const LecturerDashboardHeader()),
            const SizedBox(height: AppSpacing.lg),
            _staggered(
              1,
              Row(
                children: [
                  Expanded(
                    child: Text('Chức năng',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  IconButton(
                    tooltip: 'Tùy chỉnh',
                    icon: const Icon(Icons.tune_rounded, size: 20),
                    onPressed: () => _moTuyChinh(context),
                  ),
                ],
              ),
            ),
            _staggered(2, BentoGridMenu(items: items)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STAFF DASHBOARD (Quản trị) — layout đơn giản, giữ nguyên từ bản trước đó,
// ngoài phạm vi thiết kế lại lần này. Giảng viên giờ dùng _LecturerDashboard
// ở trên.
// ============================================================================

class _StaffDashboard extends StatelessWidget {
  const _StaffDashboard({required this.laQuanTri, required this.laGiangVien});

  final bool laQuanTri;
  final bool laGiangVien;

  List<_FeatureItem> get _tinhNangHayDung {
    if (laQuanTri) {
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
    if (laGiangVien) {
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
    return const [];
  }

  List<_FeatureItem> get _tinhNangItDung {
    if (laQuanTri) {
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
            builder: (_) => const CourseCatalogHomeScreen(laManHinhDoc: true))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _GreetingHeader(),
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

// ── Header chào (gradient card — dùng chung cho Giảng viên/Quản trị) ────────

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

// ── Lưới danh mục nhiều màu (Giảng viên/Quản trị) ────────────────────────────

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

// ── Placeholder "Sắp ra mắt" (dùng cho các tính năng Giảng viên/Quản trị
// chưa build — Bento Sinh viên dùng SnackBar trực tiếp thay vì màn riêng,
// xem feature_bento_card.dart) ────────────────────────────────────────────

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

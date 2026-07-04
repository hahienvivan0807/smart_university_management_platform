import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/data/services/auth_service.dart';
import 'package:smart_university_management_platform/data/services/token_storage.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_selection_screen.dart';
import 'package:smart_university_management_platform/main.dart';
import 'screens/academic_term_list_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/course_catalog_home_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/faculty_list_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/program_list_screen.dart';

// ============================================================================
// APP SHELL  —  khung chính của app sau khi đăng nhập
//
// ┌─────────────────────────────────────────────────────────────────┐
// │ CƠ CHẾ HOẠT ĐỘNG                                                │
// │                                                                 │
// │  NavigationDrawer          IndexedStack                         │
// │  ┌────────────┐            ┌──────────────────────┐             │
// │  │  Header    │            │  [0] FacultyList     │ ← hiện      │
// │  │  role+icon │  ───[0]──▶ │  [1] CourseCatalog   │ ← ẩn        │
// │  │───────────│            │  [2] TermOfferings   │ ← ẩn        │
// │  │ [0] Khoa  │  ───[1]──▶ │  ...                 │             │
// │  │ [1] Môn   │  ───[2]──▶ └──────────────────────┘             │
// │  │ [2] Kỳ   │                                                   │
// │  │───────────│   Tại sao IndexedStack thay vì Navigator.push?   │
// │  │ Đăng xuất │     → push tạo widget mới mỗi lần chuyển tab     │
// │  └────────────┘     → IndexedStack giữ tất cả widget alive,     │
// │                       chỉ ẩn/hiện — state (scroll, data)        │
// │                       được bảo toàn khi quay lại tab cũ         │
// └─────────────────────────────────────────────────────────────────┘
//
// ROLE-BASED MENU:
//   Tất cả user → thấy Khoa/Bộ môn, Danh mục môn học, Học kỳ & Lớp HP
//   Admin / AcademicOffice → thấy thêm section "Quản trị"
//   (kiểm tra session.roles từ main.dart — đây là roles thật từ JWT,
//    không phải activeRole do user chọn trên UI)
//
// ACTIVE ROLE vs REAL ROLES:
//   activeRole  = role user chọn khi login (UX navigation state)
//                 → dùng để hiện tiêu đề "Xin chào, Giảng Viên"
//   session.roles = danh sách role thật từ JWT
//                 → dùng để kiểm tra quyền show/hide menu + CRUD
// ============================================================================

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.activeRole});

  /// Role user chọn khi login — chỉ để hiển thị tên/icon trong header.
  /// KHÔNG dùng để kiểm tra quyền (dùng session.roles cho việc đó).
  final AppRole activeRole;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Index của tab đang được hiển thị trong IndexedStack.
  /// Khi user chọn menu item, _selectedIndex thay đổi → setState → rebuild.
  int _selectedIndex = 0;

  /// Danh sách tab theo đúng thứ tự xuất hiện trong NavigationDrawer.
  /// IndexedStack dùng cùng thứ tự này: children[0] = tab đầu tiên.
  ///
  /// Tại sao khai báo late? Vì _buildTabs() gọi trong initState sau super.initState(),
  /// đảm bảo widget.activeRole đã sẵn sàng.
  late final List<_Tab> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = _buildTabs();
    // Dashboard (tab 0) luôn là màn đầu tiên user thấy sau đăng nhập,
    // cho mọi role — đây chính là ý nghĩa của "trang chủ".
    _selectedIndex = 0;

    // Tải FullName/Email 1 lần cho màn Dashboard + Profile. Không cần
    // await trong initState (fire-and-forget) — AnimatedBuilder trong 2
    // màn đó tự rebuild khi session.me có dữ liệu.
    session.taiThongTinCuaToi(AuthService(client: authenticatedClient));
  }

  /// Xây danh sách tab dựa trên role thật (session.roles từ JWT).
  List<_Tab> _buildTabs() {
    // Tabs cơ bản: mọi user đã đăng nhập đều thấy
    final tabs = <_Tab>[
      _Tab(
        icon: Icons.dashboard_outlined,
        iconSelected: Icons.dashboard,
        label: 'Trang chủ',
        screen: const DashboardScreen(),
      ),
      _Tab(
        icon: Icons.account_balance_outlined,
        iconSelected: Icons.account_balance,
        label: 'Khoa & Bộ môn',
        // FacultyListScreen: user tap → DepartmentListScreen (drill-down)
        screen: const FacultyListScreen(),
      ),
      _Tab(
        icon: Icons.book_outlined,
        iconSelected: Icons.book,
        label: 'Danh mục môn học',
        screen: const CourseCatalogHomeScreen(),
      ),
      _Tab(
        icon: Icons.calendar_month_outlined,
        iconSelected: Icons.calendar_month,
        label: 'Học kỳ & Lớp HP',
        screen: const AcademicTermListScreen(),
      ),
      _Tab(
        icon: Icons.menu_book_outlined,
        iconSelected: Icons.menu_book,
        label: 'Chương trình đào tạo',
        screen: const ProgramListScreen(),
      ),
    ];

    // Admin/AcademicOffice thấy thêm tab Quản trị
    final roles = session.roles;
    final coQuyenQuanTri =
        roles.contains('Admin') || roles.contains('AcademicOffice');
    if (coQuyenQuanTri) {
      tabs.add(_Tab(
        icon: Icons.admin_panel_settings_outlined,
        iconSelected: Icons.admin_panel_settings,
        label: 'Quản trị',
        screen: const AdminDashboardScreen(),
      ));
    }

    return tabs;
  }

  /// Đóng drawer + chuyển tab.
  /// Navigator.pop(context) để đóng drawer trước khi setState,
  /// tránh animation bị giật khi cả 2 thay đổi cùng lúc.
  void _chonTab(int index) {
    Navigator.pop(context); // đóng NavigationDrawer
    setState(() => _selectedIndex = index);
  }

  Future<void> _dangXuat() async {
    // 1. Đóng drawer
    Navigator.pop(context);
    // 2. Xóa token khỏi secure storage
    await TokenStorage().clear();
    // 3. Xóa session state (session là global từ main.dart)
    session.logout();
    // 4. Về màn hình chọn role (xóa toàn bộ stack — không thể back lại)
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false, // predicator false = xóa mọi route trong stack
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,

      // AppBar: hamburger icon mở drawer + tên tab đang chọn
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Builder cần thiết để lấy đúng Scaffold context chứa drawer
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu_rounded, color: context.text),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          _tabs[_selectedIndex].label,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Hồ sơ cá nhân',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),

      // NavigationDrawer: side panel kéo từ bên trái
      // selectedIndex chỉ đếm NavigationDrawerDestination, bỏ qua widget khác
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _chonTab,
        backgroundColor: context.sidebar,
        indicatorColor: context.accentSoft,
        children: [
          // ── Header: thông tin user ────────────────────────────────────
          _DrawerHeader(role: widget.activeRole),

          // ── Nav destinations ──────────────────────────────────────────
          // Mỗi NavigationDrawerDestination tương ứng 1 index trong IndexedStack
          for (final tab in _tabs)
            NavigationDrawerDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.iconSelected, color: AppColors.accent),
              label: Text(tab.label),
            ),

          // ── Phân tách trước Đăng xuất ─────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            child: Divider(),
          ),

          // ── Đăng xuất: ListTile thường (không phải Destination) ────────
          // Không đưa vào IndexedStack vì đây là action, không phải tab
          ListTile(
            leading: Icon(Icons.logout_rounded, color: context.muted, size: 22),
            title: Text('Đăng xuất',
                style: Theme.of(context).textTheme.bodyLarge),
            onTap: _dangXuat,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md + 4),
          ),
        ],
      ),

      // IndexedStack: render TẤT CẢ screens cùng lúc, chỉ hiện 1 cái
      //
      // Tại sao không dùng if/else hoặc switch?
      //   → if/else destroy & recreate widget mỗi lần đổi tab
      //   → IndexedStack giữ state sống: FacultyListScreen đã load data
      //     rồi, chuyển sang tab khác rồi quay lại vẫn thấy data cũ
      //     (không cần reload = nhanh hơn, ít request hơn)
      body: IndexedStack(
        index: _selectedIndex,
        children: [for (final tab in _tabs) tab.screen],
      ),
    );
  }
}

// ── Data class cho mỗi tab ────────────────────────────────────────────────────

class _Tab {
  const _Tab({
    required this.icon,
    required this.iconSelected,
    required this.label,
    required this.screen,
  });

  final IconData icon;
  final IconData iconSelected;
  final String label;
  final Widget screen; // widget thực tế được nhúng vào IndexedStack
}

// ── Drawer header: hiện role icon + tên ──────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.role});
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo gradient (nhất quán với splash/login)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6E6ADE), AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Smart University',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          // Hiện role name từ AppRole.label (VD: "Giảng Viên", "Sinh Viên")
          Row(
            children: [
              Icon(role.icon, size: 13, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                role.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/features/academic/app_shell.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_picker_screen.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_selection_screen.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// SPLASH SCREEN  —  brand-first launch
//
// Shows the logo and app name on a clean canvas, then auto-advances to the
// role-selection screen after a short, deliberate pause (2s — long enough to
// register the branding, short enough not to feel like a loading problem).
//
// A gentle fade-in + slight scale on the logo makes the entrance feel
// intentional rather than abrupt. Honors the platform's reduced-motion
// setting: when disabled, the brand simply appears.
// ============================================================================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(seconds: 2);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scaleIn = Tween<double>(
    begin: 0.92,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _scheduleAdvance();
  }

  Future<void> _scheduleAdvance() async {
    // Bước 1: đợi 2 giây để hiện branding
    await Future.delayed(_hold);

    // Bước 2: kiểm tra mounted trước khi dùng context
    // (widget có thể bị dispose trong lúc chờ)
    if (!mounted) return;

    // Bước 3: hỏi storage — user đã đăng nhập chưa?
    // Dùng đúng `tokenStorage` (biến global từ main.dart) — KHÔNG tạo
    // TokenStorage() mới ở đây, vì trên Windows các instance
    // FlutterSecureStorage độc lập không nhìn thấy dữ liệu của nhau.
    final hasSession = await tokenStorage.hasSession();

    // Bước 4: kiểm tra mounted lần 2 vì storage.hasSession() cũng là async
    if (!mounted) return;

    // Bước 5: nếu chưa có session → đi màn chọn vai trò / đăng nhập
    if (!hasSession) {
      Navigator.of(context)
          .pushReplacement(_fade(const RoleSelectionScreen()));
      return;
    }

    // Bước 6: có session → đọc roles đã lưu
    final roles = await tokenStorage.readRoles();
    if (!mounted) return;

    // Bước 7: edge case — có token nhưng roles bị mất (xóa thủ công,
    // cài lại app, v.v.) → về đăng nhập lại cho an toàn
    if (roles.isEmpty) {
      Navigator.of(context)
          .pushReplacement(_fade(const RoleSelectionScreen()));
      return;
    }

    // Bước 8: khôi phục session từ storage
    session.restore(roles);

    // Bước 9: route theo số lượng role
    final Widget destination = roles.length == 1
        ? AppShell(activeRole: AppRole.fromBackendId(roles.first))
        : RolePickerScreen(roles: roles);

    Navigator.of(context).pushReplacement(_fade(destination));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final brand = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Logo(size: 64),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Smart University',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Campus, organized.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );

    return Scaffold(
      backgroundColor: context.canvas,
      body: Center(
        child: reduceMotion
            ? brand
            : FadeTransition(
                opacity: _fadeIn,
                child: ScaleTransition(scale: _scaleIn, child: brand),
              ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Brand mark — same gradient lockup used on the login screen, scaled up.
// ----------------------------------------------------------------------------

class _Logo extends StatelessWidget {
  const _Logo({this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6ADE), AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

// ----------------------------------------------------------------------------

PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );

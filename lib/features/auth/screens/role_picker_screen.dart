import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/home/screens/workspace_screen.dart';

// ============================================================================
// ROLE PICKER SCREEN  —  post-login, shown only when requiresRoleSelection=true
//
// Different from RoleSelectionScreen (pre-login UX hint):
//   • RoleSelectionScreen  → shown before login, lists ALL possible roles
//   • RolePickerScreen     → shown AFTER login, lists only the roles the JWT
//                            confirms this account actually has
//
// The chosen role is stored as Flutter navigation state (constructor param on
// WorkspaceScreen). It is NEVER sent to the API. The JWT's real roles remain
// the sole authority for what the user is permitted to do.
// ============================================================================

class RolePickerScreen extends StatelessWidget {
  // Nhận List<String> thay vì LoginResponse
  // → dùng được cả từ login lẫn từ storage khi app khởi động lại
  const RolePickerScreen({super.key, required this.roles});

  final List<String> roles; // ví dụ: ["Student", "Lecturer"]

  void _pick(BuildContext context, AppRole role) {
    Navigator.of(context).pushReplacement(
      _fade(WorkspaceScreen(activeRole: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Chuyển mỗi String role → AppRole (có label, icon tiếng Việt)
    final appRoles = roles.map(AppRole.fromBackendId).toList();

    return Scaffold(
      backgroundColor: context.panel,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _Logo(size: 30),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Smart University',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Text(
                    'Chọn không gian làm việc',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    // roles.length dùng được vì đây là List<String> — chỉ đếm số lượng
                    'Tài khoản của bạn có ${roles.length} vai trò. '
                    'Hãy chọn vai trò cho phiên này.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Dùng appRoles (List<AppRole>) thay vì roles (List<String>)
                  // vì _RoleCard và _pick cần AppRole (có icon, label, blurb)
                  for (final role in appRoles) ...[
                    _RoleCard(
                      role: role,
                      onTap: () => _pick(context, role),
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Lựa chọn này chỉ xác định giao diện — không ảnh hưởng đến quyền hệ thống.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------

class _RoleCard extends StatefulWidget {
  const _RoleCard({required this.role, required this.onTap});
  final AppRole role;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.canvas,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hover ? AppColors.accent : context.border,
              width: _hover ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                    alpha: context.isDark ? 0.0 : (_hover ? 0.05 : 0.02)),
                blurRadius: _hover ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: context.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.role.icon,
                    color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.role.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(widget.role.blurb,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 12.5)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: context.faint),
            ],
          ),
        ),
      ),
    );
  }
}

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
      ),
      child: Icon(Icons.school_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    );

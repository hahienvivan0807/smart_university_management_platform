import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/auth/screens/login_screen.dart';

// ============================================================================
// ROLE SELECTION SCREEN
//
// Surfaces the two everyday roles — Student and Lecturer — as large, obvious
// cards. The three staff roles (Department Staff, Academic Office, Admin) live
// behind a discreet "Staff access" entry point so the main screen stays clean
// and an admin login path isn't advertised to every student who opens the app.
//
// IMPORTANT — the selected role is UX-only navigation state. It is passed to
// LoginScreen purely so the screen can show a "Signing in as ..." hint. It is
// NEVER sent to the API and NEVER used for authorization. The JWT's real roles
// are the only thing that decides what a signed-in user can do — tapping
// "Admin" here grants nothing unless the account actually has that role.
//
// Role identifiers match the seeded Roles table:
//   Student · Lecturer · DepartmentStaff · AcademicOffice · Admin
// ============================================================================

// A selectable role. [id] matches the Roles table Name column exactly.

const _primaryRoles = <AppRole>[
  AppRole(
    id: 'Sinh Viên',
    label: 'Sinh Viên',
    blurb: 'Các môn học, điểm số và lịch học',
    icon: Icons.school_outlined,
  ),
  AppRole(
    id: 'Giảng Viên',
    label: 'Giảng Viên',
    blurb: 'Lớp học, danh sách học sinh và chấm điểm',
    icon: Icons.co_present_outlined,
  ),
];

const _staffRoles = <AppRole>[
  AppRole(
    id: 'DepartmentStaff',
    label: 'Department Staff',
    blurb: 'Department and faculty operations',
    icon: Icons.groups_outlined,
  ),
  AppRole(
    id: 'AcademicOffice',
    label: 'Academic Office',
    blurb: 'Enrollment and academic records',
    icon: Icons.account_balance_outlined,
  ),
  AppRole(
    id: 'Admin',
    label: 'Administrator',
    blurb: 'System administration',
    icon: Icons.shield_outlined,
  ),
];

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _staffExpanded = false;

  void _select(AppRole role) {
    // Hand the chosen role to the login screen as a display-only hint.
    Navigator.of(context).push(_fade(LoginScreen(selectedRole: role)));
  }

  @override
  Widget build(BuildContext context) {
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
                  // Brand lockup.
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

                  Text("Ai đang sử dụng?",
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hãy lựa chọn cách bạn sử dụng nền tảng này.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Two primary roles.
                  for (final role in _primaryRoles) ...[
                    _RoleCard(role: role, onTap: () => _select(role)),
                    const SizedBox(height: AppSpacing.sm + 2),
                  ],

                  const SizedBox(height: AppSpacing.xs),

                  // Discreet staff entry point.
                  _StaffToggle(
                    expanded: _staffExpanded,
                    onTap: () =>
                        setState(() => _staffExpanded = !_staffExpanded),
                  ),

                  // Revealed staff roles.
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState: _staffExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.sm + 2),
                        for (final role in _staffRoles) ...[
                          _RoleCard(
                            role: role,
                            compact: true,
                            onTap: () => _select(role),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Tài khoản được cấp bởi trường học của bạn.',
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
// A single role card. [compact] tightens it for the revealed staff list.
// ----------------------------------------------------------------------------

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.role,
    required this.onTap,
    this.compact = false,
  });

  final AppRole role;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final iconBox = widget.compact ? 38.0 : 46.0;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: EdgeInsets.all(
              widget.compact ? AppSpacing.sm + 4 : AppSpacing.md),
          decoration: BoxDecoration(
            color: context.canvas,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: _hover ? AppColors.accent : context.border,
              width: _hover ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(context.isDark ? 0.0 : (_hover ? 0.05 : 0.02)),
                blurRadius: _hover ? 18 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: iconBox,
                width: iconBox,
                decoration: BoxDecoration(
                  color: context.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(widget.role.icon,
                    color: AppColors.accent,
                    size: widget.compact ? 19 : 22),
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
// The discreet staff-access entry point. Low-key by design: a small key icon
// and quiet label, not a prominent button.
// ----------------------------------------------------------------------------

class _StaffToggle extends StatelessWidget {
  const _StaffToggle({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.key_outlined, size: 15, color: context.faint),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              'Quyền quản trị',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: context.muted),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              duration: const Duration(milliseconds: 200),
              turns: expanded ? 0.5 : 0,
              child: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: context.faint),
            ),
          ],
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
  transitionDuration: const Duration(milliseconds: 340),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, animation, __, child) {
    // New page slides up from slightly below while fading in.
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ));

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(position: slide, child: child),
    );
  },
);


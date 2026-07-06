import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_selection_screen.dart';
import 'package:smart_university_management_platform/main.dart';
import 'change_password_screen.dart';

// ============================================================================
// PROFILE SCREEN  —  avatar, thông tin cá nhân, đổi mật khẩu, đăng xuất.
// Mở từ nút avatar trên AppBar của AppShell.
// ============================================================================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _dangXuat(BuildContext context) async {
    await tokenStorage.clear();
    session.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvas,
      appBar: AppBar(
        backgroundColor: context.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Hồ sơ cá nhân',
            style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: AnimatedBuilder(
        animation: session,
        builder: (context, _) {
          final me = session.me;
          final role = session.activeRole;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Center(
                child: Column(
                  children: [
                    _AvatarCircle(fullName: me?.fullName, role: role),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      me?.fullName ?? 'Đang tải...',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role?.label ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: context.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _InfoCard(
                children: [
                  _InfoRow(icon: Icons.badge_outlined, label: 'Mã đăng nhập', value: me?.loginCode ?? '—'),
                  _InfoRow(icon: Icons.email_outlined, label: 'Email', value: me?.email ?? '—'),
                  _InfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Vai trò',
                    value: me?.roles.join(', ') ?? '—',
                    laHangCuoi: true,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _ActionCard(
                icon: Icons.lock_outline_rounded,
                label: 'Đổi mật khẩu',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ActionCard(
                icon: Icons.logout_rounded,
                label: 'Đăng xuất',
                color: AppColors.red,
                onTap: () => _dangXuat(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.fullName, required this.role});
  final String? fullName;
  final AppRole? role;

  String get _chuCai {
    if (fullName == null || fullName!.trim().isEmpty) return '?';
    final parts = fullName!.trim().split(RegExp(r'\s+'));
    return parts.last[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6E6ADE), AppColors.accent],
        ),
      ),
      child: Center(
        child: Text(
          _chuCai,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Card thông tin chi tiết ───────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.panel,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.border),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.laHangCuoi = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool laHangCuoi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: laHangCuoi
            ? null
            : Border(bottom: BorderSide(color: context.border)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.muted),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action card (đổi mật khẩu / đăng xuất) ────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final mau = color ?? context.text;
    return Material(
      color: context.panel,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: context.border),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Icon(icon, size: 20, color: mau),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: mau, fontWeight: FontWeight.w500)),
              ),
              Icon(Icons.chevron_right_rounded, color: context.faint),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/features/auth/models/app_role.dart';
import 'package:smart_university_management_platform/features/auth/screens/role_selection_screen.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// WORKSPACE SCREEN  —  placeholder for the role-specific app shell
//
// Phase 1 goal: prove routing lands here correctly with the chosen role.
// Phase 2+ will replace the body with real content (courses, timetable, etc.)
// per role. The [activeRole] is UX-only navigation state — it controls which
// workspace the user sees, not what the API permits.
// ============================================================================

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key, required this.activeRole});

  final AppRole activeRole;

  Future<void> _logout(BuildContext context) async {
    await tokenStorage.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.panel,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    color: context.accentSoft,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(activeRole.icon,
                      color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  activeRole.label,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  activeRole.blurb,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: context.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: context.border),
                  ),
                  child: Text(
                    'Workspace — Phase 2 sẽ xây dựng nội dung tại đây.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: context.muted),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Đăng xuất'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

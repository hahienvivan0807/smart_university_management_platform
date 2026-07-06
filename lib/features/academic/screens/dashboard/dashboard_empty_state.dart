import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';

// ============================================================================
// DASHBOARD EMPTY STATE — widget tái dùng cho các card không có dữ liệu.
//
// Không dùng Lottie (chưa có asset + không muốn thêm package `lottie` chỉ
// cho 1 hiệu ứng) — thay bằng animation Flutter thuần: icon "thở" nhẹ
// (scale lên/xuống liên tục) trong 1 vòng tròn gradient mềm, đủ sống động
// mà không cần asset ngoài.
// ============================================================================

class DashboardEmptyState extends StatefulWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  State<DashboardEmptyState> createState() => _DashboardEmptyStateState();
}

class _DashboardEmptyStateState extends State<DashboardEmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  late final Animation<double> _breathe = Tween<double>(begin: 0.94, end: 1.06)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _breathe,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      context.accentSoft,
                      AppColors.accent.withValues(alpha: 0.18),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: AppColors.accent, size: 26),
              ),
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

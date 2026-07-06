import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/main.dart';
import 'digital_student_card_sheet.dart';

// ============================================================================
// DASHBOARD HEADER — lời chào theo buổi + avatar + chuông thông báo (pulse)
// + thẻ sinh viên điện tử thu nhỏ.
//
//   • Lời chào "Chào buổi sáng/chiều/tối" tính theo `DateTime.now().hour`
//     (dữ liệu thật — giờ máy, không mock).
//   • Chuông thông báo: MOCK số chưa đọc (Phase 6 Notification chưa có
//     backend) — pulse animation chỉ chạy khi có số > 0; bấm vào hiện
//     SnackBar báo tính năng đang phát triển, KHÔNG bịa ra 1 màn danh sách
//     thông báo giả.
//   • Thẻ SV thu nhỏ: dữ liệu thật (`session.me`), bấm để phóng to xem QR
//     (xem digital_student_card_sheet.dart).
// ============================================================================

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  String _loiChao() {
    final gio = DateTime.now().hour;
    if (gio < 11) return 'Chào buổi sáng';
    if (gio < 14) return 'Chào buổi trưa';
    if (gio < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

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
        final me = session.me;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6E6ADE), AppColors.accent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _chuCai(me?.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
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
                      Text(_loiChao(),
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        me?.fullName ?? 'Sinh viên',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                const _NotificationBell(),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (me != null)
              _MiniStudentCard(
                  onTap: () => showDigitalStudentCardSheet(context, me)),
          ],
        );
      },
    );
  }
}

// ── Chuông thông báo (mock số chưa đọc + pulse) ──────────────────────────────

class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  // MOCK — Phase 6 (Notification) chưa có backend, xem CONTEXT.md.
  static const _soChuaDoc = 2;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  @override
  void initState() {
    super.initState();
    if (_soChuaDoc > 0) _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _xuLyBam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng thông báo đang được phát triển.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _xuLyBam,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.panel,
          shape: BoxShape.circle,
          border: Border.all(color: context.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.notifications_outlined, color: context.text, size: 20),
            if (_soChuaDoc > 0)
              Positioned(
                top: 9,
                right: 10,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.25).animate(
                      CurvedAnimation(
                          parent: _controller, curve: Curves.easeInOut)),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Thẻ sinh viên thu nhỏ ─────────────────────────────────────────────────────

class _MiniStudentCard extends StatelessWidget {
  const _MiniStudentCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: context.panel,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2_rounded,
                color: AppColors.accent, size: 18),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text('Xem thẻ sinh viên điện tử',
                  style: Theme.of(context).textTheme.labelLarge),
            ),
            Icon(Icons.chevron_right_rounded, size: 18, color: context.faint),
          ],
        ),
      ),
    );
  }
}

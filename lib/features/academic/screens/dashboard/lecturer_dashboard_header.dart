import 'package:flutter/material.dart';

import 'package:smart_university_management_platform/core/theme.dart';
import 'package:smart_university_management_platform/main.dart';

// ============================================================================
// LECTURER DASHBOARD HEADER — cùng ngôn ngữ hình ảnh với DashboardHeader bên
// Sinh viên (lời chào theo buổi + avatar + chuông thông báo), nhưng KHÔNG có
// thẻ SV điện tử (không áp dụng cho giảng viên). Chuông thông báo vẫn là
// mock trang trí — chưa có luồng thông báo nào thật sự gửi tới giảng viên
// (Notification hiện chỉ gửi cho sinh viên khi lớp tạm ngưng), nên cố tình
// không giả vờ có dữ liệu thật.
// ============================================================================

class LecturerDashboardHeader extends StatelessWidget {
  const LecturerDashboardHeader({super.key});

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
        return Row(
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
                  Text(_loiChao(), style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    me?.fullName ?? 'Giảng viên',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            const _LecturerNotificationBell(),
          ],
        );
      },
    );
  }
}

// ── Chuông thông báo (trang trí, chưa nối dữ liệu thật) ──────────────────────

class _LecturerNotificationBell extends StatelessWidget {
  const _LecturerNotificationBell();

  void _xuLyBam(BuildContext context) {
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
      onTap: () => _xuLyBam(context),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: context.panel,
          shape: BoxShape.circle,
          border: Border.all(color: context.border),
        ),
        child: Icon(Icons.notifications_outlined, color: context.text, size: 20),
      ),
    );
  }
}

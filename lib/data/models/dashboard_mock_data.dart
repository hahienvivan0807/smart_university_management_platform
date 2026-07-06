import 'package:flutter/material.dart';

// ============================================================================
// DASHBOARD MOCK DATA — model thuần cho phần Student Dashboard CHƯA có backend
// thật (câu quote động lực, cấu hình các ô Bento). Khi Phase 6/7 (Notification/
// Analytics) hoặc Tuition/News có API thật, chỉ cần thay nguồn dữ liệu ở
// dashboard_screen.dart — các widget con không cần sửa vì đều nhận vào model
// này, không tự fetch.
// ============================================================================

/// Câu động lực hiển thị trong `NextClassCard` khi hôm nay không còn lớp nào.
/// Thuần mock — không có endpoint "quote of the day" ở backend.
class MotivationalQuote {
  const MotivationalQuote(this.text, this.author);

  final String text;
  final String author;

  static const _all = [
    MotivationalQuote(
        'Đừng đợi cơ hội, hãy tạo ra nó.', 'George Bernard Shaw'),
    MotivationalQuote(
        'Kỷ luật là cầu nối giữa mục tiêu và thành tựu.', 'Jim Rohn'),
    MotivationalQuote(
        'Học hôm nay để dẫn đầu ngày mai.', 'Khuyết danh'),
    MotivationalQuote(
        'Thành công là tổng của những nỗ lực nhỏ lặp lại mỗi ngày.',
        'Robert Collier'),
  ];

  /// Chọn 1 câu ổn định theo ngày (không đổi mỗi lần rebuild trong ngày).
  factory MotivationalQuote.ofToday() =>
      _all[DateTime.now().day % _all.length];
}

/// Trạng thái 1 ô trong Bento Grid.
enum BentoStatus { active, comingSoon }

/// Cấu hình tĩnh cho 1 ô chức năng trong Bento Grid — KHÔNG chứa dữ liệu
/// nghiệp vụ, chỉ mô tả cách hiển thị + hành động khi bấm.
class DashboardFeatureConfig {
  const DashboardFeatureConfig({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.status,
    this.featured = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final BentoStatus status;

  /// true = ô lớn chiếm hàng đầu Bento (hiệu ứng bất đối xứng).
  final bool featured;

  /// null khi [status] = comingSoon (khi đó bấm vào chỉ hiện Snackbar).
  final void Function(BuildContext context)? onTap;
}
